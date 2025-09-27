import { Schema, model } from 'mongoose';
const ServiceSchema = new Schema({
    name: { type: String, required: true },
    description: { type: String, required: true },
    price: { type: Number, required: true },
    category: { type: String, enum: ['stringing', 'grip', 'other'], required: true }
}, { timestamps: true });
export const ServiceModel = model('Service', ServiceSchema);
//# sourceMappingURL=ServiceModel.js.map