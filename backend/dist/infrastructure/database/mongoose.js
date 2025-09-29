"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.mongoose = void 0;
exports.connectMongo = connectMongo;
const mongoose_1 = __importDefault(require("mongoose"));
exports.mongoose = mongoose_1.default;
async function connectMongo(uri) {
    await mongoose_1.default.connect(uri);
}
//# sourceMappingURL=mongoose.js.map