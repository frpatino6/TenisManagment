import { Request, Response } from 'express';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { JwtService } from '../../infrastructure/services/JwtService';

export class FirebaseAuthController {
  private jwtService = new JwtService(process.env.JWT_SECRET!);

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
      
      if (!user) {
        // Buscar por email si no existe Firebase UID
        user = await AuthUserModel.findOne({ email: decodedToken.email });
        
        if (user) {
          // Vincular Firebase UID a usuario existente
          user.firebaseUid = decodedToken.uid;
          await user.save();
        } else {
          // Crear nuevo usuario
          user = await AuthUserModel.create({
            firebaseUid: decodedToken.uid,
            email: decodedToken.email,
            name: decodedToken.name,
            role: 'student' // Por defecto
          });
          
          // Crear perfil de estudiante por defecto
          await StudentModel.create({
            authUserId: user._id,
            name: decodedToken.name,
            email: decodedToken.email,
            phone: '',
            membershipType: 'basic',
            balance: 0
          });
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
