import { Schema, model, Types } from 'mongoose';

/**
 * StudentTenant document interface
 * Represents the relationship between a Student and a Tenant (N:M)
 * Created automatically when a student makes their first booking in a tenant
 * Tracks balance per tenant (students can have different balances in different centers)
 */
export interface StudentTenantDocument {
  _id: Types.ObjectId;
  studentId: Types.ObjectId; // Reference to Student
  tenantId: Types.ObjectId; // Reference to Tenant
  balance: number; // Balance specific to this tenant
  isActive: boolean;
  joinedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const StudentTenantSchema = new Schema<StudentTenantDocument>(
  {
    studentId: {
      type: Schema.Types.ObjectId,
      ref: 'Student',
      required: true,
      index: true,
    },
    tenantId: {
      type: Schema.Types.ObjectId,
      ref: 'Tenant',
      required: true,
      index: true,
    },
    balance: { type: Number, default: 0, required: true },
    isActive: { type: Boolean, default: true, index: true },
    joinedAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

// Compound indexes
StudentTenantSchema.index({ studentId: 1, tenantId: 1 }, { unique: true });
StudentTenantSchema.index({ tenantId: 1, isActive: 1 });
StudentTenantSchema.index({ studentId: 1, isActive: 1 });
StudentTenantSchema.index({ tenantId: 1, balance: 1 }); // For balance queries

export const StudentTenantModel = model<StudentTenantDocument>(
  'StudentTenant',
  StudentTenantSchema,
);

