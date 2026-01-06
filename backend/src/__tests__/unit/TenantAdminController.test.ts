/**
 * Unit Tests for TenantAdminController
 * TEN-88: MT-BACK-006 - Testing de TenantAdminController
 */

import { describe, it, beforeEach, expect, jest, beforeAll, afterAll } from '@jest/globals';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Types } from 'mongoose';
import { TenantAdminController } from '../../application/controllers/TenantAdminController';
import { TenantService } from '../../application/services/TenantService';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { TenantAdminModel } from '../../infrastructure/database/models/TenantAdminModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { Request, Response } from 'express';

describe('TenantAdminController', () => {
  let mongo: MongoMemoryServer;
  let controller: TenantAdminController;
  let tenantService: TenantService;
  let tenantId: string;
  let tenantAdminId: string;
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;

  beforeAll(async () => {
    mongo = await MongoMemoryServer.create();
    const mongoUri = mongo.getUri();
    await mongoose.connect(mongoUri);
    tenantService = new TenantService();
    controller = new TenantAdminController(tenantService);
  });

  beforeEach(async () => {
    // Clean up
    await TenantModel.deleteMany({});
    await TenantAdminModel.deleteMany({});
    await AuthUserModel.deleteMany({});
    await ProfessorModel.deleteMany({});
    await ProfessorTenantModel.deleteMany({});
    await CourtModel.deleteMany({});
    await BookingModel.deleteMany({});
    await PaymentModel.deleteMany({});
    await StudentTenantModel.deleteMany({});

    // Create Tenant Admin
    const adminUser = await AuthUserModel.create({
      email: 'admin@test.com',
      name: 'Tenant Admin',
      role: 'tenant_admin',
    });
    tenantAdminId = adminUser._id.toString();

    // Create Tenant
    const tenant = await TenantModel.create({
      name: 'Test Center',
      slug: 'test-center',
      adminUserId: adminUser._id,
      isActive: true,
    });
    tenantId = tenant._id.toString();

    // Create TenantAdmin relation
    await TenantAdminModel.create({
      tenantId: tenant._id,
      adminUserId: adminUser._id,
      isActive: true,
    });

    // Setup mocks
    mockRequest = {
      user: { id: tenantAdminId, role: 'tenant_admin' },
      tenantId,
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

  describe('getTenantInfo', () => {
    it('should return tenant information', async () => {
      await controller.getTenantInfo(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          id: tenantId,
          name: 'Test Center',
          slug: 'test-center',
        }),
      );
    });

    it('should return 401 if user is not authenticated', async () => {
      mockRequest.user = undefined;

      await controller.getTenantInfo(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
    });

    it('should return 404 if user is not admin of any tenant', async () => {
      await TenantAdminModel.deleteMany({});
      mockRequest.user = { id: tenantAdminId, role: 'tenant_admin' };

      await controller.getTenantInfo(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });
  });

  describe('updateTenantConfig', () => {
    it('should update tenant configuration', async () => {
      mockRequest.body = {
        name: 'Updated Center',
        config: {
          logo: 'https://example.com/logo.png',
          primaryColor: '#FF0000',
        },
      };

      await controller.updateTenantConfig(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Updated Center',
          config: expect.objectContaining({
            logo: 'https://example.com/logo.png',
            primaryColor: '#FF0000',
          }),
        }),
      );
    });

    it('should return 401 if user is not authenticated', async () => {
      mockRequest.user = undefined;
      mockRequest.body = { name: 'Updated Center' };

      await controller.updateTenantConfig(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
    });
  });

  describe('listProfessors', () => {
    it('should return list of professors', async () => {
      // Create professor
      const profAuth = await AuthUserModel.create({
        email: 'prof@test.com',
        name: 'Professor',
        role: 'professor',
      });

      const professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'prof@test.com',
        phone: '123456789',
        hourlyRate: 100,
        experienceYears: 5,
      });

      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: new Types.ObjectId(tenantId),
        isActive: true,
      });

      await controller.listProfessors(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          professors: expect.arrayContaining([
            expect.objectContaining({
              name: 'Professor',
              email: 'prof@test.com',
            }),
          ]),
        }),
      );
    });

    it('should return 400 if tenantId is missing', async () => {
      mockRequest.tenantId = undefined;

      await controller.listProfessors(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });

  describe('inviteProfessor', () => {
    it('should add existing professor to tenant', async () => {
      // Create professor
      const profAuth = await AuthUserModel.create({
        email: 'prof@test.com',
        name: 'Professor',
        role: 'professor',
      });

      const professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'prof@test.com',
        phone: '123456789',
        hourlyRate: 100,
        experienceYears: 5,
      });

      mockRequest.body = {
        email: 'prof@test.com',
        pricing: {
          individualClass: 120,
        },
      };

      await controller.inviteProfessor(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(201);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          professorId: professor._id.toString(),
          tenantId,
        }),
      );
    });

    it('should return 400 if email is missing', async () => {
      mockRequest.body = {};

      await controller.inviteProfessor(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });

    it('should create professor automatically if does not exist', async () => {
      mockRequest.body = { email: 'nonexistent@test.com' };

      await controller.inviteProfessor(mockRequest as Request, mockResponse as Response);

      // Should create the professor automatically and return 201
      expect(mockResponse.status).toHaveBeenCalledWith(201);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          tenantId,
          message: 'Profesor agregado al tenant exitosamente',
        }),
      );
    });
  });

  describe('activateProfessor', () => {
    it('should activate professor in tenant', async () => {
      // Create professor
      const profAuth = await AuthUserModel.create({
        email: 'prof@test.com',
        name: 'Professor',
        role: 'professor',
      });

      const professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'prof@test.com',
        phone: '123456789',
        hourlyRate: 100,
        experienceYears: 5,
      });

      const professorTenant = await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: new Types.ObjectId(tenantId),
        isActive: false,
      });

      mockRequest.params = { id: professor._id.toString() };

      await controller.activateProfessor(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          isActive: true,
        }),
      );
    });

    it('should return 404 if professor does not exist', async () => {
      mockRequest.params = { id: new Types.ObjectId().toString() };

      await controller.activateProfessor(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });
  });

  describe('deactivateProfessor', () => {
    it('should deactivate professor in tenant', async () => {
      // Create professor
      const profAuth = await AuthUserModel.create({
        email: 'prof@test.com',
        name: 'Professor',
        role: 'professor',
      });

      const professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'prof@test.com',
        phone: '123456789',
        hourlyRate: 100,
        experienceYears: 5,
      });

      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: new Types.ObjectId(tenantId),
        isActive: true,
      });

      mockRequest.params = { id: professor._id.toString() };

      await controller.deactivateProfessor(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          isActive: false,
        }),
      );
    });
  });

  describe('listCourts', () => {
    it('should return list of courts', async () => {
      await CourtModel.create({
        tenantId: new Types.ObjectId(tenantId),
        name: 'Cancha 1',
        type: 'tennis',
        price: 50,
        isActive: true,
      });

      await controller.listCourts(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          courts: expect.arrayContaining([
            expect.objectContaining({
              name: 'Cancha 1',
              type: 'tennis',
              price: 50,
            }),
          ]),
        }),
      );
    });
  });

  describe('createCourt', () => {
    it('should create a court', async () => {
      mockRequest.body = {
        name: 'Cancha 1',
        type: 'tennis',
        price: 50,
        description: 'Cancha central',
      };

      await controller.createCourt(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(201);
      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Cancha 1',
          type: 'tennis',
          price: 50,
        }),
      );
    });

    it('should return 400 if required fields are missing', async () => {
      mockRequest.body = {
        name: 'Cancha 1',
        // Missing type and price
      };

      await controller.createCourt(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });

  describe('updateCourt', () => {
    it('should update a court', async () => {
      const court = await CourtModel.create({
        tenantId: new Types.ObjectId(tenantId),
        name: 'Cancha 1',
        type: 'tennis',
        price: 50,
        isActive: true,
      });

      mockRequest.params = { id: court._id.toString() };
      mockRequest.body = {
        name: 'Cancha Central',
        price: 60,
      };

      await controller.updateCourt(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Cancha Central',
          price: 60,
        }),
      );
    });

    it('should return 404 if court does not exist', async () => {
      mockRequest.params = { id: new Types.ObjectId().toString() };
      mockRequest.body = { name: 'Updated Court' };

      await controller.updateCourt(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });
  });

  describe('deleteCourt', () => {
    it('should delete a court', async () => {
      const court = await CourtModel.create({
        tenantId: new Types.ObjectId(tenantId),
        name: 'Cancha 1',
        type: 'tennis',
        price: 50,
        isActive: true,
      });

      mockRequest.params = { id: court._id.toString() };

      await controller.deleteCourt(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Cancha eliminada exitosamente',
        }),
      );
    });

    it('should return 404 if court does not exist', async () => {
      mockRequest.params = { id: new Types.ObjectId().toString() };

      await controller.deleteCourt(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });
  });

  describe('getMetrics', () => {
    it('should return tenant metrics', async () => {
      // Create test data
      const profAuth = await AuthUserModel.create({
        email: 'prof@test.com',
        name: 'Professor',
        role: 'professor',
      });

      const professor = await ProfessorModel.create({
        authUserId: profAuth._id,
        name: 'Professor',
        email: 'prof@test.com',
        phone: '123456789',
        hourlyRate: 100,
        experienceYears: 5,
      });

      await ProfessorTenantModel.create({
        professorId: professor._id,
        tenantId: new Types.ObjectId(tenantId),
        isActive: true,
      });

      await CourtModel.create({
        tenantId: new Types.ObjectId(tenantId),
        name: 'Cancha 1',
        type: 'tennis',
        price: 50,
        isActive: true,
      });

      await PaymentModel.create({
        tenantId: new Types.ObjectId(tenantId),
        studentId: new Types.ObjectId(),
        professorId: professor._id,
        amount: 100,
        date: new Date(),
        method: 'cash',
        concept: 'Payment',
      });

      await controller.getMetrics(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.json).toHaveBeenCalledWith(
        expect.objectContaining({
          bookings: expect.objectContaining({
            total: expect.any(Number),
          }),
          payments: expect.objectContaining({
            total: expect.any(Number),
            revenue: expect.any(Number),
          }),
          users: expect.objectContaining({
            professors: 1,
            students: expect.any(Number),
          }),
          courts: expect.objectContaining({
            total: 1,
          }),
        }),
      );
    });

    it('should return 400 if tenantId is missing', async () => {
      mockRequest.tenantId = undefined;

      await controller.getMetrics(mockRequest as Request, mockResponse as Response);

      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });
});

