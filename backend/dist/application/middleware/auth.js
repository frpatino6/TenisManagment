"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
exports.requireRole = requireRole;
exports.requireSuperAdmin = requireSuperAdmin;
function authMiddleware(jwtService) {
    return (req, res, next) => {
        const header = req.headers.authorization;
        if (!header || !header.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'Unauthorized' });
        }
        const token = header.substring(7);
        try {
            const payload = jwtService.verify(token);
            req.user = { id: payload.sub, role: payload.role };
            next();
        }
        catch {
            return res.status(401).json({ error: 'Invalid token' });
        }
    };
}
function requireRole(role) {
    return (req, res, next) => {
        if (!req.user || req.user.role !== role)
            return res.status(403).json({ error: 'Forbidden' });
        next();
    };
}
/**
 * Middleware para requerir rol de Super Admin
 * TEN-87: MT-BACK-005
 */
function requireSuperAdmin(req, res, next) {
    if (!req.user) {
        res.status(401).json({ error: 'No autenticado' });
        return;
    }
    if (req.user.role !== 'super_admin') {
        res.status(403).json({ error: 'Solo Super Admin puede acceder a este recurso' });
        return;
    }
    next();
}
//# sourceMappingURL=auth.js.map