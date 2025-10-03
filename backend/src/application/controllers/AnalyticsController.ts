import { Request, Response } from 'express';
import { MongoProfessorRepository } from '../../infrastructure/repositories/MongoRepositories';
import { MongoBookingRepository } from '../../infrastructure/repositories/MongoRepositories';
import { MongoPaymentRepository } from '../../infrastructure/repositories/MongoRepositories';
import { MongoScheduleRepository } from '../../infrastructure/repositories/MongoRepositories';

export class AnalyticsController {
  private professors: MongoProfessorRepository;
  private bookings: MongoBookingRepository;
  private payments: MongoPaymentRepository;
  private schedules: MongoScheduleRepository;

  constructor() {
    this.professors = new MongoProfessorRepository();
    this.bookings = new MongoBookingRepository();
    this.payments = new MongoPaymentRepository();
    this.schedules = new MongoScheduleRepository();
  }

  getOverview = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      // Find the Professor document using the authUserId
      const ProfessorModel = require('../../infrastructure/database/models/ProfessorModel').ProfessorModel;
      const professor = await ProfessorModel.findOne({ authUserId: professorId });

      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      const { period = 'month', serviceType, status } = req.query;
      const actualProfessorId = professor._id.toString();

      // Get date range based on period
      const dateRange = this.getDateRange(period as string);
      
      // Get metrics
      const metrics = await this.getMetrics(actualProfessorId, dateRange, serviceType as string, status as string);
      
      // Get charts
      const charts = await this.getCharts(actualProfessorId, dateRange, serviceType as string, status as string);

      const overview = {
        metrics,
        charts,
        lastUpdated: new Date().toISOString(),
        period: period as string,
      };

      return res.json(overview);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  getRevenueData = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const ProfessorModel = require('../../infrastructure/database/models/ProfessorModel').ProfessorModel;
      const professor = await ProfessorModel.findOne({ authUserId: professorId });

      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      const { period = 'month' } = req.query;
      const actualProfessorId = professor._id.toString();
      const dateRange = this.getDateRange(period as string);

      const chartData = await this.getRevenueChart(actualProfessorId, dateRange);
      return res.json(chartData);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  getBookingsData = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const ProfessorModel = require('../../infrastructure/database/models/ProfessorModel').ProfessorModel;
      const professor = await ProfessorModel.findOne({ authUserId: professorId });

      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      const { period = 'month' } = req.query;
      const actualProfessorId = professor._id.toString();
      const dateRange = this.getDateRange(period as string);

      const chartData = await this.getBookingsChart(actualProfessorId, dateRange);
      return res.json(chartData);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  getStudentsData = async (req: Request, res: Response) => {
    try {
      const professorId = req.user?.id;
      if (!professorId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const ProfessorModel = require('../../infrastructure/database/models/ProfessorModel').ProfessorModel;
      const professor = await ProfessorModel.findOne({ authUserId: professorId });

      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      const { period = 'month' } = req.query;
      const actualProfessorId = professor._id.toString();
      const dateRange = this.getDateRange(period as string);

      const chartData = await this.getStudentsChart(actualProfessorId, dateRange);
      return res.json(chartData);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  private getDateRange(period: string): { start: Date; end: Date } {
    const now = new Date();
    const start = new Date();

    switch (period) {
      case 'week':
        start.setDate(now.getDate() - 7);
        break;
      case 'month':
        start.setMonth(now.getMonth() - 1);
        break;
      case 'quarter':
        start.setMonth(now.getMonth() - 3);
        break;
      case 'year':
        start.setFullYear(now.getFullYear() - 1);
        break;
      default:
        start.setMonth(now.getMonth() - 1);
    }

    return { start, end: now };
  }

  private async getMetrics(professorId: string, dateRange: { start: Date; end: Date }, serviceType?: string, status?: string) {
    // Get data from database models directly
    const PaymentModel = require('../../infrastructure/database/models/PaymentModel').PaymentModel;
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;
    const ScheduleModel = require('../../infrastructure/database/models/ScheduleModel').ScheduleModel;

    // Get total revenue
    const payments = await PaymentModel.find({ professorId }).lean();
    const periodPayments = payments.filter((p: any) => 
      p.date >= dateRange.start && 
      p.date <= dateRange.end && 
      p.status === 'paid'
    );
    const totalRevenue = periodPayments.reduce((sum: number, p: any) => sum + p.amount, 0);

    // Get completed bookings
    const bookings = await BookingModel.find({ professorId }).lean();
    const periodBookings = bookings.filter((b: any) => 
      b.createdAt && 
      b.createdAt >= dateRange.start && 
      b.createdAt <= dateRange.end &&
      (!serviceType || b.serviceType === serviceType) &&
      (!status || b.status === status)
    );
    const completedBookings = periodBookings.filter((b: any) => b.status === 'completed');

    // Get active students
    const students = await this.professors.listStudents(professorId);
    const activeStudents = students.filter((s: any) => {
      const studentBookings = bookings.filter((b: any) => b.studentId === s.id);
      return studentBookings.some((b: any) => 
        b.createdAt && 
        b.createdAt >= dateRange.start && 
        b.createdAt <= dateRange.end
      );
    });

    // Get occupancy rate
    const schedules = await ScheduleModel.find({ professorId }).lean();
    const periodSchedules = schedules.filter((s: any) => 
      s.date >= dateRange.start && 
      s.date <= dateRange.end
    );
    const occupiedSchedules = periodSchedules.filter((s: any) => !s.isAvailable);
    const occupancyRate = periodSchedules.length > 0 
      ? Math.round((occupiedSchedules.length / periodSchedules.length) * 100)
      : 0;

    // Calculate previous period for comparison
    const previousDateRange = this.getPreviousPeriod(dateRange);
    const previousPayments = payments.filter((p: any) => 
      p.date >= previousDateRange.start && 
      p.date <= previousDateRange.end && 
      p.status === 'paid'
    );
    const previousRevenue = previousPayments.reduce((sum: number, p: any) => sum + p.amount, 0);
    const revenueChange = previousRevenue > 0 
      ? Math.round(((totalRevenue - previousRevenue) / previousRevenue) * 100)
      : 0;

    return [
      {
        title: 'Ingresos del Período',
        value: `$${totalRevenue.toLocaleString()}`,
        change: revenueChange !== 0 ? `${revenueChange > 0 ? '+' : ''}${revenueChange}%` : null,
        icon: 'money',
        color: '#4CAF50',
        isPositive: revenueChange >= 0,
        subtitle: 'vs período anterior',
      },
      {
        title: 'Clases Completadas',
        value: completedBookings.length.toString(),
        change: null,
        icon: 'bookings',
        color: '#2196F3',
        isPositive: true,
        subtitle: 'en el período',
      },
      {
        title: 'Estudiantes Activos',
        value: activeStudents.length.toString(),
        change: null,
        icon: 'students',
        color: '#FF9800',
        isPositive: true,
        subtitle: 'con clases recientes',
      },
      {
        title: 'Tasa de Ocupación',
        value: `${occupancyRate}%`,
        change: null,
        icon: 'occupancy',
        color: '#9C27B0',
        isPositive: occupancyRate >= 70,
        subtitle: 'de horarios ocupados',
      },
    ];
  }

  private async getCharts(professorId: string, dateRange: { start: Date; end: Date }, serviceType?: string, status?: string) {
    const charts = [];

    // Revenue chart
    const revenueChart = await this.getRevenueChart(professorId, dateRange);
    if (revenueChart.data.length > 0) {
      charts.push(revenueChart);
    }

    // Bookings chart
    const bookingsChart = await this.getBookingsChart(professorId, dateRange);
    if (bookingsChart.data.length > 0) {
      charts.push(bookingsChart);
    }

    return charts;
  }

  private async getRevenueChart(professorId: string, dateRange: { start: Date; end: Date }) {
    const PaymentModel = require('../../infrastructure/database/models/PaymentModel').PaymentModel;
    const payments = await PaymentModel.find({ professorId }).lean();
    const periodPayments = payments.filter((p: any) => 
      p.date >= dateRange.start && 
      p.date <= dateRange.end && 
      p.status === 'paid'
    );

    // Group by month
    const monthlyRevenue = new Map<string, number>();
    periodPayments.forEach((payment: any) => {
      const month = payment.date.toISOString().substring(0, 7); // YYYY-MM
      monthlyRevenue.set(month, (monthlyRevenue.get(month) || 0) + payment.amount);
    });

    const data = Array.from(monthlyRevenue.entries()).map(([month, amount]) => ({
      label: month,
      value: amount,
      date: new Date(month + '-01'),
    }));

    return {
      title: 'Ingresos por Mes',
      type: 'line',
      data,
      xAxisLabel: 'Mes',
      yAxisLabel: 'Ingresos ($)',
      description: 'Evolución de ingresos en el período seleccionado',
    };
  }

  private async getBookingsChart(professorId: string, dateRange: { start: Date; end: Date }) {
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;
    const bookings = await BookingModel.find({ professorId }).lean();
    const periodBookings = bookings.filter((b: any) => 
      b.createdAt && 
      b.createdAt >= dateRange.start && 
      b.createdAt <= dateRange.end
    );

    // Group by service type
    const serviceTypeCount = new Map<string, number>();
    periodBookings.forEach((booking: any) => {
      serviceTypeCount.set(booking.serviceType, (serviceTypeCount.get(booking.serviceType) || 0) + 1);
    });

    const data = Array.from(serviceTypeCount.entries()).map(([type, count]) => ({
      label: this.getServiceTypeLabel(type),
      value: count,
    }));

    return {
      title: 'Clases por Tipo',
      type: 'bar',
      data,
      xAxisLabel: 'Tipo de Servicio',
      yAxisLabel: 'Número de Clases',
      description: 'Distribución de clases por tipo de servicio',
    };
  }

  private async getStudentsChart(professorId: string, dateRange: { start: Date; end: Date }) {
    const students = await this.professors.listStudents(professorId);
    
    // Group by membership type
    const membershipCount = new Map<string, number>();
    students.forEach((student: any) => {
      const membership = student.membershipType || 'basic';
      membershipCount.set(membership, (membershipCount.get(membership) || 0) + 1);
    });

    const data = Array.from(membershipCount.entries()).map(([type, count]) => ({
      label: type === 'premium' ? 'Premium' : 'Básico',
      value: count,
    }));

    return {
      title: 'Estudiantes por Membresía',
      type: 'pie',
      data,
      description: 'Distribución de estudiantes por tipo de membresía',
    };
  }

  private getServiceTypeLabel(type: string): string {
    switch (type) {
      case 'individual_class':
        return 'Individual';
      case 'group_class':
        return 'Grupal';
      case 'court_rental':
        return 'Alquiler';
      default:
        return type;
    }
  }

  private getPreviousPeriod(currentRange: { start: Date; end: Date }): { start: Date; end: Date } {
    const duration = currentRange.end.getTime() - currentRange.start.getTime();
    return {
      start: new Date(currentRange.start.getTime() - duration),
      end: new Date(currentRange.end.getTime() - duration),
    };
  }
}
