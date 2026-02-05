/**
 * Rollback script: removes only the data created by seed-tenant-minimal for one tenant.
 * Does not touch any data that existed before running the seed.
 *
 * Usage:
 *   From backend root: npx tsx scripts/seed-tenant-rollback.ts [tenant-name]
 *   tenant-name must match what you used when running the seed (default: "Centro Demo").
 *
 * Env: MONGO_URI required. Firebase vars required to delete the 3 users from Firebase Auth.
 */

import dotenv from 'dotenv';
import path from 'path';
import mongoose from 'mongoose';
import admin from 'firebase-admin';
import { AuthUserModel } from '../src/infrastructure/database/models/AuthUserModel';
import { TenantModel } from '../src/infrastructure/database/models/TenantModel';
import { TenantAdminModel } from '../src/infrastructure/database/models/TenantAdminModel';
import { ProfessorModel } from '../src/infrastructure/database/models/ProfessorModel';
import { ProfessorTenantModel } from '../src/infrastructure/database/models/ProfessorTenantModel';
import { StudentModel } from '../src/infrastructure/database/models/StudentModel';
import { StudentTenantModel } from '../src/infrastructure/database/models/StudentTenantModel';
import { CourtModel } from '../src/infrastructure/database/models/CourtModel';

dotenv.config({ path: path.join(__dirname, '..', '.env') });

const DEFAULT_TENANT_NAME = 'Centro Demo';

function initFirebase(): void {
  const projectId = process.env.FIREBASE_PROJECT_ID;
  const privateKey = process.env.FIREBASE_PRIVATE_KEY;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL;
  if (!projectId || !privateKey || !clientEmail) {
    throw new Error(
      'Firebase is required to delete seed users. Set FIREBASE_PROJECT_ID, FIREBASE_PRIVATE_KEY, FIREBASE_CLIENT_EMAIL in .env',
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

async function deleteFirebaseUserByEmail(email: string): Promise<void> {
  try {
    const userRecord = await admin.auth().getUserByEmail(email);
    await admin.auth().deleteUser(userRecord.uid);
    console.log('Deleted Firebase user:', email);
  } catch (err: unknown) {
    const code = (err as { code?: string })?.code;
    if (code === 'auth/user-not-found') {
      console.log('Firebase user already gone:', email);
    } else {
      throw err;
    }
  }
}

async function rollback(): Promise<void> {
  const mongoUri = process.env.MONGO_URI;
  if (!mongoUri) {
    throw new Error('MONGO_URI is required. Set it in .env or environment.');
  }

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

  const tenant = await TenantModel.findOne({ slug: slugBase });
  if (!tenant) {
    console.log(`No tenant found with slug "${slugBase}". Nothing to roll back.`);
    await mongoose.disconnect();
    return;
  }

  const tenantId = tenant._id;
  console.log('Rolling back tenant:', tenant.name, 'slug:', slugBase);

  const courtResult = await CourtModel.deleteMany({ tenantId });
  console.log('Deleted courts:', courtResult.deletedCount);

  await TenantAdminModel.deleteMany({ tenantId });
  console.log('Deleted TenantAdmin link(s)');

  const adminAuthUser = await AuthUserModel.findById(tenant.adminUserId);
  if (adminAuthUser) {
    await AuthUserModel.findByIdAndDelete(tenant.adminUserId);
    console.log('Deleted AuthUser (tenant_admin):', adminAuthUser.email);
  }

  const professorTenants = await ProfessorTenantModel.find({ tenantId });
  for (const pt of professorTenants) {
    await ProfessorTenantModel.findByIdAndDelete(pt._id);
    const other = await ProfessorTenantModel.findOne({ professorId: pt.professorId });
    if (!other) {
      const professor = await ProfessorModel.findById(pt.professorId);
      if (professor) {
        await AuthUserModel.findByIdAndDelete(professor.authUserId);
        await ProfessorModel.findByIdAndDelete(professor._id);
        console.log('Deleted Professor + AuthUser:', professor.email);
      }
    }
  }

  const seedProfessorAuth = await AuthUserModel.findOne({ email: professorEmail });
  if (seedProfessorAuth?.linkedId) {
    await ProfessorTenantModel.deleteMany({ professorId: seedProfessorAuth.linkedId });
    await ProfessorModel.findByIdAndDelete(seedProfessorAuth.linkedId);
    await AuthUserModel.findByIdAndDelete(seedProfessorAuth._id);
    console.log('Deleted seed Professor (no tenant):', professorEmail);
  }

  const studentTenants = await StudentTenantModel.find({ tenantId });
  for (const st of studentTenants) {
    await StudentTenantModel.findByIdAndDelete(st._id);
    const other = await StudentTenantModel.findOne({ studentId: st.studentId });
    if (!other) {
      const student = await StudentModel.findById(st.studentId);
      if (student) {
        await AuthUserModel.findByIdAndDelete(student.authUserId);
        await StudentModel.findByIdAndDelete(student._id);
        console.log('Deleted Student + AuthUser:', student.email);
      }
    }
  }

  await TenantModel.findByIdAndDelete(tenantId);
  console.log('Deleted Tenant:', tenant.name);

  initFirebase();
  await deleteFirebaseUserByEmail(adminEmail);
  await deleteFirebaseUserByEmail(professorEmail);
  for (let i = 1; i <= STUDENT_COUNT; i++) {
    await deleteFirebaseUserByEmail(`student${i}@${slugBase}.seed.local`);
  }

  console.log('\n--- Rollback completed ---');
  await mongoose.disconnect();
}

rollback().catch((err) => {
  console.error(err);
  process.exit(1);
});
