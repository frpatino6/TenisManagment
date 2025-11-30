/**
 * Unit Tests for Multi-Tenant Models
 * TEN-83: MT-BACK-001 - Testing de Modelos Multi-Tenant
 * 
 * Tests unitarios para los modelos de multi-tenancy:
 * - TenantModel
 * - TenantAdminModel
 * - ProfessorTenantModel
 * - StudentTenantModel
 */

import { describe, it, beforeEach, expect, beforeAll, afterAll } from '@jest/globals';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import { TenantModel, TenantDocument } from '../../infrastructure/database/models/TenantModel';
import { TenantAdminModel, TenantAdminDocument } from '../../infrastructure/database/models/TenantAdminModel';
import { ProfessorTenantModel, ProfessorTenantDocument } from '../../infrastructure/database/models/ProfessorTenantModel';
import { StudentTenantModel, StudentTenantDocument } from '../../infrastructure/database/models/StudentTenantModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { ServiceRequestModel } from '../../infrastructure/database/models/ServiceRequestModel';

describe('Multi-Tenant Models', () => {
  let mongo: MongoMemoryServer;

  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    const mongoUri = mongo.getUri();
    await mongoose.connect(mongoUri);
  });

  beforeEach(async () => {
    await TenantModel.deleteMany({});
    await TenantAdminModel.deleteMany({});
    await ProfessorTenantModel.deleteMany({});
    await StudentTenantModel.deleteMany({});
    await AuthUserModel.deleteMany({});
    await ProfessorModel.deleteMany({});
    await StudentModel.deleteMany({});
    await BookingModel.deleteMany({});
    await ScheduleModel.deleteMany({});
    await PaymentModel.deleteMany({});
    await ServiceRequestModel.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongo.stop();
  });

  describe('TenantModel', () => {
    it('should create a tenant with required fields', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin@tenant.com',
        name: 'Tenant Admin',
        role: 'tenant_admin',
      });

      const tenant = await TenantModel.create({
        name: 'Club de Tenis',
        slug: 'club-tenis',
        adminUserId: adminUser._id,
        isActive: true,
      });

      expect(tenant).toBeTruthy();
      expect(tenant.name).toBe('Club de Tenis');
      expect(tenant.slug).toBe('club-tenis');
      expect(tenant.adminUserId.toString()).toBe(adminUser._id.toString());
      expect(tenant.isActive).toBe(true);
    });

    it('should generate slug automatically from name if not provided', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin2@tenant.com',
        name: 'Admin 2',
        role: 'tenant_admin',
      });

      const tenant = await TenantModel.create({
        name: 'Centro de Padel',
        adminUserId: adminUser._id,
      });

      expect(tenant.slug).toBe('centro-de-padel');
    });

    it('should enforce unique slug', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin3@tenant.com',
        name: 'Admin 3',
        role: 'tenant_admin',
      });

      await TenantModel.create({
        name: 'Tenant 1',
        slug: 'unique-slug',
        adminUserId: adminUser._id,
      });

      await expect(
        TenantModel.create({
          name: 'Tenant 2',
          slug: 'unique-slug',
          adminUserId: adminUser._id,
        })
      ).rejects.toThrow();
    });

    it('should allow optional domain', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin4@tenant.com',
        name: 'Admin 4',
        role: 'tenant_admin',
      });

      const tenant = await TenantModel.create({
        name: 'Tenant with Domain',
        slug: 'tenant-domain',
        domain: 'custom.tennis.com',
        adminUserId: adminUser._id,
      });

      expect(tenant.domain).toBe('custom.tennis.com');
    });

    it('should enforce unique domain when provided', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin5@tenant.com',
        name: 'Admin 5',
        role: 'tenant_admin',
      });

      await TenantModel.create({
        name: 'Tenant 1',
        slug: 'tenant-1',
        domain: 'unique.com',
        adminUserId: adminUser._id,
      });

      await expect(
        TenantModel.create({
          name: 'Tenant 2',
          slug: 'tenant-2',
          domain: 'unique.com',
          adminUserId: adminUser._id,
        })
      ).rejects.toThrow();
    });

    it('should store config with pricing and branding', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin6@tenant.com',
        name: 'Admin 6',
        role: 'tenant_admin',
      });

      const tenant = await TenantModel.create({
        name: 'Tenant with Config',
        slug: 'tenant-config',
        adminUserId: adminUser._id,
        config: {
          logo: 'https://example.com/logo.png',
          primaryColor: '#FF5733',
          secondaryColor: '#33FF57',
          basePricing: {
            individualClass: 50000,
            groupClass: 35000,
            courtRental: 25000,
          },
        },
      });

      expect(tenant.config?.logo).toBe('https://example.com/logo.png');
      expect(tenant.config?.basePricing?.individualClass).toBe(50000);
    });

    it('should default isActive to true', async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin7@tenant.com',
        name: 'Admin 7',
        role: 'tenant_admin',
      });

      const tenant = await TenantModel.create({
        name: 'Default Active',
        slug: 'default-active',
        adminUserId: adminUser._id,
      });

      expect(tenant.isActive).toBe(true);
    });
  });

  describe('TenantAdminModel', () => {
    let tenant: TenantDocument;
    let adminUser: any;

    beforeEach(async () => {
      adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin User',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
      });
    });

    it('should create tenant admin relationship', async () => {
      const tenantAdmin = await TenantAdminModel.create({
        tenantId: tenant._id,
        adminUserId: adminUser._id,
        isActive: true,
      });

      expect(tenantAdmin).toBeTruthy();
      expect(tenantAdmin.tenantId.toString()).toBe(tenant._id.toString());
      expect(tenantAdmin.adminUserId.toString()).toBe(adminUser._id.toString());
      expect(tenantAdmin.isActive).toBe(true);
      expect(tenantAdmin.joinedAt).toBeInstanceOf(Date);
    });

    it('should enforce unique tenantId + adminUserId combination', async () => {
      await TenantAdminModel.create({
        tenantId: tenant._id,
        adminUserId: adminUser._id,
      });

      await expect(
        TenantAdminModel.create({
          tenantId: tenant._id,
          adminUserId: adminUser._id,
        })
      ).rejects.toThrow();
    });

    it('should allow same admin for different tenants', async () => {
      const tenant2 = await TenantModel.create({
        name: 'Test Tenant 2',
        slug: 'test-tenant-2',
        adminUserId: adminUser._id,
      });

      const admin1 = await TenantAdminModel.create({
        tenantId: tenant._id,
        adminUserId: adminUser._id,
      });

      const admin2 = await TenantAdminModel.create({
        tenantId: tenant2._id,
        adminUserId: adminUser._id,
      });

      expect(admin1.tenantId.toString()).not.toBe(admin2.tenantId.toString());
      expect(admin1.adminUserId.toString()).toBe(admin2.adminUserId.toString());
    });

    it('should default isActive to true', async () => {
      const tenantAdmin = await TenantAdminModel.create({
        tenantId: tenant._id,
        adminUserId: adminUser._id,
      });

      expect(tenantAdmin.isActive).toBe(true);
    });
  });

  describe('ProfessorTenantModel', () => {
    let tenant: TenantDocument;
    let professor: any;

    beforeEach(async () => {
      const authUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Professor User',
        role: 'professor',
      });

      professor = await ProfessorModel.create({
        authUserId: authUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '1234567890',
        hourlyRate: 60,
        experienceYears: 5,
      });

      const adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin User',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
      });
    });

    it('should create professor-tenant relationship', async () => {
      const professorTenant = await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
        isActive: true,
      });

      expect(professorTenant).toBeTruthy();
      expect(professorTenant.professorId.toString()).toBe(professor._id.toString());
      expect(professorTenant.tenantId.toString()).toBe(tenant._id.toString());
      expect(professorTenant.isActive).toBe(true);
      expect(professorTenant.joinedAt).toBeInstanceOf(Date);
    });

    it('should enforce unique professorId + tenantId combination', async () => {
      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
      });

      await expect(
        ProfessorTenantModel.create({
          professorId: professor._id,
          tenantId: tenant._id,
        })
      ).rejects.toThrow();
    });

    it('should allow professor to work in multiple tenants', async () => {
      const adminUser2 = await AuthUserModel.create({
        email: 'admin2@test.com',
        name: 'Admin 2',
        role: 'tenant_admin',
      });

      const tenant2 = await TenantModel.create({
        name: 'Test Tenant 2',
        slug: 'test-tenant-2',
        adminUserId: adminUser2._id,
      });

      const pt1 = await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
      });

      const pt2 = await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant2._id,
      });

      expect(pt1.tenantId.toString()).not.toBe(pt2.tenantId.toString());
      expect(pt1.professorId.toString()).toBe(pt2.professorId.toString());
    });

    it('should store tenant-specific pricing', async () => {
      const professorTenant = await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
        pricing: {
          individualClass: 70000,
          groupClass: 50000,
          courtRental: 30000,
        },
      });

      expect(professorTenant.pricing?.individualClass).toBe(70000);
      expect(professorTenant.pricing?.groupClass).toBe(50000);
      expect(professorTenant.pricing?.courtRental).toBe(30000);
    });

    it('should default isActive to true', async () => {
      const professorTenant = await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: tenant._id,
      });

      expect(professorTenant.isActive).toBe(true);
    });
  });

  describe('StudentTenantModel', () => {
    let tenant: TenantDocument;
    let student: any;

    beforeEach(async () => {
      const authUser = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Student User',
        role: 'student',
      });

      student = await StudentModel.create({
        authUserId: authUser._id,
        name: 'Test Student',
        email: 'student@test.com',
        membershipType: 'basic',
        balance: 0,
      });

      const adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin User',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
      });
    });

    it('should create student-tenant relationship', async () => {
      const studentTenant = await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
        balance: 0,
      });

      expect(studentTenant).toBeTruthy();
      expect(studentTenant.studentId.toString()).toBe(student._id.toString());
      expect(studentTenant.tenantId.toString()).toBe(tenant._id.toString());
      expect(studentTenant.balance).toBe(0);
      expect(studentTenant.isActive).toBe(true);
      expect(studentTenant.joinedAt).toBeInstanceOf(Date);
    });

    it('should enforce unique studentId + tenantId combination', async () => {
      await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
      });

      await expect(
        StudentTenantModel.create({
          studentId: student._id,
          tenantId: tenant._id,
        })
      ).rejects.toThrow();
    });

    it('should allow student to have balance in multiple tenants', async () => {
      const adminUser2 = await AuthUserModel.create({
        email: 'admin2@test.com',
        name: 'Admin 2',
        role: 'tenant_admin',
      });

      const tenant2 = await TenantModel.create({
        name: 'Test Tenant 2',
        slug: 'test-tenant-2',
        adminUserId: adminUser2._id,
      });

      const st1 = await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
        balance: 1000,
      });

      const st2 = await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant2._id,
        balance: 500,
      });

      expect(st1.balance).toBe(1000);
      expect(st2.balance).toBe(500);
      expect(st1.tenantId.toString()).not.toBe(st2.tenantId.toString());
    });

    it('should default balance to 0', async () => {
      const studentTenant = await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
      });

      expect(studentTenant.balance).toBe(0);
    });

    it('should default isActive to true', async () => {
      const studentTenant = await StudentTenantModel.create({
        studentId: student._id,
        tenantId: tenant._id,
      });

      expect(studentTenant.isActive).toBe(true);
    });
  });

  describe('Models with tenantId requirement', () => {
    let tenant: TenantDocument;
    let student: any;
    let professor: any;

    beforeEach(async () => {
      const adminUser = await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Admin User',
        role: 'tenant_admin',
      });

      tenant = await TenantModel.create({
        name: 'Test Tenant',
        slug: 'test-tenant',
        adminUserId: adminUser._id,
      });

      const studentAuth = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Student User',
        role: 'student',
      });

      student = await StudentModel.create({
        authUserId: studentAuth._id,
        name: 'Test Student',
        email: 'student@test.com',
        membershipType: 'basic',
        balance: 0,
      });

      const profAuth = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Professor User',
        role: 'professor',
      });

      professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '1234567890',
        hourlyRate: 60,
        experienceYears: 5,
      });
    });

    describe('BookingModel', () => {
      it('should require tenantId when creating booking', async () => {
        const schedule = await ScheduleModel.create({
          tenantId: tenant._id,
          professorId: professor._id,
          date: new Date('2024-12-01'),
          startTime: new Date('2024-12-01T10:00:00Z'),
          endTime: new Date('2024-12-01T11:00:00Z'),
          isAvailable: false,
        });

        const booking = await BookingModel.create({
          tenantId: tenant._id,
          scheduleId: schedule._id,
          studentId: student._id,
          professorId: professor._id,
          serviceType: 'individual_class',
          price: 50000,
          status: 'confirmed',
        });

        expect(booking.tenantId.toString()).toBe(tenant._id.toString());
      });

      it('should fail without tenantId', async () => {
        const schedule = await ScheduleModel.create({
          tenantId: tenant._id,
          professorId: professor._id,
          date: new Date('2024-12-01'),
          startTime: new Date('2024-12-01T10:00:00Z'),
          endTime: new Date('2024-12-01T11:00:00Z'),
          isAvailable: false,
        });

        await expect(
          BookingModel.create({
            scheduleId: schedule._id,
            studentId: student._id,
            professorId: professor._id,
            serviceType: 'individual_class',
            price: 50000,
            status: 'confirmed',
          } as any)
        ).rejects.toThrow();
      });
    });

    describe('ScheduleModel', () => {
      it('should require tenantId when creating schedule', async () => {
        const schedule = await ScheduleModel.create({
          tenantId: tenant._id,
          professorId: professor._id,
          date: new Date('2024-12-01'),
          startTime: new Date('2024-12-01T10:00:00Z'),
          endTime: new Date('2024-12-01T11:00:00Z'),
          isAvailable: true,
        });

        expect(schedule.tenantId.toString()).toBe(tenant._id.toString());
      });

      it('should fail without tenantId', async () => {
        await expect(
          ScheduleModel.create({
            professorId: professor._id,
            date: new Date('2024-12-01'),
            startTime: new Date('2024-12-01T10:00:00Z'),
            endTime: new Date('2024-12-01T11:00:00Z'),
            isAvailable: true,
          } as any)
        ).rejects.toThrow();
      });
    });

    describe('PaymentModel', () => {
      it('should require tenantId when creating payment', async () => {
        const payment = await PaymentModel.create({
          tenantId: tenant._id,
          studentId: student._id,
          professorId: professor._id,
          amount: 50000,
          date: new Date('2024-12-01'),
          method: 'cash',
          status: 'paid',
        });

        expect(payment.tenantId.toString()).toBe(tenant._id.toString());
      });

      it('should fail without tenantId', async () => {
        await expect(
          PaymentModel.create({
            studentId: student._id,
            professorId: professor._id,
            amount: 50000,
            date: new Date('2024-12-01'),
            method: 'cash',
            status: 'paid',
          } as any)
        ).rejects.toThrow();
      });
    });

    describe('ServiceRequestModel', () => {
      it('should require tenantId when creating service request', async () => {
        const { ServiceModel } = await import('../../infrastructure/database/models/ServiceModel');
        const service = await ServiceModel.create({
          name: 'Test Service',
          description: 'Test Description',
          category: 'other',
          price: 10000,
        });

        const serviceRequest = await ServiceRequestModel.create({
          tenantId: tenant._id,
          studentId: student._id,
          serviceId: service._id,
          status: 'requested',
        });

        expect(serviceRequest.tenantId.toString()).toBe(tenant._id.toString());
      });

      it('should fail without tenantId', async () => {
        const { ServiceModel } = await import('../../infrastructure/database/models/ServiceModel');
        const service = await ServiceModel.create({
          name: 'Test Service',
          description: 'Test Description',
          category: 'other',
          price: 10000,
        });

        await expect(
          ServiceRequestModel.create({
            studentId: student._id,
            serviceId: service._id,
            status: 'requested',
          } as any)
        ).rejects.toThrow();
      });
    });
  });
});

