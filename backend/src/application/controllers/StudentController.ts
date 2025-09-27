import { Request, Response } from 'express';
import { container, TYPES } from '../../infrastructure/di/container.js';
import { BookLessonUseCase, CheckCourtAvailabilityUseCase, ViewBalanceUseCase, ViewPaymentHistoryUseCase, RequestServiceUseCase } from '../../domain/use-cases/index.js';

export class StudentController {
  private bookLesson = container.get<BookLessonUseCase>(TYPES.BookLessonUseCase);
  private availability = container.get<CheckCourtAvailabilityUseCase>(TYPES.CheckCourtAvailabilityUseCase);
  private balance = container.get<ViewBalanceUseCase>(TYPES.ViewBalanceUseCase);
  private paymentHistory = container.get<ViewPaymentHistoryUseCase>(TYPES.ViewPaymentHistoryUseCase);
  private requestServiceUseCase = container.get<RequestServiceUseCase>(TYPES.RequestServiceUseCase);

  availableSchedules = async (req: Request, res: Response) => {
    try {
      const result = await this.availability.execute({ professorId: String(req.query.professorId), dateFrom: req.query.from ? new Date(String(req.query.from)) : undefined, dateTo: req.query.to ? new Date(String(req.query.to)) : undefined });
      return res.json(result);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  book = async (req: Request, res: Response) => {
    try {
      const booking = await this.bookLesson.execute(req.body);
      return res.status(201).json(booking);
    } catch (e) {
      return res.status(400).json({ error: (e as Error).message });
    }
  };

  listBookings = async (_req: Request, res: Response) => {
    return res.json({ items: [] });
  };

  getBalance = async (req: Request, res: Response) => {
    const result = await this.balance.execute(String(req.query.studentId));
    return res.json(result);
  };

  paymentHistoryList = async (req: Request, res: Response) => {
    const result = await this.paymentHistory.execute(String(req.query.studentId));
    return res.json(result);
  };

  requestService = async (req: Request, res: Response) => {
    const result = await this.requestServiceUseCase.execute(req.body);
    return res.status(201).json(result);
  };
}

