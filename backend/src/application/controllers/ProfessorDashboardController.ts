import { Request, Response } from 'express';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { Logger } from '../../infrastructure/services/Logger';
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
          hourlyRate: 0
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
      const experienceYears = Math.max(1, Math.floor((new Date().getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24 * 365)));

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
      
      const schedules = await ScheduleModel.find({
        professorId: professor._id,
        startTime: {
          $gte: startOfDay,
          $lte: endOfDay
        },
        studentId: { $exists: true, $ne: null }, // Only reserved schedules
        status: 'confirmed' // Only confirmed classes (not completed or cancelled)
      })
        .populate('studentId', 'name email')
        .sort({ startTime: 1 });

      // Get booking info for each schedule to include price and service type
      const classesData = await Promise.all(
        schedules.map(async (schedule) => {
          const booking = await BookingModel.findOne({ scheduleId: schedule._id });
          
          return {
            id: schedule._id.toString(),
            studentName: (schedule.studentId as any).name,
            studentId: (schedule.studentId as any)._id.toString(),
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            status: schedule.status || 'confirmed',
            notes: schedule.notes,
            serviceType: booking?.serviceType,
            price: booking?.price,
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

      // First, let's see ALL schedules with studentId for this professor
      const allReservedSchedules = await ScheduleModel.find({
        professorId: professor._id,
        studentId: { $exists: true, $ne: null }
      })
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

      const todayClasses = await ScheduleModel.find({
        professorId: professor._id,
        startTime: {
          $gte: today,
          $lt: tomorrow
        },
        studentId: { $exists: true, $ne: null }, // Solo horarios reservados
        status: 'confirmed' // Solo clases confirmadas (no completadas ni canceladas)
      })
        .populate('studentId', 'name email')
        .sort({ startTime: 1 });

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
          const booking = await BookingModel.findOne({ scheduleId: schedule._id });
          
          return {
            id: schedule._id.toString(),
            studentName: schedule.studentId ? (schedule.studentId as any).name : 'Estudiante',
            studentId: schedule.studentId ? (schedule.studentId as any)._id.toString() : '',
            startTime: schedule.startTime,
            endTime: schedule.endTime,
            status: schedule.status || 'pending',
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

      const weekClasses = await ScheduleModel.find({
        professorId: professor._id,
        startTime: {
          $gte: today,
          $lt: weekEnd
        },
        studentId: { $exists: true, $ne: null } // Solo horarios reservados
      })
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

      // Obtener pagos del mes
      const monthlyPayments = await PaymentModel.find({
        professorId: professor._id,
        createdAt: { $gte: startOfMonth }
      });

      // Obtener pagos de la semana
      const weeklyPayments = await PaymentModel.find({
        professorId: professor._id,
        createdAt: { $gte: startOfWeek }
      });

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

      const { name, phone, specialties, hourlyRate } = req.body;

      const professor = await ProfessorModel.findOneAndUpdate(
        { authUserId: professorId },
        {
          name,
          phone,
          specialties,
          hourlyRate,
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
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { date, startTime, endTime } = req.body;
      
      if (!date || !startTime || !endTime) {
        return res.status(400).json({ error: 'Faltan campos requeridos: date, startTime, endTime' });
      }

      // Get professor
      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const professor = await ProfessorModel.findOne({ authUserId: authUser._id });
      if (!professor) {
        return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
      }

      // Parse dates - they come in ISO format but we need to preserve local time
      // The client sends dates in local timezone, but when parsed as Date they become UTC
      // We need to adjust by adding the timezone offset
      const parsedStartTime = new Date(startTime);
      const parsedEndTime = new Date(endTime);
      const parsedDate = new Date(date);

      console.log('Received dates (from client):', { date, startTime, endTime });
      console.log('Parsed as UTC:', { 
        parsedDate: parsedDate.toISOString(), 
        parsedStartTime: parsedStartTime.toISOString(),
        parsedEndTime: parsedEndTime.toISOString()
      });
      console.log('Local time interpretation:', {
        startHour: parsedStartTime.getUTCHours(),
        endHour: parsedEndTime.getUTCHours(),
      });

      // Create schedule
      const schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: parsedDate,
        startTime: parsedStartTime,
        endTime: parsedEndTime,
        isAvailable: true,
        status: 'pending'
      });

      console.log(`Schedule created: ${schedule._id}`);
      
      res.status(201).json({
        id: schedule._id,
        professorId: schedule.professorId,
        date: schedule.date,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        isAvailable: schedule.isAvailable,
        status: schedule.status
      });
    } catch (error) {
      console.error('Error creating schedule:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get all schedules for the professor
   */
  getMySchedules = async (req: Request, res: Response) => {
    console.log('');
    console.log('========================================');
    console.log('=== GET MY SCHEDULES CALLED ===');
    console.log('========================================');
    console.log('');
    
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

      // Get all schedules for the professor
      const schedules = await ScheduleModel.find({
        professorId: professor._id,
        startTime: { $gte: new Date() } // Only future schedules
      })
        .populate('studentId', 'name email')
        .sort({ startTime: 1 })
        .limit(100);

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
        
        return {
          id: schedule._id.toString(),
          date: schedule.date,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
          isAvailable: schedule.isAvailable,
          isBlocked: schedule.isBlocked || false,
          blockReason: schedule.blockReason || null,
          status: schedule.status,
          studentName: hasStudent ? (schedule.studentId as any).name : null,
          studentEmail: hasStudent ? (schedule.studentId as any).email : null
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

      // Update booking status
      const booking = await BookingModel.findOne({ scheduleId: schedule._id });
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

      // Update booking
      const booking = await BookingModel.findOne({ scheduleId: schedule._id });
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
}
