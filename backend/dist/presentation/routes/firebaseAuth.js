"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const FirebaseAuthController_1 = require("../../application/controllers/FirebaseAuthController");
const firebaseAuth_1 = require("../../application/middleware/firebaseAuth");
const router = (0, express_1.Router)();
const firebaseAuthController = new FirebaseAuthController_1.FirebaseAuthController();
// Verificar token de Firebase
router.post('/verify', firebaseAuthController.verifyToken);
// Obtener información del usuario autenticado
router.get('/me', firebaseAuth_1.firebaseAuthMiddleware, firebaseAuthController.getMe);
exports.default = router;
//# sourceMappingURL=firebaseAuth.js.map