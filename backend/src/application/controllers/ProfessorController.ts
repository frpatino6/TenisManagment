import { Request, Response } from 'express';
import { container, TYPES } from '../../infrastructure/di/container';
import {
  PublishScheduleUseCase,
  ManageCourtAvailabilityUseCase,
  TrackIncomeUseCase,
  ManageServicesUseCase,
} from '../../domain/use-cases/index';
import {
  ScheduleRepository,
  ServiceRepository,
  ProfessorRepository,
  PaymentRepository,
  StudentRepository,
} from '../../domain/repositories/index';

export class ProfessorController {
  private publish = container.get<PublishScheduleUseCase>(TYPES.PublishScheduleUseCase);
  private availability = container.get<ManageCourtAvailabilityUseCase>(
    TYPES.ManageCourtAvailabilityUseCase,
  );
  private income = container.get<TrackIncomeUseCase>(TYPES.TrackIncomeUseCase);
  private services = container.get<ManageServicesUseCase>(TYPES.ManageServicesUseCase);
  private schedules = container.get<ScheduleRepository>(TYPES.ScheduleRepository);
  private serviceRepo = container.get<ServiceRepository>(TYPES.ServiceRepository);
  private payments = container.get<PaymentRepository>(TYPES.PaymentRepository);
  private students = container.get<StudentRepository>(TYPES.StudentRepository);
  private professors = container.get<ProfessorRepository>(TYPES.ProfessorRepository);

  getSchedule = async (req: Request, res: Response) => {
    try {
      const professorId = String(req.query.professorId);
      const from = req.query.from ? new Date(String(req.query.from)) : undefined;
      const to = req.query.to ? new Date(String(req.query.to)) : undefined;
      if (!professorId) return res.status(400).json({ error: 'professorId is required' });
      const items = await this.schedules.findAvailableByProfessor(professorId, from, to);
      return res.json({ items });
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  createSchedule = async (req: Request, res: Response) => {
    try {
      const created = await this.publish.execute(req.body);
      return res.status(201).json(created);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  updateSchedule = async (req: Request, res: Response) => {
    const updated = await this.availability.setAvailability(
      req.params.id,
      Boolean(req.body?.isAvailable),
    );
    if (!updated) return res.status(404).json({ error: 'Not found' });
    return res.json(updated);
  };

  deleteSchedule = async (req: Request, res: Response) => {
    try {
      await this.schedules.delete(req.params.id);
      return res.status(204).send();
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  incomeReport = async (req: Request, res: Response) => {
    const from = new Date(String(req.query.from));
    const to = new Date(String(req.query.to));
    const result = await this.income.execute(String(req.query.professorId), from, to);
    return res.json(result);
  };

  createService = async (req: Request, res: Response) => {
    const created = await this.services.create(req.body);
    return res.status(201).json(created);
  };

  updateService = async (req: Request, res: Response) => {
    const updated = await this.services.update(req.params.id, req.body);
    if (!updated) return res.status(404).json({ error: 'Not found' });
    return res.json(updated);
  };

  listServices = async (_req: Request, res: Response) => {
    const items = await this.serviceRepo.list();
    return res.json({ items });
  };

  deleteService = async (req: Request, res: Response) => {
    await this.serviceRepo.delete(req.params.id);
    return res.status(204).send();
  };

  listStudents = async (req: Request, res: Response) => {
    try {
      const professorId = String(req.query.professorId);
      if (!professorId) return res.status(400).json({ error: 'professorId is required' });
      const items = await this.professors.listStudents(professorId);
      return res.json({ items });
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  createPayment = async (req: Request, res: Response) => {
    try {
      const { studentId, professorId, amount, date, method, concept } = req.body ?? {};
      if (!studentId || !professorId || !amount || !date || !method || !concept) {
        return res.status(400).json({ error: 'Missing required fields' });
      }
      const payment = await this.payments.create({
        studentId,
        professorId,
        amount,
        date: new Date(date),
        method,
        concept,
      });
      await this.students.updateBalance(studentId, -Math.abs(amount));
      return res.status(201).json(payment);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };
}
