export class PublishSchedule {
    constructor(schedules) {
        this.schedules = schedules;
    }
    async execute(input) {
        const toCreate = { ...input, isAvailable: input.isAvailable ?? true };
        return this.schedules.publish(toCreate);
    }
}
export class ManageCourtAvailability {
    constructor(schedules) {
        this.schedules = schedules;
    }
    async setAvailability(scheduleId, isAvailable) {
        return this.schedules.update(scheduleId, { isAvailable });
    }
}
export class TrackIncome {
    constructor(reports) {
        this.reports = reports;
    }
    async execute(professorId, from, to) {
        return this.reports.getProfessorIncome(professorId, from, to);
    }
}
export class ManageServices {
    constructor(services) {
        this.services = services;
    }
    create(service) {
        return this.services.create(service);
    }
    update(id, update) {
        return this.services.update(id, update);
    }
}
//# sourceMappingURL=ProfessorUseCases.js.map