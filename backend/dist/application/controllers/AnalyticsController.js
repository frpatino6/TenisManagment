"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AnalyticsController = void 0;
const MongoRepositories_1 = require("../../infrastructure/repositories/MongoRepositories");
const MongoRepositories_2 = require("../../infrastructure/repositories/MongoRepositories");
const MongoRepositories_3 = require("../../infrastructure/repositories/MongoRepositories");
const MongoRepositories_4 = require("../../infrastructure/repositories/MongoRepositories");
class AnalyticsController {
    constructor() {
        this.getOverview = async (req, res) => {
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
                const dateRange = this.getDateRange(period);
                // Get metrics
                const metrics = await this.getMetrics(actualProfessorId, dateRange, serviceType, status);
                // Get charts
                const charts = await this.getCharts(actualProfessorId, dateRange, serviceType, status);
                const overview = {
                    metrics,
                    charts,
                    lastUpdated: new Date().toISOString(),
                    period: period,
                };
                return res.json(overview);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.getRevenueData = async (req, res) => {
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
                const dateRange = this.getDateRange(period);
                const chartData = await this.getRevenueChart(actualProfessorId, dateRange);
                return res.json(chartData);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.getBookingsData = async (req, res) => {
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
                const dateRange = this.getDateRange(period);
                const chartData = await this.getBookingsChart(actualProfessorId, dateRange);
                return res.json(chartData);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.getStudentsData = async (req, res) => {
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
                const dateRange = this.getDateRange(period);
                const chartData = await this.getStudentsChart(actualProfessorId, dateRange);
                return res.json(chartData);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.professors = new MongoRepositories_1.MongoProfessorRepository();
        this.bookings = new MongoRepositories_2.MongoBookingRepository();
        this.payments = new MongoRepositories_3.MongoPaymentRepository();
        this.schedules = new MongoRepositories_4.MongoScheduleRepository();
    }
    getDateRange(period) {
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
    async getMetrics(professorId, dateRange, serviceType, status) {
        // Get data from database models directly
        const PaymentModel = require('../../infrastructure/database/models/PaymentModel').PaymentModel;
        const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;
        const ScheduleModel = require('../../infrastructure/database/models/ScheduleModel').ScheduleModel;
        // Get total revenue
        const payments = await PaymentModel.find({ professorId }).lean();
        const periodPayments = payments.filter((p) => p.date >= dateRange.start &&
            p.date <= dateRange.end &&
            p.status === 'paid');
        const totalRevenue = periodPayments.reduce((sum, p) => sum + p.amount, 0);
        // Get completed bookings
        const bookings = await BookingModel.find({ professorId }).lean();
        const periodBookings = bookings.filter((b) => b.createdAt &&
            b.createdAt >= dateRange.start &&
            b.createdAt <= dateRange.end &&
            (!serviceType || b.serviceType === serviceType) &&
            (!status || b.status === status));
        const completedBookings = periodBookings.filter((b) => b.status === 'completed');
        // Get active students
        const students = await this.professors.listStudents(professorId);
        const activeStudents = students.filter((s) => {
            const studentBookings = bookings.filter((b) => b.studentId === s.id);
            return studentBookings.some((b) => b.createdAt &&
                b.createdAt >= dateRange.start &&
                b.createdAt <= dateRange.end);
        });
        // Get occupancy rate
        const schedules = await ScheduleModel.find({ professorId }).lean();
        const periodSchedules = schedules.filter((s) => s.date >= dateRange.start &&
            s.date <= dateRange.end);
        const occupiedSchedules = periodSchedules.filter((s) => !s.isAvailable);
        const occupancyRate = periodSchedules.length > 0
            ? Math.round((occupiedSchedules.length / periodSchedules.length) * 100)
            : 0;
        // Calculate previous period for comparison
        const previousDateRange = this.getPreviousPeriod(dateRange);
        const previousPayments = payments.filter((p) => p.date >= previousDateRange.start &&
            p.date <= previousDateRange.end &&
            p.status === 'paid');
        const previousRevenue = previousPayments.reduce((sum, p) => sum + p.amount, 0);
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
    async getCharts(professorId, dateRange, serviceType, status) {
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
    async getRevenueChart(professorId, dateRange) {
        const PaymentModel = require('../../infrastructure/database/models/PaymentModel').PaymentModel;
        const payments = await PaymentModel.find({ professorId }).lean();
        const periodPayments = payments.filter((p) => p.date >= dateRange.start &&
            p.date <= dateRange.end &&
            p.status === 'paid');
        // Group by month
        const monthlyRevenue = new Map();
        periodPayments.forEach((payment) => {
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
    async getBookingsChart(professorId, dateRange) {
        const BookingModel = require('../../infrastructure/database/models/BookingModel').BookingModel;
        const bookings = await BookingModel.find({ professorId }).lean();
        const periodBookings = bookings.filter((b) => b.createdAt &&
            b.createdAt >= dateRange.start &&
            b.createdAt <= dateRange.end);
        // Group by service type
        const serviceTypeCount = new Map();
        periodBookings.forEach((booking) => {
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
    async getStudentsChart(professorId, dateRange) {
        const students = await this.professors.listStudents(professorId);
        // Group by membership type
        const membershipCount = new Map();
        students.forEach((student) => {
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
    getServiceTypeLabel(type) {
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
    getPreviousPeriod(currentRange) {
        const duration = currentRange.end.getTime() - currentRange.start.getTime();
        return {
            start: new Date(currentRange.start.getTime() - duration),
            end: new Date(currentRange.end.getTime() - duration),
        };
    }
}
exports.AnalyticsController = AnalyticsController;
//# sourceMappingURL=AnalyticsController.js.map