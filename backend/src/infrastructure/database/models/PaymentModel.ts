import { Schema, model, Types } from 'mongoose';

export interface PaymentDocument {
  _id: Types.ObjectId;
  studentId: Types.ObjectId;
  professorId: Types.ObjectId;
  amount: number;
  date: Date;
  method: 'cash' | 'card' | 'transfer';
  concept: string;
}

const PaymentSchema = new Schema<PaymentDocument>(
  {
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    professorId: { type: Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
    amount: { type: Number, required: true },
    date: { type: Date, required: true, index: true },
    method: { type: String, enum: ['cash', 'card', 'transfer'], required: true },
    concept: { type: String, required: true },
  },
  { timestamps: true },
);

export const PaymentModel = model<PaymentDocument>('Payment', PaymentSchema);
