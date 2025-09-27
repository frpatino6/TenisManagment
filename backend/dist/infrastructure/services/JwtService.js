import jwt from 'jsonwebtoken';
export class JwtService {
    constructor(secret) {
        this.secret = secret;
    }
    signAccess(payload, expiresIn = 15 * 60) {
        const options = { expiresIn };
        return jwt.sign(payload, this.secret, options);
    }
    signRefresh(payload, expiresIn = 7 * 24 * 60 * 60) {
        const options = { expiresIn };
        return jwt.sign(payload, this.secret, options);
    }
    verify(token) {
        return jwt.verify(token, this.secret);
    }
}
//# sourceMappingURL=JwtService.js.map