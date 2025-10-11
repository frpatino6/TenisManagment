/**
 * Tests unitarios para Core Services
 * TEN-68: TS-012 - Testing de Servicios Core
 */

import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { JwtService, JwtPayload } from '../../infrastructure/services/JwtService';
import { BcryptPasswordService } from '../../infrastructure/services/PasswordService';
import { Logger, createRequestId } from '../../infrastructure/services/Logger';

describe('Core Services', () => {
  
  describe('JwtService', () => {
    let jwtService: JwtService;
    const testSecret = 'test-secret-key-for-jwt-testing';

    beforeEach(() => {
      jwtService = new JwtService(testSecret);
    });

    describe('signAccess', () => {
      it('should generate valid access token', () => {
        const payload: JwtPayload = {
          sub: 'user-123',
          role: 'student'
        };

        const token = jwtService.signAccess(payload);

        expect(token).toBeDefined();
        expect(typeof token).toBe('string');
        expect(token.split('.')).toHaveLength(3);
      });

      it('should include payload in token', () => {
        const payload: JwtPayload = {
          sub: 'user-456',
          role: 'professor'
        };

        const token = jwtService.signAccess(payload);
        const decoded = jwtService.verify(token);

        expect(decoded.sub).toBe('user-456');
        expect(decoded.role).toBe('professor');
      });

      it('should use default expiration of 15 minutes', () => {
        const payload: JwtPayload = {
          sub: 'user-123',
          role: 'student'
        };

        const token = jwtService.signAccess(payload);
        const decoded: any = jwtService.verify(token);

        expect(decoded.exp).toBeDefined();
        const expiresIn = decoded.exp - decoded.iat;
        expect(expiresIn).toBe(15 * 60);
      });

      it('should accept custom expiration', () => {
        const payload: JwtPayload = {
          sub: 'user-123',
          role: 'student'
        };

        const token = jwtService.signAccess(payload, 3600); // 1 hour
        const decoded: any = jwtService.verify(token);

        const expiresIn = decoded.exp - decoded.iat;
        expect(expiresIn).toBe(3600);
      });
    });

    describe('signRefresh', () => {
      it('should generate valid refresh token', () => {
        const payload: JwtPayload = {
          sub: 'user-789',
          role: 'student'
        };

        const token = jwtService.signRefresh(payload);

        expect(token).toBeDefined();
        expect(typeof token).toBe('string');
        expect(token.split('.')).toHaveLength(3);
      });

      it('should use default expiration of 7 days', () => {
        const payload: JwtPayload = {
          sub: 'user-123',
          role: 'student'
        };

        const token = jwtService.signRefresh(payload);
        const decoded: any = jwtService.verify(token);

        const expiresIn = decoded.exp - decoded.iat;
        expect(expiresIn).toBe(7 * 24 * 60 * 60);
      });

      it('should accept custom expiration', () => {
        const payload: JwtPayload = {
          sub: 'user-123',
          role: 'student'
        };

        const token = jwtService.signRefresh(payload, 86400); // 1 day
        const decoded: any = jwtService.verify(token);

        const expiresIn = decoded.exp - decoded.iat;
        expect(expiresIn).toBe(86400);
      });
    });

    describe('verify', () => {
      it('should verify and decode valid token', () => {
        const payload: JwtPayload = {
          sub: 'user-999',
          role: 'professor'
        };

        const token = jwtService.signAccess(payload);
        const decoded = jwtService.verify(token);

        expect(decoded.sub).toBe('user-999');
        expect(decoded.role).toBe('professor');
      });

      it('should throw error for invalid token', () => {
        expect(() => {
          jwtService.verify('invalid-token');
        }).toThrow();
      });

      it('should throw error for malformed token', () => {
        expect(() => {
          jwtService.verify('not.a.token');
        }).toThrow();
      });

      it('should throw error for expired token', () => {
        const payload: JwtPayload = {
          sub: 'user-123',
          role: 'student'
        };

        const token = jwtService.signAccess(payload, -1); // Already expired

        expect(() => {
          jwtService.verify(token);
        }).toThrow();
      });

      it('should verify token signed with same secret', () => {
        const payload: JwtPayload = {
          sub: 'user-123',
          role: 'student'
        };

        const token = jwtService.signAccess(payload);

        expect(() => {
          jwtService.verify(token);
        }).not.toThrow();
      });
    });
  });

  describe('BcryptPasswordService', () => {
    let passwordService: BcryptPasswordService;

    beforeEach(() => {
      passwordService = new BcryptPasswordService();
    });

    describe('hash', () => {
      it('should hash password successfully', async () => {
        const password = 'password123';

        const hash = await passwordService.hash(password);

        expect(hash).toBeDefined();
        expect(typeof hash).toBe('string');
        expect(hash).not.toBe(password);
        expect(hash.length).toBeGreaterThan(20);
      });

      it('should generate different hashes for same password', async () => {
        const password = 'password123';

        const hash1 = await passwordService.hash(password);
        const hash2 = await passwordService.hash(password);

        expect(hash1).not.toBe(hash2);
      });

      it('should handle empty password', async () => {
        const hash = await passwordService.hash('');

        expect(hash).toBeDefined();
        expect(typeof hash).toBe('string');
      });

      it('should handle long passwords', async () => {
        const longPassword = 'a'.repeat(1000);

        const hash = await passwordService.hash(longPassword);

        expect(hash).toBeDefined();
        expect(typeof hash).toBe('string');
      });

      it('should handle special characters in password', async () => {
        const password = 'P@ssw0rd!#$%^&*()';

        const hash = await passwordService.hash(password);

        expect(hash).toBeDefined();
        const isValid = await passwordService.compare(password, hash);
        expect(isValid).toBe(true);
      });
    });

    describe('compare', () => {
      it('should return true for matching password and hash', async () => {
        const password = 'mySecurePassword123';
        const hash = await passwordService.hash(password);

        const isValid = await passwordService.compare(password, hash);

        expect(isValid).toBe(true);
      });

      it('should return false for non-matching password', async () => {
        const password = 'correctPassword';
        const wrongPassword = 'wrongPassword';
        const hash = await passwordService.hash(password);

        const isValid = await passwordService.compare(wrongPassword, hash);

        expect(isValid).toBe(false);
      });

      it('should return false for empty password against hash', async () => {
        const password = 'password123';
        const hash = await passwordService.hash(password);

        const isValid = await passwordService.compare('', hash);

        expect(isValid).toBe(false);
      });

      it('should handle case-sensitive comparison', async () => {
        const password = 'Password123';
        const hash = await passwordService.hash(password);

        const isValidLower = await passwordService.compare('password123', hash);
        const isValidCorrect = await passwordService.compare('Password123', hash);

        expect(isValidLower).toBe(false);
        expect(isValidCorrect).toBe(true);
      });

      it('should return false for invalid hash format', async () => {
        const password = 'password123';
        const invalidHash = 'not-a-valid-hash';

        const isValid = await passwordService.compare(password, invalidHash);

        expect(isValid).toBe(false);
      });
    });
  });

  describe('Logger', () => {
    let logger: Logger;
    let consoleLogSpy: jest.SpyInstance;
    let consoleInfoSpy: jest.SpyInstance;
    let consoleWarnSpy: jest.SpyInstance;
    let consoleErrorSpy: jest.SpyInstance;

    beforeEach(() => {
      logger = new Logger();
      consoleLogSpy = jest.spyOn(console, 'log').mockImplementation();
      consoleInfoSpy = jest.spyOn(console, 'info').mockImplementation();
      consoleWarnSpy = jest.spyOn(console, 'warn').mockImplementation();
      consoleErrorSpy = jest.spyOn(console, 'error').mockImplementation();
    });

    afterEach(() => {
      consoleLogSpy.mockRestore();
      consoleInfoSpy.mockRestore();
      consoleWarnSpy.mockRestore();
      consoleErrorSpy.mockRestore();
    });

    describe('debug', () => {
      it('should log debug messages', () => {
        logger.debug('Debug message');

        expect(consoleLogSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleLogSpy.mock.calls[0][0]);
        expect(loggedData.level).toBe('debug');
        expect(loggedData.msg).toBe('Debug message');
      });

      it('should include additional fields', () => {
        logger.debug('Debug with fields', { userId: '123', action: 'login' });

        expect(consoleLogSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleLogSpy.mock.calls[0][0]);
        expect(loggedData.userId).toBe('123');
        expect(loggedData.action).toBe('login');
      });
    });

    describe('info', () => {
      it('should log info messages', () => {
        logger.info('Info message');

        expect(consoleInfoSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleInfoSpy.mock.calls[0][0]);
        expect(loggedData.level).toBe('info');
        expect(loggedData.msg).toBe('Info message');
      });

      it('should include timestamp', () => {
        logger.info('Test message');

        expect(consoleInfoSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleInfoSpy.mock.calls[0][0]);
        expect(loggedData.time).toBeDefined();
        expect(new Date(loggedData.time)).toBeInstanceOf(Date);
      });
    });

    describe('warn', () => {
      it('should log warn messages', () => {
        logger.warn('Warning message');

        expect(consoleWarnSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleWarnSpy.mock.calls[0][0]);
        expect(loggedData.level).toBe('warn');
        expect(loggedData.msg).toBe('Warning message');
      });
    });

    describe('error', () => {
      it('should log error messages', () => {
        logger.error('Error message');

        expect(consoleErrorSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleErrorSpy.mock.calls[0][0]);
        expect(loggedData.level).toBe('error');
        expect(loggedData.msg).toBe('Error message');
      });

      it('should include error details', () => {
        logger.error('Database error', { code: 'DB_001', table: 'users' });

        expect(consoleErrorSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleErrorSpy.mock.calls[0][0]);
        expect(loggedData.code).toBe('DB_001');
        expect(loggedData.table).toBe('users');
      });
    });

    describe('child', () => {
      it('should create child logger with default fields', () => {
        const parentLogger = new Logger({ service: 'auth' });
        const childLogger = parentLogger.child({ controller: 'AuthController' });

        childLogger.info('Test message');

        expect(consoleInfoSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleInfoSpy.mock.calls[0][0]);
        expect(loggedData.service).toBe('auth');
        expect(loggedData.controller).toBe('AuthController');
      });

      it('should preserve parent default fields', () => {
        const parentLogger = new Logger({ appName: 'TennisApp', env: 'test' });
        const childLogger = parentLogger.child({ requestId: 'req-123' });

        childLogger.info('Child log');

        expect(consoleInfoSpy).toHaveBeenCalled();
        const loggedData = JSON.parse(consoleInfoSpy.mock.calls[0][0]);
        expect(loggedData.appName).toBe('TennisApp');
        expect(loggedData.env).toBe('test');
        expect(loggedData.requestId).toBe('req-123');
      });

      it('should allow multiple child loggers', () => {
        const parent = new Logger({ service: 'api' });
        const child1 = parent.child({ module: 'auth' });
        const child2 = parent.child({ module: 'booking' });

        child1.info('Auth log');
        child2.info('Booking log');

        expect(consoleInfoSpy).toHaveBeenCalledTimes(2);
      });
    });

    describe('Log Formatting', () => {
      it('should format logs as JSON', () => {
        logger.info('Test');

        expect(consoleInfoSpy).toHaveBeenCalled();
        const logString = consoleInfoSpy.mock.calls[0][0];
        expect(() => JSON.parse(logString)).not.toThrow();
      });

      it('should include all standard fields', () => {
        logger.info('Message');

        const loggedData = JSON.parse(consoleInfoSpy.mock.calls[0][0]);
        expect(loggedData).toHaveProperty('level');
        expect(loggedData).toHaveProperty('msg');
        expect(loggedData).toHaveProperty('time');
      });
    });
  });

  describe('createRequestId', () => {
    it('should generate valid UUID', () => {
      const requestId = createRequestId();

      expect(requestId).toBeDefined();
      expect(typeof requestId).toBe('string');
      expect(requestId).toMatch(/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i);
    });

    it('should generate unique IDs', () => {
      const id1 = createRequestId();
      const id2 = createRequestId();

      expect(id1).not.toBe(id2);
    });

    it('should generate many unique IDs', () => {
      const ids = new Set();
      for (let i = 0; i < 1000; i++) {
        ids.add(createRequestId());
      }

      expect(ids.size).toBe(1000);
    });
  });
});

