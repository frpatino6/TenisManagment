import { Schema, model, Types } from 'mongoose';

export type UserRole = 'professor' | 'student';

export interface AuthUserDocument {
  _id: Types.ObjectId;
  email: string;
  passwordHash: string;
  role: UserRole;
  linkedId?: Types.ObjectId; // points to Professor or Student
  refreshToken?: string;
}

const AuthUserSchema = new Schema<AuthUserDocument>({
  email: { type: String, required: true, unique: true, index: true },
  passwordHash: { type: String, required: true },
  role: { type: String, enum: ['professor', 'student'], required: true },
  linkedId: { type: Schema.Types.ObjectId },
  refreshToken: { type: String }
}, { timestamps: true });

export const AuthUserModel = model<AuthUserDocument>('AuthUser', AuthUserSchema);

