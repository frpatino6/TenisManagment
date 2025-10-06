// Global type definitions for testing
import '@jest/globals';

declare global {
  namespace NodeJS {
    interface Global {
      testUtils: {
        createTestUser: (overrides?: any) => any;
        createTestProfessor: (overrides?: any) => any;
        createTestStudent: (overrides?: any) => any;
        createTestSchedule: (overrides?: any) => any;
        createTestBooking: (overrides?: any) => any;
      };
    }
  }

  var testUtils: {
    createTestUser: (overrides?: any) => any;
    createTestProfessor: (overrides?: any) => any;
    createTestStudent: (overrides?: any) => any;
    createTestSchedule: (overrides?: any) => any;
    createTestBooking: (overrides?: any) => any;
  };
}

export {};
