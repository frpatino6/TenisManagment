import { Schema, model, Types } from 'mongoose';

export interface PricingConfig {
  individualClass: number;
  groupClass: number;
  courtRental: number;
}

export interface SystemConfigDocument {
  _id: Types.ObjectId;
  key: string;
  value: any;
  description?: string;
  updatedAt?: Date;
  createdAt?: Date;
}

const SystemConfigSchema = new Schema<SystemConfigDocument>(
  {
    key: { type: String, required: true, unique: true, index: true },
    value: { type: Schema.Types.Mixed, required: true },
    description: { type: String },
  },
  { timestamps: true }
);

export const SystemConfigModel = model<SystemConfigDocument>(
  'SystemConfig',
  SystemConfigSchema
);

