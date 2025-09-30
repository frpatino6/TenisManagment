import { Schema, model, Types } from 'mongoose';

export interface ServiceRequestDocument {
  _id: Types.ObjectId;
  studentId: Types.ObjectId;
  serviceId: Types.ObjectId;
  notes?: string;
  status: 'requested';
  createdAt: Date;
}

const ServiceRequestSchema = new Schema<ServiceRequestDocument>(
  {
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    serviceId: { type: Schema.Types.ObjectId, ref: 'Service', required: true, index: true },
    notes: { type: String },
    status: { type: String, enum: ['requested'], default: 'requested', index: true },
  },
  { timestamps: { createdAt: true, updatedAt: false } },
);

ServiceRequestSchema.index({ studentId: 1, serviceId: 1, status: 1 });

export const ServiceRequestModel = model<ServiceRequestDocument>(
  'ServiceRequest',
  ServiceRequestSchema,
);
