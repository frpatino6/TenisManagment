import { Container } from 'inversify';
import { MongoProfessorRepository, MongoStudentRepository, MongoScheduleRepository, MongoBookingRepository, MongoPaymentRepository, MongoServiceRepository, MongoReportRepository, MongoServiceRequestRepository } from '../repositories/MongoRepositories.js';
import { PublishSchedule, ManageCourtAvailability, TrackIncome, ManageServices } from '../../domain/use-cases/ProfessorUseCases.js';
import { BookLesson, CheckCourtAvailability, ViewBalance, ViewPaymentHistory, RequestService } from '../../domain/use-cases/StudentUseCases.js';
import { JwtService } from '../services/JwtService.js';
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
    JwtService: Symbol.for('JwtService')
};
export const container = new Container({ defaultScope: 'Singleton' });
// repositories
container.bind(TYPES.ProfessorRepository).toConstantValue(new MongoProfessorRepository());
container.bind(TYPES.StudentRepository).toConstantValue(new MongoStudentRepository());
container.bind(TYPES.ScheduleRepository).toConstantValue(new MongoScheduleRepository());
container.bind(TYPES.BookingRepository).toConstantValue(new MongoBookingRepository());
container.bind(TYPES.PaymentRepository).toConstantValue(new MongoPaymentRepository());
container.bind(TYPES.ServiceRepository).toConstantValue(new MongoServiceRepository());
container.bind(TYPES.ReportRepository).toConstantValue(new MongoReportRepository());
container.bind(TYPES.ServiceRequestRepository).toConstantValue(new MongoServiceRequestRepository());
// services
container.bind(TYPES.JwtService).toConstantValue(new JwtService(process.env.JWT_SECRET || 'dev_secret'));
// use cases
container.bind(TYPES.PublishScheduleUseCase).toDynamicValue(ctx => new PublishSchedule(ctx.container.get(TYPES.ScheduleRepository)));
container.bind(TYPES.ManageCourtAvailabilityUseCase).toDynamicValue(ctx => new ManageCourtAvailability(ctx.container.get(TYPES.ScheduleRepository)));
container.bind(TYPES.TrackIncomeUseCase).toDynamicValue(ctx => new TrackIncome(ctx.container.get(TYPES.ReportRepository)));
container.bind(TYPES.ManageServicesUseCase).toDynamicValue(ctx => new ManageServices(ctx.container.get(TYPES.ServiceRepository)));
container.bind(TYPES.BookLessonUseCase).toDynamicValue(ctx => new BookLesson(ctx.container.get(TYPES.BookingRepository), ctx.container.get(TYPES.ScheduleRepository)));
container.bind(TYPES.CheckCourtAvailabilityUseCase).toDynamicValue(ctx => new CheckCourtAvailability(ctx.container.get(TYPES.ScheduleRepository)));
container.bind(TYPES.ViewBalanceUseCase).toDynamicValue(ctx => new ViewBalance(ctx.container.get(TYPES.StudentRepository)));
container.bind(TYPES.ViewPaymentHistoryUseCase).toDynamicValue(ctx => new ViewPaymentHistory(ctx.container.get(TYPES.PaymentRepository)));
container.bind(TYPES.RequestServiceUseCase).toDynamicValue(ctx => new RequestService(ctx.container.get(TYPES.ServiceRequestRepository)));
//# sourceMappingURL=container.js.map