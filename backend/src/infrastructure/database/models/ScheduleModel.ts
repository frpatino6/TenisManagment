import { Schema, model, Types } from 'mongoose';

export interface ScheduleDocument {
  _id: Types.ObjectId;
  professorId: Types.ObjectId;
  studentId?: Types.ObjectId;
  date: Date;
  startTime: Date;
  endTime: Date;
  type: 'individual' | 'group' | 'court_rental';
  isAvailable: boolean;
  maxStudents?: number;
  status?: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  notes?: string;
  price?: number;
}

const ScheduleSchema = new Schema<ScheduleDocument>({
  professorId: { type: Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
  studentId: { type: Schema.Types.ObjectId, ref: 'Student' },
  date: { type: Date, required: true, index: true },
  startTime: { type: Date, required: true },
  endTime: { type: Date, required: true },
  type: { type: String, enum: ['individual', 'group', 'court_rental'], required: true },
  isAvailable: { type: Boolean, default: true, index: true },
  maxStudents: { type: Number },
  status: { type: String, enum: ['pending', 'confirmed', 'cancelled', 'completed'], default: 'pending' },
  notes: { type: String },
  price: { type: Number }
}, { timestamps: true });

ScheduleSchema.index({ date: 1, professorId: 1, isAvailable: 1 });

export const ScheduleModel = model<ScheduleDocument>('Schedule', ScheduleSchema);

