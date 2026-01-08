import { Request, Response } from 'express';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { JwtService } from '../../infrastructure/services/JwtService';
import { config } from '../../infrastructure/config';
import { Logger } from '../../infrastructure/services/Logger';
import admin from '../../infrastructure/auth/firebase';
import { TenantService } from '../services/TenantService';

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
        this.logger.warn('verifyToken called without idToken');
        return res.status(400).json({ error: 'ID token is required' });
      }


      // Verificar token con Firebase Admin SDK
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (verifyError: any) {
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
      let user = await AuthUserModel.findOne({ firebaseUid: decodedToken.uid });

      if (user) {
        // Verificar si ya tiene un registro en students o professors según su rol
        if (user.role === 'student') {
          const existingStudent = await StudentModel.findOne({ authUserId: user._id });

          if (!existingStudent) {
            await StudentModel.create({
              authUserId: user._id,
              name: user.name || decodedToken.name || 'Usuario',
              email: user.email,
              membershipType: 'basic',
              balance: 0,
            });
          }
        } else if (user.role === 'professor') {
          const existingProfessor = await ProfessorModel.findOne({ authUserId: user._id });

          if (!existingProfessor) {
            await ProfessorModel.create({
              authUserId: user._id,
              name: user.name || decodedToken.name || 'Usuario',
              email: user.email,
              phone: '',
              specialties: [],
              hourlyRate: 0,
              experienceYears: 0,
            });
          }
        }
      } else {
        // Buscar por email si no existe Firebase UID
        user = await AuthUserModel.findOne({ email: decodedToken.email });

        if (user) {
          // Vincular Firebase UID a usuario existente
          user.firebaseUid = decodedToken.uid;
          await user.save();
          
          // Verificar si tiene perfil de estudiante o profesor
          if (user.role === 'student') {
            const existingStudent = await StudentModel.findOne({ authUserId: user._id });
            if (!existingStudent) {
              await StudentModel.create({
                authUserId: user._id,
                name: user.name || decodedToken.name || 'Usuario',
                email: user.email,
                membershipType: 'basic',
                balance: 0,
              });
            }
          } else if (user.role === 'professor') {
            const existingProfessor = await ProfessorModel.findOne({ authUserId: user._id });
            if (!existingProfessor) {
              await ProfessorModel.create({
                authUserId: user._id,
                name: user.name || decodedToken.name || 'Usuario',
                email: user.email,
                phone: '',
                specialties: [],
                hourlyRate: 0,
                experienceYears: 0,
              });
            }
          }
        } else {
          // Crear nuevo usuario
          user = await AuthUserModel.create({
            firebaseUid: decodedToken.uid,
            email: decodedToken.email,
            name: decodedToken.name || 'Usuario',
            role: 'student', // Por defecto
          });

          // Crear perfil de estudiante por defecto
          await StudentModel.create({
            authUserId: user._id,
            name: decodedToken.name || user.name || 'Usuario',
            email: decodedToken.email,
            membershipType: 'basic',
            balance: 0,
          });
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
      } else if (code === 'auth/argument-error' || message.includes('malformed')) {
        errorMessage = 'El token es inválido o está malformado.';
      } else if (code === 'auth/invalid-credential' || message.includes('credential')) {
        errorMessage = 'Las credenciales son incorrectas o han expirado.';
      } else {
        errorMessage = `Error de autenticación: ${message}`;
      }
      
      res.status(statusCode).json({ error: errorMessage, details: message });
    }
  };

  // Registrar usuario con email/contraseña
  registerUser = async (req: Request, res: Response) => {
    try {
      const { name, email, phone, role, firebaseUid, tenantId } = req.body;

      if (!name || !email || !role || !firebaseUid) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      // Verificar si el usuario ya existe
      let user = await AuthUserModel.findOne({
        $or: [{ firebaseUid: firebaseUid }, { email: email }],
      });

      if (user) {
        // Si el usuario existe pero no tiene firebaseUid, actualizarlo
        if (!user.firebaseUid && user.email === email && user.role === role) {
          this.logger.info('Actualizando firebaseUid para usuario existente', {
            userId: user._id.toString(),
            email,
          });
          user.firebaseUid = firebaseUid;
          if (name && !user.name) {
            user.name = name;
          }
          await user.save();
          
          // El perfil ya debería existir (creado desde invitación), verificar y continuar
          // Generar tokens JWT y retornar
          const accessToken = this.jwtService.signAccess({ sub: user._id.toString(), role: user.role });
          const refreshToken = this.jwtService.signRefresh({
            sub: user._id.toString(),
            role: user.role,
          });

          return res.status(200).json({
            accessToken,
            refreshToken,
            user: {
              id: user._id.toString(),
              email: user.email,
              name: user.name,
              role: user.role,
            },
          });
        } else {
        return res.status(409).json({ error: 'User already exists' });
        }
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
        try {
          const student = await StudentModel.create({
            authUserId: user._id,
            name: name,
            email: email,
            phone: phone,
            membershipType: 'basic',
            balance: 0,
          });
          this.logger.info('Student created', { studentId: student._id.toString() });
        } catch (error: any) {
          this.logger.error('Error creating Student profile', { error: error.message, stack: error.stack });
          // Rollback: delete AuthUser if student creation fails
          await AuthUserModel.findByIdAndDelete(user._id);
          return res.status(500).json({ error: 'Failed to create student profile', details: error.message });
        }
      } else if (role === 'professor') {
        this.logger.info('Creating Professor profile for AuthUser', { authUserId: user._id.toString() });
        let professor;
        try {
          professor = await ProfessorModel.create({
            authUserId: user._id,
            name: name,
            email: email,
            phone: phone,
            specialties: [],
            hourlyRate: 0,
            experienceYears: 0, // Required field
          });
          this.logger.info('Professor created successfully', { professorId: professor._id.toString() });
        } catch (error: any) {
          this.logger.error('Error creating Professor profile', { 
            error: error.message, 
            stack: error.stack,
            authUserId: user._id.toString(),
            email: email,
            role: role
          });
          // Rollback: delete AuthUser if professor creation fails
          await AuthUserModel.findByIdAndDelete(user._id);
          return res.status(500).json({ 
            error: 'Failed to create professor profile', 
            details: error.message,
            code: error.code || 'UNKNOWN_ERROR'
          });
        }

        // Si se proporciona tenantId, crear la relación ProfessorTenant
        if (tenantId) {
          try {
            const tenantService = new TenantService();
            await tenantService.addProfessorToTenant(
              professor._id.toString(),
              tenantId,
            );
            this.logger.info('Professor added to tenant', { 
              professorId: professor._id.toString(), 
              tenantId 
            });
          } catch (error: any) {
            this.logger.error('Error adding professor to tenant', { 
              error: error.message,
              professorId: professor._id.toString(),
              tenantId
            });
            // No hacemos rollback aquí, el profesor ya está creado
            // Solo logueamos el error pero permitimos que el registro continúe
          }
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
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      this.logger.error('Registration error', { error: message });
      res.status(400).json({ error: message });
    }
  };

  // Obtener información del usuario autenticado
  getMe = async (req: Request, res: Response) => {
    try {
      const userId = req.user?.id;
      const firebaseUid = req.user?.uid;
      
      if (!userId) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      let user = await AuthUserModel.findById(userId);
      
      // Si no se encuentra por ID, intentar por firebaseUid
      if (!user && firebaseUid) {
        user = await AuthUserModel.findOne({ firebaseUid });
      }
      
      if (!user) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      // Verificar si tiene perfil de estudiante o profesor
      if (user.role === 'student') {
        const student = await StudentModel.findOne({ authUserId: user._id });
        if (!student) {
          await StudentModel.create({
            authUserId: user._id,
            name: user.name || 'Usuario',
            email: user.email,
            membershipType: 'basic',
            balance: 0,
          });
        }
      } else if (user.role === 'professor') {
        const professor = await ProfessorModel.findOne({ authUserId: user._id });
        if (!professor) {
          await ProfessorModel.create({
            authUserId: user._id,
            name: user.name || 'Usuario',
            email: user.email,
            phone: '',
            specialties: [],
            hourlyRate: 0,
            experienceYears: 0,
          });
        }
      }
      
      res.json({
        id: user._id,
        email: user.email,
        name: user.name,
        role: user.role,
      });
    } catch (error) {
      res.status(500).json({ error: 'Error interno del servidor', details: (error as Error).message });
    }
  };
}
