"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.StudentModel = void 0;
const mongoose_1 = require("mongoose");
const StudentSchema = new mongoose_1.Schema({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true, index: true },
    phone: { type: String, required: true },
    membershipType: { type: String, enum: ['basic', 'premium'], required: true },
    balance: { type: Number, default: 0 }
}, { timestamps: true });
exports.StudentModel = (0, mongoose_1.model)('Student', StudentSchema);
//# sourceMappingURL=StudentModel.js.map