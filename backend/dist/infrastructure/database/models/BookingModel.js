"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BookingModel = void 0;
const mongoose_1 = require("mongoose");
const BookingSchema = new mongoose_1.Schema({
    tenantId: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: 'Tenant',
        required: true,
        index: true,
    },
    scheduleId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Schedule', required: true, index: true },
    studentId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    professorId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
    serviceType: {
        type: String,
        enum: ['individual_class', 'group_class', 'court_rental'],
        required: true
    },
    price: { type: Number, required: true },
    status: {
        type: String,
        enum: ['pending', 'confirmed', 'cancelled', 'completed'],
        default: 'pending'
    },
    notes: { type: String },
    bookingDate: { type: Date, default: Date.now }
}, { timestamps: true });
BookingSchema.index({ scheduleId: 1, studentId: 1 });
BookingSchema.index({ professorId: 1, createdAt: 1 });
BookingSchema.index({ tenantId: 1, studentId: 1 });
BookingSchema.index({ tenantId: 1, professorId: 1 });
BookingSchema.index({ tenantId: 1, createdAt: 1 });
exports.BookingModel = (0, mongoose_1.model)('Booking', BookingSchema);
//# sourceMappingURL=BookingModel.js.map