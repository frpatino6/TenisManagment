"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MongoServiceRequestRepository = exports.MongoReportRepository = exports.MongoServiceRepository = exports.MongoPaymentRepository = exports.MongoBookingRepository = exports.MongoScheduleRepository = exports.MongoStudentRepository = exports.MongoProfessorRepository = void 0;
const mongoose_1 = require("mongoose");
const ProfessorModel_1 = require("../database/models/ProfessorModel");
const StudentModel_1 = require("../database/models/StudentModel");
const ScheduleModel_1 = require("../database/models/ScheduleModel");
const BookingModel_1 = require("../database/models/BookingModel");
const PaymentModel_1 = require("../database/models/PaymentModel");
const ServiceModel_1 = require("../database/models/ServiceModel");
const ServiceRequestModel_1 = require("../database/models/ServiceRequestModel");
class MongoProfessorRepository {
    async create(professor) {
        const created = await ProfessorModel_1.ProfessorModel.create(professor);
        return { id: created._id.toString(), ...professor };
    }
    async findById(id) {
        const doc = await ProfessorModel_1.ProfessorModel.findById(id).lean();
        return doc
            ? {
                id: doc._id.toString(),
                name: doc.name,
                email: doc.email,
                phone: doc.phone,
                specialties: doc.specialties,
                hourlyRate: doc.hourlyRate,
                experienceYears: doc.experienceYears,
            }
            : null;
    }
    async findByEmail(email) {
        const doc = await ProfessorModel_1.ProfessorModel.findOne({ email }).lean();
        return doc
            ? {
                id: doc._id.toString(),
                name: doc.name,
                email: doc.email,
                phone: doc.phone,
                specialties: doc.specialties,
                hourlyRate: doc.hourlyRate,
                experienceYears: doc.experienceYears,
            }
            : null;
    }
    async listStudents(professorId) {
        const pipeline = [
            { $match: { professorId: new mongoose_1.Types.ObjectId(professorId) } },
            {
                $lookup: {
                    from: 'bookings',
                    localField: '_id',
                    foreignField: 'scheduleId',
                    as: 'bookings',
                },
            },
            { $unwind: '$bookings' },
            {
                $lookup: {
                    from: 'students',
                    localField: 'bookings.studentId',
                    foreignField: '_id',
                    as: 'student',
                },
            },
            { $unwind: '$student' },
            { $group: { _id: '$student._id', doc: { $first: '$student' } } },
            { $replaceWith: '$doc' },
        ];
        const rows = await ScheduleModel_1.ScheduleModel.aggregate(pipeline);
        return rows.map((s) => ({
            id: s._id.toString(),
            name: s.name,
            email: s.email,
            phone: s.phone,
            membershipType: s.membershipType,
            balance: s.balance,
        }));
    }
    async update(id, update) {
        const doc = await ProfessorModel_1.ProfessorModel.findByIdAndUpdate(id, update, { new: true }).lean();
        return doc
            ? {
                id: doc._id.toString(),
                name: doc.name,
                email: doc.email,
                phone: doc.phone,
                specialties: doc.specialties,
                hourlyRate: doc.hourlyRate,
                experienceYears: doc.experienceYears,
            }
            : null;
    }
}
exports.MongoProfessorRepository = MongoProfessorRepository;
class MongoStudentRepository {
    async create(student) {
        const created = await StudentModel_1.StudentModel.create(student);
        return { id: created._id.toString(), ...student };
    }
    async findById(id) {
        const doc = await StudentModel_1.StudentModel.findById(id).lean();
        return doc
            ? {
                id: doc._id.toString(),
                name: doc.name,
                email: doc.email,
                phone: doc.phone ?? '',
                membershipType: doc.membershipType,
                balance: doc.balance,
            }
            : null;
    }
    async findByEmail(email) {
        const doc = await StudentModel_1.StudentModel.findOne({ email }).lean();
        return doc
            ? {
                id: doc._id.toString(),
                name: doc.name,
                email: doc.email,
                phone: doc.phone ?? '',
                membershipType: doc.membershipType,
                balance: doc.balance,
            }
            : null;
    }
    async updateBalance(id, delta) {
        const doc = await StudentModel_1.StudentModel.findByIdAndUpdate(id, { $inc: { balance: delta } }, { new: true }).lean();
        return doc
            ? {
                id: doc._id.toString(),
                name: doc.name,
                email: doc.email,
                phone: doc.phone ?? '',
                membershipType: doc.membershipType,
                balance: doc.balance,
            }
            : null;
    }
}
exports.MongoStudentRepository = MongoStudentRepository;
class MongoScheduleRepository {
    async publish(schedule) {
        const created = await ScheduleModel_1.ScheduleModel.create({
            ...schedule,
            professorId: new mongoose_1.Types.ObjectId(schedule.professorId),
        });
        return {
            id: created._id.toString(),
            professorId: created.professorId.toString(),
            date: created.date,
            startTime: created.startTime.toISOString(),
            endTime: created.endTime.toISOString(),
            isAvailable: created.isAvailable,
            notes: created.notes,
            status: created.status,
        };
    }
    async findAvailableByProfessor(professorId, dateFrom, dateTo) {
        const query = { professorId: new mongoose_1.Types.ObjectId(professorId), isAvailable: true };
        if (dateFrom || dateTo) {
            query.date = {};
            if (dateFrom)
                query.date.$gte = dateFrom;
            if (dateTo)
                query.date.$lte = dateTo;
        }
        const docs = await ScheduleModel_1.ScheduleModel.find(query).lean();
        return docs.map((d) => ({
            id: d._id.toString(),
            professorId: d.professorId.toString(),
            date: d.date,
            startTime: d.startTime.toISOString(),
            endTime: d.endTime.toISOString(),
            isAvailable: d.isAvailable,
            notes: d.notes,
            status: d.status,
        }));
    }
    async findById(id) {
        const d = await ScheduleModel_1.ScheduleModel.findById(id).lean();
        return d
            ? {
                id: d._id.toString(),
                professorId: d.professorId.toString(),
                date: d.date,
                startTime: d.startTime.toISOString(),
                endTime: d.endTime.toISOString(),
                isAvailable: d.isAvailable,
                notes: d.notes,
                status: d.status,
            }
            : null;
    }
    async update(id, update) {
        const d = await ScheduleModel_1.ScheduleModel.findByIdAndUpdate(id, update, { new: true }).lean();
        return d
            ? {
                id: d._id.toString(),
                professorId: d.professorId.toString(),
                date: d.date,
                startTime: d.startTime.toISOString(),
                endTime: d.endTime.toISOString(),
                isAvailable: d.isAvailable,
                notes: d.notes,
                status: d.status,
            }
            : null;
    }
    async delete(id) {
        await ScheduleModel_1.ScheduleModel.findByIdAndDelete(id);
    }
}
exports.MongoScheduleRepository = MongoScheduleRepository;
class MongoBookingRepository {
    async create(booking) {
        const created = await BookingModel_1.BookingModel.create({
            ...booking,
            studentId: new mongoose_1.Types.ObjectId(booking.studentId),
            scheduleId: new mongoose_1.Types.ObjectId(booking.scheduleId),
        });
        return {
            id: created._id.toString(),
            studentId: created.studentId.toString(),
            scheduleId: created.scheduleId.toString(),
            serviceType: created.serviceType,
            status: created.status,
            price: created.price,
            notes: created.notes,
            bookingDate: created.bookingDate,
            createdAt: created.createdAt,
        };
    }
    async listByStudent(studentId) {
        const docs = await BookingModel_1.BookingModel.find({ studentId: new mongoose_1.Types.ObjectId(studentId) }).lean();
        return docs.map((d) => ({
            id: d._id.toString(),
            studentId: d.studentId.toString(),
            scheduleId: d.scheduleId.toString(),
            serviceType: d.serviceType,
            status: d.status,
            price: d.price,
            notes: d.notes,
            bookingDate: d.bookingDate,
            createdAt: d.createdAt,
        }));
    }
    async listBySchedule(scheduleId) {
        const docs = await BookingModel_1.BookingModel.find({ scheduleId: new mongoose_1.Types.ObjectId(scheduleId) }).lean();
        return docs.map((d) => ({
            id: d._id.toString(),
            studentId: d.studentId.toString(),
            scheduleId: d.scheduleId.toString(),
            serviceType: d.serviceType,
            status: d.status,
            price: d.price,
            notes: d.notes,
            bookingDate: d.bookingDate,
            createdAt: d.createdAt,
        }));
    }
    async update(id, update) {
        const d = await BookingModel_1.BookingModel.findByIdAndUpdate(id, update, { new: true }).lean();
        return d
            ? {
                id: d._id.toString(),
                studentId: d.studentId.toString(),
                scheduleId: d.scheduleId.toString(),
                serviceType: d.serviceType,
                status: d.status,
                price: d.price,
                notes: d.notes,
                bookingDate: d.bookingDate,
                createdAt: d.createdAt,
            }
            : null;
    }
}
exports.MongoBookingRepository = MongoBookingRepository;
class MongoPaymentRepository {
    async create(payment) {
        const created = await PaymentModel_1.PaymentModel.create({
            ...payment,
            studentId: new mongoose_1.Types.ObjectId(payment.studentId),
            professorId: new mongoose_1.Types.ObjectId(payment.professorId),
        });
        return {
            id: created._id.toString(),
            studentId: created.studentId.toString(),
            professorId: created.professorId.toString(),
            amount: created.amount,
            date: created.date,
            method: created.method,
            concept: created.concept,
        };
    }
    async listByStudent(studentId, from, to) {
        const query = { studentId: new mongoose_1.Types.ObjectId(studentId) };
        if (from || to) {
            query.date = {};
            if (from)
                query.date.$gte = from;
            if (to)
                query.date.$lte = to;
        }
        const docs = await PaymentModel_1.PaymentModel.find(query).sort({ date: -1 }).lean();
        return docs.map((d) => ({
            id: d._id.toString(),
            studentId: d.studentId.toString(),
            professorId: d.professorId.toString(),
            amount: d.amount,
            date: d.date,
            method: d.method,
            concept: d.concept,
        }));
    }
}
exports.MongoPaymentRepository = MongoPaymentRepository;
class MongoServiceRepository {
    async create(service) {
        const created = await ServiceModel_1.ServiceModel.create(service);
        return {
            id: created._id.toString(),
            name: created.name,
            description: created.description,
            price: created.price,
            category: created.category,
        };
    }
    async update(id, update) {
        const d = await ServiceModel_1.ServiceModel.findByIdAndUpdate(id, update, { new: true }).lean();
        return d
            ? {
                id: d._id.toString(),
                name: d.name,
                description: d.description,
                price: d.price,
                category: d.category,
            }
            : null;
    }
    async list() {
        const docs = await ServiceModel_1.ServiceModel.find({}).lean();
        return docs.map((d) => ({
            id: d._id.toString(),
            name: d.name,
            description: d.description,
            price: d.price,
            category: d.category,
        }));
    }
    async delete(id) {
        await ServiceModel_1.ServiceModel.findByIdAndDelete(id);
    }
}
exports.MongoServiceRepository = MongoServiceRepository;
class MongoReportRepository {
    async getProfessorIncome(professorId, from, to) {
        const pipeline = [
            { $match: { professorId: new mongoose_1.Types.ObjectId(professorId), date: { $gte: from, $lte: to } } },
            {
                $group: {
                    _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
                    amount: { $sum: '$amount' },
                },
            },
            { $project: { _id: 0, date: '$_id', amount: 1 } },
            { $sort: { date: 1 } },
        ];
        const rows = await PaymentModel_1.PaymentModel.aggregate(pipeline);
        const total = rows.reduce((acc, r) => acc + r.amount, 0);
        return { total, breakdown: rows };
    }
}
exports.MongoReportRepository = MongoReportRepository;
class MongoServiceRequestRepository {
    async create(request) {
        const created = await ServiceRequestModel_1.ServiceRequestModel.create({
            ...request,
            studentId: new mongoose_1.Types.ObjectId(request.studentId),
            serviceId: new mongoose_1.Types.ObjectId(request.serviceId),
        });
        return {
            id: created._id.toString(),
            studentId: created.studentId.toString(),
            serviceId: created.serviceId.toString(),
            notes: created.notes,
            status: created.status,
            createdAt: created.createdAt,
        };
    }
}
exports.MongoServiceRequestRepository = MongoServiceRequestRepository;
//# sourceMappingURL=MongoRepositories.js.map