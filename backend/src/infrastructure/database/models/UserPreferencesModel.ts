import { Schema, model, Types } from 'mongoose';

/**
 * UserPreferences document interface
 * Stores user preferences like favorite professors and tenants
 */
export interface UserPreferencesDocument {
  _id: Types.ObjectId;
  userId: Types.ObjectId; // Reference to AuthUser
  favoriteProfessors: Types.ObjectId[]; // Array of Professor IDs
  favoriteTenants: Types.ObjectId[]; // Array of Tenant IDs
  createdAt: Date;
  updatedAt: Date;
}

const UserPreferencesSchema = new Schema<UserPreferencesDocument>(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'AuthUser',
      required: true,
      unique: true,
      index: true,
    },
    favoriteProfessors: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Professor',
      },
    ],
    favoriteTenants: [
      {
        type: Schema.Types.ObjectId,
        ref: 'Tenant',
      },
    ],
  },
  { timestamps: true },
);

// Indexes
UserPreferencesSchema.index({ userId: 1 }, { unique: true });
UserPreferencesSchema.index({ 'favoriteProfessors': 1 });
UserPreferencesSchema.index({ 'favoriteTenants': 1 });

export const UserPreferencesModel = model<UserPreferencesDocument>(
  'UserPreferences',
  UserPreferencesSchema,
);

