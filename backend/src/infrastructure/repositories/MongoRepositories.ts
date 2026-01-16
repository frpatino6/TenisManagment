import { Types, PipelineStage } from 'mongoose';
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
import { Professor } from '../../domain/entities/Professor';
import { Student } from '../../domain/entities/Student';
import { Schedule } from '../../domain/entities/Schedule';
import { Booking } from '../../domain/entities/Booking';
import { Payment } from '../../domain/entities/Payment';
import { Service } from '../../domain/entities/Service';
import { ProfessorModel } from '../database/models/ProfessorModel';
import { StudentModel } from '../database/models/StudentModel';
import { ScheduleModel } from '../database/models/ScheduleModel';
import { BookingModel } from '../database/models/BookingModel';
import { PaymentModel } from '../database/models/PaymentModel';
import { ServiceModel } from '../database/models/ServiceModel';
import { ServiceRequestModel } from '../database/models/ServiceRequestModel';
import { ServiceRequest } from '../../domain/entities/ServiceRequest';

export class MongoProfessorRepository implements ProfessorRepository {
  async create(professor: Omit<Professor, 'id'>): Promise<Professor> {
    const created = await ProfessorModel.create(professor);
    return { id: created._id.toString(), ...professor };
  }
  async findById(id: string): Promise<Professor | null> {
    const doc = await ProfessorModel.findById(id).lean();
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
  async findByEmail(email: string): Promise<Professor | null> {
    const doc = await ProfessorModel.findOne({ email }).lean();
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
  async listStudents(professorId: string): Promise<Student[]> {
    const pipeline: any[] = [
      { $match: { professorId: new Types.ObjectId(professorId) } },
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
    const rows: Array<any> = await (ScheduleModel as any).aggregate(pipeline);
    return rows.map((s) => ({
      id: s._id.toString(),
      name: s.name,
      email: s.email,
      phone: s.phone,
      membershipType: s.membershipType,
      balance: s.balance,
    }));
  }
  async update(id: string, update: Partial<Professor>): Promise<Professor | null> {
    const doc = await ProfessorModel.findByIdAndUpdate(id, update, { new: true }).lean();
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

export class MongoStudentRepository implements StudentRepository {
  async create(student: Omit<Student, 'id'>): Promise<Student> {
    const created = await StudentModel.create(student);
    return { id: created._id.toString(), ...student };
  }
  async findById(id: string): Promise<Student | null> {
    const doc = await StudentModel.findById(id).lean();
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
  async findByEmail(email: string): Promise<Student | null> {
    const doc = await StudentModel.findOne({ email }).lean();
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
  async updateBalance(id: string, delta: number): Promise<Student | null> {
    const doc = await StudentModel.findByIdAndUpdate(
      id,
      { $inc: { balance: delta } },
      { new: true },
    ).lean();
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

export class MongoScheduleRepository implements ScheduleRepository {
  async publish(schedule: Omit<Schedule, 'id'>): Promise<Schedule> {
    const created = await ScheduleModel.create({
      ...schedule,
      professorId: new Types.ObjectId(schedule.professorId),
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
  async findAvailableByProfessor(
    professorId: string,
    dateFrom?: Date,
    dateTo?: Date,
  ): Promise<Schedule[]> {
    const query: any = { professorId: new Types.ObjectId(professorId), isAvailable: true };
    if (dateFrom || dateTo) {
      query.date = {};
      if (dateFrom) query.date.$gte = dateFrom;
      if (dateTo) query.date.$lte = dateTo;
    }
    const docs = await ScheduleModel.find(query).lean();
    return docs.map((d) => ({
      id: d._id.toString(),
      professorId: d.professorId.toString(),
      date: d.date,
      startTime: (d.startTime as Date).toISOString(),
      endTime: (d.endTime as Date).toISOString(),
      isAvailable: d.isAvailable,
      notes: d.notes,
      status: d.status,
    }));
  }
  async findById(id: string): Promise<Schedule | null> {
    const d = await ScheduleModel.findById(id).lean();
    return d
      ? {
        id: d._id.toString(),
        professorId: d.professorId.toString(),
        date: d.date,
        startTime: (d.startTime as Date).toISOString(),
        endTime: (d.endTime as Date).toISOString(),
        isAvailable: d.isAvailable,
        notes: d.notes,
        status: d.status,
      }
      : null;
  }
  async update(id: string, update: Partial<Schedule>): Promise<Schedule | null> {
    const d = await ScheduleModel.findByIdAndUpdate(id, update, { new: true }).lean();
    return d
      ? {
        id: d._id.toString(),
        professorId: d.professorId.toString(),
        date: d.date,
        startTime: (d.startTime as Date).toISOString(),
        endTime: (d.endTime as Date).toISOString(),
        isAvailable: d.isAvailable,
        notes: d.notes,
        status: d.status,
      }
      : null;
  }
  async delete(id: string): Promise<void> {
    await ScheduleModel.findByIdAndDelete(id);
  }
}

export class MongoBookingRepository implements BookingRepository {
  async create(booking: Omit<Booking, 'id' | 'createdAt'>): Promise<Booking> {
    const created = await BookingModel.create({
      ...booking,
      studentId: new Types.ObjectId(booking.studentId),
      scheduleId: booking.scheduleId ? new Types.ObjectId(booking.scheduleId) : undefined,
      courtId: booking.courtId ? new Types.ObjectId(booking.courtId) : undefined,
    });
    return {
      id: created._id.toString(),
      studentId: created.studentId.toString(),
      scheduleId: created.scheduleId?.toString(),
      courtId: created.courtId?.toString(),
      serviceType: created.serviceType,
      status: created.status,
      price: created.price,
      notes: created.notes,
      bookingDate: created.bookingDate,
      createdAt: created.createdAt,
    };
  }
  async listByStudent(studentId: string): Promise<Booking[]> {
    const docs = await BookingModel.find({ studentId: new Types.ObjectId(studentId) }).lean();
    return docs.map((d) => ({
      id: d._id.toString(),
      studentId: d.studentId.toString(),
      scheduleId: d.scheduleId?.toString(),
      courtId: d.courtId?.toString(),
      serviceType: d.serviceType,
      status: d.status,
      price: d.price,
      notes: d.notes,
      bookingDate: d.bookingDate,
      createdAt: d.createdAt,
    }));
  }
  async listBySchedule(scheduleId: string): Promise<Booking[]> {
    const docs = await BookingModel.find({ scheduleId: new Types.ObjectId(scheduleId) }).lean();
    return docs.map((d) => ({
      id: d._id.toString(),
      studentId: d.studentId.toString(),
      scheduleId: d.scheduleId?.toString(),
      courtId: d.courtId?.toString(),
      serviceType: d.serviceType,
      status: d.status,
      price: d.price,
      notes: d.notes,
      bookingDate: d.bookingDate,
      createdAt: d.createdAt,
    }));
  }
  async update(id: string, update: Partial<Booking>): Promise<Booking | null> {
    const d = await BookingModel.findByIdAndUpdate(id, update, { new: true }).lean();
    return d
      ? {
        id: d._id.toString(),
        studentId: d.studentId.toString(),
        scheduleId: d.scheduleId?.toString(),
        courtId: d.courtId?.toString(),
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

export class MongoPaymentRepository implements PaymentRepository {
  async create(payment: Omit<Payment, 'id'>): Promise<Payment> {
    const created = await PaymentModel.create({
      ...payment,
      studentId: new Types.ObjectId(payment.studentId),
      professorId: payment.professorId ? new Types.ObjectId(payment.professorId) : undefined,
    });
    return {
      id: created._id.toString(),
      studentId: created.studentId.toString(),
      professorId: created.professorId?.toString(),
      amount: created.amount,
      date: created.date,
      method: created.method,
      concept: created.concept,
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
    return docs.map((d) => ({
      id: d._id.toString(),
      studentId: d.studentId.toString(),
      professorId: d.professorId?.toString(),
      amount: d.amount,
      date: d.date,
      method: d.method,
      concept: d.concept,
    }));
  }
}

export class MongoServiceRepository implements ServiceRepository {
  async create(service: Omit<Service, 'id'>): Promise<Service> {
    const created = await ServiceModel.create(service);
    return {
      id: created._id.toString(),
      name: created.name,
      description: created.description,
      price: created.price,
      category: created.category,
    };
  }
  async update(id: string, update: Partial<Service>): Promise<Service | null> {
    const d = await ServiceModel.findByIdAndUpdate(id, update, { new: true }).lean();
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
  async list(): Promise<Service[]> {
    const docs = await ServiceModel.find({}).lean();
    return docs.map((d) => ({
      id: d._id.toString(),
      name: d.name,
      description: d.description,
      price: d.price,
      category: d.category,
    }));
  }
  async delete(id: string): Promise<void> {
    await ServiceModel.findByIdAndDelete(id);
  }
}

export class MongoReportRepository implements ReportRepository {
  async getProfessorIncome(
    professorId: string,
    from: Date,
    to: Date,
  ): Promise<{ total: number; breakdown: Array<{ date: string; amount: number }> }> {
    const pipeline: PipelineStage[] = [
      { $match: { professorId: new Types.ObjectId(professorId), date: { $gte: from, $lte: to } } },
      {
        $group: {
          _id: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
          amount: { $sum: '$amount' },
        },
      },
      { $project: { _id: 0, date: '$_id', amount: 1 } },
      { $sort: { date: 1 as 1 } },
    ];
    const rows: Array<{ date: string; amount: number }> = await PaymentModel.aggregate(pipeline);
    const total = rows.reduce((acc, r) => acc + r.amount, 0);
    return { total, breakdown: rows };
  }
}

export class MongoServiceRequestRepository implements ServiceRequestRepository {
  async create(request: Omit<ServiceRequest, 'id' | 'createdAt'>): Promise<ServiceRequest> {
    const created = await ServiceRequestModel.create({
      ...request,
      studentId: new Types.ObjectId(request.studentId),
      serviceId: new Types.ObjectId(request.serviceId),
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
