"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProfessorDashboardController = void 0;
const AuthUserModel_1 = require("../../infrastructure/database/models/AuthUserModel");
const ProfessorModel_1 = require("../../infrastructure/database/models/ProfessorModel");
const StudentModel_1 = require("../../infrastructure/database/models/StudentModel");
const ScheduleModel_1 = require("../../infrastructure/database/models/ScheduleModel");
const PaymentModel_1 = require("../../infrastructure/database/models/PaymentModel");
const Logger_1 = require("../../infrastructure/services/Logger");
const logger = new Logger_1.Logger({ controller: 'ProfessorDashboardController' });
class ProfessorDashboardController {
    constructor() {
        // Obtener información del profesor
        this.getProfessorInfo = async (req, res) => {
            logger.debug('getProfessorInfo called', { requestId: req.requestId });
            try {
                const professorId = req.user?.id;
                if (!professorId) {
                    logger.warn('Missing professorId in req.user', { requestId: req.requestId });
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                logger.debug('Looking for professor by authUserId');
                let professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: professorId });
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
                    professor = await ProfessorModel_1.ProfessorModel.create({
                        authUserId: authUser._id,
                        name: authUser.name || 'Profesor',
                        email: authUser.email,
                        phone: '',
                        specialties: [],
                        hourlyRate: 0
                    });
                    logger.info('Professor created');
                }
                else {
                    logger.debug('Professor found');
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
                logger.debug('Sending professor info');
                res.json(professorInfo);
            }
            catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error getting professor info', { error: message, requestId: req.requestId });
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
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error getting students', { error: message, requestId: req.requestId });
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Obtener horarios por fecha específica
        this.getScheduleByDate = async (req, res) => {
            try {
                const professorId = req.user?.id;
                if (!professorId) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const { date } = req.query;
                if (!date || typeof date !== 'string') {
                    return res.status(400).json({ error: 'Parámetro date es requerido (formato: YYYY-MM-DD)' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: professorId });
                if (!professor) {
                    return res.status(404).json({ error: 'Profesor no encontrado' });
                }
                // Parse the date (comes as YYYY-MM-DD)
                const targetDate = new Date(date);
                if (isNaN(targetDate.getTime())) {
                    return res.status(400).json({ error: 'Formato de fecha inválido (use YYYY-MM-DD)' });
                }
                // Adjust for Colombia timezone (UTC-5)
                const colombiaDate = new Date(targetDate.getTime() - (5 * 60 * 60 * 1000));
                colombiaDate.setHours(0, 0, 0, 0);
                const nextDay = new Date(colombiaDate);
                nextDay.setDate(nextDay.getDate() + 1);
                console.log(`Getting schedules for date ${date}:`, {
                    targetDate: targetDate.toISOString(),
                    colombiaDate: colombiaDate.toISOString(),
                    nextDay: nextDay.toISOString()
                });
                const schedules = await ScheduleModel_1.ScheduleModel.find({
                    professorId: professor._id,
                    startTime: {
                        $gte: colombiaDate,
                        $lt: nextDay
                    },
                    studentId: { $exists: true, $ne: null }
                })
                    .populate('studentId', 'name email')
                    .sort({ startTime: 1 });
                console.log(`Found ${schedules.length} classes for date ${date}`);
                const classesData = schedules.map(schedule => ({
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
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error getting schedule by date', { error: message, requestId: req.requestId });
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
                const allReservedSchedules = await ScheduleModel_1.ScheduleModel.find({
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
                        studentName: s.studentId?.name,
                        status: s.status
                    });
                });
                const todayClasses = await ScheduleModel_1.ScheduleModel.find({
                    professorId: professor._id,
                    startTime: {
                        $gte: today,
                        $lt: tomorrow
                    },
                    studentId: { $exists: true, $ne: null } // Solo horarios reservados
                })
                    .populate('studentId', 'name email')
                    .sort({ startTime: 1 });
                console.log(`Found ${todayClasses.length} classes for today (between ${today.toISOString()} and ${tomorrow.toISOString()})`);
                if (todayClasses.length > 0) {
                    console.log('First class:', {
                        startTime: todayClasses[0].startTime.toISOString(),
                        studentName: todayClasses[0].studentId?.name
                    });
                }
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
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error getting today schedule', { error: message, requestId: req.requestId });
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
                // Obtener horarios reales de la semana (usando startTime)
                const today = new Date();
                today.setHours(0, 0, 0, 0);
                const weekEnd = new Date(today);
                weekEnd.setDate(weekEnd.getDate() + 7);
                const weekClasses = await ScheduleModel_1.ScheduleModel.find({
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
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error getting week schedule', { error: message, requestId: req.requestId });
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
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error getting earnings stats', { error: message, requestId: req.requestId });
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
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error updating profile', { error: message, requestId: req.requestId });
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Confirmar clase
        this.confirmClass = async (req, res) => {
            try {
                const { classId } = req.params;
                // TODO: Implement actual class confirmation logic
                logger.info('Class confirmed', { classId, requestId: req.requestId });
                res.json({ message: `Class ${classId} confirmed` });
            }
            catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error confirming class', { error: message, requestId: req.requestId });
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        // Cancelar clase
        this.cancelClass = async (req, res) => {
            try {
                const { classId } = req.params;
                const { reason } = req.body;
                // TODO: Implement actual class cancellation logic
                logger.info('Class cancelled', { classId, requestId: req.requestId });
                res.json({ message: `Class ${classId} cancelled` });
            }
            catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                logger.error('Error canceling class', { error: message, requestId: req.requestId });
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Create a new available schedule
         */
        this.createSchedule = async (req, res) => {
            console.log('=== ProfessorDashboardController.createSchedule called ===');
            try {
                const firebaseUid = req.user?.uid;
                if (!firebaseUid) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const { date, startTime, endTime, type, price } = req.body;
                if (!date || !startTime || !endTime || !type) {
                    return res.status(400).json({ error: 'Faltan campos requeridos' });
                }
                // Get professor
                const authUser = await AuthUserModel_1.AuthUserModel.findOne({ firebaseUid });
                if (!authUser) {
                    return res.status(404).json({ error: 'Usuario no encontrado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: authUser._id });
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
                const schedule = await ScheduleModel_1.ScheduleModel.create({
                    professorId: professor._id,
                    date: parsedDate,
                    startTime: parsedStartTime,
                    endTime: parsedEndTime,
                    type,
                    isAvailable: true,
                    status: 'pending',
                    price: price || professor.hourlyRate
                });
                console.log(`Schedule created: ${schedule._id}`);
                res.status(201).json({
                    id: schedule._id,
                    professorId: schedule.professorId,
                    date: schedule.date,
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    type: schedule.type,
                    isAvailable: schedule.isAvailable,
                    status: schedule.status,
                    price: schedule.price
                });
            }
            catch (error) {
                console.error('Error creating schedule:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Get all schedules for the professor
         */
        this.getMySchedules = async (req, res) => {
            console.log('=== ProfessorDashboardController.getMySchedules called ===');
            try {
                const firebaseUid = req.user?.uid;
                if (!firebaseUid) {
                    return res.status(401).json({ error: 'Usuario no autenticado' });
                }
                const authUser = await AuthUserModel_1.AuthUserModel.findOne({ firebaseUid });
                if (!authUser) {
                    return res.status(404).json({ error: 'Usuario no encontrado' });
                }
                const professor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: authUser._id });
                if (!professor) {
                    return res.status(404).json({ error: 'Perfil de profesor no encontrado' });
                }
                // Get all schedules for the professor
                const schedules = await ScheduleModel_1.ScheduleModel.find({
                    professorId: professor._id,
                    startTime: { $gte: new Date() } // Only future schedules
                })
                    .populate('studentId', 'name email')
                    .sort({ startTime: 1 })
                    .limit(100);
                const schedulesData = schedules.map(schedule => ({
                    id: schedule._id.toString(),
                    date: schedule.date,
                    startTime: schedule.startTime,
                    endTime: schedule.endTime,
                    type: schedule.type,
                    isAvailable: schedule.isAvailable,
                    isBlocked: schedule.isBlocked || false,
                    blockReason: schedule.blockReason || null,
                    status: schedule.status,
                    price: schedule.price,
                    studentName: schedule.studentId ? schedule.studentId.name : null,
                    studentEmail: schedule.studentId ? schedule.studentId.email : null
                }));
                console.log(`Found ${schedulesData.length} schedules for professor ${professor._id}`);
                res.json({ items: schedulesData });
            }
            catch (error) {
                console.error('Error getting schedules:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Delete a schedule
         */
        this.deleteSchedule = async (req, res) => {
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
                const schedule = await ScheduleModel_1.ScheduleModel.findById(scheduleId);
                if (!schedule) {
                    return res.status(404).json({ error: 'Horario no encontrado' });
                }
                // Check if schedule is already booked
                if (!schedule.isAvailable && schedule.studentId) {
                    return res.status(400).json({ error: 'No se puede eliminar un horario ya reservado' });
                }
                await ScheduleModel_1.ScheduleModel.findByIdAndDelete(scheduleId);
                console.log(`Schedule deleted: ${scheduleId}`);
                res.json({ message: 'Horario eliminado exitosamente' });
            }
            catch (error) {
                console.error('Error deleting schedule:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Block a schedule (mark as unavailable for students)
         */
        this.blockSchedule = async (req, res) => {
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
                const schedule = await ScheduleModel_1.ScheduleModel.findById(scheduleId);
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
            }
            catch (error) {
                console.error('Error blocking schedule:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
        /**
         * Unblock a schedule
         */
        this.unblockSchedule = async (req, res) => {
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
                const schedule = await ScheduleModel_1.ScheduleModel.findById(scheduleId);
                if (!schedule) {
                    return res.status(404).json({ error: 'Horario no encontrado' });
                }
                schedule.isBlocked = false;
                schedule.blockReason = undefined;
                schedule.isAvailable = true;
                await schedule.save();
                console.log(`Schedule unblocked: ${scheduleId}`);
                res.json({ message: 'Horario desbloqueado exitosamente' });
            }
            catch (error) {
                console.error('Error unblocking schedule:', error);
                res.status(500).json({ error: 'Error interno del servidor' });
            }
        };
    }
}
exports.ProfessorDashboardController = ProfessorDashboardController;
//# sourceMappingURL=ProfessorDashboardController.js.map