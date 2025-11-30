import { Schema, model, Types } from 'mongoose';

/**
 * Pricing configuration specific to a professor in a tenant
 */
export interface ProfessorTenantPricing {
  individualClass?: number;
  groupClass?: number;
  courtRental?: number;
}

/**
 * ProfessorTenant document interface
 * Represents the relationship between a Professor and a Tenant (N:M)
 * Allows professors to work in multiple centers with different pricing per center
 */
export interface ProfessorTenantDocument {
  _id: Types.ObjectId;
  professorId: Types.ObjectId; // Reference to Professor
  tenantId: Types.ObjectId; // Reference to Tenant
  pricing?: ProfessorTenantPricing; // Pricing specific to this tenant (overrides professor's default pricing)
  isActive: boolean;
  joinedAt: Date;
  createdAt: Date;
  updatedAt: Date;
}

const ProfessorTenantPricingSchema = new Schema<ProfessorTenantPricing>(
  {
    individualClass: { type: Number },
    groupClass: { type: Number },
    courtRental: { type: Number },
  },
  { _id: false },
);

const ProfessorTenantSchema = new Schema<ProfessorTenantDocument>(
  {
    professorId: {
      type: Schema.Types.ObjectId,
      ref: 'Professor',
      required: true,
      index: true,
    },
    tenantId: {
      type: Schema.Types.ObjectId,
      ref: 'Tenant',
      required: true,
      index: true,
    },
    pricing: { type: ProfessorTenantPricingSchema },
    isActive: { type: Boolean, default: true, index: true },
    joinedAt: { type: Date, default: Date.now },
  },
  { timestamps: true },
);

// Compound indexes
ProfessorTenantSchema.index({ professorId: 1, tenantId: 1 }, { unique: true });
ProfessorTenantSchema.index({ tenantId: 1, isActive: 1 });
ProfessorTenantSchema.index({ professorId: 1, isActive: 1 });

export const ProfessorTenantModel = model<ProfessorTenantDocument>(
  'ProfessorTenant',
  ProfessorTenantSchema,
);

