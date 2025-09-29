"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ProfessorModel = void 0;
const mongoose_1 = require("mongoose");
const ProfessorSchema = new mongoose_1.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    phone: { type: String, required: true },
    specialties: { type: [String], default: [] },
    hourlyRate: { type: Number, required: true }
}, { timestamps: true });
exports.ProfessorModel = (0, mongoose_1.model)('Professor', ProfessorSchema);
//# sourceMappingURL=ProfessorModel.js.map