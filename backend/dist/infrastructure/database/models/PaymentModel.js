"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentModel = void 0;
const mongoose_1 = require("mongoose");
const PaymentSchema = new mongoose_1.Schema({
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
exports.PaymentModel = (0, mongoose_1.model)('Payment', PaymentSchema);
//# sourceMappingURL=PaymentModel.js.map