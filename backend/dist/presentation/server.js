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
const config_1 = require("../infrastructure/config");
const app = (0, express_1.default)();
// Security middlewares
app.use((0, helmet_1.default)());
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
// Health check
app.get('/health', (_req, res) => {
    res.status(200).json({ status: 'ok' });
});
// Global error handler
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err, _req, res, _next) => {
    const message = err instanceof Error ? err.message : 'Unknown error';
    res.status(500).json({ error: message });
});
const PORT = config_1.config.port;
const MONGO_URI = config_1.config.mongoUri;
async function start() {
    try {
        await mongoose_1.default.connect(MONGO_URI);
        console.log('Connected to MongoDB');
        app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
    }
    catch (error) {
        console.error('Failed to start server', error);
        process.exit(1);
    }
}
void start();
//# sourceMappingURL=server.js.map