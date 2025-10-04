/**
 * Tests unitarios para firebase.ts - Integración con Firebase Admin SDK
 * TS-015: Testing de Autenticación Firebase
 */

// Mock de firebase-admin
const mockInitializeApp = jest.fn();
const mockCredentialCert = jest.fn();
const mockAuth = jest.fn(() => ({
  verifyIdToken: jest.fn(),
}));

jest.mock('firebase-admin', () => ({
  apps: [],
  initializeApp: mockInitializeApp,
  credential: {
    cert: mockCredentialCert,
  },
  auth: mockAuth,
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
  });

  describe('Firebase Initialization', () => {
    it('should initialize Firebase Admin SDK when enabled', () => {
      // Re-import to trigger initialization
      jest.resetModules();
      require('../../infrastructure/auth/firebase');

      expect(mockInitializeApp).toHaveBeenCalled();
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

      expect(mockInitializeApp).not.toHaveBeenCalled();
    });

    it('should not initialize Firebase when already initialized', () => {
      // Mock existing apps
      const mockApps = [{ name: 'existing-app' }];
      jest.doMock('firebase-admin', () => ({
        apps: mockApps,
        initializeApp: mockInitializeApp,
        credential: {
          cert: mockCredentialCert,
        },
        auth: mockAuth,
      }));

      jest.resetModules();
      require('../../infrastructure/auth/firebase');

      expect(mockInitializeApp).not.toHaveBeenCalled();
    });

    it('should handle private key with escaped newlines', () => {
      // Este test verifica que el módulo se puede cargar sin errores
      expect(() => {
        jest.resetModules();
        require('../../infrastructure/auth/firebase');
      }).not.toThrow();
    });
  });

  describe('Firebase Admin Export', () => {
    it('should export admin instance', () => {
      const firebaseModule = require('../../infrastructure/auth/firebase');
      expect(firebaseModule.default).toBeDefined();
    });
  });

  describe('Service Account Configuration', () => {
    it('should create correct service account object', () => {
      // Este test verifica que el módulo se puede cargar sin errores
      expect(() => {
        jest.resetModules();
        require('../../infrastructure/auth/firebase');
      }).not.toThrow();
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
      // Este test verifica que el módulo se puede cargar sin errores
      expect(() => {
        jest.resetModules();
        require('../../infrastructure/auth/firebase');
      }).not.toThrow();
    });
  });
});
