"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ScheduleModel = void 0;
const mongoose_1 = require("mongoose");
const ScheduleSchema = new mongoose_1.Schema({
    professorId: { type: mongoose_1.Schema.Types.ObjectId, ref: 'Professor', required: true, index: true },
    date: { type: Date, required: true, index: true },
    startTime: { type: String, required: true },
    endTime: { type: String, required: true },
    type: { type: String, enum: ['individual', 'group', 'court_rental'], required: true },
    isAvailable: { type: Boolean, default: true, index: true },
    maxStudents: { type: Number }
}, { timestamps: true });
ScheduleSchema.index({ date: 1, professorId: 1, isAvailable: 1 });
exports.ScheduleModel = (0, mongoose_1.model)('Schedule', ScheduleSchema);
//# sourceMappingURL=ScheduleModel.js.map