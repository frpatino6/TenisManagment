import { Schema, model, Types } from 'mongoose';

export interface PricingConfig {
  individualClass?: number;
  groupClass?: number;
  courtRental?: number;
}

export interface ProfessorDocument {
  _id: Types.ObjectId;
  authUserId: Types.ObjectId; // Reference to AuthUser
  name: string;
  email: string;
  phone: string;
  specialties: string[];
  hourlyRate: number;
  experienceYears: number;
  pricing?: PricingConfig; // Custom pricing (overrides base pricing)
}

const ProfessorSchema = new Schema<ProfessorDocument>(
  {
    authUserId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true, unique: true },
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    phone: { type: String, required: true },
    specialties: { type: [String], default: [] },
    hourlyRate: { type: Number, required: true },
    experienceYears: { type: Number, required: true, default: 0 },
    pricing: {
      individualClass: { type: Number },
      groupClass: { type: Number },
      courtRental: { type: Number },
    },
  },
  { timestamps: true },
);

export const ProfessorModel = model<ProfessorDocument>('Professor', ProfessorSchema);
