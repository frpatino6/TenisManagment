import { Request, Response } from 'express';
import { SystemConfigModel } from '../../infrastructure/database/models/SystemConfigModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';

// Default base pricing
const DEFAULT_BASE_PRICING = {
  individualClass: 50000,
  groupClass: 35000,
  courtRental: 25000,
};

export class PricingController {
  /**
   * Debug: Clean pricing field for all professors (removes old invalid structure)
   */
  cleanProfessorPricing = async (req: Request, res: Response) => {
    try {
      // Remove pricing field from all professors to start fresh
      const result = await ProfessorModel.updateMany(
        {},
        { $unset: { pricing: "" } }
      );

      res.json({
        message: 'Pricing field cleaned for all professors',
        modifiedCount: result.modifiedCount,
      });
    } catch (error) {
      console.error('Error cleaning pricing:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Initialize base pricing in database (call once to setup)
   */
  initializeBasePricing = async (req: Request, res: Response) => {
    try {
      // Check if already exists
      const existingConfig = await SystemConfigModel.findOne({ key: 'base_pricing' });

      if (existingConfig) {
        return res.json({
          message: 'Base pricing already exists',
          pricing: existingConfig.value,
          createdAt: existingConfig.createdAt,
        });
      }

      // Create base pricing
      const config = await SystemConfigModel.create({
        key: 'base_pricing',
        value: DEFAULT_BASE_PRICING,
        description: 'Base pricing for all service types (used as default for professors)',
      });

      res.status(201).json({
        message: 'Base pricing initialized successfully',
        pricing: config.value,
        createdAt: config.createdAt,
      });
    } catch (error) {
      console.error('Error initializing base pricing:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

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

      res.json({
        pricing: config.value,
        source: 'system',
        updatedAt: config.updatedAt,
      });
    } catch (error) {
      console.error('Error getting base pricing:', error);
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

      res.json({
        professorId: professor._id,
        professorName: professor.name,
        pricing: effectivePricing,
        customPricing: professor.pricing || {},
        basePricing,
      });
    } catch (error) {
      console.error('Error getting professor pricing:', error);
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

      res.json({
        pricing: effectivePricing,
        customPricing: professor.pricing || {},
        basePricing,
        hasCustomPricing: !!professor.pricing,
      });
    } catch (error) {
      console.error('Error getting my pricing:', error);
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
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { individualClass, groupClass, courtRental } = req.body;

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
        if (individualClass === null) {
          updateData['pricing.individualClass'] = null;
        } else {
          updateData['pricing.individualClass'] = individualClass;
        }
      }
      
      if (groupClass !== undefined) {
        if (groupClass === null) {
          updateData['pricing.groupClass'] = null;
        } else {
          updateData['pricing.groupClass'] = groupClass;
        }
      }
      
      if (courtRental !== undefined) {
        if (courtRental === null) {
          updateData['pricing.courtRental'] = null;
        } else {
          updateData['pricing.courtRental'] = courtRental;
        }
      }

      // Update using findOneAndUpdate
      const updatedProfessor = await ProfessorModel.findOneAndUpdate(
        { authUserId: authUser._id },
        { $set: updateData },
        { new: true }
      );

      if (!updatedProfessor) {
        return res.status(404).json({ error: 'Error al actualizar precios' });
      }

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
      });
    } catch (error) {
      console.error('Error updating pricing:', error);
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

      res.json({
        message: 'Precios restablecidos a valores base',
        pricing: basePricing,
        basePricing,
      });
    } catch (error) {
      console.error('Error resetting pricing:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };
}

