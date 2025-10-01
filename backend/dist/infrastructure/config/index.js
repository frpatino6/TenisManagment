"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.config = void 0;
const zod_1 = require("zod");
const EnvSchema = zod_1.z.object({
    NODE_ENV: zod_1.z.enum(['development', 'test', 'production']).default('development'),
    PORT: zod_1.z.coerce.number().int().positive().default(3000),
    MONGO_URI: zod_1.z.string().min(1).default('mongodb://localhost:27017/tennis_mgmt'),
    JWT_SECRET: zod_1.z.string().min(10, 'JWT_SECRET must be at least 10 characters'),
    FIREBASE_PROJECT_ID: zod_1.z.string().optional(),
    FIREBASE_PRIVATE_KEY: zod_1.z.string().optional(),
    FIREBASE_CLIENT_EMAIL: zod_1.z.string().optional(),
    CORS_ORIGINS: zod_1.z.string().optional(), // comma-separated
    JSON_LIMIT: zod_1.z.string().default('1mb'),
    RATE_LIMIT_WINDOW_MS: zod_1.z.coerce
        .number()
        .int()
        .positive()
        .default(15 * 60 * 1000),
    RATE_LIMIT_MAX: zod_1.z.coerce.number().int().positive().default(100),
    RATE_LIMIT_AUTH_MAX: zod_1.z.coerce.number().int().positive().default(20),
});
const parsed = EnvSchema.safeParse(process.env);
if (!parsed.success) {
    const issues = parsed.error.issues.map((i) => `${i.path.join('.')}: ${i.message}`).join('; ');
    throw new Error(`Invalid environment configuration: ${issues}`);
}
const env = parsed.data;
const firebaseEnabled = Boolean(env.FIREBASE_PROJECT_ID && env.FIREBASE_PRIVATE_KEY && env.FIREBASE_CLIENT_EMAIL);
exports.config = {
    nodeEnv: env.NODE_ENV,
    port: env.PORT,
    mongoUri: env.MONGO_URI,
    jwtSecret: env.JWT_SECRET,
    http: {
        corsOrigins: env.CORS_ORIGINS?.split(',')
            .map((o) => o.trim())
            .filter(Boolean) ?? [],
        jsonLimit: env.JSON_LIMIT,
        rateLimit: {
            windowMs: env.RATE_LIMIT_WINDOW_MS,
            max: env.RATE_LIMIT_MAX,
            authMax: env.RATE_LIMIT_AUTH_MAX,
        },
    },
    firebase: {
        enabled: firebaseEnabled,
        projectId: env.FIREBASE_PROJECT_ID,
        privateKey: env.FIREBASE_PRIVATE_KEY,
        clientEmail: env.FIREBASE_CLIENT_EMAIL,
    },
};
//# sourceMappingURL=index.js.map