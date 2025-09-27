import { Schema, model } from 'mongoose';
const ServiceRequestSchema = new Schema({
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    serviceId: { type: Schema.Types.ObjectId, ref: 'Service', required: true, index: true },
    notes: { type: String },
    status: { type: String, enum: ['requested'], default: 'requested', index: true }
}, { timestamps: { createdAt: true, updatedAt: false } });
ServiceRequestSchema.index({ studentId: 1, serviceId: 1, status: 1 });
export const ServiceRequestModel = model('ServiceRequest', ServiceRequestSchema);
//# sourceMappingURL=ServiceRequestModel.js.map