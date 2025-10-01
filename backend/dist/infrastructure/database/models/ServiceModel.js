"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ServiceModel = void 0;
const mongoose_1 = require("mongoose");
const ServiceSchema = new mongoose_1.Schema({
    name: { type: String, required: true },
    description: { type: String, required: true },
    price: { type: Number, required: true },
    category: { type: String, enum: ['stringing', 'grip', 'other'], required: true },
}, { timestamps: true });
exports.ServiceModel = (0, mongoose_1.model)('Service', ServiceSchema);
//# sourceMappingURL=ServiceModel.js.map