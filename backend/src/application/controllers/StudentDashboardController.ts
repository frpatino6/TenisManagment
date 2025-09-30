import { Request, Response } from 'express';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { ServiceRequestModel } from '../../infrastructure/database/models/ServiceRequestModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';

export class StudentDashboardController {
  /**
   * Get student's recent activities (bookings, payments, service requests)
   */
  getRecentActivities = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getRecentActivities called ===');
    console.log('req.user:', req.user);
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        console.log('No firebaseUid found in req.user');
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      // Get AuthUser by Firebase UID
      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        console.log('AuthUser not found for Firebase UID:', firebaseUid);
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      // Get Student profile
      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        console.log('Student profile not found for authUserId:', authUser._id);
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      console.log('Student found:', student._id);

      // Get recent activities (last 30 days)
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      // Fetch bookings with schedule and professor info
      const bookings = await BookingModel.find({
        studentId: student._id,
        createdAt: { $gte: thirtyDaysAgo }
      })
        .populate({
          path: 'scheduleId',
          populate: {
            path: 'professorId',
            select: 'name'
          }
        })
        .sort({ createdAt: -1 })
        .limit(10);

      // Fetch payments with professor info
      const payments = await PaymentModel.find({
        studentId: student._id,
        date: { $gte: thirtyDaysAgo }
      })
        .populate('professorId', 'name')
        .sort({ date: -1 })
        .limit(10);

      // Fetch service requests
      const serviceRequests = await ServiceRequestModel.find({
        studentId: student._id,
        createdAt: { $gte: thirtyDaysAgo }
      })
        .sort({ createdAt: -1 })
        .limit(10);

      // Transform data into unified activity format
      const activities: any[] = [];

      // Add bookings as activities
      for (const booking of bookings) {
        const schedule = booking.scheduleId as any;
        const professor = schedule?.professorId as any;
        
        activities.push({
          id: booking._id.toString(),
          type: 'booking',
          title: booking.status === 'confirmed' ? 'Clase reservada' : 
                 booking.status === 'cancelled' ? 'Reserva cancelada' : 'Reserva pendiente',
          description: professor?.name ? `Prof. ${professor.name}` : 'Profesor',
          date: booking.createdAt || new Date(),
          status: booking.status,
          icon: 'calendar_today',
          color: booking.status === 'confirmed' ? 'blue' : 
                 booking.status === 'cancelled' ? 'red' : 'orange'
        });
      }

      // Add payments as activities
      for (const payment of payments) {
        const professor = payment.professorId as any;
        
        activities.push({
          id: payment._id.toString(),
          type: 'payment',
          title: 'Pago realizado',
          description: `${professor?.name || 'Profesor'} - $${payment.amount.toLocaleString()}`,
          date: payment.date,
          status: 'completed',
          icon: 'payment',
          color: 'green'
        });
      }

      // Add service requests as activities
      for (const request of serviceRequests) {
        activities.push({
          id: request._id.toString(),
          type: 'service_request',
          title: 'Solicitud de servicio',
          description: request.notes || 'Servicio solicitado',
          date: request.createdAt,
          status: request.status,
          icon: 'support_agent',
          color: 'orange'
        });
      }

      // Sort all activities by date (most recent first)
      activities.sort((a, b) => {
        const dateA = new Date(a.date);
        const dateB = new Date(b.date);
        return dateB.getTime() - dateA.getTime();
      });

      // Return top 10 most recent activities
      const recentActivities = activities.slice(0, 10);

      console.log(`Found ${recentActivities.length} recent activities for student ${student._id}`);

      res.json({
        items: recentActivities
      });
    } catch (error) {
      console.error('Error getting recent activities:', error);
      console.error('Error stack:', error instanceof Error ? error.stack : 'No stack');
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get student info/profile
   */
  getStudentInfo = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getStudentInfo called ===');
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      // Get statistics
      const totalBookings = await BookingModel.countDocuments({ studentId: student._id });
      const totalPayments = await PaymentModel.countDocuments({ studentId: student._id });
      const totalSpent = await PaymentModel.aggregate([
        { $match: { studentId: student._id } },
        { $group: { _id: null, total: { $sum: '$amount' } } }
      ]);

      res.json({
        id: student._id,
        name: student.name,
        email: student.email,
        phone: student.phone,
        level: 'Principiante', // Default level, can be extended in future
        totalClasses: totalBookings,
        totalPayments: totalPayments,
        totalSpent: totalSpent.length > 0 ? totalSpent[0].total : 0
      });
    } catch (error) {
      console.error('Error getting student info:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get list of all professors
   */
  getProfessors = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getProfessors called ===');
    
    try {
      const professors = await ProfessorModel.find()
        .select('name email phone specialties hourlyRate experienceYears rating')
        .limit(50);

      const professorsData = professors.map(prof => ({
        id: prof._id.toString(),
        name: prof.name,
        email: prof.email,
        phone: prof.phone || '',
        specialties: prof.specialties || [],
        hourlyRate: prof.hourlyRate || 0,
        experienceYears: 0, // Can be added to model later
        rating: 0 // Can be added to model later
      }));

      console.log(`Found ${professorsData.length} professors`);
      res.json({ items: professorsData });
    } catch (error) {
      console.error('Error getting professors:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get available schedules for a specific professor
   */
  getAvailableSchedules = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getAvailableSchedules called ===');
    
    try {
      const { professorId } = req.query;
      
      if (!professorId) {
        return res.status(400).json({ error: 'professorId es requerido' });
      }

      // Get all schedules for the professor that don't have a booking yet
      const schedules = await ScheduleModel.find({
        professorId,
        startTime: { $gte: new Date() }, // Only future schedules
        isAvailable: true // Only available slots
      })
        .sort({ startTime: 1 })
        .limit(100);

      const schedulesData = schedules.map(schedule => ({
        id: schedule._id.toString(),
        professorId: schedule.professorId.toString(),
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        type: schedule.type,
        price: schedule.price || 0,
        status: schedule.status
      }));

      console.log(`Found ${schedulesData.length} available schedules for professor ${professorId}`);
      res.json({ items: schedulesData });
    } catch (error) {
      console.error('Error getting available schedules:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Book a lesson
   */
  bookLesson = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.bookLesson called ===');
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { scheduleId } = req.body;
      
      if (!scheduleId) {
        return res.status(400).json({ error: 'scheduleId es requerido' });
      }

      // Get student
      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      // Check if schedule exists and is available
      const schedule = await ScheduleModel.findById(scheduleId);
      if (!schedule) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }

      if (!schedule.isAvailable) {
        return res.status(400).json({ error: 'Este horario ya no está disponible' });
      }

      // Create booking
      const booking = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        type: schedule.type === 'individual' ? 'lesson' : 'court_rental',
        status: 'confirmed',
        paymentStatus: 'pending'
      });

      // Update schedule availability
      schedule.isAvailable = false;
      schedule.studentId = student._id;
      schedule.status = 'confirmed';
      await schedule.save();

      console.log(`Booking created: ${booking._id}`);
      
      res.status(201).json({
        id: booking._id,
        studentId: booking.studentId,
        scheduleId: booking.scheduleId,
        type: booking.type,
        status: booking.status,
        paymentStatus: booking.paymentStatus,
        createdAt: booking.createdAt
      });
    } catch (error) {
      console.error('Error booking lesson:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };
}
