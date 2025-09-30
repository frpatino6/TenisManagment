import { Request, Response, NextFunction } from 'express';
import admin from '../../infrastructure/auth/firebase';
import { config } from '../../infrastructure/config';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
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
    logger.info('Token verified');

    // Buscar usuario en la base de datos por firebaseUid
    const user = await AuthUserModel.findOne({ firebaseUid: decodedToken.uid });

    if (!user) {
      logger.warn('User not found for Firebase UID');
      return res.status(404).json({ error: 'User not found' });
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
    logger.error('Firebase auth error', { error: message });
    res.status(401).json({ error: 'Invalid token' });
  }
};
