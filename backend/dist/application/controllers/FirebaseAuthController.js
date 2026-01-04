"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.FirebaseAuthController = void 0;
const AuthUserModel_1 = require("../../infrastructure/database/models/AuthUserModel");
const StudentModel_1 = require("../../infrastructure/database/models/StudentModel");
const ProfessorModel_1 = require("../../infrastructure/database/models/ProfessorModel");
const JwtService_1 = require("../../infrastructure/services/JwtService");
const config_1 = require("../../infrastructure/config");
const Logger_1 = require("../../infrastructure/services/Logger");
const firebase_1 = __importDefault(require("../../infrastructure/auth/firebase"));
class FirebaseAuthController {
    constructor() {
        this.jwtService = new JwtService_1.JwtService(config_1.config.jwtSecret);
        this.logger = new Logger_1.Logger({ controller: 'FirebaseAuthController' });
        // Verificar token de Firebase y crear/actualizar usuario
        this.verifyToken = async (req, res) => {
            try {
                if (!config_1.config.firebase.enabled) {
                    return res.status(503).json({ error: 'Firebase auth disabled' });
                }
                const { idToken } = req.body;
                if (!idToken) {
                    this.logger.warn('verifyToken called without idToken');
                    return res.status(400).json({ error: 'ID token is required' });
                }
                this.logger.info('Verifying Firebase token', { tokenLength: idToken.length });
                // Verificar token con Firebase Admin SDK
                let decodedToken;
                try {
                    decodedToken = await firebase_1.default.auth().verifyIdToken(idToken);
                    this.logger.info('Token verified successfully', { uid: decodedToken.uid, email: decodedToken.email });
                }
                catch (verifyError) {
                    this.logger.error('Token verification failed', {
                        error: verifyError.message,
                        code: verifyError.code
                    });
                    return res.status(401).json({
                        error: 'Token inválido o expirado',
                        details: verifyError.message || 'El token de Firebase no pudo ser verificado'
                    });
                }
                // Buscar usuario existente por Firebase UID
                let user = await AuthUserModel_1.AuthUserModel.findOne({ firebaseUid: decodedToken.uid });
                if (user) {
                    // Verificar si ya tiene un registro en students o professors según su rol
                    if (user.role === 'student') {
                        const existingStudent = await StudentModel_1.StudentModel.findOne({ authUserId: user._id });
                        if (!existingStudent) {
                            this.logger.info('Creating missing Student profile for existing user');
                            await StudentModel_1.StudentModel.create({
                                authUserId: user._id,
                                name: user.name || decodedToken.name || 'Usuario',
                                email: user.email,
                                membershipType: 'basic',
                                balance: 0,
                            });
                            this.logger.info('Student profile created');
                        }
                    }
                    else if (user.role === 'professor') {
                        const existingProfessor = await ProfessorModel_1.ProfessorModel.findOne({ authUserId: user._id });
                        if (!existingProfessor) {
                            this.logger.info('Creating missing Professor profile for existing user');
                            await ProfessorModel_1.ProfessorModel.create({
                                authUserId: user._id,
                                name: user.name || decodedToken.name || 'Usuario',
                                email: user.email,
                                phone: '',
                                specialties: [],
                                hourlyRate: 0,
                            });
                            this.logger.info('Professor profile created');
                        }
                    }
                }
                else if (!user) {
                    // Buscar por email si no existe Firebase UID
                    user = await AuthUserModel_1.AuthUserModel.findOne({ email: decodedToken.email });
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
                            role: 'student', // Por defecto
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
                            balance: 0,
                        });
                        this.logger.info('Student created');
                    }
                }
                // Generar tokens JWT propios
                const accessToken = this.jwtService.signAccess({ sub: user._id.toString(), role: user.role });
                const refreshToken = this.jwtService.signRefresh({
                    sub: user._id.toString(),
                    role: user.role,
                });
                res.json({
                    accessToken,
                    refreshToken,
                    user: {
                        id: user._id,
                        email: user.email,
                        name: user.name,
                        role: user.role,
                    },
                });
            }
            catch (error) {
                const message = error instanceof Error ? error.message : String(error);
                const code = error?.code || 'unknown';
                const stack = error instanceof Error ? error.stack : undefined;
                this.logger.error('Firebase auth error in verifyToken', {
                    error: message,
                    code,
                    stack: stack?.split('\n').slice(0, 5).join('\n')
                });
                // Mensajes más específicos según el tipo de error
                let errorMessage = 'Error de autenticación';
                let statusCode = 401;
                if (code === 'auth/id-token-expired' || message.includes('expired')) {
                    errorMessage = 'El token ha expirado. Por favor, inicia sesión nuevamente.';
                }
                else if (code === 'auth/argument-error' || message.includes('malformed')) {
                    errorMessage = 'El token es inválido o está malformado.';
                }
                else if (code === 'auth/invalid-credential' || message.includes('credential')) {
                    errorMessage = 'Las credenciales son incorrectas o han expirado.';
                }
                else {
                    errorMessage = `Error de autenticación: ${message}`;
                }
                res.status(statusCode).json({ error: errorMessage, details: message });
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
                    $or: [{ firebaseUid: firebaseUid }, { email: email }],
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
                    role: role,
                });
                this.logger.info('AuthUser created');
                // Crear perfil según el rol
                if (role === 'student') {
                    this.logger.info('Creating Student profile for AuthUser');
                    try {
                        const student = await StudentModel_1.StudentModel.create({
                            authUserId: user._id,
                            name: name,
                            email: email,
                            phone: phone,
                            membershipType: 'basic',
                            balance: 0,
                        });
                        this.logger.info('Student created', { studentId: student._id.toString() });
                    }
                    catch (error) {
                        this.logger.error('Error creating Student profile', { error: error.message, stack: error.stack });
                        // Rollback: delete AuthUser if student creation fails
                        await AuthUserModel_1.AuthUserModel.findByIdAndDelete(user._id);
                        return res.status(500).json({ error: 'Failed to create student profile', details: error.message });
                    }
                }
                else if (role === 'professor') {
                    this.logger.info('Creating Professor profile for AuthUser', { authUserId: user._id.toString() });
                    try {
                        const professor = await ProfessorModel_1.ProfessorModel.create({
                            authUserId: user._id,
                            name: name,
                            email: email,
                            phone: phone,
                            specialties: [],
                            hourlyRate: 0,
                            experienceYears: 0, // Required field
                        });
                        this.logger.info('Professor created successfully', { professorId: professor._id.toString() });
                    }
                    catch (error) {
                        this.logger.error('Error creating Professor profile', {
                            error: error.message,
                            stack: error.stack,
                            authUserId: user._id.toString(),
                            email: email,
                            role: role
                        });
                        // Rollback: delete AuthUser if professor creation fails
                        await AuthUserModel_1.AuthUserModel.findByIdAndDelete(user._id);
                        return res.status(500).json({
                            error: 'Failed to create professor profile',
                            details: error.message,
                            code: error.code || 'UNKNOWN_ERROR'
                        });
                    }
                }
                // Generar tokens JWT
                const accessToken = this.jwtService.signAccess({ sub: user._id.toString(), role: user.role });
                const refreshToken = this.jwtService.signRefresh({
                    sub: user._id.toString(),
                    role: user.role,
                });
                res.status(201).json({
                    accessToken,
                    refreshToken,
                    user: {
                        id: user._id,
                        email: user.email,
                        name: user.name,
                        role: user.role,
                    },
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
                    role: user.role,
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