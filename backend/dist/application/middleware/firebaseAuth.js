"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.firebaseAuthMiddleware = void 0;
const firebase_1 = __importDefault(require("../../infrastructure/auth/firebase"));
const AuthUserModel_1 = require("../../infrastructure/database/models/AuthUserModel");
const Logger_1 = require("../../infrastructure/services/Logger");
const logger = new Logger_1.Logger({ module: 'firebaseAuthMiddleware' });
const firebaseAuthMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            logger.warn('Missing or invalid authorization header');
            return res.status(401).json({ error: 'No token provided' });
        }
        const idToken = authHeader.split('Bearer ')[1];
        logger.debug('Verifying Firebase token');
        // Verificar token con Firebase
        const decodedToken = await firebase_1.default.auth().verifyIdToken(idToken);
        logger.info('Token verified');
        // Buscar usuario en la base de datos por firebaseUid
        const user = await AuthUserModel_1.AuthUserModel.findOne({ firebaseUid: decodedToken.uid });
        logger.debug('User lookup by firebaseUid', { found: Boolean(user) });
        if (!user) {
            logger.warn('User not found for Firebase UID');
            return res.status(404).json({ error: 'User not found' });
        }
        logger.debug('User authenticated');
        // Agregar información del usuario a la request
        req.user = {
            id: user._id.toString(),
            role: user.role,
            uid: decodedToken.uid
        };
        logger.debug('Next middleware');
        next();
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error('Firebase auth error', { error: message });
        res.status(401).json({ error: 'Invalid token' });
    }
};
exports.firebaseAuthMiddleware = firebaseAuthMiddleware;
//# sourceMappingURL=firebaseAuth.js.map