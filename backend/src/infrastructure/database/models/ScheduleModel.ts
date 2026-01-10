import { Schema, model, Types } from 'mongoose';

export interface ScheduleDocument {
  _id: Types.ObjectId;
  tenantId: Types.ObjectId;
  professorId: Types.ObjectId;
  studentId?: Types.ObjectId;
  courtId?: Types.ObjectId;
  date: Date;
  startTime: Date;
  endTime: Date;
  isAvailable: boolean;
  isBlocked?: boolean;
  blockReason?: string;
  status?: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  notes?: string;
}

const ScheduleSchema = new Schema<ScheduleDocument>({
  tenantId: {
    type: Schema.Types.ObjectId,
    ref: 'Tenant',
    required: true,
    index: true,
  },
  professorId: { type: Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
  studentId: { type: Schema.Types.ObjectId, ref: 'Student' },
  courtId: { type: Schema.Types.ObjectId, ref: 'Court' },
  date: { type: Date, required: true, index: true },
  startTime: { type: Date, required: true },
  endTime: { type: Date, required: true },
  isAvailable: { type: Boolean, default: true, index: true },
  isBlocked: { type: Boolean, default: false },
  blockReason: { type: String },
  status: { type: String, enum: ['pending', 'confirmed', 'cancelled', 'completed'], default: 'pending' },
  notes: { type: String }
}, { timestamps: true });

ScheduleSchema.index({ date: 1, professorId: 1, isAvailable: 1 });
ScheduleSchema.index({ tenantId: 1, professorId: 1, date: 1 });
ScheduleSchema.index({ tenantId: 1, isAvailable: 1 });
ScheduleSchema.index({ tenantId: 1, date: 1 });

export const ScheduleModel = model<ScheduleDocument>('Schedule', ScheduleSchema);

