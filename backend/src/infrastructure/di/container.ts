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
  MongoMessageRepository,
  MongoConversationRepository,
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
  MessageRepository,
  ConversationRepository,
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
  SendMessageUseCaseImpl,
  GetConversationUseCaseImpl,
  GetConversationsUseCaseImpl,
  GetMessagesUseCaseImpl,
  MarkMessageAsReadUseCaseImpl,
  GetUnreadCountUseCaseImpl,
  CreateConversationUseCaseImpl,
} from '../../domain/use-cases/MessageUseCases';
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
  SendMessageUseCase,
  GetConversationUseCase,
  GetConversationsUseCase,
  GetMessagesUseCase,
  MarkMessageAsReadUseCase,
  GetUnreadCountUseCase,
  CreateConversationUseCase,
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
  MessageRepository: Symbol.for('MessageRepository'),
  ConversationRepository: Symbol.for('ConversationRepository'),
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
  SendMessageUseCase: Symbol.for('SendMessageUseCase'),
  GetConversationUseCase: Symbol.for('GetConversationUseCase'),
  GetConversationsUseCase: Symbol.for('GetConversationsUseCase'),
  GetMessagesUseCase: Symbol.for('GetMessagesUseCase'),
  MarkMessageAsReadUseCase: Symbol.for('MarkMessageAsReadUseCase'),
  GetUnreadCountUseCase: Symbol.for('GetUnreadCountUseCase'),
  CreateConversationUseCase: Symbol.for('CreateConversationUseCase'),
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
container
  .bind<MessageRepository>(TYPES.MessageRepository)
  .toConstantValue(new MongoMessageRepository());
container
  .bind<ConversationRepository>(TYPES.ConversationRepository)
  .toConstantValue(new MongoConversationRepository());

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

// Message use cases
container
  .bind<SendMessageUseCase>(TYPES.SendMessageUseCase)
  .toDynamicValue((ctx) => new SendMessageUseCaseImpl(
    ctx.container.get(TYPES.MessageRepository),
    ctx.container.get(TYPES.ConversationRepository)
  ));
container
  .bind<GetConversationUseCase>(TYPES.GetConversationUseCase)
  .toDynamicValue((ctx) => new GetConversationUseCaseImpl(ctx.container.get(TYPES.ConversationRepository)));
container
  .bind<GetConversationsUseCase>(TYPES.GetConversationsUseCase)
  .toDynamicValue((ctx) => new GetConversationsUseCaseImpl(ctx.container.get(TYPES.ConversationRepository)));
container
  .bind<GetMessagesUseCase>(TYPES.GetMessagesUseCase)
  .toDynamicValue((ctx) => new GetMessagesUseCaseImpl(ctx.container.get(TYPES.MessageRepository)));
container
  .bind<MarkMessageAsReadUseCase>(TYPES.MarkMessageAsReadUseCase)
  .toDynamicValue((ctx) => new MarkMessageAsReadUseCaseImpl(ctx.container.get(TYPES.MessageRepository)));
container
  .bind<GetUnreadCountUseCase>(TYPES.GetUnreadCountUseCase)
  .toDynamicValue((ctx) => new GetUnreadCountUseCaseImpl(ctx.container.get(TYPES.MessageRepository)));
container
  .bind<CreateConversationUseCase>(TYPES.CreateConversationUseCase)
  .toDynamicValue((ctx) => new CreateConversationUseCaseImpl(ctx.container.get(TYPES.ConversationRepository)));
