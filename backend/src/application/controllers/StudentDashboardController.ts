import { Request, Response } from 'express';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { ServiceRequestModel } from '../../infrastructure/database/models/ServiceRequestModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { SystemConfigModel } from '../../infrastructure/database/models/SystemConfigModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { UserPreferencesModel } from '../../infrastructure/database/models/UserPreferencesModel';
import { TenantService } from '../services/TenantService';
import { Types } from 'mongoose';

// Default base pricing
const DEFAULT_BASE_PRICING = {
  individualClass: 50000,
  groupClass: 35000,
  courtRental: 25000,
};

export class StudentDashboardController {
  private tenantService: TenantService;

  constructor() {
    this.tenantService = new TenantService();
  }

  /**
   * Find an available court for a given time range
   * Returns the first available court, or null if none available
   */
  private async findAvailableCourt(
    tenantId: Types.ObjectId,
    startTime: Date,
    endTime: Date,
  ): Promise<{ _id: Types.ObjectId; name: string } | null> {
    // Get all active courts for this tenant
    const courts = await CourtModel.find({
      tenantId: tenantId,
      isActive: true,
    }).lean();

    if (courts.length === 0) {
      return null;
    }

    // Find all bookings that have a courtId assigned and might overlap with the requested time
    // We need to check both court_rental (using bookingDate) and lessons (using scheduleId)
    const bookingsWithCourt = await BookingModel.find({
      tenantId: tenantId,
      courtId: { $exists: true, $ne: null },
      status: { $in: ['confirmed', 'pending'] },
    })
      .populate('scheduleId')
      .lean();

    // Create a set of occupied court IDs during this time
    const occupiedCourtIds = new Set<string>();

    bookingsWithCourt.forEach((booking) => {
      if (!booking.courtId) return;

      let bookingStart: Date;
      let bookingEnd: Date;

      if (booking.serviceType === 'court_rental' && booking.bookingDate) {
        // Court rental: use bookingDate as start, assume 1 hour duration
        bookingStart = new Date(booking.bookingDate);
        bookingEnd = new Date(bookingStart);
        bookingEnd.setUTCHours(bookingEnd.getUTCHours() + 1);
      } else if (booking.scheduleId && (booking.scheduleId as any).startTime) {
        // Lesson: use schedule times
        const schedule = booking.scheduleId as any;
        bookingStart = new Date(schedule.startTime);
        bookingEnd = new Date(schedule.endTime);
      } else {
        // Can't determine time, skip
        return;
      }

      // Check if time ranges overlap
      const overlaps =
        (startTime >= bookingStart && startTime < bookingEnd) ||
        (endTime > bookingStart && endTime <= bookingEnd) ||
        (startTime <= bookingStart && endTime >= bookingEnd);

      if (overlaps) {
        occupiedCourtIds.add(booking.courtId.toString());
      }
    });

    // Find first available court
    for (const court of courts) {
      if (!occupiedCourtIds.has(court._id.toString())) {
        return { _id: court._id, name: court.name };
      }
    }

    return null;
  }
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
   * Get list of professors for the active tenant
   * TEN-96: Updated to filter by tenant (multi-tenancy)
   */
  getProfessors = async (req: Request, res: Response) => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        return res.status(400).json({ 
          error: 'Tenant ID requerido. Selecciona un centro primero.' 
        });
      }

      // Get base pricing
      const baseConfig = await SystemConfigModel.findOne({ key: 'base_pricing' });
      const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;

      // Get active professors for this tenant
      const professorTenants = await ProfessorTenantModel.find({
        tenantId: new Types.ObjectId(tenantId),
        isActive: true,
      })
        .populate('professorId', 'name email phone specialties hourlyRate pricing experienceYears rating')
        .lean();

      const professorsData = professorTenants.map((pt: any) => {
        const prof = pt.professorId;
        if (!prof) return null;

        // Use tenant-specific pricing if available, otherwise professor's pricing, otherwise base pricing
        const effectivePricing = {
          individualClass:
            pt.pricing?.individualClass ??
            prof.pricing?.individualClass ??
            basePricing.individualClass,
          groupClass:
            pt.pricing?.groupClass ??
            prof.pricing?.groupClass ??
            basePricing.groupClass,
          courtRental:
            pt.pricing?.courtRental ??
            prof.pricing?.courtRental ??
            basePricing.courtRental,
        };

        return {
          id: prof._id.toString(),
          name: prof.name,
          email: prof.email,
          phone: prof.phone || '',
          specialties: prof.specialties || [],
          hourlyRate: prof.hourlyRate || 0,
          pricing: effectivePricing,
          experienceYears: prof.experienceYears || 0,
          rating: prof.rating || 0,
        };
      }).filter((p: any) => p !== null);

      res.json({ items: professorsData });
    } catch (error) {
      console.error('Error getting professors:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get available schedules for a specific professor
   * TEN-90: Actualizado para mantener compatibilidad
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
        isAvailable: true, // Only available slots
        $or: [
          { isBlocked: { $exists: false } },
          { isBlocked: false }
        ]
      })
        .populate('tenantId', 'name slug config')
        .sort({ startTime: 1 })
        .limit(100);

      const schedulesData = schedules.map(schedule => ({
        id: schedule._id.toString(),
        professorId: schedule.professorId.toString(),
        tenantId: schedule.tenantId ? (schedule.tenantId as any)._id.toString() : null,
        tenantName: schedule.tenantId ? (schedule.tenantId as any).name : null,
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        type: 'individual_class', // Default type since we removed it from schedule
        price: 0, // Price is now set during booking
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
   * Get professor schedules grouped by tenant (center)
   * TEN-90: MT-BACK-008
   * GET /api/student-dashboard/professors/:professorId/schedules
   */
  getProfessorSchedules = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getProfessorSchedules called ===');
    
    try {
      const { professorId } = req.params;
      
      if (!professorId) {
        return res.status(400).json({ error: 'professorId es requerido' });
      }

      // Verify professor exists
      const professor = await ProfessorModel.findById(professorId);
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Get all available schedules for the professor
      const schedules = await ScheduleModel.find({
        professorId: new Types.ObjectId(professorId),
        startTime: { $gte: new Date() }, // Only future schedules
        isAvailable: true, // Only available slots
        $or: [
          { isBlocked: { $exists: false } },
          { isBlocked: false }
        ]
      })
        .populate('tenantId', 'name slug config')
        .sort({ startTime: 1 })
        .limit(200);

      // Group schedules by tenantId
      const groupedByTenant: Record<string, any> = {};

      for (const schedule of schedules) {
        const tenantId = schedule.tenantId ? (schedule.tenantId as any)._id.toString() : 'unknown';
        const tenant = schedule.tenantId as any;

        if (!groupedByTenant[tenantId]) {
          groupedByTenant[tenantId] = {
            tenantId,
            tenantName: tenant?.name || 'Centro desconocido',
            tenantSlug: tenant?.slug || '',
            tenantLogo: tenant?.config?.logo || null,
            schedules: [],
          };
        }

        groupedByTenant[tenantId].schedules.push({
          id: schedule._id.toString(),
          date: schedule.date,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
          status: schedule.status || 'pending',
          notes: schedule.notes,
        });
      }

      const result = {
        professorId: professor._id.toString(),
        professorName: professor.name,
        schedules: Object.values(groupedByTenant),
      };

      console.log(`Found ${schedules.length} schedules for professor ${professorId}, grouped into ${Object.keys(groupedByTenant).length} tenants`);
      res.json(result);
    } catch (error) {
      console.error('Error getting professor schedules:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get schedules for a specific tenant, grouped by professor
   * TEN-90: MT-BACK-008
   * GET /api/student-dashboard/tenants/:tenantId/schedules
   */
  getTenantSchedules = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getTenantSchedules called ===');
    
    try {
      const { tenantId } = req.params;
      
      if (!tenantId) {
        return res.status(400).json({ error: 'tenantId es requerido' });
      }

      // Verify tenant exists
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        return res.status(404).json({ error: 'Centro no encontrado' });
      }

      if (!tenant.isActive) {
        return res.status(400).json({ error: 'El centro no está activo' });
      }

      // Get all available schedules for this tenant
      const schedules = await ScheduleModel.find({
        tenantId: new Types.ObjectId(tenantId),
        startTime: { $gte: new Date() }, // Only future schedules
        isAvailable: true, // Only available slots
        $or: [
          { isBlocked: { $exists: false } },
          { isBlocked: false }
        ]
      })
        .populate('professorId', 'name email specialties pricing hourlyRate')
        .sort({ startTime: 1 })
        .limit(200);

      // Group schedules by professorId
      const groupedByProfessor: Record<string, any> = {};

      for (const schedule of schedules) {
        const professorId = schedule.professorId ? schedule.professorId.toString() : 'unknown';
        const professor = schedule.professorId as any;

        if (!groupedByProfessor[professorId]) {
          groupedByProfessor[professorId] = {
            professorId,
            professorName: professor?.name || 'Profesor desconocido',
            professorEmail: professor?.email || '',
            specialties: professor?.specialties || [],
            schedules: [],
          };
        }

        groupedByProfessor[professorId].schedules.push({
          id: schedule._id.toString(),
          date: schedule.date,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
          status: schedule.status || 'pending',
          notes: schedule.notes,
        });
      }

      const result = {
        tenantId: tenant._id.toString(),
        tenantName: tenant.name,
        tenantSlug: tenant.slug,
        tenantLogo: tenant.config?.logo || null,
        schedules: Object.values(groupedByProfessor),
      };

      console.log(`Found ${schedules.length} schedules for tenant ${tenantId}, grouped into ${Object.keys(groupedByProfessor).length} professors`);
      res.json(result);
    } catch (error) {
      console.error('Error getting tenant schedules:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get all available schedules grouped by tenant and professor
   * TEN-90: MT-BACK-008
   * GET /api/student-dashboard/available-schedules
   */
  getAllAvailableSchedules = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getAllAvailableSchedules called ===');
    
    try {
      // Get all available schedules across all tenants
      const schedules = await ScheduleModel.find({
        startTime: { $gte: new Date() }, // Only future schedules
        isAvailable: true, // Only available slots
        $or: [
          { isBlocked: { $exists: false } },
          { isBlocked: false }
        ]
      })
        .populate('tenantId', 'name slug config')
        .populate('professorId', 'name email specialties')
        .sort({ startTime: 1 })
        .limit(500);

      // Group by tenant first, then by professor
      const groupedByTenant: Record<string, any> = {};

      for (const schedule of schedules) {
        const tenantId = schedule.tenantId ? (schedule.tenantId as any)._id.toString() : 'unknown';
        const tenant = schedule.tenantId as any;
        const professorId = schedule.professorId ? schedule.professorId.toString() : 'unknown';
        const professor = schedule.professorId as any;

        if (!groupedByTenant[tenantId]) {
          groupedByTenant[tenantId] = {
            tenantId,
            tenantName: tenant?.name || 'Centro desconocido',
            tenantSlug: tenant?.slug || '',
            tenantLogo: tenant?.config?.logo || null,
            professors: {},
          };
        }

        if (!groupedByTenant[tenantId].professors[professorId]) {
          groupedByTenant[tenantId].professors[professorId] = {
            professorId,
            professorName: professor?.name || 'Profesor desconocido',
            professorEmail: professor?.email || '',
            specialties: professor?.specialties || [],
            schedules: [],
          };
        }

        groupedByTenant[tenantId].professors[professorId].schedules.push({
          id: schedule._id.toString(),
          date: schedule.date,
          startTime: schedule.startTime,
          endTime: schedule.endTime,
          status: schedule.status || 'pending',
          notes: schedule.notes,
        });
      }

      // Transform professors object to array
      const result = Object.values(groupedByTenant).map((tenantGroup: any) => ({
        tenantId: tenantGroup.tenantId,
        tenantName: tenantGroup.tenantName,
        tenantSlug: tenantGroup.tenantSlug,
        tenantLogo: tenantGroup.tenantLogo,
        professors: Object.values(tenantGroup.professors),
      }));

      console.log(`Found ${schedules.length} available schedules, grouped into ${result.length} tenants`);
      res.json({ items: result });
    } catch (error) {
      console.error('Error getting all available schedules:', error);
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

      const { scheduleId, serviceType, price } = req.body;
      
      console.log('Request body:', { scheduleId, serviceType, price });
      
      if (!scheduleId) {
        return res.status(400).json({ error: 'scheduleId es requerido' });
      }
      
      if (!serviceType) {
        return res.status(400).json({ error: 'serviceType es requerido' });
      }
      
      if (!price || price <= 0) {
        return res.status(400).json({ error: 'price es requerido y debe ser mayor a 0' });
      }

      // Get student
      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        console.log('ERROR: AuthUser not found for firebaseUid:', firebaseUid);
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        console.log('ERROR: Student not found for authUserId:', authUser._id);
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      console.log('Looking for schedule:', scheduleId);
      
      // Check if schedule exists and is available
      const schedule = await ScheduleModel.findById(scheduleId);
      console.log('Schedule found:', !!schedule);
      if (!schedule) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }

      if (!schedule.isAvailable) {
        return res.status(400).json({ error: 'Este horario ya no está disponible' });
      }

      // Get professor from schedule
      const professor = await ProfessorModel.findById(schedule.professorId);
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Get tenantId from schedule (required for multi-tenancy)
      const tenantId = schedule.tenantId;
      if (!tenantId) {
        return res.status(400).json({ error: 'El horario no tiene un tenant asociado' });
      }

      // Ensure StudentTenant relationship exists (creates if not exists)
      await this.tenantService.addStudentToTenant(
        student._id.toString(),
        tenantId.toString(),
      );

      // Find an available court for this lesson
      const availableCourt = await this.findAvailableCourt(
        tenantId,
        schedule.startTime,
        schedule.endTime,
      );

      if (!availableCourt) {
        return res.status(409).json({
          error: 'No hay canchas disponibles para este horario. Por favor, intenta con otro horario.',
        });
      }

      // Create booking with tenantId and assigned courtId
      const booking = await BookingModel.create({
        tenantId: tenantId,
        scheduleId: schedule._id,
        studentId: student._id,
        professorId: professor._id,
        courtId: availableCourt._id,
        serviceType: serviceType,
        price: price,
        status: 'confirmed',
        notes: `Reserva de ${serviceType} - Cancha: ${availableCourt.name}`
      });

      // Update schedule availability
      schedule.isAvailable = false;
      schedule.studentId = student._id;
      schedule.status = 'confirmed';
      await schedule.save();

      console.log(`Booking created: ${booking._id} with court: ${availableCourt.name}`);
      
      res.status(201).json({
        id: booking._id,
        studentId: booking.studentId,
        scheduleId: booking.scheduleId,
        courtId: booking.courtId?.toString(),
        serviceType: booking.serviceType,
        status: booking.status,
        price: booking.price,
        createdAt: booking.createdAt
      });
    } catch (error) {
      console.error('Error booking lesson:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get student bookings
   */
  getBookings = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getBookings called ===');
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

      // Get base pricing for professor pricing calculation
      const baseConfig = await SystemConfigModel.findOne({ key: 'base_pricing' });
      const basePricing = baseConfig?.value || DEFAULT_BASE_PRICING;

      // Build query with tenantId filter if present
      const bookingQuery: any = {
        studentId: student._id,
      };

      // Filter by tenantId if provided (from middleware)
      if (req.tenantId) {
        bookingQuery.tenantId = new Types.ObjectId(req.tenantId);
      }

      // Fetch all bookings for the student with populated schedule, professor, and court
      // Only populate scheduleId if it exists (not for court_rental)
      const bookings = await BookingModel.find(bookingQuery)
        .populate({
          path: 'scheduleId',
          populate: {
            path: 'professorId',
            select: 'name email specialties pricing hourlyRate'
          },
          strictPopulate: false // Allow null scheduleId
        })
        .populate({
          path: 'professorId',
          select: 'name email specialties pricing hourlyRate',
          strictPopulate: false // Allow null professorId
        })
        .populate({
          path: 'courtId',
          select: 'name type price',
          strictPopulate: false // Allow null courtId
        })
        .sort({ createdAt: -1 });

      console.log(`Found ${bookings.length} bookings for student ${student._id}`);

      // Format bookings according to frontend BookingModel structure
      const bookingsData = bookings.map((booking) => {
        const schedule = booking.scheduleId as any;
        const professor = (schedule?.professorId || booking.professorId) as any;
        const court = booking.courtId as any;

        // Calculate effective pricing for the professor
        const effectivePricing = {
          individualClass:
            professor?.pricing?.individualClass ?? basePricing.individualClass,
          groupClass: professor?.pricing?.groupClass ?? basePricing.groupClass,
          courtRental: professor?.pricing?.courtRental ?? basePricing.courtRental,
        };

        // For court_rental, use bookingDate if available, otherwise use current date
        let startTime = '';
        let endTime = '';
        
        if (booking.serviceType === 'court_rental') {
          // For court rentals, use bookingDate or createdAt as the time reference
          const bookingDateTime = booking.bookingDate || booking.createdAt || new Date();
          const startDateTime = new Date(bookingDateTime);
          startTime = startDateTime.toISOString();
          // Default to 1 hour duration for court rentals (using UTC)
          const endDateTime = new Date(startDateTime);
          endDateTime.setUTCHours(endDateTime.getUTCHours() + 1);
          endTime = endDateTime.toISOString();
        } else if (schedule) {
          // For classes with schedule, use schedule times
          startTime = schedule.startTime ? new Date(schedule.startTime).toISOString() : '';
          endTime = schedule.endTime ? new Date(schedule.endTime).toISOString() : '';
        } else {
          // Fallback: use bookingDate or createdAt
          const bookingDateTime = booking.bookingDate || booking.createdAt || new Date();
          const startDateTime = new Date(bookingDateTime);
          startTime = startDateTime.toISOString();
          const endDateTime = new Date(startDateTime);
          endDateTime.setUTCHours(endDateTime.getUTCHours() + 1);
          endTime = endDateTime.toISOString();
        }

        return {
          id: booking._id.toString(),
          professor: {
            id: professor?._id?.toString() || '',
            name: professor?.name || '',
            email: professor?.email || '',
            specialties: professor?.specialties || [],
            pricing: effectivePricing,
          },
          schedule: {
            id: schedule?._id?.toString() || '',
            professorId: schedule?.professorId?._id?.toString() || schedule?.professorId?.toString() || professor?._id?.toString() || '',
            startTime: startTime,
            endTime: endTime,
            type: booking.serviceType === 'court_rental' ? 'court_rental' : (booking.serviceType === 'group_class' ? 'group_class' : 'individual_class'),
            price: booking.price,
            status: schedule?.status || booking.status || 'pending',
          },
          court: court ? {
            id: court._id?.toString() || '',
            name: court.name || '',
            type: court.type || 'tennis',
            price: court.price || 0,
          } : null,
          serviceType: booking.serviceType,
          price: booking.price,
          status: booking.status,
          createdAt: booking.createdAt ? new Date(booking.createdAt).toISOString() : new Date().toISOString(),
        };
      });

      console.log(`Returning ${bookingsData.length} formatted bookings`);

      res.json({ items: bookingsData });
    } catch (error) {
      console.error('Error getting bookings:', error);
      console.error('Error stack:', error instanceof Error ? error.stack : 'No stack');
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Book a court (court rental)
   * TEN-89: MT-BACK-007
   */
  bookCourt = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.bookCourt called ===');
    
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const { courtId, startTime, endTime, price } = req.body;
      
      console.log('Request body:', { courtId, startTime, endTime, price });
      
      if (!courtId) {
        return res.status(400).json({ error: 'courtId es requerido' });
      }
      
      if (!startTime || !endTime) {
        return res.status(400).json({ error: 'startTime y endTime son requeridos' });
      }
      
      if (!price || price <= 0) {
        return res.status(400).json({ error: 'price es requerido y debe ser mayor a 0' });
      }

      // Get student
      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        console.log('ERROR: AuthUser not found for firebaseUid:', firebaseUid);
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        console.log('ERROR: Student not found for authUserId:', authUser._id);
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      console.log('Looking for court:', courtId);
      
      // Check if court exists and is available
      const court = await CourtModel.findById(courtId);
      console.log('Court found:', !!court);
      if (!court) {
        return res.status(404).json({ error: 'Cancha no encontrada' });
      }

      if (!court.isActive) {
        return res.status(400).json({ error: 'Esta cancha no está disponible' });
      }

      // Get tenantId from court (required for multi-tenancy)
      const tenantId = court.tenantId;
      if (!tenantId) {
        return res.status(400).json({ error: 'La cancha no tiene un tenant asociado' });
      }

      // Ensure StudentTenant relationship exists (creates if not exists)
      await this.tenantService.addStudentToTenant(
        student._id.toString(),
        tenantId.toString(),
      );

      // Parse dates - they come as ISO strings in UTC
      const requestedStart = new Date(startTime);
      const requestedEnd = new Date(endTime);

      // Validate date range
      if (requestedStart >= requestedEnd) {
        return res.status(400).json({ error: 'La hora de inicio debe ser anterior a la hora de fin' });
      }

      // Check for conflicting bookings for this specific court
      // We need to check both court_rental and lessons that have this court assigned
      const oneHourBefore = new Date(requestedStart);
      oneHourBefore.setUTCHours(oneHourBefore.getUTCHours() - 1);
      
      // Find all bookings for this specific court that might overlap
      const potentialConflicts = await BookingModel.find({
        tenantId: tenantId,
        courtId: court._id,
        status: { $in: ['confirmed', 'pending'] },
        $or: [
          // Court rentals: check bookingDate
          {
            serviceType: 'court_rental',
            bookingDate: {
              $gte: oneHourBefore,
              $lte: requestedEnd,
            },
          },
          // Lessons: we'll check schedule times after populating
          {
            scheduleId: { $exists: true },
          },
        ],
      })
        .populate('scheduleId')
        .lean();

      // Check for actual overlaps
      const hasConflict = potentialConflicts.some((booking) => {
        let existingStart: Date;
        let existingEnd: Date;

        if (booking.serviceType === 'court_rental' && booking.bookingDate) {
          // Court rental: use bookingDate as start, assume 1-hour duration
          existingStart = new Date(booking.bookingDate);
          existingEnd = new Date(existingStart);
          existingEnd.setUTCHours(existingEnd.getUTCHours() + 1);
        } else if (booking.scheduleId && (booking.scheduleId as any).startTime) {
          // Lesson: use schedule times
          const schedule = booking.scheduleId as any;
          existingStart = new Date(schedule.startTime);
          existingEnd = new Date(schedule.endTime);
        } else {
          // Can't determine time, skip
          return false;
        }

        // Two time ranges overlap if:
        // - requestedStart is within existing range, OR
        // - requestedEnd is within existing range, OR
        // - requested range completely contains existing range
        return (
          (requestedStart >= existingStart && requestedStart < existingEnd) ||
          (requestedEnd > existingStart && requestedEnd <= existingEnd) ||
          (requestedStart <= existingStart && requestedEnd >= existingEnd)
        );
      });

      if (hasConflict) {
        return res.status(409).json({
          error: 'El horario seleccionado ya está ocupado. Por favor, selecciona otro horario.',
        });
      }

      // Create booking for court rental with courtId
      const booking = await BookingModel.create({
        tenantId: tenantId,
        courtId: court._id,
        // scheduleId is optional for court_rental - not included
        studentId: student._id,
        // professorId is optional for court_rental - not included
        serviceType: 'court_rental',
        price: price,
        status: 'confirmed',
        notes: `Reserva de cancha: ${court.name} - ${requestedStart.toISOString()} a ${requestedEnd.toISOString()}`,
        bookingDate: requestedStart,
      });

      
      res.status(201).json({
        id: booking._id,
        studentId: booking.studentId,
        courtId: court._id,
        serviceType: booking.serviceType,
        status: booking.status,
        price: booking.price,
        startTime: new Date(startTime).toISOString(),
        endTime: new Date(endTime).toISOString(),
        createdAt: booking.createdAt
      });
    } catch (error) {
      console.error('Error booking court:', error);
      const errorMessage = error instanceof Error ? error.message : String(error);
      const errorStack = error instanceof Error ? error.stack : 'No stack trace';
      console.error('Error details:', { errorMessage, errorStack });
      res.status(500).json({ 
        error: 'Error interno del servidor',
        message: errorMessage,
        details: process.env.NODE_ENV === 'development' ? errorStack : undefined
      });
    }
  };

  /**
   * Get tenants (centers) where the student has made bookings
   * TEN-91: MT-BACK-009
   * GET /api/student-dashboard/tenants
   */
  getMyTenants = async (req: Request, res: Response) => {
    console.log('=== StudentDashboardController.getMyTenants called ===');
    
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

      // Get Student profile
      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      // Get all active StudentTenant relationships
      const studentTenants = await StudentTenantModel.find({
        studentId: student._id,
        isActive: true,
      })
        .populate('tenantId', 'name slug config isActive')
        .sort({ joinedAt: -1 });

      // Get last booking for each tenant
      const tenantsWithActivity = await Promise.all(
        studentTenants.map(async (st) => {
          const tenant = st.tenantId as any;
          
          // Get last booking for this student in this tenant
          const lastBooking = await BookingModel.findOne({
            studentId: student._id,
            tenantId: tenant._id,
          })
            .sort({ createdAt: -1 })
            .limit(1)
            .lean();

          return {
            id: tenant._id.toString(),
            name: tenant.name,
            slug: tenant.slug,
            logo: tenant.config?.logo || null,
            isActive: st.isActive,
            joinedAt: st.joinedAt,
            balance: st.balance,
            lastBooking: lastBooking ? {
              id: lastBooking._id.toString(),
              createdAt: lastBooking.createdAt,
            } : null,
          };
        })
      );

      console.log(`Found ${tenantsWithActivity.length} active tenants for student ${student._id}`);
      res.json({ items: tenantsWithActivity });
    } catch (error) {
      console.error('Error getting student tenants:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get all available active tenants (for selection)
   * TEN-91: MT-BACK-009
   * GET /api/student-dashboard/tenants/available
   */
  getAvailableTenants = async (_req: Request, res: Response): Promise<void> => {
    try {
      const tenants = await TenantModel.find({ isActive: true })
        .select('_id name slug domain config isActive')
        .lean();

      const items = tenants.map((tenant) => ({
        id: tenant._id.toString(),
        name: tenant.name,
        slug: tenant.slug,
        domain: tenant.domain || null,
        logo: tenant.config?.logo || null,
        isActive: tenant.isActive,
      }));

      res.json({ items });
    } catch (error) {
      console.error('Error getting available tenants:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get available time slots for a court on a specific date
   * GET /api/student-dashboard/courts/:courtId/available-slots?date=YYYY-MM-DD
   */
  getCourtAvailableSlots = async (req: Request, res: Response): Promise<void> => {
    try {
      const { courtId } = req.params;
      const { date } = req.query;
      const tenantId = req.tenantId;

      if (!courtId) {
        res.status(400).json({ error: 'courtId es requerido' });
        return;
      }

      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido. Selecciona un centro primero.' });
        return;
      }

      // Parse date or use today
      // Important: Use UTC to avoid timezone issues
      let targetDate: Date;
      if (date) {
        // Parse date string (YYYY-MM-DD) and create UTC date
        const dateParts = (date as string).split('-');
        targetDate = new Date(Date.UTC(
          parseInt(dateParts[0]),
          parseInt(dateParts[1]) - 1, // Month is 0-indexed
          parseInt(dateParts[2]),
          0, 0, 0, 0
        ));
      } else {
        const now = new Date();
        targetDate = new Date(Date.UTC(
          now.getUTCFullYear(),
          now.getUTCMonth(),
          now.getUTCDate(),
          0, 0, 0, 0
        ));
      }
      
      const nextDay = new Date(targetDate);
      nextDay.setUTCDate(nextDay.getUTCDate() + 1);

      console.log('Checking availability for date:', {
        inputDate: date,
        targetDateUTC: targetDate.toISOString(),
        nextDayUTC: nextDay.toISOString(),
      });

      // Verify court exists and belongs to tenant
      const court = await CourtModel.findOne({
        _id: new Types.ObjectId(courtId),
        tenantId: new Types.ObjectId(tenantId),
        isActive: true,
      }).populate('tenantId');

      if (!court) {
        res.status(404).json({ error: 'Cancha no encontrada o no disponible' });
        return;
      }

      // Get tenant to check operating hours configuration
      const tenant = await TenantModel.findById(tenantId);
      
      // Operating hours must be configured - use defaults if not set (temporary)
      let open = '06:00';
      let close = '22:00';
      const targetDayOfWeek = targetDate.getUTCDay(); // 0 = Sunday, 6 = Saturday

      if (tenant?.config?.operatingHours) {
        const operatingHours = tenant.config.operatingHours;
        
        // Try new format first: schedule array
        if (operatingHours.schedule && Array.isArray(operatingHours.schedule) && operatingHours.schedule.length > 0) {
          const daySchedule = operatingHours.schedule.find(s => s.dayOfWeek === targetDayOfWeek);
          
          if (daySchedule) {
            open = daySchedule.open;
            close = daySchedule.close;
          } else {
            // Day not found in schedule, center is closed on this day
            res.json({
              courtId: court._id.toString(),
              date: targetDate.toISOString().split('T')[0],
              availableSlots: [],
              bookedSlots: [],
              message: 'El centro no opera en este día',
            });
            return;
          }
        }
        // Legacy format: single open/close with daysOfWeek
        else if (operatingHours.open && operatingHours.close) {
          open = operatingHours.open;
          close = operatingHours.close;
          
          // Check if day is in daysOfWeek (if specified)
          if (operatingHours.daysOfWeek && operatingHours.daysOfWeek.length > 0) {
            if (!operatingHours.daysOfWeek.includes(targetDayOfWeek)) {
              res.json({
                courtId: court._id.toString(),
                date: targetDate.toISOString().split('T')[0],
                availableSlots: [],
                bookedSlots: [],
                message: 'El centro no opera en este día',
              });
              return;
            }
          }
        } else {
          // Log warning but use defaults
          console.warn(`Tenant ${tenantId} does not have operating hours configured. Using defaults: ${open} - ${close}`);
        }
      } else {
        // Log warning but use defaults
        console.warn(`Tenant ${tenantId} does not have operating hours configured. Using defaults: ${open} - ${close}`);
      }

      const [openHour] = open.split(':').map(Number);
      const [closeHour] = close.split(':').map(Number);

      // Validate operating hours
      if (isNaN(openHour) || openHour < 0 || openHour >= 24) {
        res.status(400).json({ error: 'Hora de apertura inválida en la configuración del centro' });
        return;
      }

      if (isNaN(closeHour) || closeHour <= 0 || closeHour > 24) {
        res.status(400).json({ error: 'Hora de cierre inválida en la configuración del centro' });
        return;
      }

      if (openHour >= closeHour) {
        res.status(400).json({ error: 'La hora de apertura debe ser anterior a la hora de cierre' });
        return;
      }

      const startHour = openHour;
      const endHour = closeHour;

      // Get all bookings for this specific court on this date
      // We need to check both court_rental and lessons that have this court assigned
      const bookings = await BookingModel.find({
        tenantId: new Types.ObjectId(tenantId),
        courtId: new Types.ObjectId(courtId),
        status: { $in: ['confirmed', 'pending'] },
        $or: [
          // Court rentals: check bookingDate
          {
            serviceType: 'court_rental',
            bookingDate: {
              $gte: targetDate,
              $lt: nextDay,
            },
          },
          // Lessons: we'll check schedule times after populating
          {
            scheduleId: { $exists: true },
          },
        ],
      })
        .populate('scheduleId')
        .lean();

      // Generate available time slots based on operating hours
      // operatingHours are in local time of the tenant, so we generate slots in local time
      const availableSlots: string[] = [];
      const bookedSlots = new Set<string>();

      // Mark booked slots - bookings are stored in UTC, convert to local time for comparison
      // operatingHours are in local time, so we need to compare in local time
      bookings.forEach((booking) => {
        let bookingTime: Date | null = null;

        if (booking.serviceType === 'court_rental' && booking.bookingDate) {
          // Court rental: use bookingDate
          bookingTime = new Date(booking.bookingDate);
        } else if (booking.scheduleId && (booking.scheduleId as any).startTime) {
          // Lesson: use schedule startTime
          const schedule = booking.scheduleId as any;
          const scheduleStart = new Date(schedule.startTime);
          // Check if schedule is on the target date
          const scheduleDate = new Date(Date.UTC(
            scheduleStart.getUTCFullYear(),
            scheduleStart.getUTCMonth(),
            scheduleStart.getUTCDate(),
            0, 0, 0, 0
          ));
          if (scheduleDate.getTime() === targetDate.getTime()) {
            bookingTime = scheduleStart;
          }
        }

        if (bookingTime) {
          // Convert UTC booking to local time for comparison with local operating hours
          const hour = bookingTime.getUTCHours();
          bookedSlots.add(`${hour.toString().padStart(2, '0')}:00`);
        }
      });

      // Generate all possible slots based on operating hours (in local time)     
      for (let hour = startHour; hour < endHour; hour++) {
        const slot = `${hour.toString().padStart(2, '0')}:00`;
        if (!bookedSlots.has(slot)) {
          availableSlots.push(slot);
        }
      }
      res.json({
        courtId: court._id.toString(),
        date: targetDate.toISOString().split('T')[0],
        availableSlots,
        bookedSlots: Array.from(bookedSlots),
      });
    } catch (error) {
      console.error('Error getting court available slots:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get available courts for the active tenant
   * TEN-96: MT-FRONT-005
   * GET /api/student-dashboard/courts
   */
  getCourts = async (req: Request, res: Response): Promise<void> => {
    try {
      const tenantId = req.tenantId;
      if (!tenantId) {
        res.status(400).json({ error: 'Tenant ID requerido. Selecciona un centro primero.' });
        return;
      }

      const courts = await CourtModel.find({
        tenantId: new Types.ObjectId(tenantId),
        isActive: true,
      })
        .sort({ name: 1 })
        .lean();

      const items = courts.map((court) => ({
        id: court._id.toString(),
        name: court.name,
        type: court.type,
        pricePerHour: court.price || 0,
        description: court.description || null,
        features: court.features || [],
      }));

      res.json({ items });
    } catch (error) {
      console.error('Error getting courts:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get user preferences (favorite professors and tenants)
   * GET /api/student-dashboard/preferences
   */
  getPreferences = async (req: Request, res: Response): Promise<void> => {
    try {
      const authUser = req.user;
      if (!authUser) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      // Get or create preferences
      let preferences = await UserPreferencesModel.findOne({ userId: authUser.id }).populate([
        { path: 'favoriteProfessors', select: 'name email specialties' },
        { path: 'favoriteTenants', select: 'name slug config isActive' },
      ]);

      if (!preferences) {
        // Create default preferences
        preferences = await UserPreferencesModel.create({
          userId: new Types.ObjectId(authUser.id),
          favoriteProfessors: [],
          favoriteTenants: [],
        });
      }

      res.json({
        favoriteProfessors: preferences.favoriteProfessors.map((prof: any) => ({
          id: prof._id.toString(),
          name: prof.name,
          email: prof.email,
          specialties: prof.specialties || [],
        })),
        favoriteTenants: preferences.favoriteTenants.map((tenant: any) => ({
          id: tenant._id.toString(),
          name: tenant.name,
          slug: tenant.slug,
          logo: tenant.config?.logo || null,
          isActive: tenant.isActive,
        })),
      });
    } catch (error) {
      console.error('Error getting preferences:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Add professor to favorites
   * POST /api/student-dashboard/preferences/favorite-professor
   */
  addFavoriteProfessor = async (req: Request, res: Response): Promise<void> => {
    try {
      const authUser = req.user;
      if (!authUser) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { professorId } = req.body;
      if (!professorId) {
        res.status(400).json({ error: 'professorId es requerido' });
        return;
      }

      // Validate professor exists
      const professor = await ProfessorModel.findById(professorId);
      if (!professor) {
        res.status(404).json({ error: 'Profesor no encontrado' });
        return;
      }

      // Get or create preferences
      let preferences = await UserPreferencesModel.findOne({ userId: new Types.ObjectId(authUser.id) });
      if (!preferences) {
        preferences = await UserPreferencesModel.create({
          userId: new Types.ObjectId(authUser.id),
          favoriteProfessors: [],
          favoriteTenants: [],
        });
      }

      // Add professor if not already in favorites
      const professorObjectId = new Types.ObjectId(professorId);
      if (!preferences.favoriteProfessors.some((id) => id.equals(professorObjectId))) {
        preferences.favoriteProfessors.push(professorObjectId);
        await preferences.save();
      }

      res.json({ message: 'Profesor agregado a favoritos', professorId });
    } catch (error) {
      console.error('Error adding favorite professor:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Remove professor from favorites
   * DELETE /api/student-dashboard/preferences/favorite-professor/:professorId
   */
  removeFavoriteProfessor = async (req: Request, res: Response): Promise<void> => {
    try {
      const authUser = req.user;
      if (!authUser) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { professorId } = req.params;
      if (!professorId) {
        res.status(400).json({ error: 'professorId es requerido' });
        return;
      }

      const preferences = await UserPreferencesModel.findOne({ userId: new Types.ObjectId(authUser.id) });
      if (!preferences) {
        res.status(404).json({ error: 'Preferencias no encontradas' });
        return;
      }

      const professorObjectId = new Types.ObjectId(professorId);
      preferences.favoriteProfessors = preferences.favoriteProfessors.filter(
        (id) => !id.equals(professorObjectId),
      );
      await preferences.save();

      res.json({ message: 'Profesor eliminado de favoritos', professorId });
    } catch (error) {
      console.error('Error removing favorite professor:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Add tenant to favorites
   * POST /api/student-dashboard/preferences/favorite-tenant
   */
  addFavoriteTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const authUser = req.user;
      if (!authUser) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { tenantId } = req.body;
      if (!tenantId) {
        res.status(400).json({ error: 'tenantId es requerido' });
        return;
      }

      // Validate tenant exists
      const tenant = await TenantModel.findById(tenantId);
      if (!tenant) {
        res.status(404).json({ error: 'Centro no encontrado' });
        return;
      }

      // Get or create preferences
      let preferences = await UserPreferencesModel.findOne({ userId: new Types.ObjectId(authUser.id) });
      if (!preferences) {
        preferences = await UserPreferencesModel.create({
          userId: new Types.ObjectId(authUser.id),
          favoriteProfessors: [],
          favoriteTenants: [],
        });
      }

      // Add tenant if not already in favorites
      const tenantObjectId = new Types.ObjectId(tenantId);
      if (!preferences.favoriteTenants.some((id) => id.equals(tenantObjectId))) {
        preferences.favoriteTenants.push(tenantObjectId);
        await preferences.save();
      }

      res.json({ message: 'Centro agregado a favoritos', tenantId });
    } catch (error) {
      console.error('Error adding favorite tenant:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Remove tenant from favorites
   * DELETE /api/student-dashboard/preferences/favorite-tenant/:tenantId
   */
  removeFavoriteTenant = async (req: Request, res: Response): Promise<void> => {
    try {
      const authUser = req.user;
      if (!authUser) {
        res.status(401).json({ error: 'No autenticado' });
        return;
      }

      const { tenantId } = req.params;
      if (!tenantId) {
        res.status(400).json({ error: 'tenantId es requerido' });
        return;
      }

      const preferences = await UserPreferencesModel.findOne({ userId: new Types.ObjectId(authUser.id) });
      if (!preferences) {
        res.status(404).json({ error: 'Preferencias no encontradas' });
        return;
      }

      const tenantObjectId = new Types.ObjectId(tenantId);
      preferences.favoriteTenants = preferences.favoriteTenants.filter(
        (id) => !id.equals(tenantObjectId),
      );
      await preferences.save();

      res.json({ message: 'Centro eliminado de favoritos', tenantId });
    } catch (error) {
      console.error('Error removing favorite tenant:', error);
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  };

  /**
   * Get the active tenant for the current student
   * Returns the first favorite tenant (no longer uses activeTenantId)
   * GET /api/student-dashboard/active-tenant
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
   * Set the active tenant for the current student
   * Adds tenant to favorites and moves it to the first position (no longer uses activeTenantId)
   * POST /api/student-dashboard/active-tenant
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

      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
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

      // Ensure StudentTenant relationship exists
      await this.tenantService.addStudentToTenant(student._id.toString(), tenantId);

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
