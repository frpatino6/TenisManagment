import { Schema, model, Types } from 'mongoose';

export interface BookingDocument {
  _id: Types.ObjectId;
  studentId: Types.ObjectId;
  scheduleId: Types.ObjectId;
  type: 'lesson' | 'court_rental';
  status: 'confirmed' | 'pending' | 'cancelled';
  paymentStatus: 'paid' | 'pending' | 'overdue';
  createdAt: Date;
}

const BookingSchema = new Schema<BookingDocument>({
  studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
  scheduleId: { type: Schema.Types.ObjectId, ref: 'Schedule', required: true, index: true },
  type: { type: String, enum: ['lesson', 'court_rental'], required: true },
  status: { type: String, enum: ['confirmed', 'pending', 'cancelled'], default: 'pending' },
  paymentStatus: { type: String, enum: ['paid', 'pending', 'overdue'], default: 'pending', index: true }
}, { timestamps: { createdAt: true, updatedAt: true } });

BookingSchema.index({ studentId: 1, scheduleId: 1 });

export const BookingModel = model<BookingDocument>('Booking', BookingSchema);

