/**
 * Minimal tenant seed script.
 * Creates the minimum data for a center/tenant to test the app:
 * - 1 Tenant (center)
 * - 1 Tenant Admin (AuthUser + TenantAdmin link)
 * - 1 Professor (AuthUser + Professor, WITHOUT ProfessorTenant — admin authorizes later)
 * - 5 Students (AuthUser + Student + StudentTenant each)
 * - 2 Padel courts
 *
 * Users are created in Firebase Auth (email/password) and linked in MongoDB (firebaseUid).
 * Does NOT create tournaments (use the other tournament seed script for that).
 *
 * Usage:
 *   From backend root: npx tsx scripts/seed-tenant-minimal.ts [tenant-name]
 *   tenant-name optional (default: "Centro Demo"). Used for tenant name and slug.
 *
 * Env:
 *   MONGO_URI required.
 *   FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL required (to create users in Firebase).
 *   SEED_PASSWORD optional (default: "Test123!") - same password for all users in UAT.
 */

import dotenv from 'dotenv';
import path from 'path';
import mongoose from 'mongoose';
import admin from 'firebase-admin';
import { AuthUserModel } from '../src/infrastructure/database/models/AuthUserModel';
import { TenantModel } from '../src/infrastructure/database/models/TenantModel';
import { TenantAdminModel } from '../src/infrastructure/database/models/TenantAdminModel';
import { ProfessorModel } from '../src/infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../src/infrastructure/database/models/StudentModel';
import { StudentTenantModel } from '../src/infrastructure/database/models/StudentTenantModel';
import { CourtModel } from '../src/infrastructure/database/models/CourtModel';

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const DEFAULT_PASSWORD = process.env.SEED_PASSWORD ?? 'Test123!';
const DEFAULT_TENANT_NAME = 'Spin Padel';

function initFirebase(): void {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  if (!projectId || !privateKey || !clientEmail) {
    throw new Error(
      'Firebase is required to create seed users. Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL in .env',
    );
  }
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        privateKey: (privateKey as string).replace(/\\n/g, '\n'),
        clientEmail,
      }),
      projectId,
    });
  }
}

async function getOrCreateFirebaseUid(
  email: string,
  password: string,
  displayName: string,
): Promise<string> {
  try {
    const userRecord = await admin.auth().createUser({
      email,
      password,
      displayName,
      emailVerified: true,
    });
    return userRecord.uid;
  } catch (err: unknown) {
    const code = (err as { code?: string })?.code;
    if (code === 'auth/email-already-exists') {
      const existing = await admin.auth().getUserByEmail(email);
      return existing.uid;
    }
    throw err;
  }
}

async function seed(): Promise<void> {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    throw new Error('MONGO_URI is required. Set it in .env or environment.');
  }

  initFirebase();
  console.log('Firebase Admin initialized');

  const tenantName = process.argv[2] ?? DEFAULT_TENANT_NAME;
  const slugBase = tenantName
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '') || 'centro-demo';

  const adminEmail = `admin@${slugBase}.seed.local`;
  const professorEmail = `professor@${slugBase}.seed.local`;
  const STUDENT_COUNT = 5;

  await mongoose.connect(mongoUri);
  console.log('Connected to MongoDB');

  const existingTenant = await TenantModel.findOne({ slug: slugBase });
  if (existingTenant) {
    console.warn(`Tenant with slug "${slugBase}" already exists. Aborting to avoid duplicates.`);
    await mongoose.disconnect();
    process.exit(1);
  }

  const adminDisplayName = `Admin ${tenantName}`;
  const firebaseUidAdmin = await getOrCreateFirebaseUid(
    adminEmail,
    DEFAULT_PASSWORD,
    adminDisplayName,
  );
  console.log('Created Firebase user (tenant_admin):', adminEmail);

  const authAdmin = await AuthUserModel.create({
    email: adminEmail,
    role: 'tenant_admin',
    name: adminDisplayName,
    firebaseUid: firebaseUidAdmin,
  });
  console.log('Created AuthUser (tenant_admin):', authAdmin.email);

  const tenant = await TenantModel.create({
    name: tenantName,
    slug: slugBase,
    adminUserId: authAdmin._id,
    isActive: true,
  });
  console.log('Created Tenant:', tenant.name, 'slug:', tenant.slug);

  await TenantAdminModel.create({
    tenantId: tenant._id,
    adminUserId: authAdmin._id,
    isActive: true,
  });
  console.log('Created TenantAdmin link');

  const professorDisplayName = `Profesor ${tenantName}`;
  const firebaseUidProfessor = await getOrCreateFirebaseUid(
    professorEmail,
    DEFAULT_PASSWORD,
    professorDisplayName,
  );
  console.log('Created Firebase user (professor):', professorEmail);

  const authProfessor = await AuthUserModel.create({
    email: professorEmail,
    role: 'professor',
    name: professorDisplayName,
    firebaseUid: firebaseUidProfessor,
  });

  const professor = await ProfessorModel.create({
    authUserId: authProfessor._id,
    name: `Profesor ${tenantName}`,
    email: professorEmail,
    phone: '+57300123456',
    specialties: ['Pádel'],
    hourlyRate: 50_000,
    experienceYears: 5,
  });

  await AuthUserModel.updateOne(
    { _id: authProfessor._id },
    { $set: { linkedId: professor._id } },
  );
  console.log(
    'Created Professor (no tenant yet — admin can authorize from tenant):',
    professor.email,
  );

  const studentEmails: string[] = [];
  for (let i = 1; i <= STUDENT_COUNT; i++) {
    const studentEmail = `student${i}@${slugBase}.seed.local`;
    const studentDisplayName = `Estudiante ${tenantName} ${i}`;
    const firebaseUidStudent = await getOrCreateFirebaseUid(
      studentEmail,
      DEFAULT_PASSWORD,
      studentDisplayName,
    );
    console.log('Created Firebase user (student):', studentEmail);

    const authStudent = await AuthUserModel.create({
      email: studentEmail,
      role: 'student',
      name: studentDisplayName,
      firebaseUid: firebaseUidStudent,
    });

    const student = await StudentModel.create({
      authUserId: authStudent._id,
      name: studentDisplayName,
      email: studentEmail,
      membershipType: 'basic',
      balance: 0,
      activeTenantId: tenant._id,
    });

    await AuthUserModel.updateOne(
      { _id: authStudent._id },
      { $set: { linkedId: student._id } },
    );

    await StudentTenantModel.create({
      studentId: student._id,
      tenantId: tenant._id,
      balance: 0,
      isActive: true,
    });
    studentEmails.push(studentEmail);
  }
  console.log('Created', STUDENT_COUNT, 'Students + StudentTenant');

  await CourtModel.create([
    {
      tenantId: tenant._id,
      name: 'Cancha 1',
      type: 'padel',
      price: 60_000,
      isActive: true,
      description: 'Cancha de pádel',
    },
    {
      tenantId: tenant._id,
      name: 'Cancha 2',
      type: 'padel',
      price: 60_000,
      isActive: true,
      description: 'Cancha de pádel',
    },
  ]);
  console.log('Created 2 padel courts');

  console.log('\n--- Seed completed ---');
  console.log('Tenant:', tenant.name, '(_id:', tenant._id.toString() + ')');
  console.log('Login (same password for all):', DEFAULT_PASSWORD);
  console.log('  Admin:    ', adminEmail);
  console.log('  Professor:', professorEmail, '(sin tenant — autorizar desde admin)');
  studentEmails.forEach((e, i) => console.log('  Student', i + 1 + ': ', e));
  await mongoose.disconnect();
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
