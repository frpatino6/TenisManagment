import { Types, PipelineStage } from 'mongoose';
import { ProfessorRepository, StudentRepository, ScheduleRepository, BookingRepository, PaymentRepository, ServiceRepository, ReportRepository } from '../../domain/repositories/index.js';
import { Professor } from '../../domain/entities/Professor.js';
import { Student } from '../../domain/entities/Student.js';
import { Schedule } from '../../domain/entities/Schedule.js';
import { Booking } from '../../domain/entities/Booking.js';
import { Payment } from '../../domain/entities/Payment.js';
import { Service } from '../../domain/entities/Service.js';
import { ProfessorModel } from '../database/models/ProfessorModel.js';
import { StudentModel } from '../database/models/StudentModel.js';
import { ScheduleModel } from '../database/models/ScheduleModel.js';
import { BookingModel } from '../database/models/BookingModel.js';
import { PaymentModel } from '../database/models/PaymentModel.js';
import { ServiceModel } from '../database/models/ServiceModel.js';

export class MongoProfessorRepository implements ProfessorRepository {
  async create(professor: Omit<Professor, 'id'>): Promise<Professor> {
    const created = await ProfessorModel.create(professor);
    return { id: created._id.toString(), ...professor };
  }
  async findById(id: string): Promise<Professor | null> {
    const doc = await ProfessorModel.findById(id).lean();
    return doc ? { id: doc._id.toString(), name: doc.name, email: doc.email, phone: doc.phone, specialties: doc.specialties, hourlyRate: doc.hourlyRate } : null;
  }
  async findByEmail(email: string): Promise<Professor | null> {
    const doc = await ProfessorModel.findOne({ email }).lean();
    return doc ? { id: doc._id.toString(), name: doc.name, email: doc.email, phone: doc.phone, specialties: doc.specialties, hourlyRate: doc.hourlyRate } : null;
  }
  async listStudents(professorId: string): Promise<Student[]> {
    // Placeholder: join via bookings or professor-student relation if added later
    const bookings = await BookingModel.find({}).populate('studentId').lean();
    const seen = new Set<string>();
    const students: Student[] = [];
    for (const b of bookings) {
      const s: any = b.studentId;
      if (s && !seen.has(s._id.toString())) {
        students.push({ id: s._id.toString(), name: s.name, email: s.email, phone: s.phone, membershipType: s.membershipType, balance: s.balance });
        seen.add(s._id.toString());
      }
    }
    return students;
  }
  async update(id: string, update: Partial<Professor>): Promise<Professor | null> {
    const doc = await ProfessorModel.findByIdAndUpdate(id, update, { new: true }).lean();
    return doc ? { id: doc._id.toString(), name: doc.name, email: doc.email, phone: doc.phone, specialties: doc.specialties, hourlyRate: doc.hourlyRate } : null;
  }
}

export class MongoStudentRepository implements StudentRepository {
  async create(student: Omit<Student, 'id'>): Promise<Student> {
    const created = await StudentModel.create(student);
    return { id: created._id.toString(), ...student };
  }
  async findById(id: string): Promise<Student | null> {
    const doc = await StudentModel.findById(id).lean();
    return doc ? { id: doc._id.toString(), name: doc.name, email: doc.email, phone: doc.phone, membershipType: doc.membershipType, balance: doc.balance } : null;
  }
  async findByEmail(email: string): Promise<Student | null> {
    const doc = await StudentModel.findOne({ email }).lean();
    return doc ? { id: doc._id.toString(), name: doc.name, email: doc.email, phone: doc.phone, membershipType: doc.membershipType, balance: doc.balance } : null;
  }
  async updateBalance(id: string, delta: number): Promise<Student | null> {
    const doc = await StudentModel.findByIdAndUpdate(id, { $inc: { balance: delta } }, { new: true }).lean();
    return doc ? { id: doc._id.toString(), name: doc.name, email: doc.email, phone: doc.phone, membershipType: doc.membershipType, balance: doc.balance } : null;
  }
}

export class MongoScheduleRepository implements ScheduleRepository {
  async publish(schedule: Omit<Schedule, 'id'>): Promise<Schedule> {
    const created = await ScheduleModel.create({ ...schedule, professorId: new Types.ObjectId(schedule.professorId) });
    return { id: created._id.toString(), professorId: created.professorId.toString(), date: created.date, startTime: created.startTime, endTime: created.endTime, type: created.type, isAvailable: created.isAvailable, maxStudents: created.maxStudents };
  }
  async findAvailableByProfessor(professorId: string, dateFrom?: Date, dateTo?: Date): Promise<Schedule[]> {
    const query: any = { professorId: new Types.ObjectId(professorId), isAvailable: true };
    if (dateFrom || dateTo) {
      query.date = {};
      if (dateFrom) query.date.$gte = dateFrom;
      if (dateTo) query.date.$lte = dateTo;
    }
    const docs = await ScheduleModel.find(query).lean();
    return docs.map(d => ({ id: d._id.toString(), professorId: d.professorId.toString(), date: d.date, startTime: d.startTime, endTime: d.endTime, type: d.type, isAvailable: d.isAvailable, maxStudents: d.maxStudents }));
  }
  async findById(id: string): Promise<Schedule | null> {
    const d = await ScheduleModel.findById(id).lean();
    return d ? { id: d._id.toString(), professorId: d.professorId.toString(), date: d.date, startTime: d.startTime, endTime: d.endTime, type: d.type, isAvailable: d.isAvailable, maxStudents: d.maxStudents } : null;
  }
  async update(id: string, update: Partial<Schedule>): Promise<Schedule | null> {
    const d = await ScheduleModel.findByIdAndUpdate(id, update, { new: true }).lean();
    return d ? { id: d._id.toString(), professorId: d.professorId.toString(), date: d.date, startTime: d.startTime, endTime: d.endTime, type: d.type, isAvailable: d.isAvailable, maxStudents: d.maxStudents } : null;
  }
  async delete(id: string): Promise<void> {
    await ScheduleModel.findByIdAndDelete(id);
  }
}

export class MongoBookingRepository implements BookingRepository {
  async create(booking: Omit<Booking, 'id' | 'createdAt'>): Promise<Booking> {
    const created = await BookingModel.create({ ...booking, studentId: new Types.ObjectId(booking.studentId), scheduleId: new Types.ObjectId(booking.scheduleId) });
    return { id: created._id.toString(), studentId: created.studentId.toString(), scheduleId: created.scheduleId.toString(), type: created.type, status: created.status, paymentStatus: created.paymentStatus, createdAt: created.createdAt };
  }
  async listByStudent(studentId: string): Promise<Booking[]> {
    const docs = await BookingModel.find({ studentId: new Types.ObjectId(studentId) }).lean();
    return docs.map(d => ({ id: d._id.toString(), studentId: d.studentId.toString(), scheduleId: d.scheduleId.toString(), type: d.type, status: d.status, paymentStatus: d.paymentStatus, createdAt: d.createdAt }));
  }
  async listBySchedule(scheduleId: string): Promise<Booking[]> {
    const docs = await BookingModel.find({ scheduleId: new Types.ObjectId(scheduleId) }).lean();
    return docs.map(d => ({ id: d._id.toString(), studentId: d.studentId.toString(), scheduleId: d.scheduleId.toString(), type: d.type, status: d.status, paymentStatus: d.paymentStatus, createdAt: d.createdAt }));
  }
  async update(id: string, update: Partial<Booking>): Promise<Booking | null> {
    const d = await BookingModel.findByIdAndUpdate(id, update, { new: true }).lean();
    return d ? { id: d._id.toString(), studentId: d.studentId.toString(), scheduleId: d.scheduleId.toString(), type: d.type, status: d.status, paymentStatus: d.paymentStatus, createdAt: d.createdAt } : null;
  }
}

export class MongoPaymentRepository implements PaymentRepository {
  async create(payment: Omit<Payment, 'id'>): Promise<Payment> {
    const created = await PaymentModel.create({
      ...payment,
      studentId: new Types.ObjectId(payment.studentId),
      professorId: new Types.ObjectId(payment.professorId)
    });
    return {
      id: created._id.toString(),
      studentId: created.studentId.toString(),
      professorId: created.professorId.toString(),
      amount: created.amount,
      date: created.date,
      method: created.method,
      concept: created.concept
    };
  }
  async listByStudent(studentId: string, from?: Date, to?: Date): Promise<Payment[]> {
    const query: any = { studentId: new Types.ObjectId(studentId) };
    if (from || to) {
      query.date = {};
      if (from) query.date.$gte = from;
      if (to) query.date.$lte = to;
    }
    const docs = await PaymentModel.find(query).sort({ date: -1 }).lean();
    return docs.map(d => ({ id: d._id.toString(), studentId: d.studentId.toString(), professorId: d.professorId.toString(), amount: d.amount, date: d.date, method: d.method, concept: d.concept }));
  }
}

export class MongoServiceRepository implements ServiceRepository {
  async create(service: Omit<Service, 'id'>): Promise<Service> {
    const created = await ServiceModel.create(service);
    return { id: created._id.toString(), name: created.name, description: created.description, price: created.price, category: created.category };
  }
  async update(id: string, update: Partial<Service>): Promise<Service | null> {
    const d = await ServiceModel.findByIdAndUpdate(id, update, { new: true }).lean();
    return d ? { id: d._id.toString(), name: d.name, description: d.description, price: d.price, category: d.category } : null;
  }
  async list(): Promise<Service[]> {
    const docs = await ServiceModel.find({}).lean();
    return docs.map(d => ({ id: d._id.toString(), name: d.name, description: d.description, price: d.price, category: d.category }));
  }
}

export class MongoReportRepository implements ReportRepository {
  async getProfessorIncome(professorId: string, from: Date, to: Date): Promise<{ total: number; breakdown: Array<{ date: string; amount: number }> }> {
    const pipeline: PipelineStage[] = [
      { $match: { professorId: new Types.ObjectId(professorId), date: { $gte: from, $lte: to } } },
      { $group: { _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } }, amount: { $sum: '$amount' } } },
      { $project: { _id: 0, date: '$_id', amount: 1 } },
      { $sort: { date: 1 as 1 } }
    ];
    const rows: Array<{ date: string; amount: number }> = await PaymentModel.aggregate(pipeline);
    const total = rows.reduce((acc, r) => acc + r.amount, 0);
    return { total, breakdown: rows };
  }
}

