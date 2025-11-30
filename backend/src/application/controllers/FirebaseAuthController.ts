import { Request, Response } from 'express';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { JwtService } from '../../infrastructure/services/JwtService';
import { config } from '../../infrastructure/config';
import { Logger } from '../../infrastructure/services/Logger';
import admin from '../../infrastructure/auth/firebase';

export class FirebaseAuthController {
  private jwtService = new JwtService(config.jwtSecret);
  private logger = new Logger({ controller: 'FirebaseAuthController' });

  // Verificar token de Firebase y crear/actualizar usuario
  verifyToken = async (req: Request, res: Response) => {
    try {
      if (!config.firebase.enabled) {
        return res.status(503).json({ error: 'Firebase auth disabled' });
      }
      const { idToken } = req.body;

      if (!idToken) {
        return res.status(400).json({ error: 'ID token is required' });
      }

      // Verificar token con Firebase Admin SDK
      const decodedToken = await admin.auth().verifyIdToken(idToken);

      // Buscar usuario existente por Firebase UID
      let user = await AuthUserModel.findOne({ firebaseUid: decodedToken.uid });

      if (user) {
        // Verificar si ya tiene un registro en students o professors según su rol
        if (user.role === 'student') {
          const existingStudent = await StudentModel.findOne({ authUserId: user._id });

          if (!existingStudent) {
            this.logger.info('Creating missing Student profile for existing user');
            await StudentModel.create({
              authUserId: user._id,
              name: user.name || decodedToken.name || 'Usuario',
              email: user.email,
              membershipType: 'basic',
              balance: 0,
            });
            this.logger.info('Student profile created');
          }
        } else if (user.role === 'professor') {
          const existingProfessor = await ProfessorModel.findOne({ authUserId: user._id });

          if (!existingProfessor) {
            this.logger.info('Creating missing Professor profile for existing user');
            await ProfessorModel.create({
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
      } else if (!user) {
        // Buscar por email si no existe Firebase UID
        user = await AuthUserModel.findOne({ email: decodedToken.email });

        if (user) {
          // Vincular Firebase UID a usuario existente
          this.logger.info('Linking Firebase UID to existing user');
          user.firebaseUid = decodedToken.uid;
          await user.save();
        } else {
          // Crear nuevo usuario
          this.logger.info('Creating new AuthUser for Firebase UID');
          user = await AuthUserModel.create({
            firebaseUid: decodedToken.uid,
            email: decodedToken.email,
            name: decodedToken.name || 'Usuario',
            role: 'student', // Por defecto
          });
          this.logger.info('AuthUser created');

          // Crear perfil de estudiante por defecto
          this.logger.info('Creating Student profile for AuthUser');
          const student = await StudentModel.create({
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
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      const code = (error as any)?.code || 'unknown';
      const stack = error instanceof Error ? error.stack : undefined;
      this.logger.error('Firebase auth error', { 
        error: message, 
        code,
        stack: stack?.split('\n').slice(0, 3).join('\n')
      });
      res.status(401).json({ error: 'Invalid token', details: message });
    }
  };

  // Registrar usuario con email/contraseña
  registerUser = async (req: Request, res: Response) => {
    try {
      const { name, email, phone, role, firebaseUid } = req.body;

      if (!name || !email || !role || !firebaseUid) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      // Verificar si el usuario ya existe
      let user = await AuthUserModel.findOne({
        $or: [{ firebaseUid: firebaseUid }, { email: email }],
      });

      if (user) {
        return res.status(409).json({ error: 'User already exists' });
      }

      // Crear nuevo usuario
      this.logger.info('Creating new AuthUser for registration');
      user = await AuthUserModel.create({
        firebaseUid: firebaseUid,
        email: email,
        name: name,
        role: role,
      });
      this.logger.info('AuthUser created');

      // Crear perfil según el rol
      if (role === 'student') {
        this.logger.info('Creating Student profile for AuthUser');
        const student = await StudentModel.create({
          authUserId: user._id,
          name: name,
          email: email,
          phone: phone,
          membershipType: 'basic',
          balance: 0,
        });
        this.logger.info('Student created');
      } else if (role === 'professor') {
        this.logger.info('Creating Professor profile for AuthUser');
        const professor = await ProfessorModel.create({
          authUserId: user._id,
          name: name,
          email: email,
          phone: phone,
          specialties: [],
          hourlyRate: 0,
        });
        this.logger.info('Professor created');
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
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error('Registration error', { error: message });
      res.status(400).json({ error: message });
    }
  };

  // Obtener información del usuario autenticado
  getMe = async (req: Request, res: Response) => {
    try {
      const user = await AuthUserModel.findById(req.user?.id);
      if (!user) {
        return res.status(404).json({ error: 'User not found' });
      }

      res.json({
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role,
      });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  };
}
