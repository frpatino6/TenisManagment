import { Schedule } from '../entities/Schedule';
import { Service } from '../entities/Service';
import { PublishScheduleUseCase, ManageCourtAvailabilityUseCase, TrackIncomeUseCase, ManageServicesUseCase } from './index';
import { ScheduleRepository, ReportRepository, ServiceRepository } from '../repositories/index';

export class PublishSchedule implements PublishScheduleUseCase {
  constructor(private readonly schedules: ScheduleRepository) {}
  async execute(input: Omit<Schedule, 'id' | 'isAvailable'> & { isAvailable?: boolean }): Promise<Schedule> {
    const toCreate: Omit<Schedule, 'id'> = { ...input, isAvailable: input.isAvailable ?? true } as Omit<Schedule, 'id'>;
    return this.schedules.publish(toCreate);
  }
}

export class ManageCourtAvailability implements ManageCourtAvailabilityUseCase {
  constructor(private readonly schedules: ScheduleRepository) {}
  async setAvailability(scheduleId: string, isAvailable: boolean) {
    return this.schedules.update(scheduleId, { isAvailable });
  }
}

export class TrackIncome implements TrackIncomeUseCase {
  constructor(private readonly reports: ReportRepository) {}
  async execute(professorId: string, from: Date, to: Date) {
    return this.reports.getProfessorIncome(professorId, from, to);
  }
}

export class ManageServices implements ManageServicesUseCase {
  constructor(private readonly services: ServiceRepository) {}
  create(service: Omit<Service, 'id'>) {
    return this.services.create(service);
  }
  update(id: string, update: Partial<Service>) {
    return this.services.update(id, update);
  }
}

