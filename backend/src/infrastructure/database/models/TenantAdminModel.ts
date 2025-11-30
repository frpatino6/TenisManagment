import { Schema, model, Types } from 'mongoose';

/**
 * TenantAdmin document interface
 * Represents the relationship between a Tenant and its Admin (N:1)
 */
export interface TenantAdminDocument {
  _id: Types.ObjectId;
  tenantId: Types.ObjectId; // Reference to Tenant
  adminUserId: Types.ObjectId; // Reference to AuthUser (Tenant Admin)
  isActive: boolean;
  joinedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const TenantAdminSchema = new Schema<TenantAdminDocument>(
  {
    tenantId: {
      type: Schema.Types.ObjectId,
      ref: 'Tenant',
      required: true,
      index: true,
    },
    adminUserId: {
      type: Schema.Types.ObjectId,
      ref: 'AuthUser',
      required: true,
      index: true,
    },
    isActive: { type: Boolean, default: true, index: true },
    joinedAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

// Compound indexes
TenantAdminSchema.index({ tenantId: 1, adminUserId: 1 }, { unique: true });
TenantAdminSchema.index({ tenantId: 1, isActive: 1 });
TenantAdminSchema.index({ adminUserId: 1, isActive: 1 });

export const TenantAdminModel = model<TenantAdminDocument>(
  'TenantAdmin',
  TenantAdminSchema,
);

