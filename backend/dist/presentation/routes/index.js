"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const auth_1 = __importDefault(require("./auth"));
const professor_1 = __importDefault(require("./professor"));
const professor_dashboard_1 = __importDefault(require("./professor-dashboard"));
const analytics_1 = __importDefault(require("./analytics"));
const student_1 = __importDefault(require("./student"));
const pricing_1 = __importDefault(require("./pricing"));
const router = (0, express_1.Router)();
// Placeholder routers to be mounted later
router.get('/', (_req, res) => {
    res.json({ message: 'API ready' });
});
router.use('/auth', auth_1.default);
router.use('/professor', professor_1.default);
router.use('/professor-dashboard', professor_dashboard_1.default);
router.use('/professor-dashboard/analytics', analytics_1.default);
router.use('/student', student_1.default);
router.use('/pricing', pricing_1.default);
exports.default = router;
//# sourceMappingURL=index.js.map