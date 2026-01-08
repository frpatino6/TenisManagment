/**
 * TenantAdminController - Gestión del Centro
 * TEN-88: MT-BACK-006
 *
 * Controlador para que Tenant Admin gestione su centro: configuración, profesores, canchas, reportes.
 */

import { Request, Response } from 'express';
import { TenantService, UpdateTenantInput } from '../services/TenantService';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { TenantAdminModel } from '../../infrastructure/database/models/TenantAdminModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { CourtModel, CourtDocument } from '../../infrastructure/database/models/CourtModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { Logger } from '../../infrastructure/services/Logger';
import { Types } from 'mongoose';

const logger = new Logger({ module: 'TenantAdminController' });

export class TenantAdminController {
  constructor(private readonly tenantService: TenantService) { }

  /**
   * GET /api/tenant/me
   * Obtener información del tenant del admin autenticado
   */
  getTenantInfo = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      // Obtener el tenant del admin
      const tenantAdmin = await TenantAdminModel.findOne({
        adminUserId: userId,
        isActive: true,
      }).populate('tenantId');

      if (!tenantAdmin) {
        res.status(404).json({ error: 'No eres admin de ningún tenant' });
        return;
      }

      const tenant = tenantAdmin.tenantId as any;

      res.json({
        id: tenant._id.toString(),
        name: tenant.name,
        slug: tenant.slug,
        domain: tenant.domain,
        config: tenant.config,
        isActive: tenant.isActive,
        createdAt: tenant.createdAt,
        updatedAt: tenant.updatedAt,
      });
    } catch (error) {
      logger.error('Error obteniendo información del tenant', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * PUT /api/tenant/me
   * Actualizar configuración del tenant
   */
  updateTenantConfig = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      // Obtener el tenant del admin
      const tenantAdmin = await TenantAdminModel.findOne({
        adminUserId: userId,
        isActive: true,
      });

      if (!tenantAdmin) {
        res.status(404).json({ error: 'No eres admin de ningún tenant' });
        return;
      }

      const { name, slug, domain, config } = req.body;

      const input: UpdateTenantInput = {
        name,
        slug,
        domain,
        config,
      };

      const tenant = await this.tenantService.updateTenant(
        tenantAdmin.tenantId.toString(),
        input,
        userId,
        'tenant_admin',
      );

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
        updatedAt: tenant.updatedAt,
      });
    } catch (error) {
      logger.error('Error actualizando configuración del tenant', { error: (error as Error).message });
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
   * PUT /api/tenant/operating-hours
   * Configurar horarios de operación del centro
   */
  updateOperatingHours = async (req: Request, res: Response): Promise<void> => {
    try {
      const userId = req.user?.id;
      if (!userId) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      // Obtener el tenant del admin
      const tenantAdmin = await TenantAdminModel.findOne({
        adminUserId: userId,
        isActive: true,
      });

      if (!tenantAdmin) {
        res.status(404).json({ error: 'No eres admin de ningún tenant' });
        return;
      }

      const { schedule } = req.body;

      logger.info('Actualizando horarios de operación', {
        schedule,
        tenantId: tenantAdmin.tenantId.toString()
      });

      // Validaciones
      if (!schedule || !Array.isArray(schedule)) {
        res.status(400).json({ error: 'schedule es requerido y debe ser un array' });
        return;
      }

      if (schedule.length === 0) {
        res.status(400).json({ error: 'schedule debe contener al menos un día' });
        return;
      }

      // Validar formato de hora (HH:mm)
      const timeRegex = /^([0-1]?[0-9]|2[0-3]):[0-5][0-9]$/;

      // Validar cada día en el schedule
      const seenDays = new Set<number>();
      for (const daySchedule of schedule) {
        // Validar estructura
        if (typeof daySchedule.dayOfWeek !== 'number' ||
          typeof daySchedule.open !== 'string' ||
          typeof daySchedule.close !== 'string') {
          res.status(400).json({
            error: 'Cada día debe tener dayOfWeek (number), open (string) y close (string)'
          });
          return;
        }

        // Validar dayOfWeek (0-6)
        if (daySchedule.dayOfWeek < 0 || daySchedule.dayOfWeek > 6) {
          res.status(400).json({
            error: `dayOfWeek debe estar entre 0 y 6 (0=Domingo, 6=Sábado). Día inválido: ${daySchedule.dayOfWeek}`
          });
          return;
        }

        // Validar que no haya días duplicados
        if (seenDays.has(daySchedule.dayOfWeek)) {
          res.status(400).json({
            error: `El día ${daySchedule.dayOfWeek} está duplicado en el schedule`
          });
          return;
        }
        seenDays.add(daySchedule.dayOfWeek);

        // Validar formato de hora
        if (!timeRegex.test(daySchedule.open) || !timeRegex.test(daySchedule.close)) {
          res.status(400).json({
            error: `El formato de hora debe ser HH:mm (ej: 08:00, 20:00). Día: ${daySchedule.dayOfWeek}`
          });
          return;
        }

        const [openHour, openMinute] = daySchedule.open.split(':').map(Number);
        const [closeHour, closeMinute] = daySchedule.close.split(':').map(Number);

        // Validar rangos
        if (openHour < 0 || openHour >= 24 || openMinute < 0 || openMinute >= 60) {
          res.status(400).json({ error: `Hora de apertura inválida para el día ${daySchedule.dayOfWeek}` });
          return;
        }

        if (closeHour < 0 || closeHour > 24 || closeMinute < 0 || closeMinute >= 60) {
          res.status(400).json({ error: `Hora de cierre inválida para el día ${daySchedule.dayOfWeek}` });
          return;
        }

        // Convertir a minutos para comparar
        const openMinutes = openHour * 60 + openMinute;
        const closeMinutes = closeHour * 60 + closeMinute;

        if (openMinutes >= closeMinutes) {
          res.status(400).json({
            error: `La hora de apertura debe ser anterior a la hora de cierre para el día ${daySchedule.dayOfWeek}`
          });
          return;
        }
      }

      // Obtener tenant actual
      const tenant = await TenantModel.findById(tenantAdmin.tenantId);
      if (!tenant) {
        res.status(404).json({ error: 'Tenant no encontrado' });
        return;
      }

      // Actualizar operatingHours en la configuración
      // Convertir tenant.config a objeto plano para evitar problemas con objetos Mongoose
      const currentConfig = tenant.config ? JSON.parse(JSON.stringify(tenant.config)) : {};

      // Ordenar schedule por dayOfWeek para consistencia
      const sortedSchedule = [...schedule].sort((a, b) => a.dayOfWeek - b.dayOfWeek);

      const operatingHours = {
        schedule: sortedSchedule,
      };

      const updatedConfig = {
        ...currentConfig,
        operatingHours,
      };

      logger.info('Configuración a guardar', {
        updatedConfig: JSON.stringify(updatedConfig),
        operatingHours: JSON.stringify(operatingHours)
      });

      const input: UpdateTenantInput = {
        config: updatedConfig,
      };

      const updatedTenant = await this.tenantService.updateTenant(
        tenantAdmin.tenantId.toString(),
        input,
        userId,
        'tenant_admin',
      );

      logger.info('Tenant actualizado', {
        tenantId: tenantAdmin.tenantId.toString(),
        operatingHours: updatedTenant?.config?.operatingHours
      });

      if (!updatedTenant) {
        res.status(404).json({ error: 'Tenant no encontrado' });
        return;
      }

      logger.info('Horarios de operación actualizados', {
        tenantId: tenantAdmin.tenantId.toString(),
        schedule: sortedSchedule,
        updatedBy: userId
      });

      res.json({
        id: updatedTenant._id.toString(),
        name: updatedTenant.name,
        slug: updatedTenant.slug,
        domain: updatedTenant.domain,
        config: updatedTenant.config,
        isActive: updatedTenant.isActive,
        createdAt: updatedTenant.createdAt,
        updatedAt: updatedTenant.updatedAt,
      });
    } catch (error) {
      logger.error('Error actualizando horarios de operación', { error: (error as Error).message });
      const message = (error as Error).message;
      if (message.includes('no encontrado')) {
        res.status(404).json({ error: message });
      } else if (message.includes('permisos')) {
        res.status(403).json({ error: message });
      } else {
        res.status(500).json({ error: 'Error interno del servidor' });
      }
    }
  };

  /**
   * GET /api/tenant/professors
   * Listar profesores del tenant
   */
  listProfessors = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const professorTenants = await ProfessorTenantModel.find({
        tenantId: new Types.ObjectId(tenantId),
      })
        .populate('professorId')
        .lean();

      const professors = await Promise.all(
        professorTenants.map(async (pt) => {
          const professor = pt.professorId as any;
          const professorAuth = await AuthUserModel.findById(professor.authUserId).lean();

          // Contar bookings del profesor en este tenant
          const bookingsCount = await BookingModel.countDocuments({
            professorId: professor._id,
            tenantId: new Types.ObjectId(tenantId),
          });

          return {
            id: professor._id.toString(),
            name: professor.name,
            email: professor.email,
            phone: professor.phone,
            specialties: professor.specialties,
            hourlyRate: professor.hourlyRate,
            experienceYears: professor.experienceYears,
            pricing: pt.pricing,
            isActive: pt.isActive,
            joinedAt: pt.joinedAt,
            bookingsCount,
            authUserId: professorAuth?._id.toString(),
          };
        }),
      );

      res.json({ professors });
    } catch (error) {
      logger.error('Error listando profesores', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * POST /api/tenant/professors/invite
   * Invitar profesor al tenant
   */
  inviteProfessor = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { email, pricing } = req.body;

      if (!email) {
        res.status(400).json({ error: 'Email es requerido' });
        return;
      }

      // Buscar si el profesor ya existe
      const authUser = await AuthUserModel.findOne({ email });
      let professor;

      if (authUser && authUser.role === 'professor') {
        // Profesor ya existe, obtener su perfil
        professor = await ProfessorModel.findOne({ authUserId: authUser._id });
        if (!professor) {
          res.status(404).json({ error: 'Usuario profesor encontrado pero sin perfil' });
          return;
        }
      } else if (authUser) {
        res.status(409).json({ error: 'El email ya está registrado con otro rol' });
        return;
      } else {
        // Crear nuevo profesor automáticamente
        logger.info('Creando nuevo profesor desde invitación', { email });

        // Extraer nombre del email (parte antes del @) como nombre temporal
        const tempName = email.split('@')[0];

        // Crear AuthUser sin firebaseUid (se asociará cuando el profesor se registre en Firebase)
        const newAuthUser = await AuthUserModel.create({
          email,
          name: tempName,
          role: 'professor',
        });

        // Crear perfil de profesor
        professor = await ProfessorModel.create({
          authUserId: newAuthUser._id,
          name: tempName,
          email,
          phone: '-', // Valor por defecto, el profesor actualizará su teléfono cuando se registre
          specialties: [],
          hourlyRate: 0,
          experienceYears: 0,
        });

        logger.info('Profesor creado exitosamente desde invitación', {
          authUserId: newAuthUser._id.toString(),
          professorId: professor._id.toString(),
        });
      }

      // Agregar profesor al tenant
      const professorTenant = await this.tenantService.addProfessorToTenant(
        professor._id.toString(),
        tenantId,
        pricing,
      );

      // TODO: Enviar email de invitación

      res.status(201).json({
        id: professorTenant._id.toString(),
        professorId: professor._id.toString(),
        tenantId,
        pricing: professorTenant.pricing,
        isActive: professorTenant.isActive,
        message: 'Profesor agregado al tenant exitosamente',
      });
    } catch (error) {
      const errorMessage = (error as Error).message;
      logger.error('Error invitando profesor', { error: errorMessage, stack: (error as Error).stack });
      if (errorMessage.includes('no encontrado')) {
        res.status(404).json({ error: errorMessage });
      } else if (errorMessage.includes('ya está activo')) {
        res.status(409).json({ error: errorMessage });
      } else {
        res.status(500).json({ error: 'Error interno del servidor', details: errorMessage });
      }
    }
  };

  /**
   * PATCH /api/tenant/professors/:id/activate
   * Activar profesor en el tenant
   */
  activateProfessor = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { id } = req.params; // professorId

      const professor = await ProfessorModel.findById(id);
      if (!professor) {
        res.status(404).json({ error: 'Profesor no encontrado' });
        return;
      }

      const professorTenant = await ProfessorTenantModel.findOne({
        professorId: professor._id,
        tenantId: new Types.ObjectId(tenantId),
      });

      if (!professorTenant) {
        res.status(404).json({ error: 'El profesor no está registrado en este tenant' });
        return;
      }

      professorTenant.isActive = true;
      await professorTenant.save();

      res.json({
        id: professorTenant._id.toString(),
        isActive: professorTenant.isActive,
        message: 'Profesor activado exitosamente',
      });
    } catch (error) {
      logger.error('Error activando profesor', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * PATCH /api/tenant/professors/:id/deactivate
   * Desactivar profesor en el tenant
   */
  deactivateProfessor = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { id } = req.params; // professorId

      const professor = await ProfessorModel.findById(id);
      if (!professor) {
        res.status(404).json({ error: 'Profesor no encontrado' });
        return;
      }

      const professorTenant = await ProfessorTenantModel.findOne({
        professorId: professor._id,
        tenantId: new Types.ObjectId(tenantId),
      });

      if (!professorTenant) {
        res.status(404).json({ error: 'El profesor no está registrado en este tenant' });
        return;
      }

      professorTenant.isActive = false;
      await professorTenant.save();

      res.json({
        id: professorTenant._id.toString(),
        isActive: professorTenant.isActive,
        message: 'Profesor desactivado exitosamente',
      });
    } catch (error) {
      logger.error('Error desactivando profesor', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * GET /api/tenant/courts
   * Listar canchas del tenant
   */
  listCourts = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const courts = await CourtModel.find({
        tenantId: new Types.ObjectId(tenantId),
      }).sort({ name: 1 });

      res.json({
        courts: courts.map((court) => ({
          id: court._id.toString(),
          name: court.name,
          type: court.type,
          price: court.price,
          isActive: court.isActive,
          description: court.description,
          features: court.features,
          createdAt: court.createdAt,
          updatedAt: court.updatedAt,
        })),
      });
    } catch (error) {
      logger.error('Error listando canchas', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * POST /api/tenant/courts
   * Crear cancha
   */
  createCourt = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { name, type, price, description, features } = req.body;

      if (!name || !type || price === undefined) {
        res.status(400).json({ error: 'name, type y price son requeridos' });
        return;
      }

      const court = await CourtModel.create({
        tenantId: new Types.ObjectId(tenantId),
        name,
        type,
        price,
        description,
        features: features || [],
        isActive: true,
      });

      res.status(201).json({
        id: court._id.toString(),
        name: court.name,
        type: court.type,
        price: court.price,
        isActive: court.isActive,
        description: court.description,
        features: court.features,
        createdAt: court.createdAt,
      });
    } catch (error) {
      logger.error('Error creando cancha', { error: (error as Error).message });
      const message = (error as Error).message;
      if (message.includes('duplicate key') || message.includes('unique')) {
        res.status(409).json({ error: 'Ya existe una cancha con ese nombre en este tenant' });
      } else {
        res.status(500).json({ error: 'Error interno del servidor' });
      }
    }
  };

  /**
   * PUT /api/tenant/courts/:id
   * Actualizar cancha
   */
  updateCourt = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { id } = req.params;
      const { name, type, price, description, features, isActive } = req.body;

      const court = await CourtModel.findOne({
        _id: id,
        tenantId: new Types.ObjectId(tenantId),
      });

      if (!court) {
        res.status(404).json({ error: 'Cancha no encontrada' });
        return;
      }

      if (name !== undefined) court.name = name;
      if (type !== undefined) court.type = type;
      if (price !== undefined) court.price = price;
      if (description !== undefined) court.description = description;
      if (features !== undefined) court.features = features;
      if (isActive !== undefined) court.isActive = isActive;

      await court.save();

      res.json({
        id: court._id.toString(),
        name: court.name,
        type: court.type,
        price: court.price,
        isActive: court.isActive,
        description: court.description,
        features: court.features,
        updatedAt: court.updatedAt,
      });
    } catch (error) {
      logger.error('Error actualizando cancha', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * DELETE /api/tenant/courts/:id
   * Eliminar cancha
   */
  deleteCourt = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { id } = req.params;

      const court = await CourtModel.findOneAndDelete({
        _id: id,
        tenantId: new Types.ObjectId(tenantId),
      });

      if (!court) {
        res.status(404).json({ error: 'Cancha no encontrada' });
        return;
      }

      res.json({
        message: 'Cancha eliminada exitosamente',
        id: id,
      });
    } catch (error) {
      logger.error('Error eliminando cancha', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * GET /api/tenant/metrics
   * Obtener métricas del centro
   */
  getMetrics = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const tenantObjectId = new Types.ObjectId(tenantId);

      const [
        bookingsCount,
        paymentsCount,
        professorsCount,
        studentsCount,
        courtsCount,
        totalRevenue,
      ] = await Promise.all([
        BookingModel.countDocuments({ tenantId: tenantObjectId }),
        PaymentModel.countDocuments({ tenantId: tenantObjectId }),
        ProfessorTenantModel.countDocuments({ tenantId: tenantObjectId, isActive: true }),
        StudentTenantModel.countDocuments({ tenantId: tenantObjectId, isActive: true }),
        CourtModel.countDocuments({ tenantId: tenantObjectId, isActive: true }),
        PaymentModel.aggregate([
          { $match: { tenantId: tenantObjectId } },
          { $group: { _id: null, total: { $sum: '$amount' } } },
        ]),
      ]);

      const revenue = totalRevenue.length > 0 ? totalRevenue[0].total : 0;

      // Obtener profesores más activos
      const topProfessors = await BookingModel.aggregate([
        { $match: { tenantId: tenantObjectId } },
        { $group: { _id: '$professorId', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 5 },
        {
          $lookup: {
            from: 'professors',
            localField: '_id',
            foreignField: '_id',
            as: 'professor',
          },
        },
        { $unwind: '$professor' },
        {
          $project: {
            professorId: '$_id',
            professorName: '$professor.name',
            bookingsCount: '$count',
          },
        },
      ]);

      res.json({
        bookings: {
          total: bookingsCount,
        },
        payments: {
          total: paymentsCount,
          revenue,
        },
        users: {
          professors: professorsCount,
          students: studentsCount,
        },
        courts: {
          total: courtsCount,
        },
        topProfessors,
      });
    } catch (error) {
      logger.error('Error obteniendo métricas del centro', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * GET /api/tenant/bookings
   * Listar todas las reservas del tenant con filtros
   */
  listBookings = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const {
        status,
        from,
        to,
        courtId,
        professorId,
        studentId,
        serviceType,
        search,
        page = '1',
        limit = '20',
      } = req.query;

      const tenantObjectId = new Types.ObjectId(tenantId);

      // Construir filtro
      const filter: any = { tenantId: tenantObjectId };

      // Si hay búsqueda, encontrar primero IDs de estudiantes que coincidan
      if (search) {
        const User = require('../../infrastructure/database/models/UserModel').default;
        const matchingStudents = await User.find({
          role: 'student',
          $or: [
            { name: { $regex: search, $options: 'i' } },
            { email: { $regex: search, $options: 'i' } }
          ]
        }).select('_id');

        const studentIds = matchingStudents.map((s: any) => s._id);
        filter.studentId = { $in: studentIds };
      }

      if (status) {
        filter.status = status;
      }

      if (serviceType) {
        filter.serviceType = serviceType;
      }

      if (courtId) {
        filter.courtId = new Types.ObjectId(courtId as string);
      }

      if (professorId) {
        filter.professorId = new Types.ObjectId(professorId as string);
      }

      if (studentId) {
        filter.studentId = new Types.ObjectId(studentId as string);
      }

      // Filtro de fecha
      if (from || to) {
        filter.bookingDate = {};
        if (from) {
          filter.bookingDate.$gte = new Date(from as string);
        }
        if (to) {
          filter.bookingDate.$lte = new Date(to as string);
        }
      }

      const pageNum = parseInt(page as string, 10);
      const limitNum = parseInt(limit as string, 10);
      const skip = (pageNum - 1) * limitNum;

      const [bookings, total] = await Promise.all([
        BookingModel.find(filter)
          .populate('courtId', 'name type')
          .populate('professorId', 'name email')
          .populate('studentId', 'name email phone')
          .populate('scheduleId', 'date startTime endTime')
          .sort({ bookingDate: -1, createdAt: -1 })
          .skip(skip)
          .limit(limitNum)
          .lean(),
        BookingModel.countDocuments(filter),
      ]);

      const formattedBookings = bookings.map((booking) => {
        const court = booking.courtId as any;
        const professor = booking.professorId as any;
        const student = booking.studentId as any;
        const schedule = booking.scheduleId as any;

        return {
          id: booking._id.toString(),
          date: schedule?.date || booking.bookingDate,
          startTime: schedule?.startTime,
          endTime: schedule?.endTime,
          court: court
            ? {
              id: court._id.toString(),
              name: court.name,
              type: court.type,
            }
            : null,
          professor: professor
            ? {
              id: professor._id.toString(),
              name: professor.name,
              email: professor.email,
            }
            : null,
          student: {
            id: student._id.toString(),
            name: student.name,
            email: student.email,
            phone: student.phone,
          },
          serviceType: booking.serviceType,
          status: booking.status,
          price: booking.price,
          notes: booking.notes,
          createdAt: booking.createdAt,
          updatedAt: booking.updatedAt,
        };
      });

      res.json({
        bookings: formattedBookings,
        pagination: {
          page: pageNum,
          limit: limitNum,
          total,
          totalPages: Math.ceil(total / limitNum),
        },
      });
    } catch (error) {
      logger.error('Error listando reservas', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * GET /api/tenant/bookings/calendar
   * Vista de calendario de reservas
   */
  getBookingCalendar = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { from, to, courtId } = req.query;

      if (!from || !to) {
        res.status(400).json({ error: 'Parámetros from y to son requeridos' });
        return;
      }

      const tenantObjectId = new Types.ObjectId(tenantId);

      const filter: any = {
        tenantId: tenantObjectId,
        bookingDate: {
          $gte: new Date(from as string),
          $lte: new Date(to as string),
        },
        status: { $in: ['pending', 'confirmed'] }, // Solo reservas activas
      };

      if (courtId) {
        filter.courtId = new Types.ObjectId(courtId as string);
      }

      const bookings = await BookingModel.find(filter)
        .populate('courtId', 'name type')
        .populate('professorId', 'name')
        .populate('studentId', 'name')
        .populate('scheduleId', 'date startTime endTime')
        .sort({ bookingDate: 1 })
        .lean();

      // Agrupar por fecha
      const calendarData: { [key: string]: any[] } = {};

      bookings.forEach((booking) => {
        const schedule = booking.scheduleId as any;
        const date = schedule?.date || booking.bookingDate;
        const dateKey = new Date(date).toISOString().split('T')[0];

        if (!calendarData[dateKey]) {
          calendarData[dateKey] = [];
        }

        const court = booking.courtId as any;
        const professor = booking.professorId as any;
        const student = booking.studentId as any;

        calendarData[dateKey].push({
          id: booking._id.toString(),
          startTime: schedule?.startTime,
          endTime: schedule?.endTime,
          courtName: court?.name,
          courtType: court?.type,
          professorName: professor?.name,
          studentName: student?.name,
          serviceType: booking.serviceType,
          status: booking.status,
          price: booking.price,
        });
      });

      res.json({ calendar: calendarData });
    } catch (error) {
      logger.error('Error obteniendo calendario de reservas', {
        error: (error as Error).message,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * GET /api/tenant/bookings/:id
   * Obtener detalles completos de una reserva
   */
  getBookingDetails = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { id } = req.params;

      const booking = await BookingModel.findOne({
        _id: id,
        tenantId: new Types.ObjectId(tenantId),
      })
        .populate('courtId')
        .populate('professorId')
        .populate('studentId')
        .populate('scheduleId')
        .lean();

      if (!booking) {
        res.status(404).json({ error: 'Reserva no encontrada' });
        return;
      }

      // Buscar pago asociado
      const payment = await PaymentModel.findOne({
        tenantId: new Types.ObjectId(tenantId),
        studentId: booking.studentId,
        // Buscar pagos cercanos a la fecha de la reserva
        date: {
          $gte: new Date(booking.createdAt.getTime() - 24 * 60 * 60 * 1000), // 1 día antes
          $lte: new Date(booking.createdAt.getTime() + 24 * 60 * 60 * 1000), // 1 día después
        },
      }).lean();

      const court = booking.courtId as any;
      const professor = booking.professorId as any;
      const student = booking.studentId as any;
      const schedule = booking.scheduleId as any;

      res.json({
        id: booking._id.toString(),
        date: schedule?.date || booking.bookingDate,
        startTime: schedule?.startTime,
        endTime: schedule?.endTime,
        court: court
          ? {
            id: court._id.toString(),
            name: court.name,
            type: court.type,
            price: court.price,
            description: court.description,
            features: court.features,
          }
          : null,
        professor: professor
          ? {
            id: professor._id.toString(),
            name: professor.name,
            email: professor.email,
            phone: professor.phone,
            specialties: professor.specialties,
          }
          : null,
        student: {
          id: student._id.toString(),
          name: student.name,
          email: student.email,
          phone: student.phone,
        },
        serviceType: booking.serviceType,
        status: booking.status,
        price: booking.price,
        notes: booking.notes,
        payment: payment
          ? {
            id: payment._id.toString(),
            amount: payment.amount,
            method: payment.method,
            date: payment.date,
            status: payment.status,
          }
          : null,
        createdAt: booking.createdAt,
        updatedAt: booking.updatedAt,
      });
    } catch (error) {
      logger.error('Error obteniendo detalles de reserva', {
        error: (error as Error).message,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * PATCH /api/tenant/bookings/:id/cancel
   * Cancelar una reserva
   */
  cancelBooking = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      const userId = req.user?.id;

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      if (!userId) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { id } = req.params;
      const { reason } = req.body;

      const booking = await BookingModel.findOne({
        _id: id,
        tenantId: new Types.ObjectId(tenantId),
      });

      if (!booking) {
        res.status(404).json({ error: 'Reserva no encontrada' });
        return;
      }

      if (booking.status === 'cancelled') {
        res.status(400).json({ error: 'La reserva ya está cancelada' });
        return;
      }

      if (booking.status === 'completed') {
        res.status(400).json({ error: 'No se puede cancelar una reserva completada' });
        return;
      }

      // Actualizar estado de la reserva
      booking.status = 'cancelled';
      if (reason) {
        booking.notes = booking.notes
          ? `${booking.notes}\n\nCancelada por admin: ${reason}`
          : `Cancelada por admin: ${reason}`;
      }
      await booking.save();

      // Si hay un schedule asociado, marcarlo como disponible nuevamente
      if (booking.scheduleId) {
        await ScheduleModel.findByIdAndUpdate(booking.scheduleId, {
          isAvailable: true,
          studentId: null,
          status: 'cancelled',
        });
      }

      logger.info('Reserva cancelada por tenant admin', {
        bookingId: id,
        tenantId,
        cancelledBy: userId,
        reason,
      });

      res.json({
        id: booking._id.toString(),
        status: booking.status,
        message: 'Reserva cancelada exitosamente',
      });
    } catch (error) {
      logger.error('Error cancelando reserva', { error: (error as Error).message });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * GET /api/tenant/bookings/stats
   * Obtener estadísticas de reservas
   */
  getBookingStats = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido' });
        return;
      }

      const { from, to } = req.query;

      const tenantObjectId = new Types.ObjectId(tenantId);

      const filter: any = { tenantId: tenantObjectId };

      // Filtro de fecha
      if (from || to) {
        filter.bookingDate = {};
        if (from) {
          filter.bookingDate.$gte = new Date(from as string);
        }
        if (to) {
          filter.bookingDate.$lte = new Date(to as string);
        }
      }

      // Estadísticas por estado
      const statusStats = await BookingModel.aggregate([
        { $match: filter },
        {
          $group: {
            _id: '$status',
            count: { $sum: 1 },
            revenue: { $sum: '$price' },
          },
        },
      ]);

      // Estadísticas por cancha
      const courtStats = await BookingModel.aggregate([
        { $match: { ...filter, courtId: { $exists: true, $ne: null } } },
        {
          $group: {
            _id: '$courtId',
            count: { $sum: 1 },
            revenue: { $sum: '$price' },
          },
        },
        { $sort: { count: -1 } },
        { $limit: 10 },
        {
          $lookup: {
            from: 'courts',
            localField: '_id',
            foreignField: '_id',
            as: 'court',
          },
        },
        { $unwind: '$court' },
        {
          $project: {
            courtId: '$_id',
            courtName: '$court.name',
            courtType: '$court.type',
            bookingsCount: '$count',
            revenue: '$revenue',
          },
        },
      ]);

      // Estadísticas por profesor
      const professorStats = await BookingModel.aggregate([
        { $match: { ...filter, professorId: { $exists: true, $ne: null } } },
        {
          $group: {
            _id: '$professorId',
            count: { $sum: 1 },
            revenue: { $sum: '$price' },
          },
        },
        { $sort: { count: -1 } },
        { $limit: 10 },
        {
          $lookup: {
            from: 'professors',
            localField: '_id',
            foreignField: '_id',
            as: 'professor',
          },
        },
        { $unwind: '$professor' },
        {
          $project: {
            professorId: '$_id',
            professorName: '$professor.name',
            bookingsCount: '$count',
            revenue: '$revenue',
          },
        },
      ]);

      // Estadísticas por tipo de servicio
      const serviceTypeStats = await BookingModel.aggregate([
        { $match: filter },
        {
          $group: {
            _id: '$serviceType',
            count: { $sum: 1 },
            revenue: { $sum: '$price' },
          },
        },
      ]);

      // Total general
      const totalStats = await BookingModel.aggregate([
        { $match: filter },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            totalRevenue: { $sum: '$price' },
            averagePrice: { $avg: '$price' },
          },
        },
      ]);

      const stats = totalStats[0] || { total: 0, totalRevenue: 0, averagePrice: 0 };

      res.json({
        total: stats.total,
        totalRevenue: stats.totalRevenue,
        averagePrice: stats.averagePrice,
        byStatus: statusStats.reduce((acc: any, item: any) => {
          acc[item._id] = {
            count: item.count,
            revenue: item.revenue,
          };
          return acc;
        }, {}),
        byServiceType: serviceTypeStats.reduce((acc: any, item: any) => {
          acc[item._id] = {
            count: item.count,
            revenue: item.revenue,
          };
          return acc;
        }, {}),
        topCourts: courtStats,
        topProfessors: professorStats,
      });
    } catch (error) {
      logger.error('Error obteniendo estadísticas de reservas', {
        error: (error as Error).message,
      });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };
}

