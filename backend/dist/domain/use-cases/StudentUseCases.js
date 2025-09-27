export class CheckCourtAvailability {
    constructor(schedules) {
        this.schedules = schedules;
    }
    execute(args) {
        if (!args.professorId)
            throw new Error('professorId required for now');
        return this.schedules.findAvailableByProfessor(args.professorId, args.dateFrom, args.dateTo);
    }
}
export class ViewBalance {
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
export class ViewPaymentHistory {
    constructor(payments) {
        this.payments = payments;
    }
    execute(studentId, from, to) {
        return this.payments.listByStudent(studentId, from, to);
    }
}
export class RequestService {
    constructor(serviceRequests) {
        this.serviceRequests = serviceRequests;
    }
    async execute(args) {
        await this.serviceRequests.create({ studentId: args.studentId, serviceId: args.serviceId, notes: args.notes, status: 'requested' });
        return { status: 'requested' };
    }
}
export class BookLesson {
    constructor(bookings, schedules) {
        this.bookings = bookings;
        this.schedules = schedules;
    }
    async execute(args) {
        const schedule = await this.schedules.findById(args.scheduleId);
        if (!schedule || !schedule.isAvailable)
            throw new Error('Schedule not available');
        const booking = await this.bookings.create({ studentId: args.studentId, scheduleId: args.scheduleId, type: args.type, status: 'confirmed', paymentStatus: 'pending' });
        await this.schedules.update(args.scheduleId, { isAvailable: false });
        return booking;
    }
}
//# sourceMappingURL=StudentUseCases.js.map