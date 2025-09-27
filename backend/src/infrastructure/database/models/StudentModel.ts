import { Schema, model, Types } from 'mongoose';

export interface StudentDocument {
  _id: Types.ObjectId;
  name: string;
  email: string;
  phone: string;
  membershipType: 'basic' | 'premium';
  balance: number;
}

const StudentSchema = new Schema<StudentDocument>({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, index: true },
  phone: { type: String, required: true },
  membershipType: { type: String, enum: ['basic', 'premium'], required: true },
  balance: { type: Number, default: 0 }
}, { timestamps: true });

export const StudentModel = model<StudentDocument>('Student', StudentSchema);

