import { Schema, model, Types } from 'mongoose';

export interface BookingDocument {
  _id: Types.ObjectId;
  scheduleId: Types.ObjectId;
  studentId: Types.ObjectId;
  professorId: Types.ObjectId;
  serviceType: 'individual_class' | 'group_class' | 'court_rental';
  price: number;
  status: 'pending' | 'confirmed' | 'cancelled' | 'completed';
  notes?: string;
  bookingDate?: Date;
  createdAt: Date;
  updatedAt: Date;
}

const BookingSchema = new Schema<BookingDocument>({
  scheduleId: { type: Schema.Types.ObjectId, ref: 'Schedule', required: true, index: true },
  studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
  professorId: { type: Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
  serviceType: { 
    type: String, 
    enum: ['individual_class', 'group_class', 'court_rental'], 
    required: true 
  },
  price: { type: Number, required: true },
  status: { 
    type: String, 
    enum: ['pending', 'confirmed', 'cancelled', 'completed'], 
    default: 'pending' 
  },
  notes: { type: String },
  bookingDate: { type: Date, default: Date.now }
}, { timestamps: true });

BookingSchema.index({ scheduleId: 1, studentId: 1 });
BookingSchema.index({ professorId: 1, createdAt: 1 });

export const BookingModel = model<BookingDocument>('Booking', BookingSchema);