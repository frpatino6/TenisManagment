"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ManageServices = exports.TrackIncome = exports.ManageCourtAvailability = exports.PublishSchedule = void 0;
class PublishSchedule {
    constructor(schedules) {
        this.schedules = schedules;
    }
    async execute(input) {
        const toCreate = {
            ...input,
            isAvailable: input.isAvailable ?? true,
        };
        return this.schedules.publish(toCreate);
    }
}
exports.PublishSchedule = PublishSchedule;
class ManageCourtAvailability {
    constructor(schedules) {
        this.schedules = schedules;
    }
    async setAvailability(scheduleId, isAvailable) {
        return this.schedules.update(scheduleId, { isAvailable });
    }
}
exports.ManageCourtAvailability = ManageCourtAvailability;
class TrackIncome {
    constructor(reports) {
        this.reports = reports;
    }
    async execute(professorId, from, to) {
        return this.reports.getProfessorIncome(professorId, from, to);
    }
}
exports.TrackIncome = TrackIncome;
class ManageServices {
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
exports.ManageServices = ManageServices;
//# sourceMappingURL=ProfessorUseCases.js.map