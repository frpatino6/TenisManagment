"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentModel = void 0;
const mongoose_1 = require("mongoose");
const PaymentSchema = new mongoose_1.Schema({
    tenantId: {
        type: mongoose_1.Schema.Types.ObjectId,
        ref: 'Tenant',
        required: true,
        index: true,
    },
    studentId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    professorId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
    bookingId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Booking' },
    amount: { type: Number, required: true },
    date: { type: Date, required: true, index: true },
    status: { type: String, enum: ['pending', 'paid', 'cancelled'], default: 'paid' },
    method: { type: String, enum: ['cash', 'card', 'transfer'], required: true },
    concept: { type: String },
    description: { type: String },
}, { timestamps: true });
// Compound indexes for multi-tenancy
PaymentSchema.index({ tenantId: 1, studentId: 1 });
PaymentSchema.index({ tenantId: 1, professorId: 1 });
PaymentSchema.index({ tenantId: 1, date: 1 });
exports.PaymentModel = (0, mongoose_1.model)('Payment', PaymentSchema);
//# sourceMappingURL=PaymentModel.js.map