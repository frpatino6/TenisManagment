"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const ProfessorDashboardController_1 = require("../../application/controllers/ProfessorDashboardController");
const ProfessorController_1 = require("../../application/controllers/ProfessorController");
const firebaseAuth_1 = require("../../application/middleware/firebaseAuth");
const router = (0, express_1.Router)();
const professorDashboardController = new ProfessorDashboardController_1.ProfessorDashboardController();
const professorController = new ProfessorController_1.ProfessorController();
// Middleware para verificar autenticación con Firebase
router.use(firebaseAuth_1.firebaseAuthMiddleware);
// Rutas del dashboard del profesor
router.get('/me', professorDashboardController.getProfessorInfo);
router.put('/profile', professorDashboardController.updateProfile);
router.get('/students', professorController.listStudents);
exports.default = router;
//# sourceMappingURL=professor-dashboard.js.map