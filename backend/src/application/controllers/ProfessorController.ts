import { Request, Response } from 'express';
import { container, TYPES } from '../../infrastructure/di/container.js';
import { PublishScheduleUseCase, ManageCourtAvailabilityUseCase, TrackIncomeUseCase, ManageServicesUseCase } from '../../domain/use-cases/index.js';

export class ProfessorController {
  private publish = container.get<PublishScheduleUseCase>(TYPES.PublishScheduleUseCase);
  private availability = container.get<ManageCourtAvailabilityUseCase>(TYPES.ManageCourtAvailabilityUseCase);
  private income = container.get<TrackIncomeUseCase>(TYPES.TrackIncomeUseCase);
  private services = container.get<ManageServicesUseCase>(TYPES.ManageServicesUseCase);

  getSchedule = async (_req: Request, res: Response) => {
    return res.json({ items: [] });
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
    const updated = await this.availability.setAvailability(req.params.id, Boolean(req.body?.isAvailable));
    if (!updated) return res.status(404).json({ error: 'Not found' });
    return res.json(updated);
  };

  deleteSchedule = async (_req: Request, res: Response) => {
    return res.status(204).send();
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
}

