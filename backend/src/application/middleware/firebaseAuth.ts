import { Request, Response, NextFunction } from 'express';
import admin from '../../infrastructure/auth/firebase';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';

export const firebaseAuthMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      console.log('No authorization header or invalid format');
      return res.status(401).json({ error: 'No token provided' });
    }
    
    const idToken = authHeader.split('Bearer ')[1];
    console.log('Received token, verifying with Firebase...');
    console.log('Token length:', idToken.length);
    console.log('Token preview:', idToken.substring(0, 20) + '...');
    
    // Verificar token con Firebase
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    console.log('Token verified, Firebase UID:', decodedToken.uid);
    
    // Buscar usuario en la base de datos por firebaseUid
    const user = await AuthUserModel.findOne({ firebaseUid: decodedToken.uid });
    console.log('User found in database:', user ? 'Yes' : 'No');
    
    if (!user) {
      console.log('User not found in database for Firebase UID:', decodedToken.uid);
      return res.status(404).json({ error: 'User not found' });
    }
    
    console.log('User found:', { id: user._id, role: user.role });
    
    // Agregar información del usuario a la request
    req.user = {
      id: user._id.toString(),
      role: user.role
    };
    
    console.log('Setting req.user:', req.user);
    console.log('Calling next()...');
    next();
  } catch (error) {
    console.error('Firebase auth error:', error);
    console.error('Error details:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
};
