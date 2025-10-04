import { mockDeep } from 'jest-mock-extended';

// Firebase Admin SDK Mock
export const mockFirebaseAdmin = {
  auth: () => ({
    verifyIdToken: jest.fn().mockResolvedValue({
      uid: 'test-firebase-uid',
      email: 'test@example.com'
    })
  }),
  credential: {
    cert: jest.fn()
  },
  initializeApp: jest.fn()
};

// MongoDB Mock
export const mockMongoDB = {
  connect: jest.fn(),
  disconnect: jest.fn(),
  db: jest.fn(() => ({
    collection: jest.fn(() => ({
      findOne: jest.fn(),
      find: jest.fn(),
      insertOne: jest.fn(),
      updateOne: jest.fn(),
      deleteOne: jest.fn(),
      countDocuments: jest.fn()
    }))
  }))
};

// JWT Mock
export const mockJWT = {
  sign: jest.fn().mockReturnValue('mock-jwt-token'),
  verify: jest.fn().mockReturnValue({
    sub: 'test-user-id',
    role: 'student',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 3600
  })
};

// Bcrypt Mock
export const mockBcrypt = {
  hash: jest.fn().mockResolvedValue('mock-hashed-password'),
  compare: jest.fn().mockResolvedValue(true)
};

// Mongoose Mock
export const mockMongoose = {
  connect: jest.fn().mockResolvedValue(undefined),
  disconnect: jest.fn().mockResolvedValue(undefined),
  connection: {
    readyState: 1,
    on: jest.fn()
  }
};

// Express Request/Response Mocks
export const createMockRequest = (overrides: any = {}) => ({
  body: {},
  params: {},
  query: {},
  headers: {},
  user: undefined,
  ...overrides
});

export const createMockResponse = () => {
  const res: any = {};
  res.status = jest.fn().mockReturnValue(res);
  res.json = jest.fn().mockReturnValue(res);
  res.send = jest.fn().mockReturnValue(res);
  res.end = jest.fn().mockReturnValue(res);
  res.cookie = jest.fn().mockReturnValue(res);
  res.clearCookie = jest.fn().mockReturnValue(res);
  return res;
};

export const createMockNextFunction = () => jest.fn();

// Console Mock
export const mockConsole = {
  log: jest.fn(),
  error: jest.fn(),
  warn: jest.fn(),
  info: jest.fn(),
  debug: jest.fn()
};

// Setup global mocks
beforeEach(() => {
  // Clear all mocks before each test
  jest.clearAllMocks();
  
  // Reset mock implementations
  mockJWT.sign.mockReturnValue('mock-jwt-token');
  mockJWT.verify.mockReturnValue({
    sub: 'test-user-id',
    role: 'student',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 3600
  });
  
  mockBcrypt.hash.mockResolvedValue('mock-hashed-password');
  mockBcrypt.compare.mockResolvedValue(true);
  
  mockFirebaseAdmin.auth().verifyIdToken.mockResolvedValue({
    uid: 'test-firebase-uid',
    email: 'test@example.com'
  });
});
