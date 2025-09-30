import admin from 'firebase-admin';
import { config } from '../config';

if (config.firebase.enabled) {
  const serviceAccount = {
    type: 'service_account',
    project_id: config.firebase.projectId,
    private_key_id: 'key_id',
    private_key: (config.firebase.privateKey as string).replace(/\\n/g, '\n'),
    client_email: config.firebase.clientEmail,
    client_id: 'client_id',
    auth_uri: 'https://accounts.google.com/o/oauth2/auth',
    token_uri: 'https://oauth2.googleapis.com/token',
    auth_provider_x509_cert_url: 'https://www.googleapis.com/oauth2/v1/certs',
    client_x509_cert_url: `https://www.googleapis.com/robot/v1/metadata/x509/${config.firebase.clientEmail}`,
  };

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount as admin.ServiceAccount),
      projectId: config.firebase.projectId,
    });
  } else {
  }
}

export default admin;
