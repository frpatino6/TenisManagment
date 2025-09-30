import { Request, Response } from 'express';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { JwtService } from '../../infrastructure/services/JwtService';
import { config } from '../../infrastructure/config';

export class FirebaseAuthController {
  private jwtService = new JwtService(config.jwtSecret);

  // Verificar token de Firebase y crear/actualizar usuario
  verifyToken = async (req: Request, res: Response) => {
    try {
      const { idToken } = req.body;
      
      if (!idToken) {
        return res.status(400).json({ error: 'ID token is required' });
      }

      // Verificar token con Firebase Admin SDK
      const admin = require('../../infrastructure/auth/firebase').default;
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      
      // Buscar usuario existente por Firebase UID
      let user = await AuthUserModel.findOne({ firebaseUid: decodedToken.uid });
      console.log('User found by Firebase UID:', user ? 'Yes' : 'No');
      
      if (user) {
        // Verificar si ya tiene un registro en students o professors según su rol
        if (user.role === 'student') {
          const existingStudent = await StudentModel.findOne({ authUserId: user._id });
          console.log('Student profile exists:', existingStudent ? 'Yes' : 'No');
          
          if (!existingStudent) {
            console.log('Creating missing Student profile for existing user:', user._id);
            await StudentModel.create({
              authUserId: user._id,
              name: user.name || decodedToken.name || 'Usuario',
              email: user.email,
              membershipType: 'basic',
              balance: 0
            });
            console.log('Student profile created for existing user');
          }
        } else if (user.role === 'professor') {
          const existingProfessor = await ProfessorModel.findOne({ authUserId: user._id });
          console.log('Professor profile exists:', existingProfessor ? 'Yes' : 'No');
          
          if (!existingProfessor) {
            console.log('Creating missing Professor profile for existing user:', user._id);
            await ProfessorModel.create({
              authUserId: user._id,
              name: user.name || decodedToken.name || 'Usuario',
              email: user.email,
              phone: '',
              specialties: [],
              hourlyRate: 0
            });
            console.log('Professor profile created for existing user');
          }
        }
      } else if (!user) {
        // Buscar por email si no existe Firebase UID
        user = await AuthUserModel.findOne({ email: decodedToken.email });
        console.log('User found by email:', user ? 'Yes' : 'No');
        
        if (user) {
          // Vincular Firebase UID a usuario existente
          console.log('Linking Firebase UID to existing user:', user._id);
          user.firebaseUid = decodedToken.uid;
          await user.save();
        } else {
          // Crear nuevo usuario
          console.log('Creating new AuthUser for Firebase UID:', decodedToken.uid);
          user = await AuthUserModel.create({
            firebaseUid: decodedToken.uid,
            email: decodedToken.email,
            name: decodedToken.name || 'Usuario',
            role: 'student' // Por defecto
          });
          console.log('AuthUser created with ID:', user._id);
          
          // Crear perfil de estudiante por defecto
          console.log('Creating Student profile for AuthUser:', user._id);
          const student = await StudentModel.create({
            authUserId: user._id,
            name: decodedToken.name || user.name || 'Usuario',
            email: decodedToken.email,
            // phone is optional for Google Sign-In users
            membershipType: 'basic',
            balance: 0
          });
          console.log('Student created with ID:', student._id);
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
    } catch (error) {
      console.error('Firebase auth error:', error);
      res.status(401).json({ error: 'Invalid token' });
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
        $or: [
          { firebaseUid: firebaseUid },
          { email: email }
        ]
      });

      if (user) {
        return res.status(409).json({ error: 'User already exists' });
      }

      // Crear nuevo usuario
      console.log('Creating new AuthUser for registration:', firebaseUid);
      user = await AuthUserModel.create({
        firebaseUid: firebaseUid,
        email: email,
        name: name,
        role: role
      });
      console.log('AuthUser created with ID:', user._id);

      // Crear perfil según el rol
      if (role === 'student') {
        console.log('Creating Student profile for AuthUser:', user._id);
        const student = await StudentModel.create({
          authUserId: user._id,
          name: name,
          email: email,
          phone: phone,
          membershipType: 'basic',
          balance: 0
        });
        console.log('Student created with ID:', student._id);
      } else if (role === 'professor') {
        console.log('Creating Professor profile for AuthUser:', user._id);
        const professor = await ProfessorModel.create({
          authUserId: user._id,
          name: name,
          email: email,
          phone: phone,
          specialties: [],
          hourlyRate: 0
        });
        console.log('Professor created with ID:', professor._id);
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
    } catch (error) {
      console.error('Registration error:', error);
      res.status(400).json({ error: (error as Error).message });
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
        role: user.role
      });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  };
}
