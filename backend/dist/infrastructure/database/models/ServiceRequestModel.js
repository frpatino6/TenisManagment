"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ServiceRequestModel = void 0;
const mongoose_1 = require("mongoose");
const ServiceRequestSchema = new mongoose_1.Schema({
    studentId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    serviceId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Service', required: true, index: true },
    notes: { type: String },
    status: { type: String, enum: ['requested'], default: 'requested', index: true }
}, { timestamps: { createdAt: true, updatedAt: false } });
ServiceRequestSchema.index({ studentId: 1, serviceId: 1, status: 1 });
exports.ServiceRequestModel = (0, mongoose_1.model)('ServiceRequest', ServiceRequestSchema);
//# sourceMappingURL=ServiceRequestModel.js.map