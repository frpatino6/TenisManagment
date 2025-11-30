import { Schema, model, Types } from 'mongoose';

export type UserRole = 'super_admin' | 'tenant_admin' | 'professor' | 'student';

export interface AuthUserDocument {
  _id: Types.ObjectId;
  email: string;
  passwordHash?: string;
  role: UserRole;
  linkedId?: Types.ObjectId; // points to Professor or Student
  refreshToken?: string;
  firebaseUid?: string;
  name?: string;
}

const AuthUserSchema = new Schema<AuthUserDocument>(
  {
    email: { type: String, required: true, unique: true, index: true },
    passwordHash: { type: String },
    role: {
      type: String,
      enum: ['super_admin', 'tenant_admin', 'professor', 'student'],
      required: true,
    },
    linkedId: { type: Schema.Types.ObjectId },
    refreshToken: { type: String },
    firebaseUid: { type: String, unique: true, sparse: true },
    name: { type: String },
  },
  { timestamps: true },
);

export const AuthUserModel = model<AuthUserDocument>('AuthUser', AuthUserSchema);
