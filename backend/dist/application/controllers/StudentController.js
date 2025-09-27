import { container, TYPES } from '../../infrastructure/di/container.js';
export class StudentController {
    constructor() {
        this.bookLesson = container.get(TYPES.BookLessonUseCase);
        this.availability = container.get(TYPES.CheckCourtAvailabilityUseCase);
        this.balance = container.get(TYPES.ViewBalanceUseCase);
        this.paymentHistory = container.get(TYPES.ViewPaymentHistoryUseCase);
        this.requestServiceUseCase = container.get(TYPES.RequestServiceUseCase);
        this.bookings = container.get(TYPES.BookingRepository);
        this.availableSchedules = async (req, res) => {
            try {
                const result = await this.availability.execute({ professorId: String(req.query.professorId), dateFrom: req.query.from ? new Date(String(req.query.from)) : undefined, dateTo: req.query.to ? new Date(String(req.query.to)) : undefined });
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
            const result = await this.balance.execute(String(req.query.studentId));
            return res.json(result);
        };
        this.paymentHistoryList = async (req, res) => {
            const result = await this.paymentHistory.execute(String(req.query.studentId));
            return res.json(result);
        };
        this.requestService = async (req, res) => {
            const result = await this.requestServiceUseCase.execute(req.body);
            return res.status(201).json(result);
        };
    }
}
//# sourceMappingURL=StudentController.js.map