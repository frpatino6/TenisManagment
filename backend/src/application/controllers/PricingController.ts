import { Request, Response } from 'express';
import { SystemConfigModel } from '../../infrastructure/database/models/SystemConfigModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';

import { Logger } from '../../infrastructure/services/Logger';

// Default base pricing
const DEFAULT_BASE_PRICING = {
  individualClass: 50000,
  groupClass: 35000,
  courtRental: 25000,
};

export class PricingController {
  private readonly logger: Logger;

  constructor() {
    this.logger = new Logger({ service: 'PricingController' });
  }

  /**
   * Get base pricing configuration (system-wide defaults)
   */
  getBasePricing = async (req: Request, res: Response) => {
    try {
      const config = await SystemConfigModel.findOne({ key: 'base_pricing' });

      if (!config) {
        // If no config exists, return defaults
        return res.json({
          pricing: DEFAULT_BASE_PRICING,
          source: 'default',
        });
      }

      this.logger.info('Base pricing retrieved', { source: config ? 'system' : 'default' });

      res.json({
        pricing: config?.value || DEFAULT_BASE_PRICING,
        source: config ? 'system' : 'default',
        updatedAt: config?.updatedAt,
      });
    } catch (error) {
      this.logger.error('Error getting base pricing', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get effective pricing for a specific professor
   * Returns professor's custom pricing merged with base pricing
   */
  getProfessorPricing = async (req: Request, res: Response) => {
    try {
      const { professorId } = req.params;

      // Get base pricing
      const baseConfig = await SystemConfigModel.findOne({ key: 'base_pricing' });
      const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;

      // Get professor
      const professor = await ProfessorModel.findById(professorId);
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Merge custom pricing with base pricing
      const effectivePricing = {
        individualClass:
          professor.pricing?.individualClass ?? basePricing.individualClass,
        groupClass: professor.pricing?.groupClass ?? basePricing.groupClass,
        courtRental: professor.pricing?.courtRental ?? basePricing.courtRental,
      };

      this.logger.info('Producer pricing retrieved', { professorId, professorName: professor.name });

      res.json({
        professorId: professor._id,
        professorName: professor.name,
        pricing: effectivePricing,
        customPricing: professor.pricing || {},
        basePricing,
      });
    } catch (error) {
      this.logger.error('Error getting professor pricing', { error: (error as Error).message, professorId: req.params.professorId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get current professor's pricing (authenticated)
   */
  getMyPricing = async (req: Request, res: Response) => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
      }

      // Get base pricing
      const baseConfig = await SystemConfigModel.findOne({ key: 'base_pricing' });
      const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;

      // Merge custom pricing with base pricing
      const effectivePricing = {
        individualClass:
          professor.pricing?.individualClass ?? basePricing.individualClass,
        groupClass: professor.pricing?.groupClass ?? basePricing.groupClass,
        courtRental: professor.pricing?.courtRental ?? basePricing.courtRental,
      };

      this.logger.info('My pricing retrieved', { professorId: professor._id });

      res.json({
        pricing: effectivePricing,
        customPricing: professor.pricing || {},
        basePricing,
        hasCustomPricing: !!professor.pricing,
      });
    } catch (error) {
      this.logger.error('Error getting my pricing', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Update current professor's custom pricing
   */
  updateMyPricing = async (req: Request, res: Response) => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        this.logger.warn('No firebaseUid found in updateMyPricing');
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { individualClass, groupClass, courtRental } = req.body;
      this.logger.info('Updating pricing', { firebaseUid, prices: { individualClass, groupClass, courtRental } });

      // Validate pricing values
      if (individualClass !== undefined && (individualClass < 0 || individualClass > 1000000)) {
        return res.status(400).json({ error: 'Precio de clase individual inválido' });
      }
      if (groupClass !== undefined && (groupClass < 0 || groupClass > 1000000)) {
        return res.status(400).json({ error: 'Precio de clase grupal inválido' });
      }
      if (courtRental !== undefined && (courtRental < 0 || courtRental > 1000000)) {
        return res.status(400).json({ error: 'Precio de alquiler de cancha inválido' });
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
      }

      // Build update object
      const updateData: any = {};

      if (individualClass !== undefined) {
        updateData['pricing.individualClass'] = individualClass;
      }

      if (groupClass !== undefined) {
        updateData['pricing.groupClass'] = groupClass;
      }

      if (courtRental !== undefined) {
        updateData['pricing.courtRental'] = courtRental;
      }

      // Update using findOneAndUpdate
      const updatedProfessor = await ProfessorModel.findOneAndUpdate(
        { authUserId: authUser._id },
        { $set: updateData },
        { new: true }
      );

      if (!updatedProfessor) {
        this.logger.error('Professor not found after update', { authUserId: authUser._id });
        return res.status(404).json({ error: 'Error al actualizar precios' });
      }

      this.logger.info('Pricing updated successfully', { professorId: updatedProfessor._id });

      // Get base pricing for response
      const baseConfig = await SystemConfigModel.findOne({ key: 'base_pricing' });
      const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;

      // Calculate effective pricing
      const effectivePricing = {
        individualClass: updatedProfessor.pricing?.individualClass ?? basePricing.individualClass,
        groupClass: updatedProfessor.pricing?.groupClass ?? basePricing.groupClass,
        courtRental: updatedProfessor.pricing?.courtRental ?? basePricing.courtRental,
      };

      res.json({
        message: 'Precios actualizados exitosamente',
        pricing: effectivePricing,
        customPricing: updatedProfessor.pricing || {},
        basePricing,
        hasCustomPricing: !!updatedProfessor.pricing && Object.keys(updatedProfessor.pricing).length > 0,
      });
    } catch (error) {
      this.logger.error('Error updating pricing', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Reset professor's pricing to base pricing
   */
  resetMyPricing = async (req: Request, res: Response) => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
      }

      // Remove custom pricing
      professor.pricing = undefined;
      await professor.save();

      // Get base pricing
      const baseConfig = await SystemConfigModel.findOne({ key: 'base_pricing' });
      const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;

      this.logger.info('Pricing reset to default', { professorId: professor._id });

      res.json({
        message: 'Precios restablecidos a valores base',
        pricing: basePricing,
        customPricing: {},
        basePricing,
        hasCustomPricing: false,
      });
    } catch (error) {
      this.logger.error('Error resetting pricing', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };
}

