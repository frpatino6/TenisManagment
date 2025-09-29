"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthUserModel = void 0;
const mongoose_1 = require("mongoose");
const AuthUserSchema = new mongoose_1.Schema({
    email: { type: String, required: true, unique: true, index: true },
    passwordHash: { type: String },
    role: { type: String, enum: ['professor', 'student'], required: true },
    linkedId: { type: mongoose_1.Schema.Types.ObjectId },
    refreshToken: { type: String },
    firebaseUid: { type: String, unique: true, sparse: true },
    name: { type: String }
}, { timestamps: true });
exports.AuthUserModel = (0, mongoose_1.model)('AuthUser', AuthUserSchema);
//# sourceMappingURL=AuthUserModel.js.map