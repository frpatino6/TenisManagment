import jwt from 'jsonwebtoken';

export interface JwtPayload {
  sub: string;
  role: 'professor' | 'student';
}

export class JwtService {
  constructor(private readonly secret: string) {}

  signAccess(payload: JwtPayload, expiresIn: string = '15m'): string {
    return jwt.sign(payload, this.secret, { expiresIn });
  }

  signRefresh(payload: JwtPayload, expiresIn: string = '7d'): string {
    return jwt.sign(payload, this.secret, { expiresIn });
  }

  verify(token: string): JwtPayload {
    return jwt.verify(token, this.secret) as JwtPayload;
  }
}

