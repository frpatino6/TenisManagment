"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.firebaseAuthMiddleware = void 0;
const firebase_1 = __importDefault(require("../../infrastructure/auth/firebase"));
const firebaseAuthMiddleware = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'No token provided' });
        }
        const idToken = authHeader.split('Bearer ')[1];
        // Verificar token con Firebase
        const decodedToken = await firebase_1.default.auth().verifyIdToken(idToken);
        // Agregar información del usuario a la request
        req.user = {
            id: decodedToken.uid,
            role: 'student' // Por defecto, se puede mejorar después
        };
        next();
    }
    catch (error) {
        console.error('Firebase auth error:', error);
        res.status(401).json({ error: 'Invalid token' });
    }
};
exports.firebaseAuthMiddleware = firebaseAuthMiddleware;
//# sourceMappingURL=firebaseAuth.js.map