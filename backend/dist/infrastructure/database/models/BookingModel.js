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
    scheduleId: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: 'Schedule',
        required: false, // Made explicitly optional, validation handled in pre-save hook
        index: true
    },
    studentId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    professorId: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: 'Professor',
        required: false, // Made explicitly optional, validation handled in pre-save hook
        index: true
    },
    courtId: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: 'Court',
        required: false, // Optional - can be assigned automatically or selected
        index: true,
    },
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
// Pre-save validation hook to ensure required fields for non-court_rental bookings
BookingSchema.pre('save', function (next) {
    // Only validate if serviceType is not court_rental
    if (this.serviceType !== 'court_rental') {
        if (!this.scheduleId) {
            return next(new Error('scheduleId is required for individual_class and group_class'));
        }
        if (!this.professorId) {
            return next(new Error('professorId is required for individual_class and group_class'));
        }
    }
    next();
});
// Indexes - using sparse for optional fields to allow null values
BookingSchema.index({ scheduleId: 1, studentId: 1 }, { sparse: true });
BookingSchema.index({ professorId: 1, createdAt: 1 }, { sparse: true });
BookingSchema.index({ tenantId: 1, studentId: 1 });
BookingSchema.index({ tenantId: 1, professorId: 1 }, { sparse: true });
BookingSchema.index({ tenantId: 1, createdAt: 1 });
// Index for court rentals (without professorId or scheduleId)
BookingSchema.index({ tenantId: 1, serviceType: 1, createdAt: 1 });
// Index for checking court rental availability by date
BookingSchema.index({ tenantId: 1, serviceType: 1, bookingDate: 1, status: 1 });
// Index for checking court availability (all bookings for a specific court and time)
BookingSchema.index({ courtId: 1, bookingDate: 1, status: 1 }, { sparse: true });
BookingSchema.index({ tenantId: 1, courtId: 1, bookingDate: 1, status: 1 }, { sparse: true });
exports.BookingModel = (0, mongoose_1.model)('Booking', BookingSchema);
//# sourceMappingURL=BookingModel.js.map