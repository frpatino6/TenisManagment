import { Request, Response, NextFunction } from 'express';
import admin from '../../infrastructure/auth/firebase';
import { config } from '../../infrastructure/config';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { Logger } from '../../infrastructure/services/Logger';
const logger = new Logger({ module: 'firebaseAuthMiddleware' });

export const firebaseAuthMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  try {
    if (!config.firebase.enabled) {
      logger.warn('Firebase middleware called while disabled');
      return res.status(503).json({ error: 'Firebase auth disabled' });
    }
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      logger.warn('Missing or invalid authorization header');
      return res.status(401).json({ error: 'No token provided' });
    }

    const idToken = authHeader.split('Bearer ')[1];

    // Verificar token con Firebase
    const decodedToken = await admin.auth().verifyIdToken(idToken);

    // Buscar usuario en la base de datos por firebaseUid
    let user = await AuthUserModel.findOne({ firebaseUid: decodedToken.uid });

    if (!user) {
      // Si no se encuentra por firebaseUid, intentar buscar por email
      user = await AuthUserModel.findOne({ email: decodedToken.email });
      
      if (user) {
        // Vincular el firebaseUid al usuario existente
        user.firebaseUid = decodedToken.uid;
        await user.save();
        
        // Asegurar que tenga perfil creado
        if (user.role === 'student') {
          const student = await StudentModel.findOne({ authUserId: user._id });
          if (!student) {
            await StudentModel.create({
              authUserId: user._id,
              name: user.name || decodedToken.name || 'Usuario',
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
        return res.status(404).json({ error: 'User not found' });
      }
    } else {
      // Asegurar que tenga perfil creado
      if (user.role === 'student') {
        const student = await StudentModel.findOne({ authUserId: user._id });
        if (!student) {
          await StudentModel.create({
            authUserId: user._id,
            name: user.name || decodedToken.name || 'Usuario',
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
            name: user.name || decodedToken.name || 'Usuario',
            email: user.email,
            phone: '',
            specialties: [],
            hourlyRate: 0,
            experienceYears: 0,
          });
        }
      }
    }

    // Agregar información del usuario a la request
    req.user = {
      id: user._id.toString(),
      role: user.role,
      uid: decodedToken.uid,
    };

    next();
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const code = (error as any)?.code || 'unknown';
    const stack = error instanceof Error ? error.stack : undefined;
    logger.error('Firebase auth error', { 
      error: message, 
      code,
      stack: stack?.split('\n').slice(0, 3).join('\n')
    });
    res.status(401).json({ error: 'Invalid token', details: message });
  }
};
