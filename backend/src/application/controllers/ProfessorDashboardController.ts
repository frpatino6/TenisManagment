import { Request, Response } from 'express';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { UserPreferencesModel } from '../../infrastructure/database/models/UserPreferencesModel';
import { TenantService } from '../services/TenantService';
import { Logger } from '../../infrastructure/services/Logger';
import { Types } from 'mongoose';
const logger = new Logger({ controller: 'ProfessorDashboardController' });

export class ProfessorDashboardController {
  // Obtener información del profesor
  getProfessorInfo = async (req: Request, res: Response) => {
    logger.debug('getProfessorInfo called', { requestId: req.requestId });
    
    try {
      
      const professorId = req.user?.id;
      if (!professorId) {
        logger.warn('Missing professorId in req.user', { requestId: req.requestId });
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      logger.debug('Looking for professor by authUserId');
      let professor = await ProfessorModel.findOne({ authUserId: professorId });
      
      if (!professor) {
        logger.info('Professor not found, creating');
        
        // Buscar el AuthUser para obtener información
        const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
        const authUser = await AuthUserModel.findById(professorId);
        
        if (!authUser) {
          return res.status(404).json({ error: 'Usuario de autenticación no encontrado' });
        }
        
        logger.debug('Creating professor record');
        
        // Crear el registro del profesor
        professor = await ProfessorModel.create({
          authUserId: authUser._id,
          name: authUser.name || 'Profesor',
          email: authUser.email,
          phone: '',
          specialties: [],
          hourlyRate: 0,
          experienceYears: 0
        });
        
        logger.info('Professor created');
      } else {
        logger.debug('Professor found');
      }

      // Calcular estadísticas reales
      const totalStudents = await StudentModel.countDocuments({});
      
      // Calcular rating promedio basado en clases completadas
      const completedClasses = await ScheduleModel.countDocuments({
        professorId: professor._id,
        status: 'completed'
      });
      
      // Rating basado en clases completadas (más clases = mejor rating)
      const rating = Math.min(4.0 + (completedClasses / 100), 5.0);
      
      // Calcular años de experiencia basado en la fecha de creación del profesor
      const createdAt = (professor as any).createdAt || new Date();
      const experienceYears = professor.experienceYears || 0;

      const professorInfo = {
        id: professor._id.toString(),
        name: professor.name,
        email: professor.email,
        phone: professor.phone,
        specialties: professor.specialties,
        hourlyRate: professor.hourlyRate,
        totalStudents: totalStudents,
        rating: rating,
        experienceYears: experienceYears,
      };

      logger.debug('Sending professor info');
      res.json(professorInfo);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error getting professor info', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  // Obtener lista de estudiantes del profesor
  getStudents = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: professorId });
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Obtener estudiantes reales de la base de datos
      // Por ahora obtenemos todos los estudiantes, pero en el futuro deberíamos
      // implementar una relación real entre profesor y estudiantes
      const students = await StudentModel.find({}).limit(10);
      
      // Transformar los datos para que coincidan con el formato esperado
      const studentsData = await Promise.all(students.map(async (student) => {
        // Obtener la próxima clase del estudiante
        const nextClass = await ScheduleModel.findOne({
          studentId: student._id,
          date: { $gte: new Date() },
          status: { $in: ['pending', 'confirmed'] }
        }).sort({ date: 1, startTime: 1 });

        // Contar clases del estudiante
        const totalClasses = await ScheduleModel.countDocuments({
          studentId: student._id,
          status: 'completed'
        });

        // Calcular progreso basado en clases completadas
        const progress = totalClasses > 0 ? Math.min(totalClasses / 20, 1.0) : 0.0; // Máximo 20 clases para 100%

        // Determinar nivel basado en progreso
        let level = 'Principiante';
        if (progress >= 0.7) level = 'Avanzado';
        else if (progress >= 0.3) level = 'Intermedio';

        return {
          id: student._id.toString(),
          name: student.name,
          email: student.email,
          level: level,
          nextClassDate: nextClass ? nextClass.date.toISOString().split('T')[0] : null,
          nextClassTime: nextClass ? nextClass.startTime.toTimeString().split(' ')[0].substring(0, 5) : null,
          totalClasses: totalClasses,
          progress: progress,
        };
      }));

      res.json({ items: studentsData });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error getting students', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };


  // Obtener horarios por fecha específica
  getScheduleByDate = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { date } = req.query;
      if (!date || typeof date !== 'string') {
        return res.status(400).json({ error: 'Parámetro date es requerido (formato: YYYY-MM-DD)' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: professorId });
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Parse the date (comes as YYYY-MM-DD)
      const targetDate = new Date(date);
      if (isNaN(targetDate.getTime())) {
        return res.status(400).json({ error: 'Formato de fecha inválido (use YYYY-MM-DD)' });
      }

      // Create date range for the target date (handle timezone properly)
      const startOfDay = new Date(targetDate);
      startOfDay.setUTCHours(0, 0, 0, 0);
      const endOfDay = new Date(targetDate);
      endOfDay.setUTCHours(23, 59, 59, 999);
      
      // First, find all schedules for the date (populate tenantId)
      const allSchedules = await ScheduleModel.find({
        professorId: professor._id,
        startTime: {
          $gte: startOfDay,
          $lte: endOfDay
        }
      }).populate('tenantId', 'name').sort({ startTime: 1 });

      // Then filter to only include schedules that have bookings
      const schedulesWithBookings = [];
      for (const schedule of allSchedules) {
        const bookingQuery: any = {
          scheduleId: schedule._id,
          status: 'confirmed', // Only confirmed bookings
        };
        
        // Filter by tenantId if provided (from middleware)
        if (req.tenantId) {
          bookingQuery.tenantId = new Types.ObjectId(req.tenantId);
        }
        
        const booking = await BookingModel.findOne(bookingQuery);
        
        if (booking) {
          // Populate student info from the booking
          const student = await StudentModel.findById(booking.studentId);
          if (student) {
            schedulesWithBookings.push({
              ...schedule.toObject(),
              studentId: student._id,
              studentInfo: student
            });
          }
        }
      }

      const schedules = schedulesWithBookings;

      // Get booking info for each schedule to include price and service type
      const classesData = await Promise.all(
        schedules.map(async (schedule) => {
          const bookingQuery: any = { scheduleId: schedule._id };
          
          // Filter by tenantId if provided (from middleware)
          if (req.tenantId) {
            bookingQuery.tenantId = new Types.ObjectId(req.tenantId);
          }
          
          const booking = await BookingModel.findOne(bookingQuery);
          
          // Get tenant info from populated schedule
          const tenant = schedule.tenantId as any;
          
          return {
            id: schedule._id.toString(),
            studentName: schedule.studentInfo?.name || 'Estudiante',
            studentId: schedule.studentId?.toString() || '',
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            status: booking?.status || 'confirmed',
            notes: schedule.notes,
            serviceType: booking?.serviceType,
            price: booking?.price,
            tenantId: tenant?._id?.toString() || schedule.tenantId?.toString() || null,
            tenantName: tenant?.name || null,
          };
        })
      );

      res.json({ items: classesData });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error getting schedule by date', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  // Obtener horarios de hoy
  getTodaySchedule = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: professorId });
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Obtener horarios reales de hoy (usando startTime en lugar de date)
      // Ajustar para zona horaria de Colombia (UTC-5)
      const now = new Date();
      const today = new Date(now.getTime() - (5 * 60 * 60 * 1000)); // Ajustar a Colombia UTC-5
      today.setHours(0, 0, 0, 0);
      const tomorrow = new Date(today);
      tomorrow.setDate(tomorrow.getDate() + 1);

      console.log('Filtering schedules for today:', {
        today: today.toISOString(),
        tomorrow: tomorrow.toISOString(),
        professorId: professor._id.toString()
      });

      // Build schedule query with tenantId filter if present
      const scheduleQuery: any = {
        professorId: professor._id,
        studentId: { $exists: true, $ne: null },
      };
      
      // Filter by tenantId if provided (from middleware)
      if (req.tenantId) {
        scheduleQuery.tenantId = new Types.ObjectId(req.tenantId);
      }
      
      // First, let's see ALL schedules with studentId for this professor
      const allReservedSchedules = await ScheduleModel.find(scheduleQuery)
        .populate('studentId', 'name email')
        .sort({ startTime: 1 })
        .limit(5);

      console.log(`Total reserved schedules for professor: ${allReservedSchedules.length}`);
      allReservedSchedules.forEach((s, i) => {
        console.log(`Reserved schedule ${i + 1}:`, {
          id: s._id.toString(),
          startTime: s.startTime.toISOString(),
          studentName: (s.studentId as any)?.name,
          status: s.status
        });
      });

      // Build schedule query with tenantId filter if present
      const todayScheduleQuery: any = {
        professorId: professor._id,
        startTime: {
          $gte: today,
          $lt: tomorrow
        }
      };
      
      // Filter by tenantId if provided (from middleware)
      if (req.tenantId) {
        todayScheduleQuery.tenantId = new Types.ObjectId(req.tenantId);
      }
      
      // First, find all schedules for today
      const allTodaySchedules = await ScheduleModel.find(todayScheduleQuery).sort({ startTime: 1 });

      // Then filter to only include schedules that have bookings
      const todaySchedulesWithBookings = [];
      for (const schedule of allTodaySchedules) {
        const bookingQuery: any = {
          scheduleId: schedule._id,
          status: 'confirmed', // Only confirmed bookings
        };
        
        // Filter by tenantId if provided (from middleware)
        if (req.tenantId) {
          bookingQuery.tenantId = new Types.ObjectId(req.tenantId);
        }
        
        const booking = await BookingModel.findOne(bookingQuery);
        
        if (booking) {
          // Populate student info from the booking
          const student = await StudentModel.findById(booking.studentId);
          if (student) {
            todaySchedulesWithBookings.push({
              ...schedule.toObject(),
              studentId: student._id,
              studentInfo: student
            });
          }
        }
      }

      const todayClasses = todaySchedulesWithBookings;

      console.log(`Found ${todayClasses.length} classes for today (between ${today.toISOString()} and ${tomorrow.toISOString()})`);
      if (todayClasses.length > 0) {
        console.log('First class:', {
          startTime: todayClasses[0].startTime.toISOString(),
          studentName: (todayClasses[0].studentId as any)?.name
        });
      }

      // Get booking info for each schedule to include price and service type
      const classesData = await Promise.all(
        todayClasses.map(async (schedule) => {
          const bookingQuery: any = { scheduleId: schedule._id };
          
          // Filter by tenantId if provided (from middleware)
          if (req.tenantId) {
            bookingQuery.tenantId = new Types.ObjectId(req.tenantId);
          }
          
          const booking = await BookingModel.findOne(bookingQuery);
          
          return {
            id: schedule._id.toString(),
            studentName: schedule.studentInfo?.name || 'Estudiante',
            studentId: schedule.studentId?.toString() || '',
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            status: booking?.status || 'confirmed',
            notes: schedule.notes,
            serviceType: booking?.serviceType,
            price: booking?.price,
          };
        })
      );

      res.json({ items: classesData });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error getting today schedule', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  // Obtener horarios de la semana
  getWeekSchedule = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: professorId });
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Obtener horarios reales de la semana (usando startTime)
      const today = new Date();
      today.setHours(0, 0, 0, 0);
      const weekEnd = new Date(today);
      weekEnd.setDate(weekEnd.getDate() + 7);

      // Build schedule query with tenantId filter if present
      const weekScheduleQuery: any = {
        professorId: professor._id,
        startTime: {
          $gte: today,
          $lt: weekEnd
        },
        studentId: { $exists: true, $ne: null }, // Solo horarios reservados
      };
      
      // Filter by tenantId if provided (from middleware)
      if (req.tenantId) {
        weekScheduleQuery.tenantId = new Types.ObjectId(req.tenantId);
      }
      
      const weekClasses = await ScheduleModel.find(weekScheduleQuery)
        .populate('studentId', 'name email')
        .sort({ startTime: 1 });

      console.log(`Found ${weekClasses.length} classes for this week`);

      // Transformar los datos para que coincidan con el formato esperado
      const classesData = weekClasses.map(schedule => ({
        id: schedule._id.toString(),
        studentName: schedule.studentId ? (schedule.studentId as any).name : 'Estudiante',
        studentId: schedule.studentId ? (schedule.studentId as any)._id.toString() : '',
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        status: schedule.status || 'pending',
        notes: schedule.notes,
      }));

      res.json({ items: classesData });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error getting week schedule', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  // Obtener estadísticas de ganancias
  getEarningsStats = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: professorId });
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Calcular ganancias reales
      const now = new Date();
      const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
      const startOfWeek = new Date(now);
      startOfWeek.setDate(now.getDate() - now.getDay());

      // Build payment queries with tenantId filter if present
      const monthlyPaymentQuery: any = {
        professorId: professor._id,
        createdAt: { $gte: startOfMonth }
      };
      
      const weeklyPaymentQuery: any = {
        professorId: professor._id,
        createdAt: { $gte: startOfWeek }
      };
      
      // Filter by tenantId if provided (from middleware)
      if (req.tenantId) {
        monthlyPaymentQuery.tenantId = new Types.ObjectId(req.tenantId);
        weeklyPaymentQuery.tenantId = new Types.ObjectId(req.tenantId);
      }
      
      // Obtener pagos del mes
      const monthlyPayments = await PaymentModel.find(monthlyPaymentQuery);

      // Obtener pagos de la semana
      const weeklyPayments = await PaymentModel.find(weeklyPaymentQuery);

      // Calcular totales
      const monthlyEarnings = monthlyPayments.reduce((sum, payment) => sum + payment.amount, 0);
      const weeklyEarnings = weeklyPayments.reduce((sum, payment) => sum + payment.amount, 0);
      const classesThisMonth = monthlyPayments.length;

      // Obtener total de ganancias (todos los pagos)
      const totalPayments = await PaymentModel.find({ professorId: professor._id });
      const totalEarnings = totalPayments.reduce((sum, payment) => sum + payment.amount, 0);

      const earnings = {
        monthlyEarnings: monthlyEarnings,
        weeklyEarnings: weeklyEarnings,
        classesThisMonth: classesThisMonth,
        totalEarnings: totalEarnings,
      };

      res.json(earnings);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error getting earnings stats', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  // Actualizar perfil del profesor
  updateProfile = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { name, phone, specialties, hourlyRate, experienceYears } = req.body;

      const professor = await ProfessorModel.findOneAndUpdate(
        { authUserId: professorId },
        {
          name,
          phone,
          specialties,
          hourlyRate,
          experienceYears,
        },
        { new: true }
      );

      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      res.json(professor);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error updating profile', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  // Confirmar clase
  confirmClass = async (req: Request, res: Response) => {
    try {
      const { classId } = req.params;
      // TODO: Implement actual class confirmation logic
      logger.info('Class confirmed', { classId, requestId: req.requestId });
      res.json({ message: `Class ${classId} confirmed` });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error confirming class', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  // Cancelar clase
  cancelClass = async (req: Request, res: Response) => {
    try {
      const { classId } = req.params;
      const { reason } = req.body;
      // TODO: Implement actual class cancellation logic
      logger.info('Class cancelled', { classId, requestId: req.requestId });
      res.json({ message: `Class ${classId} cancelled` });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error('Error canceling class', { error: message, requestId: req.requestId });
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Create a new available schedule
   */
  createSchedule = async (req: Request, res: Response) => {
    console.log('=== ProfessorDashboardController.createSchedule called ===');
    console.log('Request body:', JSON.stringify(req.body, null, 2));
    console.log('req.user:', JSON.stringify(req.user, null, 2));
    console.log('Firebase UID:', req.user?.uid);
    console.log('Step 1: Starting try block...');
    
    try {
      console.log('Step 2: Getting firebaseUid...');
      const firebaseUid = req.user?.uid;
      console.log('Step 3: firebaseUid =', firebaseUid);
      
      if (!firebaseUid) {
        console.log('ERROR: No firebaseUid found');
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      console.log('Step 4: Destructuring request body...');
      const { date, startTime, endTime, tenantId } = req.body;
      console.log('Parsed body:', { date, startTime, endTime, tenantId });
      
      if (!date || !startTime || !endTime) {
        console.log('ERROR: Missing required fields');
        return res.status(400).json({ error: 'Faltan campos requeridos: date, startTime, endTime' });
      }
      
      console.log('Step 5: All required fields present, continuing...');

      // Get professor
      console.log('Looking for AuthUser with firebaseUid:', firebaseUid);
      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        console.log('ERROR: AuthUser not found');
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }
      console.log('AuthUser found:', authUser._id);

      console.log('Looking for Professor with authUserId:', authUser._id);
      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        console.log('ERROR: Professor not found');
        return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
      }
      console.log('Professor found:', professor._id);

      // Determine tenantId: from body, header, or first active tenant
      let finalTenantId: Types.ObjectId | null = null;

      // 1. Try from request body
      if (tenantId) {
        if (!Types.ObjectId.isValid(tenantId)) {
          return res.status(400).json({ error: 'tenantId inválido' });
        }
        finalTenantId = new Types.ObjectId(tenantId);
        
        // Verify professor has access to this tenant
        const professorTenant = await ProfessorTenantModel.findOne({
          professorId: professor._id,
          tenantId: finalTenantId,
          isActive: true
        });
        
        if (!professorTenant) {
          return res.status(403).json({ error: 'El profesor no tiene acceso a este centro' });
        }
      } else if (req.tenantId) {
        // 2. Try from header (X-Tenant-ID)
        finalTenantId = new Types.ObjectId(req.tenantId);
        
        // Verify professor has access to this tenant
        const professorTenant = await ProfessorTenantModel.findOne({
          professorId: professor._id,
          tenantId: finalTenantId,
          isActive: true
        });
        
        if (!professorTenant) {
          return res.status(403).json({ error: 'El profesor no tiene acceso a este centro' });
        }
      } else {
        // 3. Get first active tenant for the professor
        const professorTenant = await ProfessorTenantModel.findOne({
          professorId: professor._id,
          isActive: true
        }).sort({ joinedAt: -1 }); // Get most recently joined tenant
        
        if (!professorTenant) {
          return res.status(400).json({ 
            error: 'El profesor no está asociado a ningún centro. Debe estar asociado a un centro para crear horarios.' 
          });
        }
        
        finalTenantId = professorTenant.tenantId;
        console.log(`Using default tenant for professor: ${finalTenantId}`);
      }

      if (!finalTenantId) {
        return res.status(400).json({ error: 'No se pudo determinar el centro (tenantId) para el horario' });
      }

      // Parse dates - the client now sends UTC DateTime with the exact hour/minute selected
      // The client creates DateTime.utc() with the selected local time components
      // So if user selects 10:00 AM local, client sends 10:00 UTC (not 15:00 UTC)
      // We can directly parse these as UTC dates
      console.log('Parsing dates...');
      const parsedStartTime = new Date(startTime);
      const parsedEndTime = new Date(endTime);
      const parsedDate = new Date(date);
      console.log('Parsed dates:', {
        startTime: parsedStartTime.toISOString(),
        endTime: parsedEndTime.toISOString(),
        date: parsedDate.toISOString()
      });

      // Validate: Check if professor already has a schedule at the same time in any center
      const sameTimeSchedule = await ScheduleModel.findOne({
        professorId: professor._id,
        startTime: parsedStartTime,
        // Same day (compare dates, not times)
        $expr: {
          $and: [
            { $eq: [{ $year: '$startTime' }, parsedStartTime.getUTCFullYear()] },
            { $eq: [{ $month: '$startTime' }, parsedStartTime.getUTCMonth() + 1] },
            { $eq: [{ $dayOfMonth: '$startTime' }, parsedStartTime.getUTCDate()] },
          ]
        }
      }).populate('tenantId', 'name');

      if (sameTimeSchedule) {
        const conflictingTenant = sameTimeSchedule.tenantId as any;
        const conflictingTenantName = conflictingTenant?.name || 'otro centro';
        return res.status(409).json({ 
          error: 'CONFLICT_SAME_TIME',
          message: `Ya tienes un horario a esta hora en ${conflictingTenantName}. No puedes tener el mismo horario en diferentes centros.`,
          conflictingTenantId: conflictingTenant?._id?.toString(),
          conflictingTenantName: conflictingTenantName
        });
      }

      // Check for consecutive schedules in different centers (warning, not error)
      // Find schedules that end right before this one starts (within 30 minutes)
      const previousSchedule = await ScheduleModel.findOne({
        professorId: professor._id,
        endTime: {
          $gte: new Date(parsedStartTime.getTime() - 30 * 60 * 1000), // 30 minutes before
          $lte: parsedStartTime
        },
        // Same day
        $expr: {
          $and: [
            { $eq: [{ $year: '$endTime' }, parsedStartTime.getUTCFullYear()] },
            { $eq: [{ $month: '$endTime' }, parsedStartTime.getUTCMonth() + 1] },
            { $eq: [{ $dayOfMonth: '$endTime' }, parsedStartTime.getUTCDate()] },
          ]
        },
        tenantId: { $ne: finalTenantId } // Different center
      }).populate('tenantId', 'name');

      // Find schedules that start right after this one ends (within 30 minutes)
      const nextSchedule = await ScheduleModel.findOne({
        professorId: professor._id,
        startTime: {
          $gte: parsedEndTime,
          $lte: new Date(parsedEndTime.getTime() + 30 * 60 * 1000) // 30 minutes after
        },
        // Same day
        $expr: {
          $and: [
            { $eq: [{ $year: '$startTime' }, parsedEndTime.getUTCFullYear()] },
            { $eq: [{ $month: '$startTime' }, parsedEndTime.getUTCMonth() + 1] },
            { $eq: [{ $dayOfMonth: '$startTime' }, parsedEndTime.getUTCDate()] },
          ]
        },
        tenantId: { $ne: finalTenantId } // Different center
      }).populate('tenantId', 'name');

      const warnings: string[] = [];
      if (previousSchedule) {
        const prevTenant = previousSchedule.tenantId as any;
        warnings.push(`Tienes un horario que termina justo antes en ${prevTenant?.name || 'otro centro'}. Podrías tener retrasos para llegar a tiempo.`);
      }
      if (nextSchedule) {
        const nextTenant = nextSchedule.tenantId as any;
        warnings.push(`Tienes un horario que comienza justo después en ${nextTenant?.name || 'otro centro'}. Podrías tener retrasos para llegar a tiempo.`);
      }

      // Create schedule with tenantId
      console.log('Creating schedule with:', {
        tenantId: finalTenantId.toString(),
        professorId: professor._id.toString(),
        date: parsedDate.toISOString(),
        startTime: parsedStartTime.toISOString(),
        endTime: parsedEndTime.toISOString()
      });
      
      const schedule = await ScheduleModel.create({
        tenantId: finalTenantId,
        professorId: professor._id,
        date: parsedDate,
        startTime: parsedStartTime,
        endTime: parsedEndTime,
        isAvailable: true,
        status: 'pending'
      });

      console.log(`Schedule created successfully: ${schedule._id} with tenantId: ${finalTenantId}`);
      
      const response: any = {
        id: schedule._id,
        tenantId: schedule.tenantId,
        professorId: schedule.professorId,
        date: schedule.date,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        isAvailable: schedule.isAvailable,
        status: schedule.status
      };

      // Include warnings if any
      if (warnings.length > 0) {
        response.warnings = warnings;
      }
      
      res.status(201).json(response);

      console.log(`Schedule created successfully: ${schedule._id} with tenantId: ${finalTenantId}`);
      
      res.status(201).json({
        id: schedule._id,
        tenantId: schedule.tenantId,
        professorId: schedule.professorId,
        date: schedule.date,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        isAvailable: schedule.isAvailable,
        status: schedule.status
      });
    } catch (error) {
      console.error('=== ERROR in createSchedule ===');
      console.error('Error type:', error?.constructor?.name);
      console.error('Error message:', error instanceof Error ? error.message : String(error));
      console.error('Error stack:', error instanceof Error ? error.stack : 'No stack trace');
      if (error && typeof error === 'object') {
        try {
          console.error('Full error object:', JSON.stringify(error, Object.getOwnPropertyNames(error), 2));
        } catch (e) {
          console.error('Could not stringify error object');
        }
      }
      
      const errorMessage = error instanceof Error ? error.message : 'Error desconocido';
      
      // Check if it's a validation error (e.g., missing tenantId)
      if (errorMessage.includes('tenantId') || errorMessage.includes('required')) {
        console.log('Returning 400 - Validation error');
        return res.status(400).json({ 
          error: 'Error de validación', 
          message: 'El horario requiere un centro (tenantId) asociado' 
        });
      }
      
      console.log('Returning 500 - Internal server error');
      res.status(500).json({ error: 'Error interno del servidor', message: errorMessage });
    }
  };

  /**
   * Get all schedules for the professor
   */
  getMySchedules = async (req: Request, res: Response) => {
    
    try {
      const firebaseUid = req.user?.uid;
      console.log('Firebase UID:', firebaseUid);
      
      if (!firebaseUid) {
        console.log('ERROR: No firebaseUid');
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

      // Get all schedules for the professor - only future schedules
      // Filter by tenantId if provided (from X-Tenant-ID header)
      const now = new Date();
      
      const query: any = {
        professorId: professor._id,
        startTime: { $gte: now } // Only future schedules
      };

      // Filter by tenantId if provided in header
      if (req.tenantId) {
        query.tenantId = new Types.ObjectId(req.tenantId);
      }
      
      const schedules = await ScheduleModel.find(query)
        .populate('studentId', 'name email')
        .populate('tenantId', 'name slug')
        .sort({ startTime: 1 })
        .limit(200);

      const schedulesData = schedules.map(schedule => {
        const hasStudent = !!schedule.studentId;
        
        // Debug: Log raw studentId
        if (hasStudent) {
          console.log('Schedule with studentId:', {
            scheduleId: schedule._id.toString(),
            studentIdRaw: schedule.studentId,
            studentIdType: typeof schedule.studentId,
            studentIdName: (schedule.studentId as any)?.name,
            isAvailable: schedule.isAvailable
          });
        }
        
        const tenant = schedule.tenantId as any;
        
        return {
          id: schedule._id.toString(),
          date: schedule.date.toISOString(),
          startTime: schedule.startTime.toISOString(),
          endTime: schedule.endTime.toISOString(),
          isAvailable: schedule.isAvailable,
          isBlocked: schedule.isBlocked || false,
          blockReason: schedule.blockReason || null,
          status: schedule.status || 'pending',
          studentName: hasStudent ? (schedule.studentId as any).name : null,
          studentEmail: hasStudent ? (schedule.studentId as any).email : null,
          tenantId: tenant ? tenant._id.toString() : null,
          tenantName: tenant ? tenant.name : null
        };
      });

      // Log booked schedules for debugging
      const bookedSchedules = schedulesData.filter(s => s.studentName);
      console.log(`Found ${schedulesData.length} total schedules, ${bookedSchedules.length} booked`);

      res.json({ items: schedulesData });
    } catch (error) {
      console.error('Error getting schedules:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Delete a schedule
   */
  deleteSchedule = async (req: Request, res: Response) => {
    console.log('=== ProfessorDashboardController.deleteSchedule called ===');
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { scheduleId } = req.params;
      
      if (!scheduleId) {
        return res.status(400).json({ error: 'scheduleId es requerido' });
      }

      const schedule = await ScheduleModel.findById(scheduleId);
      if (!schedule) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }

      // Check if schedule is already booked
      if (!schedule.isAvailable && schedule.studentId) {
        return res.status(400).json({ error: 'No se puede eliminar un horario ya reservado' });
      }

      await ScheduleModel.findByIdAndDelete(scheduleId);

      console.log(`Schedule deleted: ${scheduleId}`);
      res.json({ message: 'Horario eliminado exitosamente' });
    } catch (error) {
      console.error('Error deleting schedule:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Block a schedule (mark as unavailable for students)
   */
  blockSchedule = async (req: Request, res: Response) => {
    console.log('=== ProfessorDashboardController.blockSchedule called ===');
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { scheduleId } = req.params;
      const { reason } = req.body;
      
      if (!scheduleId) {
        return res.status(400).json({ error: 'scheduleId es requerido' });
      }

      const schedule = await ScheduleModel.findById(scheduleId);
      if (!schedule) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }

      // Check if schedule is already booked
      if (schedule.studentId) {
        return res.status(400).json({ error: 'No se puede bloquear un horario ya reservado' });
      }

      schedule.isBlocked = true;
      schedule.blockReason = reason || 'Bloqueado por el profesor';
      schedule.isAvailable = false;
      await schedule.save();

      console.log(`Schedule blocked: ${scheduleId}`);
      res.json({ message: 'Horario bloqueado exitosamente' });
    } catch (error) {
      console.error('Error blocking schedule:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Unblock a schedule
   */
  unblockSchedule = async (req: Request, res: Response) => {
    console.log('=== ProfessorDashboardController.unblockSchedule called ===');
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { scheduleId } = req.params;
      
      if (!scheduleId) {
        return res.status(400).json({ error: 'scheduleId es requerido' });
      }

      const schedule = await ScheduleModel.findById(scheduleId);
      if (!schedule) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }

      schedule.isBlocked = false;
      schedule.blockReason = undefined;
      schedule.isAvailable = true;
      await schedule.save();

      console.log(`Schedule unblocked: ${scheduleId}`);
      res.json({ message: 'Horario desbloqueado exitosamente' });
    } catch (error) {
      console.error('Error unblocking schedule:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Mark a class as completed
   */
  completeClass = async (req: Request, res: Response) => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { scheduleId } = req.params;
      const { paymentAmount } = req.body;
      
      if (!scheduleId) {
        return res.status(400).json({ error: 'scheduleId es requerido' });
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
      }

      // Find schedule and verify it belongs to this professor
      const schedule = await ScheduleModel.findById(scheduleId);
      if (!schedule) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }

      if (schedule.professorId.toString() !== professor._id.toString()) {
        return res.status(403).json({ error: 'No autorizado para completar esta clase' });
      }

      if (!schedule.studentId) {
        return res.status(400).json({ error: 'Este horario no tiene una reserva' });
      }

      // Update schedule status
      schedule.status = 'completed';
      await schedule.save();

      // Build booking query with tenantId filter if present
      const bookingQuery: any = { scheduleId: schedule._id };
      
      // Filter by tenantId if provided (from middleware)
      if (req.tenantId) {
        bookingQuery.tenantId = new Types.ObjectId(req.tenantId);
      }
      
      // Update booking status
      const booking = await BookingModel.findOne(bookingQuery);
      if (booking) {
        booking.status = 'completed';
        await booking.save();
      }

      // Create payment record if amount provided
      let payment = null;
      if (paymentAmount && paymentAmount > 0 && schedule.studentId && booking) {
        payment = await PaymentModel.create({
          studentId: schedule.studentId,
          professorId: professor._id,
          bookingId: booking._id,
          amount: paymentAmount,
          date: new Date(),
          status: 'paid',
          method: 'cash', // Default to cash, can be updated later
          description: `Pago por ${booking.serviceType} - ${schedule.startTime.toLocaleDateString()}`
        });
      }

      res.json({ 
        message: 'Clase marcada como completada' + (payment ? ' y pago registrado' : ''),
        scheduleId: schedule._id,
        bookingId: booking?._id,
        paymentId: payment?._id
      });
    } catch (error) {
      console.error('Error completing class:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Cancel a booking
   */
  cancelBooking = async (req: Request, res: Response) => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { scheduleId } = req.params;
      const { reason, penaltyAmount } = req.body;
      
      if (!scheduleId) {
        return res.status(400).json({ error: 'scheduleId es requerido' });
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
      }

      // Find schedule
      const schedule = await ScheduleModel.findById(scheduleId);
      if (!schedule) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }

      if (schedule.professorId.toString() !== professor._id.toString()) {
        return res.status(403).json({ error: 'No autorizado para cancelar esta reserva' });
      }

      // Build booking query with tenantId filter if present
      const bookingQuery: any = { scheduleId: schedule._id };
      
      // Filter by tenantId if provided (from middleware)
      if (req.tenantId) {
        bookingQuery.tenantId = new Types.ObjectId(req.tenantId);
      }
      
      // Update booking
      const booking = await BookingModel.findOne(bookingQuery);
      if (booking) {
        booking.status = 'cancelled';
        booking.notes = reason || 'Cancelado por el profesor';
        await booking.save();
      }

      // Create penalty payment if amount provided
      let payment = null;
      if (penaltyAmount && penaltyAmount > 0 && schedule.studentId && booking) {
        payment = await PaymentModel.create({
          studentId: schedule.studentId,
          professorId: professor._id,
          bookingId: booking._id,
          amount: penaltyAmount,
          date: new Date(),
          status: 'paid',
          method: 'cash',
          description: `Penalización por cancelación - ${reason || 'Sin motivo especificado'}`
        });
      }

      // Free up the schedule
      schedule.studentId = undefined;
      schedule.isAvailable = true;
      schedule.status = 'cancelled';
      await schedule.save();

      res.json({ 
        message: 'Reserva cancelada exitosamente' + (payment ? ' con penalización registrada' : ''),
        scheduleId: schedule._id,
        paymentId: payment?._id
      });
    } catch (error) {
      console.error('Error cancelling booking:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get tenants (centers) where the professor is active
   * TEN-91: MT-BACK-009
   * GET /api/professor-dashboard/tenants
   */
  getMyTenants = async (req: Request, res: Response) => {
    console.log('=== ProfessorDashboardController.getMyTenants called ===');
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      // Get AuthUser by Firebase UID
      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      // Get Professor profile
      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
      }

      // Get all active ProfessorTenant relationships
      const professorTenants = await ProfessorTenantModel.find({
        professorId: professor._id,
        isActive: true,
      })
        .populate('tenantId', 'name slug config isActive')
        .sort({ joinedAt: -1 });

      // Get last activity (last schedule) for each tenant
      const tenantsWithActivity = await Promise.all(
        professorTenants.map(async (pt) => {
          const tenant = pt.tenantId as any;
          
          // Get last schedule/booking for this professor in this tenant
          const lastSchedule = await ScheduleModel.findOne({
            professorId: professor._id,
            tenantId: tenant._id,
          })
            .sort({ startTime: -1 })
            .limit(1)
            .lean();

          return {
            id: tenant._id.toString(),
            name: tenant.name,
            slug: tenant.slug,
            logo: tenant.config?.logo || null,
            isActive: pt.isActive,
            joinedAt: pt.joinedAt,
            lastActivity: lastSchedule ? lastSchedule.startTime : null,
            pricing: pt.pricing || null,
          };
        })
      );

      console.log(`Found ${tenantsWithActivity.length} active tenants for professor ${professor._id}`);
      res.json({ items: tenantsWithActivity });
    } catch (error) {
      console.error('Error getting professor tenants:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Join a tenant (center) as a professor
   * TEN-108: Self-service join has been disabled.
   * Professors must be invited by a tenant admin to join a center.
   * POST /api/professor-dashboard/tenants/join
   */
  joinTenant = async (req: Request, res: Response) => {
    res.status(403).json({
      error: 'No puedes unirte a un centro por tu cuenta. Debes ser invitado por un administrador del centro.',
      code: 'INVITATION_REQUIRED',
    });
  };

  /**
   * Get the active tenant for the current professor
   * Returns the first favorite tenant (uses UserPreferences like students)
   * GET /api/professor-dashboard/active-tenant
   */
  getActiveTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        res.status(401).json({ error: 'Usuario no autenticado' });
        return;
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        res.status(404).json({ error: 'Usuario no encontrado' });
        return;
      }

      // Get preferences and find first favorite tenant
      const preferences = await UserPreferencesModel.findOne({ userId: authUser._id })
        .populate({
          path: 'favoriteTenants',
          select: 'name slug config isActive',
        });

      if (!preferences || !preferences.favoriteTenants || preferences.favoriteTenants.length === 0) {
        res.status(404).json({ error: 'No hay centro favorito configurado' });
        return;
      }

      // Get first favorite tenant
      const firstFavorite = preferences.favoriteTenants[0] as any;
      if (!firstFavorite || !firstFavorite.isActive) {
        res.status(404).json({ error: 'No hay centro favorito activo' });
        return;
      }

      res.json({
        tenantId: firstFavorite._id.toString(),
        tenantName: firstFavorite.name,
        tenantSlug: firstFavorite.slug,
        logo: firstFavorite.config?.logo || null,
        isActive: firstFavorite.isActive,
      });
    } catch (error) {
      console.error('Error getting active tenant:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Set the active tenant for the current professor
   * Adds tenant to favorites and moves it to the first position (uses UserPreferences like students)
   * POST /api/professor-dashboard/active-tenant
   * Body: { tenantId: string }
   */
  setActiveTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        res.status(401).json({ error: 'Usuario no autenticado' });
        return;
      }

      const { tenantId } = req.body;
      if (!tenantId) {
        res.status(400).json({ error: 'tenantId es requerido' });
        return;
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        res.status(404).json({ error: 'Usuario no encontrado' });
        return;
      }

      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        res.status(404).json({ error: 'Perfil de profesor no encontrado' });
        return;
      }

      // Validate tenant exists
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        res.status(404).json({ error: 'Centro no encontrado' });
        return;
      }

      if (!tenant.isActive) {
        res.status(400).json({ error: 'El centro no está activo' });
        return;
      }

      // Verify professor has access to this tenant
      const professorTenant = await ProfessorTenantModel.findOne({
        professorId: professor._id,
        tenantId: new Types.ObjectId(tenantId),
        isActive: true,
      });

      if (!professorTenant) {
        res.status(403).json({ error: 'El profesor no tiene acceso a este centro' });
        return;
      }

      // Get or create preferences
      let preferences = await UserPreferencesModel.findOne({ userId: authUser._id });
      if (!preferences) {
        preferences = await UserPreferencesModel.create({
          userId: authUser._id,
          favoriteProfessors: [],
          favoriteTenants: [],
        });
      }

      const tenantObjectId = new Types.ObjectId(tenantId);

      // When selecting a tenant, it becomes the ONLY favorite
      // This ensures only one center has the heart icon at a time
      preferences.favoriteTenants = [tenantObjectId];
      await preferences.save();

      res.json({
        message: 'Centro configurado',
        tenantId,
        tenantName: tenant.name,
      });
    } catch (error) {
      console.error('Error setting active tenant:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };
}
