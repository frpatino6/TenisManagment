/**
 * Rollback: borra lo creado por seed-tenant-minimal (MongoDB + Firebase Auth).
 * Requiere Firebase Admin (FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL) para borrar usuarios en Auth.
 * Uso: npm run seed:tenant:rollback [tenant-name]
 * Requiere: SEED_MONGO_URI o MONGO_URI.
 */

import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import mongoose from 'mongoose';
import admin from 'firebase-admin';
import { AuthUserModel } from '../src/infrastructure/database/models/AuthUserModel';
import { TenantModel } from '../src/infrastructure/database/models/TenantModel';
import { TenantAdminModel } from '../src/infrastructure/database/models/TenantAdminModel';
import { ProfessorModel } from '../src/infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../src/infrastructure/database/models/StudentModel';
import { StudentTenantModel } from '../src/infrastructure/database/models/StudentTenantModel';
import { CourtModel } from '../src/infrastructure/database/models/CourtModel';
import { UserPreferencesModel } from '../src/infrastructure/database/models/UserPreferencesModel';

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const DEFAULT_TENANT_NAME = 'Centro Demo';

function initFirebaseAdmin(): boolean {
  if (admin.apps.length > 0) return true;

  const projectId = process.env.FIREBASE_PROJECT_ID;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  const credPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (projectId && privateKey && clientEmail) {
    try {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          privateKey: privateKey.replace(/\\n/g, '\n'),
          clientEmail,
        } as admin.ServiceAccount),
        projectId,
      });
      console.log('Firebase Admin: inicializado con FIREBASE_* env');
      return true;
    } catch (e) {
      console.error('Firebase Admin (cert) falló:', (e as Error).message);
      return false;
    }
  }

  if (credPath) {
    const resolved = path.isAbsolute(credPath) ? credPath : path.resolve(path.join(__dirname, '..'), credPath);
    if (fs.existsSync(resolved)) {
      try {
        process.env.GOOGLE_APPLICATION_CREDENTIALS = resolved;
        admin.initializeApp({ credential: admin.credential.applicationDefault() });
        console.log('Firebase Admin: inicializado con GOOGLE_APPLICATION_CREDENTIALS');
        return true;
      } catch (e) {
        console.error('Firebase Admin (applicationDefault) falló:', (e as Error).message);
        return false;
      }
    }
    console.warn('GOOGLE_APPLICATION_CREDENTIALS apunta a archivo inexistente:', resolved);
  }

  console.warn(
    'Firebase Admin no configurado. Define FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY y FIREBASE_CLIENT_EMAIL, o GOOGLE_APPLICATION_CREDENTIALS (ruta al JSON de cuenta de servicio).'
  );
  return false;
}

async function deleteFirebaseUser(uid: string): Promise<void> {
  await admin.auth().deleteUser(uid);
}

async function rollback(): Promise<void> {
  const mongoUri = process.env.SEED_MONGO_URI || process.env.MONGO_URI;
  if (!mongoUri) throw new Error('MONGO_URI or SEED_MONGO_URI required in .env');

  const tenantName = process.argv.slice(2).join(' ').trim() || DEFAULT_TENANT_NAME;
  const slugBase = tenantName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || 'centro-demo';
  const professorEmail = 'professor@test.com';

  const firebaseEnabled = initFirebaseAdmin();

  await mongoose.connect(mongoUri);
  console.log('Connected to MongoDB');

  const tenant = await TenantModel.findOne({ slug: slugBase });
  if (!tenant) {
    console.log('No tenant with slug', slugBase, '- nothing to roll back.');
    await mongoose.disconnect();
    return;
  }

  const tenantId = tenant._id;
  console.log('Rollback tenant:', tenant.name, 'slug:', slugBase);

  const adminAuth = await AuthUserModel.findById(tenant.adminUserId);
  const seedProfessor = await ProfessorModel.findOne({ email: professorEmail });
  const professorAuth = seedProfessor ? await AuthUserModel.findById(seedProfessor.authUserId) : null;
  const studentTenants = await StudentTenantModel.find({ tenantId });
  const studentAuthIds: mongoose.Types.ObjectId[] = [];
  for (const st of studentTenants) {
    const student = await StudentModel.findById(st.studentId);
    if (student) studentAuthIds.push(student.authUserId);
  }

  const firebaseUids: string[] = [];
  if (adminAuth?.firebaseUid) firebaseUids.push(adminAuth.firebaseUid);
  if (professorAuth?.firebaseUid) firebaseUids.push(professorAuth.firebaseUid);
  for (const authId of studentAuthIds) {
    const auth = await AuthUserModel.findById(authId);
    if (auth?.firebaseUid) firebaseUids.push(auth.firebaseUid);
  }

  console.log('Firebase UIDs a borrar:', firebaseUids.length, firebaseUids);

  if (!firebaseEnabled) {
    console.warn('Firebase Admin no disponible: usuarios en Auth no se borrarán.');
  } else if (firebaseUids.length === 0) {
    console.warn('No hay firebaseUid en los AuthUser de este tenant (¿seed antiguo?).');
  } else {
    let firebaseFailed = 0;
    for (const uid of firebaseUids) {
      try {
        await deleteFirebaseUser(uid);
        console.log('Firebase Auth: usuario borrado', uid);
      } catch (e) {
        const err = e as Error;
        console.warn('Firebase deleteUser falló para', uid, ':', err.message);
        firebaseFailed++;
      }
    }
    if (firebaseFailed > 0) {
      console.warn(
        `Firebase: ${firebaseFailed} usuario(s) no se borraron (credencial DECODER/OpenSSL). Borralos en Firebase Console → Authentication si hace falta.`
      );
    }
  }

  const courtResult = await CourtModel.deleteMany({ tenantId });
  console.log('Deleted courts:', courtResult.deletedCount);

  await TenantAdminModel.deleteMany({ tenantId });
  console.log('Deleted TenantAdmin(s)');

  if (adminAuth) {
    await AuthUserModel.findByIdAndDelete(tenant.adminUserId);
    console.log('Deleted AuthUser (admin):', adminAuth.email);
  }

  if (seedProfessor) {
    await AuthUserModel.findByIdAndDelete(seedProfessor.authUserId);
    await ProfessorModel.findByIdAndDelete(seedProfessor._id);
    console.log('Deleted Professor + AuthUser:', professorEmail);
  }

  for (const st of studentTenants) {
    const student = await StudentModel.findById(st.studentId);
    await StudentTenantModel.findByIdAndDelete(st._id);
    if (student) {
      await UserPreferencesModel.deleteOne({ userId: student.authUserId });
      await AuthUserModel.findByIdAndDelete(student.authUserId);
      await StudentModel.findByIdAndDelete(student._id);
      console.log('Deleted Student + AuthUser:', student.email);
    }
  }

  await TenantModel.findByIdAndDelete(tenantId);
  console.log('Deleted Tenant:', tenant.name);

  console.log('--- Rollback done ---');
  await mongoose.disconnect();
}

rollback().catch((e) => {
  console.error(e);
  process.exit(1);
});
