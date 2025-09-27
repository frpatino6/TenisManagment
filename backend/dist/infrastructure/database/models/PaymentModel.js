import { Schema, model } from 'mongoose';
const PaymentSchema = new Schema({
    studentId: { type: Schema.Types.ObjectId, ref: 'Student', required: true, index: true },
    professorId: { type: Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
    amount: { type: Number, required: true },
    date: { type: Date, required: true, index: true },
    method: { type: String, enum: ['cash', 'card', 'transfer'], required: true },
    concept: { type: String, required: true }
}, { timestamps: true });
export const PaymentModel = model('Payment', PaymentSchema);
//# sourceMappingURL=PaymentModel.js.map