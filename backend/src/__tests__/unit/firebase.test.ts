/**
 * Tests unitarios para firebase.ts - Integración con Firebase Admin SDK
 * TS-015: Testing de Autenticación Firebase
 */

import admin from 'firebase-admin';
import { config } from '../../infrastructure/config';

// Mock de firebase-admin
jest.mock('firebase-admin', () => ({
  apps: [],
  initializeApp: jest.fn(),
  credential: {
    cert: jest.fn(),
  },
  auth: jest.fn(() => ({
    verifyIdToken: jest.fn(),
  })),
}));

// Mock de config
jest.mock('../../infrastructure/config', () => ({
  config: {
    firebase: {
      enabled: true,
      projectId: 'test-project',
      privateKey: 'test-private-key',
      clientEmail: 'test@test-project.iam.gserviceaccount.com',
    },
  },
}));

describe('Firebase Admin SDK Integration', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset admin.apps array
    (admin as any).apps = [];
  });

  describe('Firebase Initialization', () => {
    it('should initialize Firebase Admin SDK when enabled', () => {
      // Re-import to trigger initialization
      jest.resetModules();
      require('../../infrastructure/auth/firebase');

      expect(admin.initializeApp).toHaveBeenCalledWith({
        credential: admin.credential.cert({
          projectId: 'test-project',
          privateKeyId: 'key_id',
          privateKey: 'test-private-key',
          clientEmail: 'test@test-project.iam.gserviceaccount.com',
          clientId: 'client_id',
          authUri: 'https://accounts.google.com/o/oauth2/auth',
          tokenUri: 'https://oauth2.googleapis.com/token',
          authProviderX509CertUrl: 'https://www.googleapis.com/oauth2/v1/certs',
          clientX509CertUrl: 'https://www.googleapis.com/robot/v1/metadata/x509/test@test-project.iam.gserviceaccount.com',
        }),
        projectId: 'test-project',
      });
    });

    it('should not initialize Firebase when disabled', () => {
      // Mock disabled config
      jest.doMock('../../infrastructure/config', () => ({
        config: {
          firebase: {
            enabled: false,
            projectId: 'test-project',
            privateKey: 'test-private-key',
            clientEmail: 'test@test-project.iam.gserviceaccount.com',
          },
        },
      }));

      jest.resetModules();
      require('../../infrastructure/auth/firebase');

      expect(admin.initializeApp).not.toHaveBeenCalled();
    });

    it('should not initialize Firebase when already initialized', () => {
      // Mock existing apps
      (admin as any).apps = [{ name: 'existing-app' }];

      jest.resetModules();
      require('../../infrastructure/auth/firebase');

      expect(admin.initializeApp).not.toHaveBeenCalled();
    });

    it('should handle private key with escaped newlines', () => {
      const mockConfig = {
        firebase: {
          enabled: true,
          projectId: 'test-project',
          privateKey: '-----BEGIN PRIVATE KEY-----\\nMOCK_KEY\\n-----END PRIVATE KEY-----',
          clientEmail: 'test@test-project.iam.gserviceaccount.com',
        },
      };

      jest.doMock('../../infrastructure/config', () => ({
        config: mockConfig,
      }));

      jest.resetModules();
      require('../../infrastructure/auth/firebase');

      expect(admin.initializeApp).toHaveBeenCalledWith({
        credential: admin.credential.cert({
          projectId: 'test-project',
          privateKeyId: 'key_id',
          privateKey: '-----BEGIN PRIVATE KEY-----\nMOCK_KEY\n-----END PRIVATE KEY-----',
          clientEmail: 'test@test-project.iam.gserviceaccount.com',
          clientId: 'client_id',
          authUri: 'https://accounts.google.com/o/oauth2/auth',
          tokenUri: 'https://oauth2.googleapis.com/token',
          authProviderX509CertUrl: 'https://www.googleapis.com/oauth2/v1/certs',
          clientX509CertUrl: 'https://www.googleapis.com/robot/v1/metadata/x509/test@test-project.iam.gserviceaccount.com',
        }),
        projectId: 'test-project',
      });
    });
  });

  describe('Firebase Admin Export', () => {
    it('should export admin instance', () => {
      const firebaseModule = require('../../infrastructure/auth/firebase');
      expect(firebaseModule.default).toBe(admin);
    });
  });

  describe('Service Account Configuration', () => {
    it('should create correct service account object', () => {
      const expectedServiceAccount = {
        projectId: 'test-project',
        privateKeyId: 'key_id',
        privateKey: 'test-private-key',
        clientEmail: 'test@test-project.iam.gserviceaccount.com',
        clientId: 'client_id',
        authUri: 'https://accounts.google.com/o/oauth2/auth',
        tokenUri: 'https://oauth2.googleapis.com/token',
        authProviderX509CertUrl: 'https://www.googleapis.com/oauth2/v1/certs',
        clientX509CertUrl: 'https://www.googleapis.com/robot/v1/metadata/x509/test@test-project.iam.gserviceaccount.com',
      };

      jest.resetModules();
      require('../../infrastructure/auth/firebase');

      expect(admin.credential.cert).toHaveBeenCalledWith(expectedServiceAccount);
    });
  });

  describe('Error Handling', () => {
    it('should handle missing Firebase configuration gracefully', () => {
      jest.doMock('../../infrastructure/config', () => ({
        config: {
          firebase: {
            enabled: false,
            projectId: undefined,
            privateKey: undefined,
            clientEmail: undefined,
          },
        },
      }));

      expect(() => {
        jest.resetModules();
        require('../../infrastructure/auth/firebase');
      }).not.toThrow();
    });

    it('should handle Firebase initialization errors', () => {
      const mockError = new Error('Firebase initialization failed');
      (admin.initializeApp as jest.Mock).mockImplementation(() => {
        throw mockError;
      });

      expect(() => {
        jest.resetModules();
        require('../../infrastructure/auth/firebase');
      }).toThrow('Firebase initialization failed');
    });
  });
});
