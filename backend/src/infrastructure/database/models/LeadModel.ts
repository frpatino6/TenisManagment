import { Schema, model, Document, Types } from 'mongoose';

export type LeadStatus = 'nuevo' | 'contactado' | 'descartado';

export interface LeadDocument extends Document {
    _id: Types.ObjectId;
    clubName: string;
    contactName: string;
    email: string;
    phone: string;
    status: LeadStatus;
    createdAt: Date;
    updatedAt: Date;
}

const LeadSchema = new Schema<LeadDocument>(
    {
        clubName: { type: String, required: true },
        contactName: { type: String, required: true },
        email: { type: String, required: true, index: true },
        phone: { type: String, required: true },
        status: {
            type: String,
            enum: ['nuevo', 'contactado', 'descartado'],
            default: 'nuevo',
            required: true,
        },
    },
    { timestamps: true }
);

export const LeadModel = model<LeadDocument>('Lead', LeadSchema);
