"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BookLesson = exports.RequestService = exports.ViewPaymentHistory = exports.ViewBalance = exports.CheckCourtAvailability = void 0;
class CheckCourtAvailability {
    constructor(schedules) {
        this.schedules = schedules;
    }
    execute(args) {
        if (!args.professorId)
            throw new Error('professorId required for now');
        return this.schedules.findAvailableByProfessor(args.professorId, args.dateFrom, args.dateTo);
    }
}
exports.CheckCourtAvailability = CheckCourtAvailability;
class ViewBalance {
    constructor(students) {
        this.students = students;
    }
    async execute(studentId) {
        const s = await this.students.findById(studentId);
        if (!s)
            throw new Error('Student not found');
        return { balance: s.balance };
    }
}
exports.ViewBalance = ViewBalance;
class ViewPaymentHistory {
    constructor(payments) {
        this.payments = payments;
    }
    execute(studentId, from, to) {
        return this.payments.listByStudent(studentId, from, to);
    }
}
exports.ViewPaymentHistory = ViewPaymentHistory;
class RequestService {
    constructor(serviceRequests) {
        this.serviceRequests = serviceRequests;
    }
    async execute(args) {
        await this.serviceRequests.create({
            studentId: args.studentId,
            serviceId: args.serviceId,
            notes: args.notes,
            status: 'requested',
        });
        return { status: 'requested' };
    }
}
exports.RequestService = RequestService;
class BookLesson {
    constructor(bookings, schedules) {
        this.bookings = bookings;
        this.schedules = schedules;
    }
    async execute(args) {
        const schedule = await this.schedules.findById(args.scheduleId);
        if (!schedule || !schedule.isAvailable)
            throw new Error('Schedule not available');
        const booking = await this.bookings.create({
            studentId: args.studentId,
            scheduleId: args.scheduleId,
            type: args.type,
            status: 'confirmed',
            paymentStatus: 'pending',
        });
        await this.schedules.update(args.scheduleId, { isAvailable: false });
        return booking;
    }
}
exports.BookLesson = BookLesson;
//# sourceMappingURL=StudentUseCases.js.map