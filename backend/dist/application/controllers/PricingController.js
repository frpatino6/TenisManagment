"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PricingController = void 0;
const SystemConfigModel_1 = require("../../infrastructure/database/models/SystemConfigModel");
const ProfessorModel_1 = require("../../infrastructure/database/models/ProfessorModel");
const AuthUserModel_1 = require("../../infrastructure/database/models/AuthUserModel");
// Default base pricing
const DEFAULT_BASE_PRICING = {
    individualClass: 50000,
    groupClass: 35000,
    courtRental: 25000,
};
class PricingController {
    constructor() {
        /**
         * Get base pricing configuration (system-wide defaults)
         */
        this.getBasePricing = async (req, res) => {
            try {
                const config = await SystemConfigModel_1.SystemConfigModel.findOne({ key: 'base_pricing' });
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
            }
            catch (error) {
                console.error('Error getting base pricing:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Get effective pricing for a specific professor
         * Returns professor's custom pricing merged with base pricing
         */
        this.getProfessorPricing = async (req, res) => {
            try {
                const { professorId } = req.params;
                // Get base pricing
                const baseConfig = await SystemConfigModel_1.SystemConfigModel.findOne({ key: 'base_pricing' });
                const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;
                // Get professor
                const professor = await ProfessorModel_1.ProfessorModel.findById(professorId);
                if (!professor) {
                    return res.status(404).json({ error: 'Profesor no encontrado' });
                }
                // Merge custom pricing with base pricing
                const effectivePricing = {
                    individualClass: professor.pricing?.individualClass ?? basePricing.individualClass,
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
            }
            catch (error) {
                console.error('Error getting professor pricing:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Get current professor's pricing (authenticated)
         */
        this.getMyPricing = async (req, res) => {
            try {
                const firebaseUid = req.user?.uid;
                if (!firebaseUid) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const authUser = await AuthUserModel_1.AuthUserModel.findOne({ firebaseUid });
                if (!authUser) {
                    return res.status(404).json({ error: 'Usuario no encontrado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: authUser._id });
                if (!professor) {
                    return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
                }
                // Get base pricing
                const baseConfig = await SystemConfigModel_1.SystemConfigModel.findOne({ key: 'base_pricing' });
                const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;
                // Merge custom pricing with base pricing
                const effectivePricing = {
                    individualClass: professor.pricing?.individualClass ?? basePricing.individualClass,
                    groupClass: professor.pricing?.groupClass ?? basePricing.groupClass,
                    courtRental: professor.pricing?.courtRental ?? basePricing.courtRental,
                };
                res.json({
                    pricing: effectivePricing,
                    customPricing: professor.pricing || {},
                    basePricing,
                    hasCustomPricing: !!professor.pricing,
                });
            }
            catch (error) {
                console.error('Error getting my pricing:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Update current professor's custom pricing
         */
        this.updateMyPricing = async (req, res) => {
            try {
                console.log('=== updateMyPricing called ===');
                console.log('Request body:', req.body);
                const firebaseUid = req.user?.uid;
                if (!firebaseUid) {
                    console.log('ERROR: No firebaseUid');
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const { individualClass, groupClass, courtRental } = req.body;
                console.log('Prices to update:', { individualClass, groupClass, courtRental });
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
                const authUser = await AuthUserModel_1.AuthUserModel.findOne({ firebaseUid });
                if (!authUser) {
                    return res.status(404).json({ error: 'Usuario no encontrado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: authUser._id });
                if (!professor) {
                    return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
                }
                // Build update object
                const updateData = {};
                if (individualClass !== undefined) {
                    if (individualClass === null) {
                        updateData['pricing.individualClass'] = null;
                    }
                    else {
                        updateData['pricing.individualClass'] = individualClass;
                    }
                }
                if (groupClass !== undefined) {
                    if (groupClass === null) {
                        updateData['pricing.groupClass'] = null;
                    }
                    else {
                        updateData['pricing.groupClass'] = groupClass;
                    }
                }
                if (courtRental !== undefined) {
                    if (courtRental === null) {
                        updateData['pricing.courtRental'] = null;
                    }
                    else {
                        updateData['pricing.courtRental'] = courtRental;
                    }
                }
                // Update using findOneAndUpdate
                console.log('Updating professor with data:', updateData);
                const updatedProfessor = await ProfessorModel_1.ProfessorModel.findOneAndUpdate({ authUserId: authUser._id }, { $set: updateData }, { new: true });
                if (!updatedProfessor) {
                    console.log('ERROR: Professor not found after update');
                    return res.status(404).json({ error: 'Error al actualizar precios' });
                }
                console.log('Professor updated successfully:', updatedProfessor.pricing);
                // Get base pricing for response
                const baseConfig = await SystemConfigModel_1.SystemConfigModel.findOne({ key: 'base_pricing' });
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
            }
            catch (error) {
                console.error('Error updating pricing:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Reset professor's pricing to base pricing
         */
        this.resetMyPricing = async (req, res) => {
            try {
                const firebaseUid = req.user?.uid;
                if (!firebaseUid) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const authUser = await AuthUserModel_1.AuthUserModel.findOne({ firebaseUid });
                if (!authUser) {
                    return res.status(404).json({ error: 'Usuario no encontrado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: authUser._id });
                if (!professor) {
                    return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
                }
                // Remove custom pricing
                professor.pricing = undefined;
                await professor.save();
                // Get base pricing
                const baseConfig = await SystemConfigModel_1.SystemConfigModel.findOne({ key: 'base_pricing' });
                const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;
                res.json({
                    message: 'Precios restablecidos a valores base',
                    pricing: basePricing,
                    customPricing: {},
                    basePricing,
                    hasCustomPricing: false,
                });
            }
            catch (error) {
                console.error('Error resetting pricing:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
    }
}
exports.PricingController = PricingController;
//# sourceMappingURL=PricingController.js.map