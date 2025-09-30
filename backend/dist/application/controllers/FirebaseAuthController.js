"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.FirebaseAuthController = void 0;
const AuthUserModel_1 = require("../../infrastructure/database/models/AuthUserModel");
const StudentModel_1 = require("../../infrastructure/database/models/StudentModel");
const ProfessorModel_1 = require("../../infrastructure/database/models/ProfessorModel");
const JwtService_1 = require("../../infrastructure/services/JwtService");
const config_1 = require("../../infrastructure/config");
const Logger_1 = require("../../infrastructure/services/Logger");
class FirebaseAuthController {
    constructor() {
        this.jwtService = new JwtService_1.JwtService(config_1.config.jwtSecret);
        this.logger = new Logger_1.Logger({ controller: 'FirebaseAuthController' });
        // Verificar token de Firebase y crear/actualizar usuario
        this.verifyToken = async (req, res) => {
            try {
                const { idToken } = req.body;
                if (!idToken) {
                    return res.status(400).json({ error: 'ID token is required' });
                }
                // Verificar token con Firebase Admin SDK
                const admin = require('../../infrastructure/auth/firebase').default;
                const decodedToken = await admin.auth().verifyIdToken(idToken);
                // Buscar usuario existente por Firebase UID
                let user = await AuthUserModel_1.AuthUserModel.findOne({ firebaseUid: decodedToken.uid });
                this.logger.debug('User lookup by Firebase UID', { found: Boolean(user) });
                if (user) {
                    // Verificar si ya tiene un registro en students o professors según su rol
                    if (user.role === 'student') {
                        const existingStudent = await StudentModel_1.StudentModel.findOne({ authUserId: user._id });
                        this.logger.debug('Student profile exists', { found: Boolean(existingStudent) });
                        if (!existingStudent) {
                            this.logger.info('Creating missing Student profile for existing user');
                            await StudentModel_1.StudentModel.create({
                                authUserId: user._id,
                                name: user.name || decodedToken.name || 'Usuario',
                                email: user.email,
                                membershipType: 'basic',
                                balance: 0
                            });
                            this.logger.info('Student profile created');
                        }
                    }
                    else if (user.role === 'professor') {
                        const existingProfessor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: user._id });
                        this.logger.debug('Professor profile exists', { found: Boolean(existingProfessor) });
                        if (!existingProfessor) {
                            this.logger.info('Creating missing Professor profile for existing user');
                            await ProfessorModel_1.ProfessorModel.create({
                                authUserId: user._id,
                                name: user.name || decodedToken.name || 'Usuario',
                                email: user.email,
                                phone: '',
                                specialties: [],
                                hourlyRate: 0
                            });
                            this.logger.info('Professor profile created');
                        }
                    }
                }
                else if (!user) {
                    // Buscar por email si no existe Firebase UID
                    user = await AuthUserModel_1.AuthUserModel.findOne({ email: decodedToken.email });
                    this.logger.debug('User lookup by email', { found: Boolean(user) });
                    if (user) {
                        // Vincular Firebase UID a usuario existente
                        this.logger.info('Linking Firebase UID to existing user');
                        user.firebaseUid = decodedToken.uid;
                        await user.save();
                    }
                    else {
                        // Crear nuevo usuario
                        this.logger.info('Creating new AuthUser for Firebase UID');
                        user = await AuthUserModel_1.AuthUserModel.create({
                            firebaseUid: decodedToken.uid,
                            email: decodedToken.email,
                            name: decodedToken.name || 'Usuario',
                            role: 'student' // Por defecto
                        });
                        this.logger.info('AuthUser created');
                        // Crear perfil de estudiante por defecto
                        this.logger.info('Creating Student profile for AuthUser');
                        const student = await StudentModel_1.StudentModel.create({
                            authUserId: user._id,
                            name: decodedToken.name || user.name || 'Usuario',
                            email: decodedToken.email,
                            // phone is optional for Google Sign-In users
                            membershipType: 'basic',
                            balance: 0
                        });
                        this.logger.info('Student created');
                    }
                }
                // Generar tokens JWT propios
                const accessToken = this.jwtService.signAccess({ sub: user._id.toString(), role: user.role });
                const refreshToken = this.jwtService.signRefresh({ sub: user._id.toString(), role: user.role });
                res.json({
                    accessToken,
                    refreshToken,
                    user: {
                        id: user._id,
                        email: user.email,
                        name: user.name,
                        role: user.role
                    }
                });
            }
            catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                this.logger.error('Firebase auth error', { error: message });
                res.status(401).json({ error: 'Invalid token' });
            }
        };
        // Registrar usuario con email/contraseña
        this.registerUser = async (req, res) => {
            try {
                const { name, email, phone, role, firebaseUid } = req.body;
                if (!name || !email || !role || !firebaseUid) {
                    return res.status(400).json({ error: 'Missing required fields' });
                }
                // Verificar si el usuario ya existe
                let user = await AuthUserModel_1.AuthUserModel.findOne({
                    $or: [
                        { firebaseUid: firebaseUid },
                        { email: email }
                    ]
                });
                if (user) {
                    return res.status(409).json({ error: 'User already exists' });
                }
                // Crear nuevo usuario
                this.logger.info('Creating new AuthUser for registration');
                user = await AuthUserModel_1.AuthUserModel.create({
                    firebaseUid: firebaseUid,
                    email: email,
                    name: name,
                    role: role
                });
                this.logger.info('AuthUser created');
                // Crear perfil según el rol
                if (role === 'student') {
                    this.logger.info('Creating Student profile for AuthUser');
                    const student = await StudentModel_1.StudentModel.create({
                        authUserId: user._id,
                        name: name,
                        email: email,
                        phone: phone,
                        membershipType: 'basic',
                        balance: 0
                    });
                    this.logger.info('Student created');
                }
                else if (role === 'professor') {
                    this.logger.info('Creating Professor profile for AuthUser');
                    const professor = await ProfessorModel_1.ProfessorModel.create({
                        authUserId: user._id,
                        name: name,
                        email: email,
                        phone: phone,
                        specialties: [],
                        hourlyRate: 0
                    });
                    this.logger.info('Professor created');
                }
                // Generar tokens JWT
                const accessToken = this.jwtService.signAccess({ sub: user._id.toString(), role: user.role });
                const refreshToken = this.jwtService.signRefresh({ sub: user._id.toString(), role: user.role });
                res.status(201).json({
                    accessToken,
                    refreshToken,
                    user: {
                        id: user._id,
                        email: user.email,
                        name: user.name,
                        role: user.role
                    }
                });
            }
            catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                this.logger.error('Registration error', { error: message });
                res.status(400).json({ error: message });
            }
        };
        // Obtener información del usuario autenticado
        this.getMe = async (req, res) => {
            try {
                const user = await AuthUserModel_1.AuthUserModel.findById(req.user?.id);
                if (!user) {
                    return res.status(404).json({ error: 'User not found' });
                }
                res.json({
                    id: user._id,
                    email: user.email,
                    name: user.name,
                    role: user.role
                });
            }
            catch (error) {
                res.status(400).json({ error: error.message });
            }
        };
    }
}
exports.FirebaseAuthController = FirebaseAuthController;
//# sourceMappingURL=FirebaseAuthController.js.map