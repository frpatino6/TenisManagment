/**
 * Seed: crea usuarios en Firebase (REST signUp), asigna custom claims (role) y datos en MongoDB.
 * La app usa el claim "role" del token para elegir endpoint (tenant/me vs student-dashboard/active-tenant).
 * Requiere: MONGO_URI o SEED_MONGO_URI, FIREBASE_WEB_API_KEY.
 * Opcional: FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL para setCustomUserClaims.
 * Uso: npm run seed:tenant [tenant-name]
 */

import dotenv from 'dotenv';
import path from 'path';
import fs from 'fs';
import axios from 'axios';
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
      console.warn('Firebase Admin (FIREBASE_* env) falló:', (e as Error).message);
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
        console.warn('Firebase Admin (JSON file) falló:', (e as Error).message);
      }
    } else {
      console.warn('GOOGLE_APPLICATION_CREDENTIALS: archivo no existe:', resolved);
    }
  }

  return false;
}

async function setFirebaseRoleClaim(uid: string, role: string): Promise<void> {
  await admin.auth().setCustomUserClaims(uid, { role });
}

const DEFAULT_PASSWORD = process.env.SEED_PASSWORD ?? 'Test123!';
const DEFAULT_TENANT_NAME = 'Spin Padel';
const STUDENT_COUNT = 2;
const FIREBASE_SIGNUP_URL = 'https://identitytoolkit.googleapis.com/v1/accounts:signUp';

async function createFirebaseUser(
  apiKey: string,
  email: string,
  password: string,
  displayName: string
): Promise<string> {
  const res = await axios.post(
    `${FIREBASE_SIGNUP_URL}?key=${apiKey}`,
    { email, password, displayName, returnSecureToken: true },
    { headers: { 'Content-Type': 'application/json' } }
  );
  const uid = res.data?.localId;
  if (!uid) throw new Error('Firebase signUp did not return localId');
  return uid;
}

async function getOrCreateFirebaseUid(
  apiKey: string,
  email: string,
  password: string,
  displayName: string
): Promise<string> {
  try {
    return await createFirebaseUser(apiKey, email, password, displayName);
  } catch (err: unknown) {
    const msg = (err as { response?: { data?: { error?: { message?: string } } } })?.response?.data?.error?.message ?? '';
    if (msg.includes('EMAIL_EXISTS')) {
      const lookup = await axios.post(
        `https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=${apiKey}`,
        { email },
        { headers: { 'Content-Type': 'application/json' } }
      );
      return lookup.data?.users?.[0]?.localId ?? '';
    }
    throw err;
  }
}

async function seed(): Promise<void> {
  const mongoUri = process.env.SEED_MONGO_URI || process.env.MONGO_URI;
  const apiKey = process.env.FIREBASE_WEB_API_KEY;
  if (!mongoUri) throw new Error('MONGO_URI or SEED_MONGO_URI required in .env');
  if (!apiKey) throw new Error('FIREBASE_WEB_API_KEY required in .env (Firebase Console → Project settings → Web API Key)');

  const tenantName = process.argv[2] ?? DEFAULT_TENANT_NAME;
  const slugBase = tenantName.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-+|-+$/g, '') || 'centro-demo';
  const adminEmail = 'admin@test.com';
  const professorEmail = 'professor@test.com';

  await mongoose.connect(mongoUri);
  console.log('Connected to MongoDB');

  const existing = await TenantModel.findOne({ slug: slugBase });
  if (existing) {
    console.warn('Tenant with slug', slugBase, 'already exists. Aborting.');
    await mongoose.disconnect();
    process.exit(1);
  }

  const adminDisplayName = `Admin ${tenantName}`;
  const firebaseUidAdmin = await getOrCreateFirebaseUid(apiKey, adminEmail, DEFAULT_PASSWORD, adminDisplayName);
  console.log('Firebase user (admin):', adminEmail);

  const authAdmin = await AuthUserModel.create({
    email: adminEmail,
    role: 'tenant_admin',
    name: adminDisplayName,
    firebaseUid: firebaseUidAdmin,
  });

  const tenant = await TenantModel.create({
    name: tenantName,
    slug: slugBase,
    adminUserId: authAdmin._id,
    isActive: true,
  });
  console.log('Tenant:', tenant.name);

  await TenantAdminModel.create({
    tenantId: tenant._id,
    adminUserId: authAdmin._id,
    isActive: true,
  });

  const professorDisplayName = `Profesor ${tenantName}`;
  const firebaseUidProfessor = await getOrCreateFirebaseUid(apiKey, professorEmail, DEFAULT_PASSWORD, professorDisplayName);
  console.log('Firebase user (professor):', professorEmail);

  const authProfessor = await AuthUserModel.create({
    email: professorEmail,
    role: 'professor',
    name: professorDisplayName,
    firebaseUid: firebaseUidProfessor,
  });

  const professor = await ProfessorModel.create({
    authUserId: authProfessor._id,
    name: professorDisplayName,
    email: professorEmail,
    phone: '+57300123456',
    specialties: ['Pádel'],
    hourlyRate: 50_000,
    experienceYears: 5,
  });
  await AuthUserModel.updateOne({ _id: authProfessor._id }, { $set: { linkedId: professor._id } });
  console.log('Professor (sin tenant):', professor.email);

  const studentEmails: string[] = [];
  const studentFirebaseUids: string[] = [];
  for (let i = 1; i <= STUDENT_COUNT; i++) {
    const email = `student${i}@test.com`;
    const displayName = `Estudiante ${tenantName} ${i}`;
    const uid = await getOrCreateFirebaseUid(apiKey, email, DEFAULT_PASSWORD, displayName);
    studentFirebaseUids.push(uid);
    console.log('Firebase user (student):', email);

    const authStudent = await AuthUserModel.create({
      email,
      role: 'student',
      name: displayName,
      firebaseUid: uid,
    });

    const student = await StudentModel.create({
      authUserId: authStudent._id,
      name: displayName,
      email,
      membershipType: 'basic',
      balance: 0,
      activeTenantId: tenant._id,
    });
    await AuthUserModel.updateOne({ _id: authStudent._id }, { $set: { linkedId: student._id } });
    await StudentTenantModel.create({
      studentId: student._id,
      tenantId: tenant._id,
      balance: 0,
      isActive: true,
    });
    await UserPreferencesModel.create({
      userId: authStudent._id,
      favoriteTenants: [tenant._id],
      favoriteProfessors: [],
    });
    studentEmails.push(email);
  }
  console.log('Students:', STUDENT_COUNT);

  await CourtModel.create([
    { tenantId: tenant._id, name: 'Cancha 1', type: 'padel', price: 60_000, isActive: true, description: 'Cancha de pádel' },
    { tenantId: tenant._id, name: 'Cancha 2', type: 'padel', price: 60_000, isActive: true, description: 'Cancha de pádel' },
  ]);
  console.log('Courts: 2');

  if (initFirebaseAdmin()) {
    try {
      await setFirebaseRoleClaim(firebaseUidAdmin, 'tenant_admin');
      console.log('Firebase claim: admin -> tenant_admin');
      await setFirebaseRoleClaim(firebaseUidProfessor, 'professor');
      console.log('Firebase claim: professor -> professor');
      for (const uid of studentFirebaseUids) {
        await setFirebaseRoleClaim(uid, 'student');
      }
      console.log('Firebase claim: students -> student');
    } catch (e) {
      console.warn('No se pudieron asignar custom claims (role) en Firebase:', (e as Error).message);
      console.warn('Configura FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL. La app puede no redirigir bien por rol.');
    }
  } else {
    console.warn('Firebase Admin no configurado: no se asignaron custom claims. La app puede no redirigir bien por rol.');
  }

  console.log('\n--- Seed listo ---');
  console.log('Tenant:', tenant.name);
  console.log('Contraseña (todos):', DEFAULT_PASSWORD);
  console.log('  Admin:   ', adminEmail);
  console.log('  Professor:', professorEmail);
  studentEmails.forEach((e, i) => console.log('  Student', i + 1 + ': ', e));
  await mongoose.disconnect();
}

seed().catch((e) => {
  console.error(e);
  process.exit(1);
});
