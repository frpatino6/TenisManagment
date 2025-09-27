import { Schema, model, Types } from 'mongoose';

export interface ServiceDocument {
  _id: Types.ObjectId;
  name: string;
  description: string;
  price: number;
  category: 'stringing' | 'grip' | 'other';
}

const ServiceSchema = new Schema<ServiceDocument>({
  name: { type: String, required: true },
  description: { type: String, required: true },
  price: { type: Number, required: true },
  category: { type: String, enum: ['stringing', 'grip', 'other'], required: true }
}, { timestamps: true });

export const ServiceModel = model<ServiceDocument>('Service', ServiceSchema);

