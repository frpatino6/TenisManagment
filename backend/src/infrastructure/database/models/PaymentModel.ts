import { Schema, model, Types } from 'mongoose';

export interface PaymentDocument {
  _id: Types.ObjectId;
  tenantId: Types.ObjectId; // Reference to Tenant (required for multi-tenancy)
  studentId: Types.ObjectId;
  professorId: Types.ObjectId;
  bookingId?: Types.ObjectId;
  amount: number;
  date: Date;
  status: 'pending' | 'paid' | 'cancelled';
  method: 'cash' | 'card' | 'transfer';
  concept?: string; // Keep for backwards compatibility
  description?: string; // New field for payment description
  createdAt: Date;
  updatedAt: Date;
}

const PaymentSchema = new Schema<PaymentDocument>(
  {
    tenantId: {
      type: Schema.Types.ObjectId,
      ref: 'Tenant',
      required: true,
      index: true,
    },
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    professorId: { type: Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
    bookingId: { type: Schema.Types.ObjectId, ref: 'Booking' },
    amount: { type: Number, required: true },
    date: { type: Date, required: true, index: true },
    status: { type: String, enum: ['pending', 'paid', 'cancelled'], default: 'paid' },
    method: { type: String, enum: ['cash', 'card', 'transfer'], required: true },
    concept: { type: String },
    description: { type: String },
  },
  { timestamps: true },
);

// Compound indexes for multi-tenancy
PaymentSchema.index({ tenantId: 1, studentId: 1 });
PaymentSchema.index({ tenantId: 1, professorId: 1 });
PaymentSchema.index({ tenantId: 1, date: 1 });

export const PaymentModel = model<PaymentDocument>('Payment', PaymentSchema);
