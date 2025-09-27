import { Schema, model, Types } from 'mongoose';

export interface ScheduleDocument {
  _id: Types.ObjectId;
  professorId: Types.ObjectId;
  date: Date;
  startTime: string;
  endTime: string;
  type: 'individual' | 'group' | 'court_rental';
  isAvailable: boolean;
  maxStudents?: number;
}

const ScheduleSchema = new Schema<ScheduleDocument>({
  professorId: { type: Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
  date: { type: Date, required: true, index: true },
  startTime: { type: String, required: true },
  endTime: { type: String, required: true },
  type: { type: String, enum: ['individual', 'group', 'court_rental'], required: true },
  isAvailable: { type: Boolean, default: true, index: true },
  maxStudents: { type: Number }
}, { timestamps: true });

ScheduleSchema.index({ date: 1, professorId: 1, isAvailable: 1 });

export const ScheduleModel = model<ScheduleDocument>('Schedule', ScheduleSchema);

