// Jest setup file for Tennis Management Backend
// This file runs before each test file

// Global test timeout
jest.setTimeout(10000);

// Mock console methods to reduce noise in tests
global.console = {
  ...console,
  // Uncomment to suppress console.log in tests
  // log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};

// Mock environment variables for testing
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = 'test-jwt-secret-key-for-testing-only';
process.env.MONGO_URI = 'mongodb://localhost:27017/tennis-management-test';

// Global test utilities
global.testUtils = {
  // Helper to create test data
  createTestUser: (overrides = {}) => ({
    id: 'test-user-id',
    name: 'Test User',
    email: 'test@example.com',
    role: 'student',
    ...overrides
  }),

  // Helper to create test professor
  createTestProfessor: (overrides = {}) => ({
    id: 'test-professor-id',
    name: 'Test Professor',
    email: 'professor@example.com',
    phone: '1234567890',
    specialties: ['tennis'],
    hourlyRate: 50,
    experienceYears: 5,
    ...overrides
  }),

  // Helper to create test student
  createTestStudent: (overrides = {}) => ({
    id: 'test-student-id',
    name: 'Test Student',
    email: 'student@example.com',
    phone: '0987654321',
    membershipType: 'basic',
    balance: 100,
    ...overrides
  }),

  // Helper to create test schedule
  createTestSchedule: (overrides = {}) => ({
    id: 'test-schedule-id',
    professorId: 'test-professor-id',
    date: new Date('2024-12-01'),
    startTime: '10:00',
    endTime: '11:00',
    type: 'individual',
    isAvailable: true,
    ...overrides
  }),

  // Helper to create test booking
  createTestBooking: (overrides = {}) => ({
    id: 'test-booking-id',
    studentId: 'test-student-id',
    scheduleId: 'test-schedule-id',
    type: 'lesson',
    status: 'confirmed',
    createdAt: new Date(),
    ...overrides
  })
};

// Setup and teardown for database tests
beforeAll(async () => {
  // Global setup for all tests
  console.log('🧪 Setting up test environment...');
});

afterAll(async () => {
  // Global cleanup for all tests
  console.log('🧹 Cleaning up test environment...');
});

beforeEach(() => {
  // Setup before each test
  jest.clearAllMocks();
});

afterEach(() => {
  // Cleanup after each test
  jest.clearAllTimers();
});
