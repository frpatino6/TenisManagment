import request from 'supertest';
import { app } from '../../presentation/server';

describe('Payment complete redirect page', () => {
  it('should serve a success HTML page', async () => {
    const response = await request(app).get('/payment-complete');

    expect(response.status).toBe(200);
    expect(response.headers['content-type']).toContain('text/html');
    expect(response.text).toContain('Pago recibido');
  });
});
