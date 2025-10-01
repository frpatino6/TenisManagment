"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.StudentController = void 0;
const container_1 = require("../../infrastructure/di/container");
class StudentController {
    constructor() {
        this.bookLesson = container_1.container.get(container_1.TYPES.BookLessonUseCase);
        this.availability = container_1.container.get(container_1.TYPES.CheckCourtAvailabilityUseCase);
        this.balance = container_1.container.get(container_1.TYPES.ViewBalanceUseCase);
        this.paymentHistory = container_1.container.get(container_1.TYPES.ViewPaymentHistoryUseCase);
        this.requestServiceUseCase = container_1.container.get(container_1.TYPES.RequestServiceUseCase);
        this.bookings = container_1.container.get(container_1.TYPES.BookingRepository);
        this.availableSchedules = async (req, res) => {
            try {
                const result = await this.availability.execute({
                    professorId: String(req.query.professorId),
                    dateFrom: req.query.from ? new Date(String(req.query.from)) : undefined,
                    dateTo: req.query.to ? new Date(String(req.query.to)) : undefined,
                });
                return res.json(result);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.book = async (req, res) => {
            try {
                const booking = await this.bookLesson.execute(req.body);
                return res.status(201).json(booking);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.listBookings = async (req, res) => {
            try {
                const studentId = String(req.query.studentId);
                if (!studentId)
                    return res.status(400).json({ error: 'studentId is required' });
                const items = await this.bookings.listByStudent(studentId);
                return res.json({ items });
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.getBalance = async (req, res) => {
            try {
                const result = await this.balance.execute(String(req.query.studentId));
                return res.json(result);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.paymentHistoryList = async (req, res) => {
            try {
                const result = await this.paymentHistory.execute(String(req.query.studentId));
                return res.json(result);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
        this.requestService = async (req, res) => {
            try {
                const result = await this.requestServiceUseCase.execute(req.body);
                return res.status(201).json(result);
            }
            catch (e) {
                return res.status(400).json({ error: e.message });
            }
        };
    }
}
exports.StudentController = StudentController;
//# sourceMappingURL=StudentController.js.map