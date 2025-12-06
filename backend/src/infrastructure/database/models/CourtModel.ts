/**
 * Court Model
 * TEN-88: MT-BACK-006
 *
 * Modelo para representar canchas/instalaciones de un tenant
 */

import { Schema, model, Types } from 'mongoose';

export interface CourtDocument {
  _id: Types.ObjectId;
  tenantId: Types.ObjectId; // Reference to Tenant (required for multi-tenancy)
  name: string; // Nombre de la cancha (ej: "Cancha 1", "Cancha Central")
  type: 'tennis' | 'padel' | 'multi'; // Tipo de cancha
  price: number; // Precio por hora de alquiler
  isActive: boolean; // Si la cancha está disponible para reservas
  description?: string; // Descripción opcional
  features?: string[]; // Características (ej: ["techada", "iluminación", "vestuarios"])
  createdAt: Date;
  updatedAt: Date;
}

const CourtSchema = new Schema<CourtDocument>(
  {
    tenantId: {
      type: Schema.Types.ObjectId,
      ref: 'Tenant',
      required: true,
      index: true,
    },
    name: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: ['tennis', 'padel', 'multi'],
      required: true,
      default: 'tennis',
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },
    description: {
      type: String,
      trim: true,
    },
    features: {
      type: [String],
      default: [],
    },
  },
  { timestamps: true },
);

// Índices compuestos
CourtSchema.index({ tenantId: 1, isActive: 1 });
CourtSchema.index({ tenantId: 1, name: 1 }, { unique: true }); // Nombre único por tenant

export const CourtModel = model<CourtDocument>('Court', CourtSchema);

