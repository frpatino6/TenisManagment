export { }; // Ensure this is a module

declare global {
  namespace Express {
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
}
