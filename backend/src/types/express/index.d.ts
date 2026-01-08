import 'express-serve-static-core';

declare module 'express-serve-static-core' {
  interface Request {
    requestId?: string;
    tenantId?: string;
    user?: {
      id: string;
      role: any;
      [key: string]: any;
    };
  }
}
