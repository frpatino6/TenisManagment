import { Schema, model } from 'mongoose';
const ProfessorSchema = new Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    phone: { type: String, required: true },
    specialties: { type: [String], default: [] },
    hourlyRate: { type: Number, required: true }
}, { timestamps: true });
export const ProfessorModel = model('Professor', ProfessorSchema);
//# sourceMappingURL=ProfessorModel.js.map