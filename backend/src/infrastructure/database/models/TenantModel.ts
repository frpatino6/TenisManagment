import { Schema, model, Types } from 'mongoose';

/**
 * Configuration for tenant branding and pricing
 */
export interface TenantConfig {
  logo?: string;
  primaryColor?: string;
  secondaryColor?: string;
  basePricing?: {
    individualClass?: number;
    groupClass?: number;
    courtRental?: number;
  };
  operatingHours?: {
    open: string; // Format: "HH:mm"
    close: string; // Format: "HH:mm"
    daysOfWeek?: number[]; // 0-6 (Sunday-Saturday)
  };
}

/**
 * Tenant document interface
 * Represents a tennis/padel center (tenant) in the multi-tenant system
 */
export interface TenantDocument {
  _id: Types.ObjectId;
  name: string;
  slug: string; // Unique URL-friendly identifier
  domain?: string; // Optional custom domain
  adminUserId: Types.ObjectId; // Reference to AuthUser (Tenant Admin)
  config?: TenantConfig;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;
}

const TenantConfigSchema = new Schema<TenantConfig>(
  {
    logo: { type: String },
    primaryColor: { type: String },
    secondaryColor: { type: String },
    basePricing: {
      individualClass: { type: Number },
      groupClass: { type: Number },
      courtRental: { type: Number },
    },
    operatingHours: {
      open: { type: String },
      close: { type: String },
      daysOfWeek: { type: [Number] },
    },
  },
  { _id: false },
);

const TenantSchema = new Schema<TenantDocument>(
  {
    name: { type: String, required: true, trim: true },
    slug: {
      type: String,
      required: function(this: TenantDocument) {
        // Slug is required, but will be auto-generated if not provided
        return !!this.slug;
      },
      unique: true,
      sparse: true, // Allow null/undefined for unique index
      lowercase: true,
      trim: true,
      match: /^[a-z0-9-]+$/, // Only lowercase letters, numbers, and hyphens
    },
    domain: {
      type: String,
      sparse: true,
      unique: true,
      lowercase: true,
      trim: true,
    },
    adminUserId: {
      type: Schema.Types.ObjectId,
      ref: 'AuthUser',
      required: true,
      index: true,
    },
    config: { type: TenantConfigSchema },
    isActive: { type: Boolean, default: true, index: true },
  },
  { timestamps: true },
);

// Indexes
TenantSchema.index({ slug: 1 }, { unique: true });
TenantSchema.index({ domain: 1 }, { unique: true, sparse: true });
TenantSchema.index({ adminUserId: 1 });
TenantSchema.index({ isActive: 1 });

// Pre-save hook to generate slug if not provided (runs before validation)
TenantSchema.pre('validate', function (next) {
  if (!this.slug && this.name) {
    this.slug = this.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/^-+|-+$/g, '');
  }
  next();
});

export const TenantModel = model<TenantDocument>('Tenant', TenantSchema);

