"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
require("reflect-metadata");
require("dotenv/config");
const express_1 = __importDefault(require("express"));
const helmet_1 = __importDefault(require("helmet"));
const cors_1 = __importDefault(require("cors"));
const express_rate_limit_1 = __importDefault(require("express-rate-limit"));
const mongoose_1 = __importDefault(require("mongoose"));
const index_1 = __importDefault(require("./routes/index"));
const firebaseAuth_1 = __importDefault(require("./routes/firebaseAuth"));
const professorDashboard_1 = __importDefault(require("./routes/professorDashboard"));
const studentDashboard_1 = __importDefault(require("./routes/studentDashboard"));
const config_1 = require("../infrastructure/config");
const Logger_1 = require("../infrastructure/services/Logger");
const requestId_1 = require("../application/middleware/requestId");
const app = (0, express_1.default)();
const logger = new Logger_1.Logger({ service: 'backend', env: config_1.config.nodeEnv });
// Security middlewares
app.use((0, helmet_1.default)());
app.use(requestId_1.requestIdMiddleware);
// CORS with allowlist
const allowedOrigins = new Set(config_1.config.http.corsOrigins);
app.use((0, cors_1.default)({
    origin: allowedOrigins.size > 0 ? (origin, callback) => {
        if (!origin || allowedOrigins.has(origin))
            return callback(null, true);
        return callback(new Error('Not allowed by CORS'));
    } : true
}));
// JSON body limit
app.use(express_1.default.json({ limit: config_1.config.http.jsonLimit }));
// Global rate limit
const limiter = (0, express_rate_limit_1.default)({ windowMs: config_1.config.http.rateLimit.windowMs, max: config_1.config.http.rateLimit.max });
app.use(limiter);
// API routes
app.use('/api', index_1.default);
app.use('/api/auth/firebase', firebaseAuth_1.default);
app.use('/api/professor-dashboard', professorDashboard_1.default);
app.use('/api/student-dashboard', studentDashboard_1.default);
// Health check
app.get('/health', (req, res) => {
    res.status(200).json({ status: 'ok', requestId: req.requestId });
});
// Global error handler
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err, req, res, _next) => {
    const message = err instanceof Error ? err.message : 'Unknown error';
    logger.error('Unhandled error', { requestId: req.requestId, error: message });
    res.status(500).json({ error: 'Internal server error', requestId: req.requestId });
});
const PORT = config_1.config.port;
const MONGO_URI = config_1.config.mongoUri;
async function start() {
    try {
        await mongoose_1.default.connect(MONGO_URI);
        logger.info('Connected to MongoDB');
        app.listen(PORT, () => logger.info('Server started', { port: PORT }));
    }
    catch (error) {
        logger.error('Failed to start server', { error: error instanceof Error ? error.message : String(error) });
        process.exit(1);
    }
}
void start();
//# sourceMappingURL=server.js.map