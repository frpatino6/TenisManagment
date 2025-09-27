import { Schema, model } from 'mongoose';
const BookingSchema = new Schema({
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    scheduleId: { type: Schema.Types.ObjectId, ref: 'Schedule', required: true, index: true },
    type: { type: String, enum: ['lesson', 'court_rental'], required: true },
    status: { type: String, enum: ['confirmed', 'pending', 'cancelled'], default: 'pending' },
    paymentStatus: { type: String, enum: ['paid', 'pending', 'overdue'], default: 'pending', index: true }
}, { timestamps: { createdAt: true, updatedAt: true } });
BookingSchema.index({ studentId: 1, scheduleId: 1 });
export const BookingModel = model('Booking', BookingSchema);
//# sourceMappingURL=BookingModel.js.map