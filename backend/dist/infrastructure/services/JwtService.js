"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.JwtService = void 0;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
class JwtService {
    constructor(secret) {
        this.secret = secret;
    }
    signAccess(payload, expiresIn = 15 * 60) {
        const options = { expiresIn };
        return jsonwebtoken_1.default.sign(payload, this.secret, options);
    }
    signRefresh(payload, expiresIn = 7 * 24 * 60 * 60) {
        const options = { expiresIn };
        return jsonwebtoken_1.default.sign(payload, this.secret, options);
    }
    verify(token) {
        return jsonwebtoken_1.default.verify(token, this.secret);
    }
}
exports.JwtService = JwtService;
//# sourceMappingURL=JwtService.js.map