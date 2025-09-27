import { Schema, model } from 'mongoose';
const AuthUserSchema = new Schema({
    email: { type: String, required: true, unique: true, index: true },
    passwordHash: { type: String, required: true },
    role: { type: String, enum: ['professor', 'student'], required: true },
    linkedId: { type: Schema.Types.ObjectId },
    refreshToken: { type: String }
}, { timestamps: true });
export const AuthUserModel = model('AuthUser', AuthUserSchema);
//# sourceMappingURL=AuthUserModel.js.map