"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BookingModel = void 0;
const mongoose_1 = require("mongoose");
const BookingSchema = new mongoose_1.Schema({
    studentId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    scheduleId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Schedule', required: true, index: true },
    type: { type: String, enum: ['lesson', 'court_rental'], required: true },
    status: { type: String, enum: ['confirmed', 'pending', 'cancelled'], default: 'pending' },
    paymentStatus: { type: String, enum: ['paid', 'pending', 'overdue'], default: 'pending', index: true }
}, { timestamps: { createdAt: true, updatedAt: true } });
BookingSchema.index({ studentId: 1, scheduleId: 1 });
exports.BookingModel = (0, mongoose_1.model)('Booking', BookingSchema);
//# sourceMappingURL=BookingModel.js.map