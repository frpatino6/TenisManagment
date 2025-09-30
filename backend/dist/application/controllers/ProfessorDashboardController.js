"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProfessorDashboardController = void 0;
const ProfessorModel_1 = require("../../infrastructure/database/models/ProfessorModel");
const StudentModel_1 = require("../../infrastructure/database/models/StudentModel");
const ScheduleModel_1 = require("../../infrastructure/database/models/ScheduleModel");
const PaymentModel_1 = require("../../infrastructure/database/models/PaymentModel");
class ProfessorDashboardController {
    constructor() {
        // Obtener información del profesor
        this.getProfessorInfo = async (req, res) => {
            console.log('=== ProfessorDashboardController.getProfessorInfo called ===');
            console.log('req.user:', req.user);
            console.log('req.headers:', req.headers);
            console.log('req.url:', req.url);
            console.log('req.method:', req.method);
            try {
                const professorId = req.user?.id;
                if (!professorId) {
                    console.log('No professorId found in req.user');
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                console.log('Looking for professor with authUserId:', professorId);
                let professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: professorId });
                if (!professor) {
                    console.log('Professor not found for authUserId:', professorId);
                    // Buscar el AuthUser para obtener información
                    const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
                    const authUser = await AuthUserModel.findById(professorId);
                    if (!authUser) {
                        return res.status(404).json({ error: 'Usuario de autenticación no encontrado' });
                    }
                    console.log('Creating professor record for authUser:', authUser.email);
                    // Crear el registro del profesor
                    professor = await ProfessorModel_1.ProfessorModel.create({
                        authUserId: authUser._id,
                        name: authUser.name || 'Profesor',
                        email: authUser.email,
                        phone: '',
                        specialties: [],
                        hourlyRate: 0
                    });
                    console.log('Professor created:', { id: professor._id, name: professor.name });
                }
                else {
                    console.log('Professor found:', { id: professor._id, name: professor.name });
                }
                // Calcular estadísticas reales
                const totalStudents = await StudentModel_1.StudentModel.countDocuments({});
                // Calcular rating promedio basado en clases completadas
                const completedClasses = await ScheduleModel_1.ScheduleModel.countDocuments({
                    professorId: professor._id,
                    status: 'completed'
                });
                // Rating basado en clases completadas (más clases = mejor rating)
                const rating = Math.min(4.0 + (completedClasses / 100), 5.0);
                // Calcular años de experiencia basado en la fecha de creación del profesor
                const createdAt = professor.createdAt || new Date();
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
                console.log('Sending response with professor info:', professorInfo);
                res.json(professorInfo);
            }
            catch (error) {
                console.error('Error getting professor info:', error);
                console.error('Error stack:', error instanceof Error ? error.stack : 'No stack');
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Obtener lista de estudiantes del profesor
        this.getStudents = async (req, res) => {
            try {
                const professorId = req.user?.id;
                if (!professorId) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: professorId });
                if (!professor) {
                    return res.status(404).json({ error: 'Profesor no encontrado' });
                }
                // Obtener estudiantes reales de la base de datos
                // Por ahora obtenemos todos los estudiantes, pero en el futuro deberíamos
                // implementar una relación real entre profesor y estudiantes
                const students = await StudentModel_1.StudentModel.find({}).limit(10);
                // Transformar los datos para que coincidan con el formato esperado
                const studentsData = await Promise.all(students.map(async (student) => {
                    // Obtener la próxima clase del estudiante
                    const nextClass = await ScheduleModel_1.ScheduleModel.findOne({
                        studentId: student._id,
                        date: { $gte: new Date() },
                        status: { $in: ['pending', 'confirmed'] }
                    }).sort({ date: 1, startTime: 1 });
                    // Contar clases del estudiante
                    const totalClasses = await ScheduleModel_1.ScheduleModel.countDocuments({
                        studentId: student._id,
                        status: 'completed'
                    });
                    // Calcular progreso basado en clases completadas
                    const progress = totalClasses > 0 ? Math.min(totalClasses / 20, 1.0) : 0.0; // Máximo 20 clases para 100%
                    // Determinar nivel basado en progreso
                    let level = 'Principiante';
                    if (progress >= 0.7)
                        level = 'Avanzado';
                    else if (progress >= 0.3)
                        level = 'Intermedio';
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
            }
            catch (error) {
                console.error('Error getting students:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Obtener horarios de hoy
        this.getTodaySchedule = async (req, res) => {
            try {
                const professorId = req.user?.id;
                if (!professorId) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: professorId });
                if (!professor) {
                    return res.status(404).json({ error: 'Profesor no encontrado' });
                }
                // Obtener horarios reales de hoy
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                const tomorrow = new Date(today);
                tomorrow.setDate(tomorrow.getDate() + 1);
                const todayClasses = await ScheduleModel_1.ScheduleModel.find({
                    professorId: professor._id,
                    date: {
                        $gte: today,
                        $lt: tomorrow
                    }
                }).populate('studentId', 'name email');
                // Transformar los datos para que coincidan con el formato esperado
                const classesData = todayClasses.map(schedule => ({
                    id: schedule._id.toString(),
                    studentName: schedule.studentId ? schedule.studentId.name : 'Estudiante',
                    studentId: schedule.studentId ? schedule.studentId._id.toString() : '',
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    type: schedule.type,
                    status: schedule.status || 'pending',
                    notes: schedule.notes,
                    price: schedule.price || 0,
                }));
                res.json({ items: classesData });
            }
            catch (error) {
                console.error('Error getting today schedule:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Obtener horarios de la semana
        this.getWeekSchedule = async (req, res) => {
            try {
                const professorId = req.user?.id;
                if (!professorId) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: professorId });
                if (!professor) {
                    return res.status(404).json({ error: 'Profesor no encontrado' });
                }
                // Obtener horarios reales de la semana
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                const weekEnd = new Date(today);
                weekEnd.setDate(weekEnd.getDate() + 7);
                const weekClasses = await ScheduleModel_1.ScheduleModel.find({
                    professorId: professor._id,
                    date: {
                        $gte: today,
                        $lt: weekEnd
                    }
                }).populate('studentId', 'name email');
                // Transformar los datos para que coincidan con el formato esperado
                const classesData = weekClasses.map(schedule => ({
                    id: schedule._id.toString(),
                    studentName: schedule.studentId ? schedule.studentId.name : 'Estudiante',
                    studentId: schedule.studentId ? schedule.studentId._id.toString() : '',
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    type: schedule.type,
                    status: schedule.status || 'pending',
                    notes: schedule.notes,
                    price: schedule.price || 0,
                }));
                res.json({ items: classesData });
            }
            catch (error) {
                console.error('Error getting week schedule:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Obtener estadísticas de ganancias
        this.getEarningsStats = async (req, res) => {
            try {
                const professorId = req.user?.id;
                if (!professorId) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: professorId });
                if (!professor) {
                    return res.status(404).json({ error: 'Profesor no encontrado' });
                }
                // Calcular ganancias reales
                const now = new Date();
                const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
                const startOfWeek = new Date(now);
                startOfWeek.setDate(now.getDate() - now.getDay());
                // Obtener pagos del mes
                const monthlyPayments = await PaymentModel_1.PaymentModel.find({
                    professorId: professor._id,
                    createdAt: { $gte: startOfMonth }
                });
                // Obtener pagos de la semana
                const weeklyPayments = await PaymentModel_1.PaymentModel.find({
                    professorId: professor._id,
                    createdAt: { $gte: startOfWeek }
                });
                // Calcular totales
                const monthlyEarnings = monthlyPayments.reduce((sum, payment) => sum + payment.amount, 0);
                const weeklyEarnings = weeklyPayments.reduce((sum, payment) => sum + payment.amount, 0);
                const classesThisMonth = monthlyPayments.length;
                // Obtener total de ganancias (todos los pagos)
                const totalPayments = await PaymentModel_1.PaymentModel.find({ professorId: professor._id });
                const totalEarnings = totalPayments.reduce((sum, payment) => sum + payment.amount, 0);
                const earnings = {
                    monthlyEarnings: monthlyEarnings,
                    weeklyEarnings: weeklyEarnings,
                    classesThisMonth: classesThisMonth,
                    totalEarnings: totalEarnings,
                };
                res.json(earnings);
            }
            catch (error) {
                console.error('Error getting earnings stats:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Actualizar perfil del profesor
        this.updateProfile = async (req, res) => {
            try {
                const professorId = req.user?.id;
                if (!professorId) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const { name, phone, specialties, hourlyRate } = req.body;
                const professor = await ProfessorModel_1.ProfessorModel.findOneAndUpdate({ authUserId: professorId }, {
                    name,
                    phone,
                    specialties,
                    hourlyRate,
                }, { new: true });
                if (!professor) {
                    return res.status(404).json({ error: 'Profesor no encontrado' });
                }
                res.json(professor);
            }
            catch (error) {
                console.error('Error updating profile:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Confirmar clase
        this.confirmClass = async (req, res) => {
            try {
                const { classId } = req.params;
                // TODO: Implement actual class confirmation logic
                console.log(`Class ${classId} confirmed`);
                res.json({ message: `Class ${classId} confirmed` });
            }
            catch (error) {
                console.error('Error confirming class:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Cancelar clase
        this.cancelClass = async (req, res) => {
            try {
                const { classId } = req.params;
                const { reason } = req.body;
                // TODO: Implement actual class cancellation logic
                console.log(`Class ${classId} cancelled with reason: ${reason}`);
                res.json({ message: `Class ${classId} cancelled` });
            }
            catch (error) {
                console.error('Error canceling class:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
    }
}
exports.ProfessorDashboardController = ProfessorDashboardController;
//# sourceMappingURL=ProfessorDashboardController.js.map