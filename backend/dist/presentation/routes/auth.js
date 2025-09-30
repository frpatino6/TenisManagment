"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const AuthController_1 = require("../../application/controllers/AuthController");
const JwtService_1 = require("../../infrastructure/services/JwtService");
const validation_1 = require("../../application/middleware/validation");
const auth_1 = require("../../application/dtos/auth");
const config_1 = require("../../infrastructure/config");
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const router = (0, express_1.Router)();
const jwt = new JwtService_1.JwtService(config_1.config.jwtSecret);
const controller = new AuthController_1.AuthController(jwt);
// Stricter rate limit for auth endpoints
const authLimiter = (0, express_rate_limit_1.default)({ windowMs: config_1.config.http.rateLimit.windowMs, max: config_1.config.http.rateLimit.authMax });
router.use(authLimiter);
router.post('/login', (0, validation_1.validateBody)(auth_1.LoginSchema), controller.login);
router.post('/register', (0, validation_1.validateBody)(auth_1.RegisterSchema), controller.register);
router.post('/refresh', controller.refresh);
exports.default = router;
//# sourceMappingURL=auth.js.map