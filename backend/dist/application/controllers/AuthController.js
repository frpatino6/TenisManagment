"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.AuthController = void 0;
const PasswordService_1 = require("../../infrastructure/services/PasswordService");
const AuthUserModel_1 = require("../../infrastructure/database/models/AuthUserModel");
const ProfessorModel_1 = require("../../infrastructure/database/models/ProfessorModel");
const StudentModel_1 = require("../../infrastructure/database/models/StudentModel");
const auth_1 = require("../dtos/auth");
class AuthController {
    constructor(jwt, passwordSvc = new PasswordService_1.BcryptPasswordService()) {
        this.jwt = jwt;
        this.passwordSvc = passwordSvc;
        this.register = async (req, res) => {
            const parsed = auth_1.RegisterSchema.safeParse(req.body);
            if (!parsed.success)
                return res.status(400).json({ error: 'Invalid body' });
            const { email, password, role, profile } = parsed.data;
            const existing = await AuthUserModel_1.AuthUserModel.findOne({ email });
            if (existing)
                return res.status(409).json({ error: 'Email already used' });
            const passwordHash = await this.passwordSvc.hash(password);
            let linkedId;
            if (role === 'professor') {
                const prof = await ProfessorModel_1.ProfessorModel.create({
                    name: profile.name,
                    email,
                    phone: profile.phone,
                    specialties: profile.specialties ?? [],
                    hourlyRate: profile.hourlyRate ?? 0
                });
                linkedId = prof._id;
            }
            else {
                const student = await StudentModel_1.StudentModel.create({
                    name: profile.name,
                    email,
                    phone: profile.phone,
                    membershipType: profile.membershipType ?? 'basic',
                    balance: 0
                });
                linkedId = student._id;
            }
            const user = await AuthUserModel_1.AuthUserModel.create({ email, passwordHash, role, linkedId });
            const access = this.jwt.signAccess({ sub: user._id.toString(), role });
            const refresh = this.jwt.signRefresh({ sub: user._id.toString(), role });
            user.refreshToken = refresh;
            await user.save();
            return res.status(201).json({ accessToken: access, refreshToken: refresh });
        };
        this.login = async (req, res) => {
            const parsed = auth_1.LoginSchema.safeParse(req.body);
            if (!parsed.success)
                return res.status(400).json({ error: 'Invalid body' });
            const { email, password } = parsed.data;
            const user = await AuthUserModel_1.AuthUserModel.findOne({ email });
            if (!user)
                return res.status(401).json({ error: 'Invalid credentials' });
            const valid = await this.passwordSvc.compare(password, user.passwordHash || '');
            if (!valid)
                return res.status(401).json({ error: 'Invalid credentials' });
            const access = this.jwt.signAccess({ sub: user._id.toString(), role: user.role });
            const refresh = this.jwt.signRefresh({ sub: user._id.toString(), role: user.role });
            user.refreshToken = refresh;
            await user.save();
            return res.json({ accessToken: access, refreshToken: refresh });
        };
        this.refresh = async (req, res) => {
            const token = req.body?.refreshToken;
            if (!token)
                return res.status(400).json({ error: 'Missing refreshToken' });
            try {
                const payload = this.jwt.verify(token);
                const user = await AuthUserModel_1.AuthUserModel.findById(payload.sub);
                if (!user || user.refreshToken !== token)
                    return res.status(401).json({ error: 'Invalid refresh token' });
                const access = this.jwt.signAccess({ sub: user._id.toString(), role: user.role });
                const refresh = this.jwt.signRefresh({ sub: user._id.toString(), role: user.role });
                user.refreshToken = refresh;
                await user.save();
                return res.json({ accessToken: access, refreshToken: refresh });
            }
            catch {
                return res.status(401).json({ error: 'Invalid refresh token' });
            }
        };
    }
}
exports.AuthController = AuthController;
//# sourceMappingURL=AuthController.js.map