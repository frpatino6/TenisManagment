import { Schema, model } from 'mongoose';
const StudentSchema = new Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    phone: { type: String, required: true },
    membershipType: { type: String, enum: ['basic', 'premium'], required: true },
    balance: { type: Number, default: 0 }
}, { timestamps: true });
export const StudentModel = model('Student', StudentSchema);
//# sourceMappingURL=StudentModel.js.map