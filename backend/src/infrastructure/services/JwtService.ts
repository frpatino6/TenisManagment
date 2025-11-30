import jwt, { SignOptions } from 'jsonwebtoken';
import { UserRole } from '../database/models/AuthUserModel';

export interface JwtPayload {
  sub: string;
  role: UserRole;
}

export class JwtService {
  constructor(private readonly secret: string) {}

  signAccess(payload: JwtPayload, expiresIn: number = 15 * 60): string {
    const options: SignOptions = { expiresIn };
    return jwt.sign(payload, this.secret, options);
  }

  signRefresh(payload: JwtPayload, expiresIn: number = 7 * 24 * 60 * 60): string {
    const options: SignOptions = { expiresIn };
    return jwt.sign(payload, this.secret, options);
  }

  verify(token: string): JwtPayload {
    return jwt.verify(token, this.secret) as JwtPayload;
  }
}
