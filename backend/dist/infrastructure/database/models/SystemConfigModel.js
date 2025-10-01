"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.SystemConfigModel = void 0;
const mongoose_1 = require("mongoose");
const SystemConfigSchema = new mongoose_1.Schema({
    key: { type: String, required: true, unique: true, index: true },
    value: { type: mongoose_1.Schema.Types.Mixed, required: true },
    description: { type: String },
}, { timestamps: true });
exports.SystemConfigModel = (0, mongoose_1.model)('SystemConfig', SystemConfigSchema);
//# sourceMappingURL=SystemConfigModel.js.map