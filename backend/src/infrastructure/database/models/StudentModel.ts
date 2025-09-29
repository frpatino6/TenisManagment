import { Schema, model, Types } from 'mongoose';

export interface StudentDocument {
  _id: Types.ObjectId;
  authUserId: Types.ObjectId; // Reference to AuthUser
  name: string;
  email: string;
  phone?: string; // Made optional for Google Sign-In users
  membershipType: 'basic' | 'premium';
  balance: number;
}

const StudentSchema = new Schema<StudentDocument>({
  authUserId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true, unique: true },
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, index: true },
  phone: { type: String }, // Made optional for Google Sign-In users
  membershipType: { type: String, enum: ['basic', 'premium'], required: true },
  balance: { type: Number, default: 0 }
}, { timestamps: true });

export const StudentModel = model<StudentDocument>('Student', StudentSchema);

