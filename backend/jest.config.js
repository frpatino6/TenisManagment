module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src'],
  testMatch: ['**/__tests__/**/*.test.ts'],
  testPathIgnorePatterns: ['/node_modules/', '/integration/'],
  transform: {
    '^.+\\.ts$': ['ts-jest', {
      isolatedModules: true,
      tsconfig: {
        strict: false,
        noImplicitAny: false,
        skipLibCheck: true,
        esModuleInterop: true,
        allowSyntheticDefaultImports: true
      }
    }]
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/__tests__/**',
    '!src/presentation/server.ts'
  ],
      coverageThreshold: {
        global: {
          branches: 0,
          functions: 0,
          lines: 0,
          statements: 0
        }
      },
  setupFilesAfterEnv: ['<rootDir>/src/__tests__/jest.setup.js'],
  setupFiles: ['<rootDir>/src/__tests__/types/global.d.ts'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1'
  },
  testTimeout: 10000,
  clearMocks: true,
  restoreMocks: true,
  verbose: true
};
