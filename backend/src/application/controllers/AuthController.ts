import { Request, Response } from 'express';
import { BcryptPasswordService } from '../../infrastructure/services/PasswordService';
import { JwtService } from '../../infrastructure/services/JwtService';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { LoginSchema, RegisterSchema } from '../dtos/auth';

export class AuthController {
  constructor(
    private readonly jwt: JwtService,
    private readonly passwordSvc = new BcryptPasswordService(),
  ) {}

  register = async (req: Request, res: Response) => {
    const parsed = RegisterSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
    const { email, password, role, profile } = parsed.data;
    const existing = await AuthUserModel.findOne({ email });
    if (existing) return res.status(409).json({ error: 'Email already used' });
    const passwordHash = await this.passwordSvc.hash(password);

    // Create AuthUser first (required for Professor/Student models)
    const user = await AuthUserModel.create({ 
      email, 
      passwordHash, 
      role,
      name: profile.name,
    });

    // Create profile with authUserId reference
    let linkedId;
    if (role === 'professor') {
      const prof = await ProfessorModel.create({
        authUserId: user._id, // Required field
        name: profile.name,
        email,
        phone: profile.phone,
        specialties: profile.specialties ?? [],
        hourlyRate: profile.hourlyRate ?? 0,
        experienceYears: 0, // Default value
      });
      linkedId = prof._id;
    } else {
      const student = await StudentModel.create({
        authUserId: user._id, // Required field
        name: profile.name,
        email,
        phone: profile.phone,
        membershipType: profile.membershipType ?? 'basic',
        balance: 0,
      });
      linkedId = student._id;
    }

    // Update AuthUser with linkedId (optional, for backward compatibility)
    user.linkedId = linkedId;
    const access = this.jwt.signAccess({ sub: user._id.toString(), role });
    const refresh = this.jwt.signRefresh({ sub: user._id.toString(), role });
    user.refreshToken = refresh;
    await user.save();
    return res.status(201).json({ accessToken: access, refreshToken: refresh });
  };

  login = async (req: Request, res: Response) => {
    const parsed = LoginSchema.safeParse(req.body);
    if (!parsed.success) return res.status(400).json({ error: 'Invalid body' });
    const { email, password } = parsed.data;
    const user = await AuthUserModel.findOne({ email });
    if (!user) return res.status(401).json({ error: 'Invalid credentials' });
    const valid = await this.passwordSvc.compare(password, user.passwordHash || '');
    if (!valid) return res.status(401).json({ error: 'Invalid credentials' });
    const access = this.jwt.signAccess({ sub: user._id.toString(), role: user.role });
    const refresh = this.jwt.signRefresh({ sub: user._id.toString(), role: user.role });
    user.refreshToken = refresh;
    await user.save();
    return res.json({ accessToken: access, refreshToken: refresh });
  };

  refresh = async (req: Request, res: Response) => {
    const token = req.body?.refreshToken as string | undefined;
    if (!token) return res.status(400).json({ error: 'Missing refreshToken' });
    try {
      const payload = this.jwt.verify(token);
      const user = await AuthUserModel.findById(payload.sub);
      if (!user || user.refreshToken !== token)
        return res.status(401).json({ error: 'Invalid refresh token' });
      const access = this.jwt.signAccess({ sub: user._id.toString(), role: user.role });
      const refresh = this.jwt.signRefresh({ sub: user._id.toString(), role: user.role });
      user.refreshToken = refresh;
      await user.save();
      return res.json({ accessToken: access, refreshToken: refresh });
    } catch {
      return res.status(401).json({ error: 'Invalid refresh token' });
    }
  };
}
