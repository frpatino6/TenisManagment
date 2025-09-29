"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.PaymentModel = void 0;
const mongoose_1 = require("mongoose");
const PaymentSchema = new mongoose_1.Schema({
    studentId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    professorId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
    amount: { type: Number, required: true },
    date: { type: Date, required: true, index: true },
    method: { type: String, enum: ['cash', 'card', 'transfer'], required: true },
    concept: { type: String, required: true }
}, { timestamps: true });
exports.PaymentModel = (0, mongoose_1.model)('Payment', PaymentSchema);
//# sourceMappingURL=PaymentModel.js.map