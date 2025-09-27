import { Schema, model, Types } from 'mongoose';

export interface ProfessorDocument {
  _id: Types.ObjectId;
  name: string;
  email: string;
  phone: string;
  specialties: string[];
  hourlyRate: number;
}

const ProfessorSchema = new Schema<ProfessorDocument>({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true, index: true },
  phone: { type: String, required: true },
  specialties: { type: [String], default: [] },
  hourlyRate: { type: Number, required: true }
}, { timestamps: true });

export const ProfessorModel = model<ProfessorDocument>('Professor', ProfessorSchema);

