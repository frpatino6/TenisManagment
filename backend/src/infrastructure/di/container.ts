import { Container } from 'inversify';
import {
  MongoProfessorRepository,
  MongoStudentRepository,
  MongoScheduleRepository,
  MongoBookingRepository,
  MongoPaymentRepository,
  MongoServiceRepository,
  MongoReportRepository,
  MongoServiceRequestRepository,
} from '../repositories/MongoRepositories';
import {
  ProfessorRepository,
  StudentRepository,
  ScheduleRepository,
  BookingRepository,
  PaymentRepository,
  ServiceRepository,
  ReportRepository,
  ServiceRequestRepository,
} from '../../domain/repositories/index';
import {
  PublishSchedule,
  ManageCourtAvailability,
  TrackIncome,
  ManageServices,
} from '../../domain/use-cases/ProfessorUseCases';
import {
  BookLesson,
  CheckCourtAvailability,
  ViewBalance,
  ViewPaymentHistory,
  RequestService,
} from '../../domain/use-cases/StudentUseCases';
import {
  PublishScheduleUseCase,
  ManageCourtAvailabilityUseCase,
  TrackIncomeUseCase,
  ManageServicesUseCase,
  BookLessonUseCase,
  CheckCourtAvailabilityUseCase,
  ViewBalanceUseCase,
  ViewPaymentHistoryUseCase,
  RequestServiceUseCase,
} from '../../domain/use-cases/index';
import { JwtService } from '../services/JwtService';
import { config } from '../config';

export const TYPES = {
  ProfessorRepository: Symbol.for('ProfessorRepository'),
  StudentRepository: Symbol.for('StudentRepository'),
  ScheduleRepository: Symbol.for('ScheduleRepository'),
  BookingRepository: Symbol.for('BookingRepository'),
  PaymentRepository: Symbol.for('PaymentRepository'),
  ServiceRepository: Symbol.for('ServiceRepository'),
  ReportRepository: Symbol.for('ReportRepository'),
  ServiceRequestRepository: Symbol.for('ServiceRequestRepository'),
  // Use cases
  PublishScheduleUseCase: Symbol.for('PublishScheduleUseCase'),
  ManageCourtAvailabilityUseCase: Symbol.for('ManageCourtAvailabilityUseCase'),
  TrackIncomeUseCase: Symbol.for('TrackIncomeUseCase'),
  ManageServicesUseCase: Symbol.for('ManageServicesUseCase'),
  BookLessonUseCase: Symbol.for('BookLessonUseCase'),
  CheckCourtAvailabilityUseCase: Symbol.for('CheckCourtAvailabilityUseCase'),
  ViewBalanceUseCase: Symbol.for('ViewBalanceUseCase'),
  ViewPaymentHistoryUseCase: Symbol.for('ViewPaymentHistoryUseCase'),
  RequestServiceUseCase: Symbol.for('RequestServiceUseCase'),
  JwtService: Symbol.for('JwtService'),
} as const;

export const container = new Container({ defaultScope: 'Singleton' });

// repositories
container
  .bind<ProfessorRepository>(TYPES.ProfessorRepository)
  .toConstantValue(new MongoProfessorRepository());
container
  .bind<StudentRepository>(TYPES.StudentRepository)
  .toConstantValue(new MongoStudentRepository());
container
  .bind<ScheduleRepository>(TYPES.ScheduleRepository)
  .toConstantValue(new MongoScheduleRepository());
container
  .bind<BookingRepository>(TYPES.BookingRepository)
  .toConstantValue(new MongoBookingRepository());
container
  .bind<PaymentRepository>(TYPES.PaymentRepository)
  .toConstantValue(new MongoPaymentRepository());
container
  .bind<ServiceRepository>(TYPES.ServiceRepository)
  .toConstantValue(new MongoServiceRepository());
container
  .bind<ReportRepository>(TYPES.ReportRepository)
  .toConstantValue(new MongoReportRepository());
container
  .bind<ServiceRequestRepository>(TYPES.ServiceRequestRepository)
  .toConstantValue(new MongoServiceRequestRepository());

// services
container.bind<JwtService>(TYPES.JwtService).toConstantValue(new JwtService(config.jwtSecret));

// use cases
container
  .bind<PublishScheduleUseCase>(TYPES.PublishScheduleUseCase)
  .toDynamicValue((ctx) => new PublishSchedule(ctx.container.get(TYPES.ScheduleRepository)));
container
  .bind<ManageCourtAvailabilityUseCase>(TYPES.ManageCourtAvailabilityUseCase)
  .toDynamicValue(
    (ctx) => new ManageCourtAvailability(ctx.container.get(TYPES.ScheduleRepository)),
  );
container
  .bind<TrackIncomeUseCase>(TYPES.TrackIncomeUseCase)
  .toDynamicValue((ctx) => new TrackIncome(ctx.container.get(TYPES.ReportRepository)));
container
  .bind<ManageServicesUseCase>(TYPES.ManageServicesUseCase)
  .toDynamicValue((ctx) => new ManageServices(ctx.container.get(TYPES.ServiceRepository)));
container
  .bind<BookLessonUseCase>(TYPES.BookLessonUseCase)
  .toDynamicValue(
    (ctx) =>
      new BookLesson(
        ctx.container.get(TYPES.BookingRepository),
        ctx.container.get(TYPES.ScheduleRepository),
      ),
  );
container
  .bind<CheckCourtAvailabilityUseCase>(TYPES.CheckCourtAvailabilityUseCase)
  .toDynamicValue((ctx) => new CheckCourtAvailability(ctx.container.get(TYPES.ScheduleRepository)));
container
  .bind<ViewBalanceUseCase>(TYPES.ViewBalanceUseCase)
  .toDynamicValue((ctx) => new ViewBalance(ctx.container.get(TYPES.StudentRepository)));
container
  .bind<ViewPaymentHistoryUseCase>(TYPES.ViewPaymentHistoryUseCase)
  .toDynamicValue((ctx) => new ViewPaymentHistory(ctx.container.get(TYPES.PaymentRepository)));
container
  .bind<RequestServiceUseCase>(TYPES.RequestServiceUseCase)
  .toDynamicValue((ctx) => new RequestService(ctx.container.get(TYPES.ServiceRequestRepository)));
