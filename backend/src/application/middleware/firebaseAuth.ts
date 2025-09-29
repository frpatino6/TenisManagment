import { Request, Response, NextFunction } from 'express';
import admin from '../../infrastructure/auth/firebase';

export const firebaseAuthMiddleware = async (req: Request, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'No token provided' });
    }
    
    const idToken = authHeader.split('Bearer ')[1];
    
    // Verificar token con Firebase
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // Agregar información del usuario a la request
    req.user = {
      id: decodedToken.uid,
      role: 'student' // Por defecto, se puede mejorar después
    };
    
    next();
  } catch (error) {
    console.error('Firebase auth error:', error);
    res.status(401).json({ error: 'Invalid token' });
  }
};
