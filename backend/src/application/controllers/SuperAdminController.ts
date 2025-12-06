/**
 * SuperAdminController - Gestión de Tenants
 * TEN-87: MT-BACK-005
 *
 * Controlador para que Super Admin gestione tenants: crear, listar, actualizar, activar/desactivar.
 */

import { Request, Response } from 'express';
import { TenantService, CreateTenantInput, UpdateTenantInput } from '../services/TenantService';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { Logger } from '../../infrastructure/services/Logger';

const logger = new Logger({ module: 'SuperAdminController' });

export class SuperAdminController {
  constructor(private readonly tenantService: TenantService) {}

  /**
   * POST /api/admin/tenants
   * Crear un nuevo tenant
   */
  createTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { name, slug, domain, adminEmail, adminName, config } = req.body;

      if (!name || !adminEmail || !adminName) {
        res.status(400).json({ error: 'name, adminEmail y adminName son requeridos' });
        return;
      }

      const input: CreateTenantInput = {
        name,
        slug,
        domain,
        adminEmail,
        adminName,
        config,
      };

      const tenant = await this.tenantService.createTenant(input, userId);

      res.status(201).json({
        id: tenant._id.toString(),
        name: tenant.name,
        slug: tenant.slug,
        domain: tenant.domain,
        isActive: tenant.isActive,
        createdAt: tenant.createdAt,
      });
    } catch (error) {
      logger.error('Error creando tenant', { error: (error as Error).message });
      const message = (error as Error).message;
      if (message.includes('ya está') || message.includes('ya está en uso')) {
        res.status(409).json({ error: message });
      } else if (message.includes('Solo Super Admin')) {
        res.status(403).json({ error: message });
      } else {
        res.status(500).json({ error: 'Error interno del servidor' });
      }
    }
  };

  /**
   * GET /api/admin/tenants
   * Listar todos los tenants con métricas básicas
   */
  listTenants = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenants = await TenantModel.find({}).sort({ createdAt: -1 }).lean();

      const tenantsWithMetrics = await Promise.all(
        tenants.map(async (tenant) => {
          const tenantId = tenant._id.toString();

          // Contar métricas
          const [bookingsCount, schedulesCount, paymentsCount, professorsCount, studentsCount] =
            await Promise.all([
              BookingModel.countDocuments({ tenantId: tenant._id }),
              ScheduleModel.countDocuments({ tenantId: tenant._id }),
              PaymentModel.countDocuments({ tenantId: tenant._id }),
              ProfessorTenantModel.countDocuments({ tenantId: tenant._id, isActive: true }),
              StudentTenantModel.countDocuments({ tenantId: tenant._id, isActive: true }),
            ]);

          return {
            id: tenantId,
            name: tenant.name,
            slug: tenant.slug,
            domain: tenant.domain,
            isActive: tenant.isActive,
            createdAt: tenant.createdAt,
            updatedAt: tenant.updatedAt,
            metrics: {
              bookings: bookingsCount,
              schedules: schedulesCount,
              payments: paymentsCount,
              professors: professorsCount,
              students: studentsCount,
            },
          };
        }),
      );

      res.json({ tenants: tenantsWithMetrics });
    } catch (error) {
      logger.error('Error listando tenants', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * GET /api/admin/tenants/:id
   * Obtener tenant específico con métricas
   */
  getTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const { id } = req.params;

      const tenant = await this.tenantService.getTenantById(id);
      if (!tenant) {
        res.status(404).json({ error: 'Tenant no encontrado' });
        return;
      }

      // Obtener métricas
      const [bookingsCount, schedulesCount, paymentsCount, professorsCount, studentsCount] =
        await Promise.all([
          BookingModel.countDocuments({ tenantId: tenant._id }),
          ScheduleModel.countDocuments({ tenantId: tenant._id }),
          PaymentModel.countDocuments({ tenantId: tenant._id }),
          ProfessorTenantModel.countDocuments({ tenantId: tenant._id, isActive: true }),
          StudentTenantModel.countDocuments({ tenantId: tenant._id, isActive: true }),
        ]);

      res.json({
        id: tenant._id.toString(),
        name: tenant.name,
        slug: tenant.slug,
        domain: tenant.domain,
        config: tenant.config,
        isActive: tenant.isActive,
        createdAt: tenant.createdAt,
        updatedAt: tenant.updatedAt,
        metrics: {
          bookings: bookingsCount,
          schedules: schedulesCount,
          payments: paymentsCount,
          professors: professorsCount,
          students: studentsCount,
        },
      });
    } catch (error) {
      logger.error('Error obteniendo tenant', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * PUT /api/admin/tenants/:id
   * Actualizar tenant
   */
  updateTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { id } = req.params;
      const { name, slug, domain, config, isActive } = req.body;

      const input: UpdateTenantInput = {
        name,
        slug,
        domain,
        config,
        isActive,
      };

      const tenant = await this.tenantService.updateTenant(id, input, userId, 'super_admin');

      if (!tenant) {
        res.status(404).json({ error: 'Tenant no encontrado' });
        return;
      }

      res.json({
        id: tenant._id.toString(),
        name: tenant.name,
        slug: tenant.slug,
        domain: tenant.domain,
        config: tenant.config,
        isActive: tenant.isActive,
        updatedAt: tenant.updatedAt,
      });
    } catch (error) {
      logger.error('Error actualizando tenant', { error: (error as Error).message });
      const message = (error as Error).message;
      if (message.includes('no encontrado')) {
        res.status(404).json({ error: message });
      } else if (message.includes('ya está en uso')) {
        res.status(409).json({ error: message });
      } else if (message.includes('permisos')) {
        res.status(403).json({ error: message });
      } else {
        res.status(500).json({ error: 'Error interno del servidor' });
      }
    }
  };

  /**
   * PATCH /api/admin/tenants/:id/activate
   * Activar tenant
   */
  activateTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { id } = req.params;

      const tenant = await this.tenantService.updateTenant(
        id,
        { isActive: true },
        userId,
        'super_admin',
      );

      if (!tenant) {
        res.status(404).json({ error: 'Tenant no encontrado' });
        return;
      }

      res.json({
        id: tenant._id.toString(),
        name: tenant.name,
        isActive: tenant.isActive,
        message: 'Tenant activado exitosamente',
      });
    } catch (error) {
      logger.error('Error activando tenant', { error: (error as Error).message });
      const message = (error as Error).message;
      if (message.includes('no encontrado')) {
        res.status(404).json({ error: message });
      } else {
        res.status(500).json({ error: 'Error interno del servidor' });
      }
    }
  };

  /**
   * PATCH /api/admin/tenants/:id/deactivate
   * Desactivar tenant
   */
  deactivateTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { id } = req.params;

      const tenant = await this.tenantService.updateTenant(
        id,
        { isActive: false },
        userId,
        'super_admin',
      );

      if (!tenant) {
        res.status(404).json({ error: 'Tenant no encontrado' });
        return;
      }

      res.json({
        id: tenant._id.toString(),
        name: tenant.name,
        isActive: tenant.isActive,
        message: 'Tenant desactivado exitosamente',
      });
    } catch (error) {
      logger.error('Error desactivando tenant', { error: (error as Error).message });
      const message = (error as Error).message;
      if (message.includes('no encontrado')) {
        res.status(404).json({ error: message });
      } else {
        res.status(500).json({ error: 'Error interno del servidor' });
      }
    }
  };

  /**
   * GET /api/admin/metrics
   * Obtener métricas globales del sistema
   */
  getGlobalMetrics = async (req: Request, res: Response): Promise<void> => {
    try {
      const [
        totalTenants,
        activeTenants,
        totalBookings,
        totalSchedules,
        totalPayments,
        totalProfessors,
        totalStudents,
      ] = await Promise.all([
        TenantModel.countDocuments({}),
        TenantModel.countDocuments({ isActive: true }),
        BookingModel.countDocuments({}),
        ScheduleModel.countDocuments({}),
        PaymentModel.countDocuments({}),
        ProfessorTenantModel.countDocuments({ isActive: true }),
        StudentTenantModel.countDocuments({ isActive: true }),
      ]);

      // Calcular ingresos totales
      const payments = await PaymentModel.find({}).select('amount').lean();
      const totalRevenue = payments.reduce((sum, payment) => sum + (payment.amount || 0), 0);

      res.json({
        tenants: {
          total: totalTenants,
          active: activeTenants,
          inactive: totalTenants - activeTenants,
        },
        bookings: {
          total: totalBookings,
        },
        schedules: {
          total: totalSchedules,
        },
        payments: {
          total: totalPayments,
          revenue: totalRevenue,
        },
        users: {
          professors: totalProfessors,
          students: totalStudents,
        },
      });
    } catch (error) {
      logger.error('Error obteniendo métricas globales', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };
}
