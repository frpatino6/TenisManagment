/**
 * Unit Tests for TenantService
 * TEN-84: MT-BACK-002 - Testing de TenantService
 */

import { describe, it, beforeEach, expect, beforeAll, afterAll } from '@jest/globals';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import { TenantService } from '../../application/services/TenantService';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { TenantAdminModel } from '../../infrastructure/database/models/TenantAdminModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';

describe('TenantService', () => {
  let mongo: MongoMemoryServer;
  let tenantService: TenantService;

  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    const mongoUri = mongo.getUri();
    await mongoose.connect(mongoUri);
    tenantService = new TenantService();
  });

  beforeEach(async () => {
    await TenantModel.deleteMany({});
    await TenantAdminModel.deleteMany({});
    await ProfessorTenantModel.deleteMany({});
    await StudentTenantModel.deleteMany({});
    await AuthUserModel.deleteMany({});
    await ProfessorModel.deleteMany({});
    await StudentModel.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongo.stop();
  });

  describe('createTenant', () => {
    let superAdmin: any;

    beforeEach(async () => {
      superAdmin = await AuthUserModel.create({
        email: 'superadmin@test.com',
        name: 'Super Admin',
        role: 'super_admin',
      });
    });

    it('should create tenant with admin user and relation', async () => {
      const result = await tenantService.createTenant(
        {
          name: 'Club de Tenis',
          adminEmail: 'admin@club.com',
          adminName: 'Admin User',
        },
        superAdmin._id.toString(),
      );

      expect(result).toBeTruthy();
      expect(result.name).toBe('Club de Tenis');
      expect(result.slug).toBe('club-de-tenis');

      // Verificar que se creó el AuthUser del admin
      const adminUser = await AuthUserModel.findOne({ email: 'admin@club.com' });
      expect(adminUser).toBeTruthy();
      expect(adminUser?.role).toBe('tenant_admin');

      // Verificar que se creó la relación TenantAdmin
      const tenantAdmin = await TenantAdminModel.findOne({
        tenantId: result._id,
        adminUserId: adminUser?._id,
      });
      expect(tenantAdmin).toBeTruthy();
      expect(tenantAdmin?.isActive).toBe(true);
    });

    it('should generate slug automatically if not provided', async () => {
      const result = await tenantService.createTenant(
        {
          name: 'Centro de Padel',
          adminEmail: 'admin2@club.com',
          adminName: 'Admin 2',
        },
        superAdmin._id.toString(),
      );

      expect(result.slug).toBe('centro-de-padel');
    });

    it('should use provided slug if given', async () => {
      const result = await tenantService.createTenant(
        {
          name: 'Club de Tenis',
          slug: 'custom-slug',
          adminEmail: 'admin3@club.com',
          adminName: 'Admin 3',
        },
        superAdmin._id.toString(),
      );

      expect(result.slug).toBe('custom-slug');
    });

    it('should throw error if user is not super admin', async () => {
      const regularUser = await AuthUserModel.create({
        email: 'user@test.com',
        name: 'Regular User',
        role: 'student',
      });

      await expect(
        tenantService.createTenant(
          {
            name: 'Club de Tenis',
            adminEmail: 'admin4@club.com',
            adminName: 'Admin 4',
          },
          regularUser._id.toString(),
        ),
      ).rejects.toThrow('Solo Super Admin puede crear tenants');
    });

    it('should throw error if admin email already exists', async () => {
      await AuthUserModel.create({
        email: 'existing@test.com',
        name: 'Existing User',
        role: 'student',
      });

      await expect(
        tenantService.createTenant(
          {
            name: 'Club de Tenis',
            adminEmail: 'existing@test.com',
            adminName: 'Admin',
          },
          superAdmin._id.toString(),
        ),
      ).rejects.toThrow('El email del admin ya está registrado');
    });

    it('should throw error if slug already exists', async () => {
      await tenantService.createTenant(
        {
          name: 'Club de Tenis',
          slug: 'existing-slug',
          adminEmail: 'admin5@club.com',
          adminName: 'Admin 5',
        },
        superAdmin._id.toString(),
      );

      await expect(
        tenantService.createTenant(
          {
            name: 'Another Club',
            slug: 'existing-slug',
            adminEmail: 'admin6@club.com',
            adminName: 'Admin 6',
          },
          superAdmin._id.toString(),
        ),
      ).rejects.toThrow('El slug ya está en uso');
    });

    it('should store config if provided', async () => {
      const result = await tenantService.createTenant(
        {
          name: 'Club con Config',
          adminEmail: 'admin7@club.com',
          adminName: 'Admin 7',
          config: {
            logo: 'https://example.com/logo.png',
            primaryColor: '#FF5733',
            basePricing: {
              individualClass: 50000,
              groupClass: 35000,
            },
          },
        },
        superAdmin._id.toString(),
      );

      expect(result.config?.logo).toBe('https://example.com/logo.png');
      expect(result.config?.basePricing?.individualClass).toBe(50000);
    });
  });

  describe('getTenantById', () => {
    it('should return tenant if exists', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin',
        role: 'tenant_admin',
      });

      const tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
      });

      const result = await tenantService.getTenantById(tenant._id.toString());
      expect(result).toBeTruthy();
      expect(result?.name).toBe('Test Tenant');
    });

    it('should return null if tenant does not exist', async () => {
      const result = await tenantService.getTenantById(new mongoose.Types.ObjectId().toString());
      expect(result).toBeNull();
    });
  });

  describe('updateTenant', () => {
    let tenant: any;
    let superAdmin: any;
    let tenantAdmin: any;

    beforeEach(async () => {
      superAdmin = await AuthUserModel.create({
        email: 'superadmin@test.com',
        name: 'Super Admin',
        role: 'super_admin',
      });

      tenantAdmin = await AuthUserModel.create({
        email: 'tenantadmin@test.com',
        name: 'Tenant Admin',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Original Name',
        slug: 'original-slug',
        adminUserId: tenantAdmin._id,
      });

      await TenantAdminModel.create({
        tenantId: tenant._id,
        adminUserId: tenantAdmin._id,
        isActive: true,
      });
    });

    it('should update tenant as super admin', async () => {
      const result = await tenantService.updateTenant(
        tenant._id.toString(),
        { name: 'Updated Name' },
        superAdmin._id.toString(),
        'super_admin',
      );

      expect(result?.name).toBe('Updated Name');
    });

    it('should update tenant as tenant admin', async () => {
      const result = await tenantService.updateTenant(
        tenant._id.toString(),
        { name: 'Updated by Admin' },
        tenantAdmin._id.toString(),
        'tenant_admin',
      );

      expect(result?.name).toBe('Updated by Admin');
    });

    it('should throw error if user is not super admin or tenant admin', async () => {
      const student = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Student',
        role: 'student',
      });

      await expect(
        tenantService.updateTenant(
          tenant._id.toString(),
          { name: 'Updated' },
          student._id.toString(),
          'student',
        ),
      ).rejects.toThrow('Solo Super Admin o Tenant Admin pueden actualizar tenants');
    });

    it('should throw error if tenant admin tries to update different tenant', async () => {
      const otherAdmin = await AuthUserModel.create({
        email: 'otheradmin@test.com',
        name: 'Other Admin',
        role: 'tenant_admin',
      });

      await expect(
        tenantService.updateTenant(
          tenant._id.toString(),
          { name: 'Updated' },
          otherAdmin._id.toString(),
          'tenant_admin',
        ),
      ).rejects.toThrow('No tienes permisos para actualizar este tenant');
    });

    it('should validate unique slug when updating', async () => {
      await TenantModel.create({
        name: 'Other Tenant',
        slug: 'taken-slug',
        adminUserId: tenantAdmin._id,
      });

      await expect(
        tenantService.updateTenant(
          tenant._id.toString(),
          { slug: 'taken-slug' },
          superAdmin._id.toString(),
          'super_admin',
        ),
      ).rejects.toThrow('El slug ya está en uso');
    });
  });

  describe('getUserTenants', () => {
    let tenant: any;
    let professor: any;
    let student: any;
    let tenantAdmin: any;

    beforeEach(async () => {
      tenantAdmin = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: tenantAdmin._id,
      });

      await TenantAdminModel.create({
        tenantId: tenant._id,
        adminUserId: tenantAdmin._id,
        isActive: true,
      });

      const profAuth = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Professor',
        role: 'professor',
      });

      professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'professor@test.com',
        phone: '1234567890',
        hourlyRate: 60,
        experienceYears: 5,
      });

      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
        isActive: true,
      });

      const studentAuth = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Student',
        role: 'student',
      });

      student = await StudentModel.create({
        authUserId: studentAuth._id,
        name: 'Student',
        email: 'student@test.com',
        membershipType: 'basic',
        balance: 0,
      });

      await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
        isActive: true,
      });
    });

    it('should return tenants for tenant admin', async () => {
      const result = await tenantService.getUserTenants(
        tenantAdmin._id.toString(),
        'tenant_admin',
      );

      expect(result).toHaveLength(1);
      expect(result[0].tenantId).toBe(tenant._id.toString());
      expect(result[0].role).toBe('tenant_admin');
    });

    it('should return tenants for professor', async () => {
      const profAuth = await AuthUserModel.findOne({ email: 'professor@test.com' });
      const result = await tenantService.getUserTenants(profAuth!._id.toString(), 'professor');

      expect(result).toHaveLength(1);
      expect(result[0].tenantId).toBe(tenant._id.toString());
      expect(result[0].role).toBe('professor');
    });

    it('should return tenants for student', async () => {
      const studentAuth = await AuthUserModel.findOne({ email: 'student@test.com' });
      const result = await tenantService.getUserTenants(studentAuth!._id.toString(), 'student');

      expect(result).toHaveLength(1);
      expect(result[0].tenantId).toBe(tenant._id.toString());
      expect(result[0].role).toBe('student');
    });

    it('should return empty array if user has no tenants', async () => {
      const newStudent = await AuthUserModel.create({
        email: 'newstudent@test.com',
        name: 'New Student',
        role: 'student',
      });

      const result = await tenantService.getUserTenants(newStudent._id.toString(), 'student');
      expect(result).toHaveLength(0);
    });
  });

  describe('validateTenantAccess', () => {
    let tenant: any;
    let superAdmin: any;
    let tenantAdmin: any;
    let professor: any;
    let student: any;

    beforeEach(async () => {
      superAdmin = await AuthUserModel.create({
        email: 'superadmin@test.com',
        name: 'Super Admin',
        role: 'super_admin',
      });

      tenantAdmin = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: tenantAdmin._id,
        isActive: true,
      });

      await TenantAdminModel.create({
        tenantId: tenant._id,
        adminUserId: tenantAdmin._id,
        isActive: true,
      });

      const profAuth = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Professor',
        role: 'professor',
      });

      professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'professor@test.com',
        phone: '1234567890',
        hourlyRate: 60,
        experienceYears: 5,
      });

      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
        isActive: true,
      });

      const studentAuth = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Student',
        role: 'student',
      });

      student = await StudentModel.create({
        authUserId: studentAuth._id,
        name: 'Student',
        email: 'student@test.com',
        membershipType: 'basic',
        balance: 0,
      });

      await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
        isActive: true,
      });
    });

    it('should allow access for super admin', async () => {
      const result = await tenantService.validateTenantAccess(
        superAdmin._id.toString(),
        'super_admin',
        tenant._id.toString(),
      );

      expect(result.hasAccess).toBe(true);
    });

    it('should allow access for tenant admin', async () => {
      const result = await tenantService.validateTenantAccess(
        tenantAdmin._id.toString(),
        'tenant_admin',
        tenant._id.toString(),
      );

      expect(result.hasAccess).toBe(true);
    });

    it('should allow access for professor in tenant', async () => {
      const profAuth = await AuthUserModel.findOne({ email: 'professor@test.com' });
      const result = await tenantService.validateTenantAccess(
        profAuth!._id.toString(),
        'professor',
        tenant._id.toString(),
      );

      expect(result.hasAccess).toBe(true);
    });

    it('should allow access for student in tenant', async () => {
      const studentAuth = await AuthUserModel.findOne({ email: 'student@test.com' });
      const result = await tenantService.validateTenantAccess(
        studentAuth!._id.toString(),
        'student',
        tenant._id.toString(),
      );

      expect(result.hasAccess).toBe(true);
    });

    it('should deny access if tenant does not exist', async () => {
      const result = await tenantService.validateTenantAccess(
        superAdmin._id.toString(),
        'super_admin',
        new mongoose.Types.ObjectId().toString(),
      );

      expect(result.hasAccess).toBe(false);
      expect(result.reason).toBe('Tenant no encontrado');
    });

    it('should deny access if tenant is inactive', async () => {
      tenant.isActive = false;
      await tenant.save();

      const result = await tenantService.validateTenantAccess(
        superAdmin._id.toString(),
        'super_admin',
        tenant._id.toString(),
      );

      expect(result.hasAccess).toBe(false);
      expect(result.reason).toBe('Tenant inactivo');
    });

    it('should deny access for professor not in tenant', async () => {
      const newProfAuth = await AuthUserModel.create({
        email: 'newprof@test.com',
        name: 'New Prof',
        role: 'professor',
      });

      const result = await tenantService.validateTenantAccess(
        newProfAuth._id.toString(),
        'professor',
        tenant._id.toString(),
      );

      expect(result.hasAccess).toBe(false);
      expect(result.reason).toBe('No estás registrado en este tenant');
    });
  });

  describe('getTenantConfig', () => {
    it('should return config if exists', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin',
        role: 'tenant_admin',
      });

      const tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
        config: {
          logo: 'https://example.com/logo.png',
          primaryColor: '#FF5733',
          basePricing: {
            individualClass: 50000,
          },
        },
      });

      const result = await tenantService.getTenantConfig(tenant._id.toString());
      expect(result).toBeTruthy();
      expect(result?.logo).toBe('https://example.com/logo.png');
    });

    it('should return null if config does not exist', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin2@test.com',
        name: 'Admin 2',
        role: 'tenant_admin',
      });

      const tenant = await TenantModel.create({
        name: 'Test Tenant 2',
        slug: 'test-tenant-2',
        adminUserId: adminUser._id,
      });

      const result = await tenantService.getTenantConfig(tenant._id.toString());
      expect(result).toBeNull();
    });

    it('should throw error if tenant does not exist', async () => {
      await expect(
        tenantService.getTenantConfig(new mongoose.Types.ObjectId().toString()),
      ).rejects.toThrow('Tenant no encontrado');
    });
  });

  describe('addProfessorToTenant', () => {
    let tenant: any;
    let professor: any;

    beforeEach(async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
      });

      const profAuth = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Professor',
        role: 'professor',
      });

      professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'professor@test.com',
        phone: '1234567890',
        hourlyRate: 60,
        experienceYears: 5,
      });
    });

    it('should add professor to tenant', async () => {
      const result = await tenantService.addProfessorToTenant(
        professor._id.toString(),
        tenant._id.toString(),
      );

      expect(result).toBeTruthy();
      expect(result.professorId.toString()).toBe(professor._id.toString());
      expect(result.tenantId.toString()).toBe(tenant._id.toString());
      expect(result.isActive).toBe(true);
    });

    it('should add professor with pricing', async () => {
      const result = await tenantService.addProfessorToTenant(
        professor._id.toString(),
        tenant._id.toString(),
        {
          individualClass: 70000,
          groupClass: 50000,
        },
      );

      expect(result.pricing?.individualClass).toBe(70000);
      expect(result.pricing?.groupClass).toBe(50000);
    });

    it('should reactivate if professor was previously removed', async () => {
      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
        isActive: false,
      });

      const result = await tenantService.addProfessorToTenant(
        professor._id.toString(),
        tenant._id.toString(),
      );

      expect(result.isActive).toBe(true);
    });

    it('should throw error if professor already active', async () => {
      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
        isActive: true,
      });

      await expect(
        tenantService.addProfessorToTenant(professor._id.toString(), tenant._id.toString()),
      ).rejects.toThrow('El profesor ya está activo en este tenant');
    });

    it('should throw error if professor does not exist', async () => {
      await expect(
        tenantService.addProfessorToTenant(
          new mongoose.Types.ObjectId().toString(),
          tenant._id.toString(),
        ),
      ).rejects.toThrow('Profesor no encontrado');
    });
  });

  describe('addStudentToTenant', () => {
    let tenant: any;
    let student: any;

    beforeEach(async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
      });

      const studentAuth = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Student',
        role: 'student',
      });

      student = await StudentModel.create({
        authUserId: studentAuth._id,
        name: 'Student',
        email: 'student@test.com',
        membershipType: 'basic',
        balance: 0,
      });
    });

    it('should add student to tenant with balance 0', async () => {
      const result = await tenantService.addStudentToTenant(
        student._id.toString(),
        tenant._id.toString(),
      );

      expect(result).toBeTruthy();
      expect(result.studentId.toString()).toBe(student._id.toString());
      expect(result.tenantId.toString()).toBe(tenant._id.toString());
      expect(result.balance).toBe(0);
      expect(result.isActive).toBe(true);
    });

    it('should return existing if student already active', async () => {
      const existing = await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
        balance: 1000,
        isActive: true,
      });

      const result = await tenantService.addStudentToTenant(
        student._id.toString(),
        tenant._id.toString(),
      );

      expect(result._id.toString()).toBe(existing._id.toString());
      expect(result.balance).toBe(1000); // Mantiene balance existente
    });

    it('should reactivate if student was previously removed', async () => {
      const existing = await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
        balance: 500,
        isActive: false,
      });

      const result = await tenantService.addStudentToTenant(
        student._id.toString(),
        tenant._id.toString(),
      );

      expect(result.isActive).toBe(true);
      expect(result.balance).toBe(500); // Mantiene balance
    });

    it('should throw error if student does not exist', async () => {
      await expect(
        tenantService.addStudentToTenant(
          new mongoose.Types.ObjectId().toString(),
          tenant._id.toString(),
        ),
      ).rejects.toThrow('Estudiante no encontrado');
    });
  });

  describe('removeUserFromTenant', () => {
    let tenant: any;
    let professor: any;
    let student: any;

    beforeEach(async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
      });

      const profAuth = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Professor',
        role: 'professor',
      });

      professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'professor@test.com',
        phone: '1234567890',
        hourlyRate: 60,
        experienceYears: 5,
      });

      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
        isActive: true,
      });

      const studentAuth = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Student',
        role: 'student',
      });

      student = await StudentModel.create({
        authUserId: studentAuth._id,
        name: 'Student',
        email: 'student@test.com',
        membershipType: 'basic',
        balance: 0,
      });

      await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
        isActive: true,
      });
    });

    it('should remove professor from tenant', async () => {
      const profAuth = await AuthUserModel.findOne({ email: 'professor@test.com' });
      const result = await tenantService.removeUserFromTenant(
        profAuth!._id.toString(),
        'professor',
        tenant._id.toString(),
      );

      expect(result).toBe(true);

      const professorTenant = await ProfessorTenantModel.findOne({
        professorId: professor._id,
        tenantId: tenant._id,
      });
      expect(professorTenant?.isActive).toBe(false);
    });

    it('should remove student from tenant', async () => {
      const studentAuth = await AuthUserModel.findOne({ email: 'student@test.com' });
      const result = await tenantService.removeUserFromTenant(
        studentAuth!._id.toString(),
        'student',
        tenant._id.toString(),
      );

      expect(result).toBe(true);

      const studentTenant = await StudentTenantModel.findOne({
        studentId: student._id,
        tenantId: tenant._id,
      });
      expect(studentTenant?.isActive).toBe(false);
    });

    it('should throw error if trying to remove tenant admin', async () => {
      const adminAuth = await AuthUserModel.findOne({ email: 'admin@test.com' });
      await expect(
        tenantService.removeUserFromTenant(
          adminAuth!._id.toString(),
          'tenant_admin',
          tenant._id.toString(),
        ),
      ).rejects.toThrow('No se puede remover un Tenant Admin de su tenant');
    });

    it('should return false if user has no relation', async () => {
      const newStudentAuth = await AuthUserModel.create({
        email: 'newstudent@test.com',
        name: 'New Student',
        role: 'student',
      });

      const result = await tenantService.removeUserFromTenant(
        newStudentAuth._id.toString(),
        'student',
        tenant._id.toString(),
      );

      expect(result).toBe(false);
    });
  });
});

