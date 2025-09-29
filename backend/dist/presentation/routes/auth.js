"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const AuthController_1 = require("../../application/controllers/AuthController");
const JwtService_1 = require("../../infrastructure/services/JwtService");
const validation_1 = require("../../application/middleware/validation");
const auth_1 = require("../../application/dtos/auth");
const router = (0, express_1.Router)();
const jwt = new JwtService_1.JwtService(process.env.JWT_SECRET || 'dev_secret');
const controller = new AuthController_1.AuthController(jwt);
router.post('/login', (0, validation_1.validateBody)(auth_1.LoginSchema), controller.login);
router.post('/register', (0, validation_1.validateBody)(auth_1.RegisterSchema), controller.register);
router.post('/refresh', controller.refresh);
exports.default = router;
//# sourceMappingURL=auth.js.map