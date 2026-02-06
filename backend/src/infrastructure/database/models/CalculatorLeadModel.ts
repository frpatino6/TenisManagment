import { Schema, model, Document, Types } from 'mongoose';

export interface CalculatorLeadDocument extends Document {
    _id: Types.ObjectId;
    clubName: string;
    email: string;
    monthlyLoss: number;
    canchas: number;
    tarifa: number;
    cancelacionesSemanales: number;
    horasGestionManual: number;
    createdAt: Date;
}

const CalculatorLeadSchema = new Schema<CalculatorLeadDocument>(
    {
        clubName: { type: String, required: true },
        email: { type: String, required: true, index: true },
        monthlyLoss: { type: Number, required: true },
        canchas: { type: Number, required: true },
        tarifa: { type: Number, required: true },
        cancelacionesSemanales: { type: Number, required: true },
        horasGestionManual: { type: Number, required: true },
    },
    { timestamps: true }
);

export const CalculatorLeadModel = model<CalculatorLeadDocument>(
    'CalculatorLead',
    CalculatorLeadSchema
);
