/**
 * Unit Tests for SuperAdminController
 * TEN-87: MT-BACK-005 - Testing de SuperAdminController
 */

import { describe, it, beforeEach, expect, jest, beforeAll, afterAll } from '@jest/globals';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Types } from 'mongoose';
import { SuperAdminController } from '../../application/controllers/SuperAdminController';
import { TenantService } from '../../application/services/TenantService';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { Request, Response } from 'express';

describe('SuperAdminController', () => {
  let mongo: MongoMemoryServer;
  let controller: SuperAdminController;
  let tenantService: TenantService;
  let superAdminId: string;
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;

  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    const mongoUri = mongo.getUri();
    await mongoose.connect(mongoUri);
    tenantService = new TenantService();
    controller = new SuperAdminController(tenantService);
  });

  beforeEach(async () => {
    // Clean up
    await TenantModel.deleteMany({});
    await AuthUserModel.deleteMany({});
    await BookingModel.deleteMany({});
    await ScheduleModel.deleteMany({});
    await PaymentModel.deleteMany({});
    await ProfessorTenantModel.deleteMany({});
    await StudentTenantModel.deleteMany({});

    // Create Super Admin
    const superAdmin = await AuthUserModel.create({
      email: 'superadmin@test.com',
      name: 'Super Admin',
      role: 'super_admin',
    });
    superAdminId = superAdmin._id.toString();

    // Setup mocks
    mockRequest = {
      user: { id: superAdminId, role: 'super_admin' },
      params: {},
      body: {},
    };

    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongo.stop();
  });

  describe('createTenant', () => {
    it('should create a tenant successfully', async () => {
      mockRequest.body = {
        name: 'Test Center',
        adminEmail: 'admin@test.com',
        adminName: 'Admin User',
      };

      await controller.createTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(201);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Test Center',
          isActive: true,
        }),
      );

      // Verify tenant was created
      const tenant = await TenantModel.findOne({ name: 'Test Center' });
      expect(tenant).not.toBeNull();
      expect(tenant?.slug).toBe('test-center');
    });

    it('should return 400 if required fields are missing', async () => {
      mockRequest.body = {
        name: 'Test Center',
        // Missing adminEmail and adminName
      };

      await controller.createTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'name, adminEmail y adminName son requeridos',
      });
    });

    it('should return 409 if email already exists', async () => {
      await AuthUserModel.create({
        email: 'admin@test.com',
        name: 'Existing Admin',
        role: 'tenant_admin',
      });

      mockRequest.body = {
        name: 'Test Center',
        adminEmail: 'admin@test.com',
        adminName: 'Admin User',
      };

      await controller.createTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(409);
    });

    it('should return 401 if user is not authenticated', async () => {
      mockRequest.user = undefined;
      mockRequest.body = {
        name: 'Test Center',
        adminEmail: 'admin@test.com',
        adminName: 'Admin User',
      };

      await controller.createTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
    });
  });

  describe('listTenants', () => {
    it('should list all tenants with metrics', async () => {
      // Create tenants
      const tenant1 = await TenantModel.create({
        name: 'Center 1',
        slug: 'center-1',
        adminUserId: new Types.ObjectId(),
        isActive: true,
      });

      const tenant2 = await TenantModel.create({
        name: 'Center 2',
        slug: 'center-2',
        adminUserId: new Types.ObjectId(),
        isActive: false,
      });

      // Create some data for metrics
      await BookingModel.create({
        tenantId: tenant1._id,
        studentId: new Types.ObjectId(),
        scheduleId: new Types.ObjectId(),
        professorId: new Types.ObjectId(),
        serviceType: 'individual_class',
        price: 100,
        status: 'confirmed',
      });

      await controller.listTenants(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          tenants: expect.arrayContaining([
            expect.objectContaining({
              name: 'Center 1',
              metrics: expect.objectContaining({
                bookings: 1,
              }),
            }),
            expect.objectContaining({
              name: 'Center 2',
            }),
          ]),
        }),
      );
    });

    it('should return empty array if no tenants exist', async () => {
      await controller.listTenants(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith({
        tenants: [],
      });
    });
  });

  describe('getTenant', () => {
    it('should return tenant with metrics', async () => {
      const tenant = await TenantModel.create({
        name: 'Test Center',
        slug: 'test-center',
        adminUserId: new Types.ObjectId(),
        isActive: true,
      });

      // Create some data for metrics
      await BookingModel.create({
        tenantId: tenant._id,
        studentId: new Types.ObjectId(),
        scheduleId: new Types.ObjectId(),
        professorId: new Types.ObjectId(),
        serviceType: 'individual_class',
        price: 100,
        status: 'confirmed',
      });

      mockRequest.params = { id: tenant._id.toString() };

      await controller.getTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          id: tenant._id.toString(),
          name: 'Test Center',
          metrics: expect.objectContaining({
            bookings: 1,
          }),
        }),
      );
    });

    it('should return 404 if tenant does not exist', async () => {
      mockRequest.params = { id: new Types.ObjectId().toString() };

      await controller.getTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
      expect(mockResponse.json).toHaveBeenCalledWith({
        error: 'Tenant no encontrado',
      });
    });
  });

  describe('updateTenant', () => {
    it('should update tenant successfully', async () => {
      const tenant = await TenantModel.create({
        name: 'Test Center',
        slug: 'test-center',
        adminUserId: new Types.ObjectId(),
        isActive: true,
      });

      mockRequest.params = { id: tenant._id.toString() };
      mockRequest.body = {
        name: 'Updated Center',
        isActive: false,
      };

      await controller.updateTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Updated Center',
          isActive: false,
        }),
      );
    });

    it('should return 404 if tenant does not exist', async () => {
      mockRequest.params = { id: new Types.ObjectId().toString() };
      mockRequest.body = { name: 'Updated Center' };

      await controller.updateTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });

    it('should return 401 if user is not authenticated', async () => {
      const tenant = await TenantModel.create({
        name: 'Test Center',
        slug: 'test-center',
        adminUserId: new Types.ObjectId(),
        isActive: true,
      });

      mockRequest.user = undefined;
      mockRequest.params = { id: tenant._id.toString() };
      mockRequest.body = { name: 'Updated Center' };

      await controller.updateTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
    });
  });

  describe('activateTenant', () => {
    it('should activate tenant successfully', async () => {
      const tenant = await TenantModel.create({
        name: 'Test Center',
        slug: 'test-center',
        adminUserId: new Types.ObjectId(),
        isActive: false,
      });

      mockRequest.params = { id: tenant._id.toString() };

      await controller.activateTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          isActive: true,
          message: 'Tenant activado exitosamente',
        }),
      );
    });

    it('should return 404 if tenant does not exist', async () => {
      mockRequest.params = { id: new Types.ObjectId().toString() };

      await controller.activateTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });
  });

  describe('deactivateTenant', () => {
    it('should deactivate tenant successfully', async () => {
      const tenant = await TenantModel.create({
        name: 'Test Center',
        slug: 'test-center',
        adminUserId: new Types.ObjectId(),
        isActive: true,
      });

      mockRequest.params = { id: tenant._id.toString() };

      await controller.deactivateTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          isActive: false,
          message: 'Tenant desactivado exitosamente',
        }),
      );
    });

    it('should return 404 if tenant does not exist', async () => {
      mockRequest.params = { id: new Types.ObjectId().toString() };

      await controller.deactivateTenant(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });
  });

  describe('getGlobalMetrics', () => {
    it('should return global metrics', async () => {
      // Create test data
      const tenant1 = await TenantModel.create({
        name: 'Center 1',
        slug: 'center-1',
        adminUserId: new Types.ObjectId(),
        isActive: true,
      });

      const tenant2 = await TenantModel.create({
        name: 'Center 2',
        slug: 'center-2',
        adminUserId: new Types.ObjectId(),
        isActive: false,
      });

      await BookingModel.create({
        tenantId: tenant1._id,
        studentId: new Types.ObjectId(),
        scheduleId: new Types.ObjectId(),
        professorId: new Types.ObjectId(),
        serviceType: 'individual_class',
        price: 100,
        status: 'confirmed',
      });

      await PaymentModel.create({
        tenantId: tenant1._id,
        studentId: new Types.ObjectId(),
        professorId: new Types.ObjectId(),
        amount: 150,
        date: new Date(),
        method: 'cash',
        concept: 'Payment',
      });

      await controller.getGlobalMetrics(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          tenants: expect.objectContaining({
            total: 2,
            active: 1,
            inactive: 1,
          }),
          bookings: expect.objectContaining({
            total: 1,
          }),
          payments: expect.objectContaining({
            total: 1,
            revenue: 150,
          }),
        }),
      );
    });

    it('should return zero metrics when no data exists', async () => {
      await controller.getGlobalMetrics(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          tenants: expect.objectContaining({
            total: 0,
            active: 0,
            inactive: 0,
          }),
          bookings: expect.objectContaining({
            total: 0,
          }),
          payments: expect.objectContaining({
            total: 0,
            revenue: 0,
          }),
        }),
      );
    });
  });
});
