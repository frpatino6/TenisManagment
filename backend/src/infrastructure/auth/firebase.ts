import admin from 'firebase-admin';
import { config } from '../config';

if (config.firebase.enabled) {
  try {
    const serviceAccount = {
      projectId: config.firebase.projectId,
      privateKey: (config.firebase.privateKey as string).replace(/\\n/g, '\n'),
      clientEmail: config.firebase.clientEmail,
    };

    if (!admin.apps.length) {
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
        projectId: config.firebase.projectId,
      });
    }
  } catch (error) {
    throw new Error('Firebase initialization failed');
  }
}

export default admin;
