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
      console.log('🚀 Analytics overview requested');
      console.log('🚀 User:', req.user);
      
      const professorId = req.user?.id;
      if (!professorId) {
        console.log('❌ No professor ID found');
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      console.log('🚀 Professor ID:', professorId);

      // Find the Professor document using the authUserId
      const ProfessorModel = require('../../infrastructure/database/models/ProfessorModel').ProfessorModel;
      const professor = await ProfessorModel.findOne({ authUserId: professorId });

      if (!professor) {
        console.log('❌ Professor not found in database');
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      console.log('🚀 Professor found:', professor._id);

      const { period = 'month', serviceType, status } = req.query;
      const actualProfessorId = professor._id.toString();

      console.log('🚀 Query params:', { period, serviceType, status });

      // Get date range based on period
      const dateRange = this.getDateRange(period as string);
      
      // Get metrics
      console.log('🚀 Getting metrics...');
      const metrics = await this.getMetrics(actualProfessorId, dateRange, serviceType as string, status as string);
      
      // Get charts
      console.log('🚀 Getting charts...');
      const charts = await this.getCharts(actualProfessorId, dateRange, serviceType as string, status as string);

      const overview = {
        metrics,
        charts,
        lastUpdated: new Date().toISOString(),
        period: period as string,
      };

      console.log('🚀 Overview generated successfully');
      return res.json(overview);
    } catch (e) {
      console.error('❌ Error in getOverview:', e);
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

  getRevenueBreakdown = async (req: Request, res: Response) => {
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

      const { period = 'month', serviceType, status } = req.query;
      const actualProfessorId = professor._id.toString();
      const dateRange = this.getDateRange(period as string);

      const breakdown = await this.getRevenueBreakdownData(actualProfessorId, dateRange, serviceType as string, status as string);
      return res.json(breakdown);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  getBookingsBreakdown = async (req: Request, res: Response) => {
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

      const { period = 'month', serviceType, status } = req.query;
      const actualProfessorId = professor._id.toString();
      const dateRange = this.getDateRange(period as string);

      const breakdown = await this.getBookingsBreakdownData(actualProfessorId, dateRange, serviceType as string, status as string);
      return res.json(breakdown);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  getRevenueTrend = async (req: Request, res: Response) => {
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

      const { period = 'month', serviceType, status } = req.query;
      const actualProfessorId = professor._id.toString();

      const trendData = await this.getRevenueTrendData(actualProfessorId, period as string, serviceType as string, status as string);
      return res.json(trendData);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  getBookingsTrend = async (req: Request, res: Response) => {
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

      const { period = 'month', serviceType, status } = req.query;
      const actualProfessorId = professor._id.toString();

      const trendData = await this.getBookingsTrendData(actualProfessorId, period as string, serviceType as string, status as string);
      return res.json(trendData);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  getStudentsBreakdown = async (req: Request, res: Response) => {
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

      const { period = 'month', serviceType, status } = req.query;
      const actualProfessorId = professor._id.toString();

      const breakdown = await this.getStudentsBreakdownData(actualProfessorId, period as string, serviceType as string, status as string);
      return res.json(breakdown);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  getStudentsTrend = async (req: Request, res: Response) => {
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

      const { period = 'month', serviceType, status } = req.query;
      const actualProfessorId = professor._id.toString();

      const trendData = await this.getStudentsTrendData(actualProfessorId, period as string, serviceType as string, status as string);
      return res.json(trendData);
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
    try {
      console.log('📊 Getting metrics for professor:', professorId);
      console.log('📊 Date range:', dateRange);
      console.log('📊 Filters:', { serviceType, status });

      // Get data from database models directly
      const PaymentModel = require('../../infrastructure/database/models/PaymentModel').PaymentModel;
      const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;
      const ScheduleModel = require('../../infrastructure/database/models/ScheduleModel').ScheduleModel;

      // Get bookings with filters applied
      const bookingQuery: any = { professorId };
      if (serviceType) bookingQuery.serviceType = serviceType;
      if (status) bookingQuery.status = status;
      
      const bookings = await BookingModel.find(bookingQuery).lean();
      console.log('📊 Total bookings found:', bookings.length);

      // Filter by date range
      const periodBookings = bookings.filter((b: any) => 
        b.createdAt && 
        b.createdAt >= dateRange.start && 
        b.createdAt <= dateRange.end
      );
      console.log('📊 Period bookings:', periodBookings.length);

      // Get payments and filter by serviceType if needed
      const payments = await PaymentModel.find({ professorId, status: 'paid' }).lean();
      console.log('📊 Total payments found:', payments.length);

      // Filter payments by date range and serviceType
      const periodPayments = payments.filter((p: any) => {
        const isInDateRange = p.date >= dateRange.start && p.date <= dateRange.end;
        
        // If serviceType filter is applied, only include payments for matching bookings
        if (serviceType) {
          if (!p.bookingId) return false;
          const relatedBooking = periodBookings.find((b: any) => b._id.toString() === p.bookingId.toString());
          return isInDateRange && relatedBooking;
        }
        
        return isInDateRange;
      });
      console.log('📊 Period payments:', periodPayments.length);

      // Calculate total revenue
      const totalRevenue = periodPayments.reduce((sum: number, p: any) => sum + p.amount, 0);
      console.log('📊 Total revenue:', totalRevenue);

      // Get completed bookings
      const completedBookings = periodBookings.filter((b: any) => b.status === 'completed');
      console.log('📊 Completed bookings:', completedBookings.length);

      // Calculate active students (simplified)
      const uniqueStudentIds = [...new Set(periodBookings.map((b: any) => b.studentId.toString()))];
      const activeStudentsCount = uniqueStudentIds.length;
      console.log('📊 Active students:', activeStudentsCount);

      // Get occupancy rate
      const schedules = await ScheduleModel.find({ professorId }).lean();
      const periodSchedules = schedules.filter((s: any) => 
        s.date >= dateRange.start && s.date <= dateRange.end
      );
      const occupiedSchedules = periodSchedules.filter((s: any) => !s.isAvailable);
      const occupancyRate = periodSchedules.length > 0 
        ? Math.round((occupiedSchedules.length / periodSchedules.length) * 100)
        : 0;
      console.log('📊 Occupancy rate:', occupancyRate);

      // Calculate previous period for comparison
      const previousDateRange = this.getPreviousPeriod(dateRange);
      const previousPayments = payments.filter((p: any) => {
        const isInPreviousDateRange = p.date >= previousDateRange.start && p.date <= previousDateRange.end;
        
        // If serviceType filter is applied, only include payments for matching bookings
        if (serviceType) {
          if (!p.bookingId) return false;
          const relatedBooking = periodBookings.find((b: any) => b._id.toString() === p.bookingId.toString());
          return isInPreviousDateRange && relatedBooking;
        }
        
        return isInPreviousDateRange;
      });
      const previousRevenue = previousPayments.reduce((sum: number, p: any) => sum + p.amount, 0);
      const revenueChange = previousRevenue > 0 
        ? Math.round(((totalRevenue - previousRevenue) / previousRevenue) * 100)
        : 0;

      const metrics = [
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
          value: activeStudentsCount.toString(),
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

      console.log('📊 Metrics calculated successfully');
      return metrics;
    } catch (error) {
      console.error('❌ Error in getMetrics:', error);
      throw error;
    }
  }

  private async getCharts(professorId: string, dateRange: { start: Date; end: Date }, serviceType?: string, status?: string) {
    try {
      console.log('📈 Getting charts for professor:', professorId);
      const charts = [];

      // Revenue chart
      const revenueChart = await this.getRevenueChart(professorId, dateRange, serviceType, status);
      if (revenueChart.data && revenueChart.data.length > 0) {
        charts.push(revenueChart);
        console.log('📈 Revenue chart added');
      }

      // Bookings chart
      const bookingsChart = await this.getBookingsChart(professorId, dateRange, serviceType, status);
      if (bookingsChart.data && bookingsChart.data.length > 0) {
        charts.push(bookingsChart);
        console.log('📈 Bookings chart added');
      }

      console.log('📈 Total charts:', charts.length);
      return charts;
    } catch (error) {
      console.error('❌ Error in getCharts:', error);
      return [];
    }
  }

  private async getRevenueChart(professorId: string, dateRange: { start: Date; end: Date }, serviceType?: string, status?: string) {
    const PaymentModel = require('../../infrastructure/database/models/PaymentModel').PaymentModel;
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;
    
    // Get all bookings first
    const allBookings = await BookingModel.find({ professorId }).lean();
    
    // Apply filters to get only relevant bookings
    const filteredBookings = allBookings.filter((b: any) => 
      b.createdAt && 
      b.createdAt >= dateRange.start && 
      b.createdAt <= dateRange.end &&
      (!serviceType || b.serviceType === serviceType) &&
      (!status || b.status === status)
    );

    // Get all payments
    const allPayments = await PaymentModel.find({ professorId }).lean();
    const periodPayments = allPayments.filter((p: any) => {
      const isInDateRange = p.date >= dateRange.start && p.date <= dateRange.end && p.status === 'paid';
      
      // If serviceType filter is applied, only include payments for matching bookings
      if (serviceType) {
        if (!p.bookingId) return false;
        const relatedBooking = filteredBookings.find((b: any) => b._id.toString() === p.bookingId.toString());
        return isInDateRange && relatedBooking;
      }
      
      return isInDateRange;
    });

    // Group by service type and month
    const serviceTypeMonthlyData = new Map<string, Map<string, number>>();
    
    for (const payment of periodPayments) {
      if (payment.bookingId) {
        const relatedBooking = filteredBookings.find((b: any) => b._id.toString() === payment.bookingId.toString());
        if (relatedBooking) {
          const serviceType = relatedBooking.serviceType || 'unknown';
          const month = payment.date.toISOString().substring(0, 7); // YYYY-MM
          
          if (!serviceTypeMonthlyData.has(serviceType)) {
            serviceTypeMonthlyData.set(serviceType, new Map());
          }
          
          const monthlyMap = serviceTypeMonthlyData.get(serviceType)!;
          monthlyMap.set(month, (monthlyMap.get(month) || 0) + payment.amount);
        }
      }
    }

    // Convert to chart data format - flatten for Flutter compatibility
    const data = Array.from(serviceTypeMonthlyData.entries()).flatMap(([serviceType, monthlyData]) => 
      Array.from(monthlyData.entries()).map(([month, amount]) => ({
        label: new Date(month + '-01').toLocaleDateString('es-ES', { month: 'short' }),
        value: amount,
        date: new Date(month + '-01'),
        color: this.getServiceTypeColor(serviceType),
        serviceType: this.getServiceTypeLabel(serviceType),
      }))
    );

    return {
      title: 'Ingresos por Mes',
      type: 'line',
      data,
      xAxisLabel: 'Mes',
      yAxisLabel: 'Ingresos ($)',
      description: 'Evolución de ingresos en el período seleccionado',
    };
  }

  private getServiceTypeColor(serviceType: string): string {
    switch (serviceType) {
      case 'individual_class':
        return '#2196F3'; // Blue
      case 'group_class':
        return '#4CAF50'; // Green
      case 'court_rental':
        return '#FF9800'; // Orange
      default:
        return '#9C27B0'; // Purple
    }
  }

  private async getBookingsChart(professorId: string, dateRange: { start: Date; end: Date }, serviceType?: string, status?: string) {
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;
    const bookings = await BookingModel.find({ professorId }).lean();
    const periodBookings = bookings.filter((b: any) => 
      b.createdAt && 
      b.createdAt >= dateRange.start && 
      b.createdAt <= dateRange.end &&
      (!serviceType || b.serviceType === serviceType) &&
      (!status || b.status === status)
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

  private async getRevenueBreakdownData(professorId: string, dateRange: { start: Date; end: Date }, serviceType?: string, status?: string) {
    console.log('🔍 BREAKDOWN DEBUG - Starting breakdown calculation');
    console.log('🔍 BREAKDOWN DEBUG - Filters:', { serviceType, status });
    console.log('🔍 BREAKDOWN DEBUG - Date range:', dateRange);
    
    const PaymentModel = require('../../infrastructure/database/models/PaymentModel').PaymentModel;
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;

    // Get bookings first to apply serviceType filter
    const bookings = await BookingModel.find({ professorId }).lean();
    console.log('🔍 BREAKDOWN DEBUG - Total bookings found:', bookings.length);
    
    const periodBookings = bookings.filter((b: any) => 
      b.createdAt && 
      b.createdAt >= dateRange.start && 
      b.createdAt <= dateRange.end &&
      (!serviceType || b.serviceType === serviceType) &&
      (!status || b.status === status)
    );
    console.log('🔍 BREAKDOWN DEBUG - Period bookings:', periodBookings.length);
    
    // Log service types in period bookings
    const serviceTypesInBookings = [...new Set(periodBookings.map((b: any) => b.serviceType))];
    console.log('🔍 BREAKDOWN DEBUG - Service types in bookings:', serviceTypesInBookings);

    // Get payments related to filtered bookings
    const payments = await PaymentModel.find({ professorId }).lean();
    console.log('🔍 BREAKDOWN DEBUG - Total payments found:', payments.length);
    
    const periodPayments = payments.filter((p: any) => {
      const isInDateRange = p.date >= dateRange.start && p.date <= dateRange.end && p.status === 'paid';
      
      if (serviceType) {
        if (!p.bookingId) return false;
        const relatedBooking = periodBookings.find((b: any) => b._id.toString() === p.bookingId.toString());
        return isInDateRange && relatedBooking;
      }
      
      return isInDateRange;
    });
    console.log('🔍 BREAKDOWN DEBUG - Period payments:', periodPayments.length);

    // Group by service type
    const serviceTypeBreakdown = new Map<string, number>();
    const totalRevenue = periodPayments.reduce((sum: number, p: any) => sum + p.amount, 0);
    console.log('🔍 BREAKDOWN DEBUG - Total revenue:', totalRevenue);

    for (const payment of periodPayments) {
      if (payment.bookingId) {
        const relatedBooking = periodBookings.find((b: any) => b._id.toString() === payment.bookingId.toString());
        if (relatedBooking) {
          const serviceType = relatedBooking.serviceType || 'unknown';
          serviceTypeBreakdown.set(serviceType, (serviceTypeBreakdown.get(serviceType) || 0) + payment.amount);
          console.log(`🔍 BREAKDOWN DEBUG - Payment ${payment.amount} for ${serviceType}`);
        } else {
          console.log('🔍 BREAKDOWN DEBUG - Payment without related booking:', payment._id);
        }
      } else {
        console.log('🔍 BREAKDOWN DEBUG - Payment without bookingId:', payment._id);
      }
    }

    console.log('🔍 BREAKDOWN DEBUG - Service type breakdown:', Object.fromEntries(serviceTypeBreakdown));

    // Convert to array with percentages
    const breakdown = Array.from(serviceTypeBreakdown.entries()).map(([type, amount]) => ({
      category: this.getServiceTypeLabel(type),
      amount: amount,
      percentage: totalRevenue > 0 ? Math.round((amount / totalRevenue) * 100) : 0,
    }));

    console.log('🔍 BREAKDOWN DEBUG - Final breakdown:', breakdown);

    return {
      totalRevenue,
      breakdown,
      period: dateRange,
    };
  }

  private async getBookingsBreakdownData(professorId: string, dateRange: { start: Date; end: Date }, serviceType?: string, status?: string) {
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;

    const bookings = await BookingModel.find({ professorId }).lean();
    const periodBookings = bookings.filter((b: any) => 
      b.createdAt && 
      b.createdAt >= dateRange.start && 
      b.createdAt <= dateRange.end &&
      (!serviceType || b.serviceType === serviceType) &&
      (!status || b.status === status)
    );

    // Group by status
    const statusBreakdown = new Map<string, number>();
    const totalBookings = periodBookings.length;

    for (const booking of periodBookings) {
      const status = booking.status || 'unknown';
      statusBreakdown.set(status, (statusBreakdown.get(status) || 0) + 1);
    }

    // Convert to array with percentages
    const breakdown = Array.from(statusBreakdown.entries()).map(([status, count]) => ({
      status: this.getStatusLabel(status),
      count: count,
      percentage: totalBookings > 0 ? Math.round((count / totalBookings) * 100) : 0,
    }));

    return {
      totalBookings,
      breakdown,
      period: dateRange,
    };
  }

  private getStatusLabel(status: string): string {
    switch (status) {
      case 'confirmed':
        return 'Confirmadas';
      case 'completed':
        return 'Completadas';
      case 'cancelled':
        return 'Canceladas';
      case 'pending':
        return 'Pendientes';
      default:
        return status;
    }
  }

  private async getRevenueTrendData(professorId: string, period: string, serviceType?: string, status?: string) {
    const PaymentModel = require('../../infrastructure/database/models/PaymentModel').PaymentModel;
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;

    const months = this.getMonthsForPeriod(period);
    const trendData = [];

    for (const month of months) {
      const monthStart = new Date(month.year, month.month - 1, 1);
      const monthEnd = new Date(month.year, month.month, 0, 23, 59, 59);

      // Get bookings for this month
      const bookings = await BookingModel.find({ professorId }).lean();
      const monthBookings = bookings.filter((b: any) => 
        b.createdAt && 
        b.createdAt >= monthStart && 
        b.createdAt <= monthEnd &&
        (!serviceType || b.serviceType === serviceType) &&
        (!status || b.status === status)
      );

      // Get payments for this month
      const payments = await PaymentModel.find({ professorId }).lean();
      const monthPayments = payments.filter((p: any) => {
        const isInMonth = p.date >= monthStart && p.date <= monthEnd && p.status === 'paid';
        
        if (serviceType) {
          if (!p.bookingId) return false;
          const relatedBooking = monthBookings.find((b: any) => b._id.toString() === p.bookingId.toString());
          return isInMonth && relatedBooking;
        }
        
        return isInMonth;
      });

      const totalRevenue = monthPayments.reduce((sum: number, p: any) => sum + p.amount, 0);
      
      trendData.push({
        period: month.name,
        value: totalRevenue,
      });
    }

    return { trend: trendData };
  }

  private async getBookingsTrendData(professorId: string, period: string, serviceType?: string, status?: string) {
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;

    const months = this.getMonthsForPeriod(period);
    const trendData = [];

    for (const month of months) {
      const monthStart = new Date(month.year, month.month - 1, 1);
      const monthEnd = new Date(month.year, month.month, 0, 23, 59, 59);

      const bookings = await BookingModel.find({ professorId }).lean();
      const monthBookings = bookings.filter((b: any) => 
        b.createdAt && 
        b.createdAt >= monthStart && 
        b.createdAt <= monthEnd &&
        (!serviceType || b.serviceType === serviceType) &&
        (!status || b.status === status)
      );

      trendData.push({
        period: month.name,
        value: monthBookings.length,
      });
    }

    return { trend: trendData };
  }

  private getMonthsForPeriod(period: string): Array<{name: string, month: number, year: number}> {
    const now = new Date();
    const months = [];

    switch (period) {
      case 'week':
        // Last 7 days
        for (let i = 6; i >= 0; i--) {
          const date = new Date(now);
          date.setDate(date.getDate() - i);
          months.push({
            name: date.toLocaleDateString('es-ES', { weekday: 'short' }),
            month: date.getMonth() + 1,
            year: date.getFullYear(),
          });
        }
        break;
      case 'month':
        // Last 6 months
        for (let i = 5; i >= 0; i--) {
          const date = new Date(now);
          date.setMonth(date.getMonth() - i);
          months.push({
            name: date.toLocaleDateString('es-ES', { month: 'short' }),
            month: date.getMonth() + 1,
            year: date.getFullYear(),
          });
        }
        break;
      case 'quarter':
        // Last 4 quarters
        for (let i = 3; i >= 0; i--) {
          const date = new Date(now);
          date.setMonth(date.getMonth() - (i * 3));
          const quarter = Math.floor(date.getMonth() / 3) + 1;
          months.push({
            name: `Q${quarter} ${date.getFullYear()}`,
            month: date.getMonth() + 1,
            year: date.getFullYear(),
          });
        }
        break;
      case 'year':
        // Last 5 years
        for (let i = 4; i >= 0; i--) {
          const date = new Date(now);
          date.setFullYear(date.getFullYear() - i);
          months.push({
            name: date.getFullYear().toString(),
            month: date.getMonth() + 1,
            year: date.getFullYear(),
          });
        }
        break;
      default:
        // Default to last 6 months
        for (let i = 5; i >= 0; i--) {
          const date = new Date(now);
          date.setMonth(date.getMonth() - i);
          months.push({
            name: date.toLocaleDateString('es-ES', { month: 'short' }),
            month: date.getMonth() + 1,
            year: date.getFullYear(),
          });
        }
    }

    return months;
  }

  private async getStudentsBreakdownData(professorId: string, period: string, serviceType?: string, status?: string) {
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;
    const ScheduleModel = require('../../infrastructure/database/models/ScheduleModel').ScheduleModel;

    // Get all bookings first
    const allBookings = await BookingModel.find({ professorId }).lean();
    
    // Apply filters to get only relevant bookings
    const filteredBookings = allBookings.filter((b: any) => 
      (!serviceType || b.serviceType === serviceType) &&
      (!status || b.status === status)
    );
    
    // Get unique students from filtered bookings only
    const uniqueStudentIds = [...new Set(filteredBookings.map((b: any) => b.studentId.toString()))];

    const now = new Date();
    const thirtyDaysAgo = new Date(now.getTime() - (30 * 24 * 60 * 60 * 1000));
    const sevenDaysFromNow = new Date(now.getTime() + (7 * 24 * 60 * 60 * 1000));

    let activeStudents = 0;
    let inactiveStudents = 0;
    const recentStudents: any[] = [];

    for (const studentId of uniqueStudentIds) {
      // Check if student has had a class in the last 30 days (using filtered bookings)
      const recentBookings = filteredBookings.filter((b: any) => 
        b.studentId.toString() === studentId &&
        b.createdAt &&
        b.createdAt >= thirtyDaysAgo
      );

      // Check if student has upcoming classes in the next 7 days (using filtered bookings)
      const upcomingBookings = filteredBookings.filter((b: any) => 
        b.studentId.toString() === studentId &&
        b.createdAt &&
        b.createdAt > now &&
        b.createdAt <= sevenDaysFromNow
      );

      const hasRecentActivity = recentBookings.length > 0;
      const hasUpcomingClasses = upcomingBookings.length > 0;

      if (hasRecentActivity || hasUpcomingClasses) {
        activeStudents++;
        
        // Get the most recent booking for this student
        const lastBooking = recentBookings.sort((a: any, b: any) => 
          new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime()
        )[0];

        if (lastBooking) {
          recentStudents.push({
            studentId: studentId,
            lastClass: lastBooking.createdAt,
            status: 'Activo',
            serviceType: lastBooking.serviceType,
          });
        }
      } else {
        inactiveStudents++;
      }
    }

    const totalStudents = activeStudents + inactiveStudents;
    const breakdown = [
      {
        category: 'Estudiantes Activos',
        count: activeStudents,
        percentage: totalStudents > 0 ? Math.round((activeStudents / totalStudents) * 100) : 0,
      },
      {
        category: 'Estudiantes Inactivos',
        count: inactiveStudents,
        percentage: totalStudents > 0 ? Math.round((inactiveStudents / totalStudents) * 100) : 0,
      },
    ];

    // Ensure we always return valid data
    const safeBreakdown = breakdown.length > 0 ? breakdown : [
      {
        category: 'Estudiantes Activos',
        count: 0,
        percentage: 0,
      },
      {
        category: 'Estudiantes Inactivos',
        count: 0,
        percentage: 0,
      },
    ];

    return {
      totalStudents: totalStudents || 0,
      breakdown: safeBreakdown,
      recentStudents: recentStudents.slice(0, 10), // Top 10 most recent
    };
  }

  private async getStudentsTrendData(professorId: string, period: string, serviceType?: string, status?: string) {
    const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;

    const months = this.getMonthsForPeriod(period);
    const trendData = [];

    for (const month of months) {
      const monthStart = new Date(month.year, month.month - 1, 1);
      const monthEnd = new Date(month.year, month.month, 0, 23, 59, 59);

      // Get all bookings for this month
      const bookings = await BookingModel.find({ professorId }).lean();
      const monthBookings = bookings.filter((b: any) => 
        b.createdAt && 
        b.createdAt >= monthStart && 
        b.createdAt <= monthEnd &&
        (!serviceType || b.serviceType === serviceType) &&
        (!status || b.status === status)
      );

      // Count unique students who had classes in this month
      const uniqueStudentsInMonth = new Set(monthBookings.map((b: any) => b.studentId.toString())).size;

      trendData.push({
        period: month.name,
        value: uniqueStudentsInMonth,
      });
    }

    return { trend: trendData };
  }
}
