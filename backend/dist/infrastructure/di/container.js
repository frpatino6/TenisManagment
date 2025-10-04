"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.container = exports.TYPES = void 0;
const inversify_1 = require("inversify");
const MongoRepositories_1 = require("../repositories/MongoRepositories");
const ProfessorUseCases_1 = require("../../domain/use-cases/ProfessorUseCases");
const StudentUseCases_1 = require("../../domain/use-cases/StudentUseCases");
const MessageUseCases_1 = require("../../domain/use-cases/MessageUseCases");
const JwtService_1 = require("../services/JwtService");
const config_1 = require("../config");
exports.TYPES = {
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
};
exports.container = new inversify_1.Container({ defaultScope: 'Singleton' });
// repositories
exports.container
    .bind(exports.TYPES.ProfessorRepository)
    .toConstantValue(new MongoRepositories_1.MongoProfessorRepository());
exports.container
    .bind(exports.TYPES.StudentRepository)
    .toConstantValue(new MongoRepositories_1.MongoStudentRepository());
exports.container
    .bind(exports.TYPES.ScheduleRepository)
    .toConstantValue(new MongoRepositories_1.MongoScheduleRepository());
exports.container
    .bind(exports.TYPES.BookingRepository)
    .toConstantValue(new MongoRepositories_1.MongoBookingRepository());
exports.container
    .bind(exports.TYPES.PaymentRepository)
    .toConstantValue(new MongoRepositories_1.MongoPaymentRepository());
exports.container
    .bind(exports.TYPES.ServiceRepository)
    .toConstantValue(new MongoRepositories_1.MongoServiceRepository());
exports.container
    .bind(exports.TYPES.ReportRepository)
    .toConstantValue(new MongoRepositories_1.MongoReportRepository());
exports.container
    .bind(exports.TYPES.ServiceRequestRepository)
    .toConstantValue(new MongoRepositories_1.MongoServiceRequestRepository());
exports.container
    .bind(exports.TYPES.MessageRepository)
    .toConstantValue(new MongoRepositories_1.MongoMessageRepository());
exports.container
    .bind(exports.TYPES.ConversationRepository)
    .toConstantValue(new MongoRepositories_1.MongoConversationRepository());
// services
exports.container.bind(exports.TYPES.JwtService).toConstantValue(new JwtService_1.JwtService(config_1.config.jwtSecret));
// use cases
exports.container
    .bind(exports.TYPES.PublishScheduleUseCase)
    .toDynamicValue((ctx) => new ProfessorUseCases_1.PublishSchedule(ctx.container.get(exports.TYPES.ScheduleRepository)));
exports.container
    .bind(exports.TYPES.ManageCourtAvailabilityUseCase)
    .toDynamicValue((ctx) => new ProfessorUseCases_1.ManageCourtAvailability(ctx.container.get(exports.TYPES.ScheduleRepository)));
exports.container
    .bind(exports.TYPES.TrackIncomeUseCase)
    .toDynamicValue((ctx) => new ProfessorUseCases_1.TrackIncome(ctx.container.get(exports.TYPES.ReportRepository)));
exports.container
    .bind(exports.TYPES.ManageServicesUseCase)
    .toDynamicValue((ctx) => new ProfessorUseCases_1.ManageServices(ctx.container.get(exports.TYPES.ServiceRepository)));
exports.container
    .bind(exports.TYPES.BookLessonUseCase)
    .toDynamicValue((ctx) => new StudentUseCases_1.BookLesson(ctx.container.get(exports.TYPES.BookingRepository), ctx.container.get(exports.TYPES.ScheduleRepository)));
exports.container
    .bind(exports.TYPES.CheckCourtAvailabilityUseCase)
    .toDynamicValue((ctx) => new StudentUseCases_1.CheckCourtAvailability(ctx.container.get(exports.TYPES.ScheduleRepository)));
exports.container
    .bind(exports.TYPES.ViewBalanceUseCase)
    .toDynamicValue((ctx) => new StudentUseCases_1.ViewBalance(ctx.container.get(exports.TYPES.StudentRepository)));
exports.container
    .bind(exports.TYPES.ViewPaymentHistoryUseCase)
    .toDynamicValue((ctx) => new StudentUseCases_1.ViewPaymentHistory(ctx.container.get(exports.TYPES.PaymentRepository)));
exports.container
    .bind(exports.TYPES.RequestServiceUseCase)
    .toDynamicValue((ctx) => new StudentUseCases_1.RequestService(ctx.container.get(exports.TYPES.ServiceRequestRepository)));
// Message use cases
exports.container
    .bind(exports.TYPES.SendMessageUseCase)
    .toDynamicValue((ctx) => new MessageUseCases_1.SendMessageUseCaseImpl(ctx.container.get(exports.TYPES.MessageRepository), ctx.container.get(exports.TYPES.ConversationRepository)));
exports.container
    .bind(exports.TYPES.GetConversationUseCase)
    .toDynamicValue((ctx) => new MessageUseCases_1.GetConversationUseCaseImpl(ctx.container.get(exports.TYPES.ConversationRepository)));
exports.container
    .bind(exports.TYPES.GetConversationsUseCase)
    .toDynamicValue((ctx) => new MessageUseCases_1.GetConversationsUseCaseImpl(ctx.container.get(exports.TYPES.ConversationRepository)));
exports.container
    .bind(exports.TYPES.GetMessagesUseCase)
    .toDynamicValue((ctx) => new MessageUseCases_1.GetMessagesUseCaseImpl(ctx.container.get(exports.TYPES.MessageRepository)));
exports.container
    .bind(exports.TYPES.MarkMessageAsReadUseCase)
    .toDynamicValue((ctx) => new MessageUseCases_1.MarkMessageAsReadUseCaseImpl(ctx.container.get(exports.TYPES.MessageRepository)));
exports.container
    .bind(exports.TYPES.GetUnreadCountUseCase)
    .toDynamicValue((ctx) => new MessageUseCases_1.GetUnreadCountUseCaseImpl(ctx.container.get(exports.TYPES.MessageRepository)));
exports.container
    .bind(exports.TYPES.CreateConversationUseCase)
    .toDynamicValue((ctx) => new MessageUseCases_1.CreateConversationUseCaseImpl(ctx.container.get(exports.TYPES.ConversationRepository)));
//# sourceMappingURL=container.js.map