export function authMiddleware(jwtService) {
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
export function requireRole(role) {
    return (req, res, next) => {
        if (!req.user || req.user.role !== role)
            return res.status(403).json({ error: 'Forbidden' });
        next();
    };
}
//# sourceMappingURL=auth.js.map