import request from 'supertest';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import { app } from '../../presentation/server';
import { LeadModel } from '../../infrastructure/database/models/LeadModel';

describe('PublicController Integration', () => {
    let mongo: MongoMemoryServer;

    beforeAll(async () => {
        mongo = await MongoMemoryServer.create();
        const mongoUri = mongo.getUri();
        // Asegurarse de que no haya una conexión previa abierta por otros tests
        if (mongoose.connection.readyState !== 0) {
            await mongoose.disconnect();
        }
        await mongoose.connect(mongoUri);
    });

    afterAll(async () => {
        await mongoose.disconnect();
        await mongo.stop();
    });

    beforeEach(async () => {
        await LeadModel.deleteMany({});
    });

    describe('POST /api/public/leads', () => {
        it('debe registrar un nuevo lead con datos válidos', async () => {
            const leadData = {
                clubName: 'Club de Prueba',
                contactName: 'Carlos Santamaria',
                email: 'carlos@prueba.com',
                phone: '1234567890'
            };

            const response = await request(app)
                .post('/api/public/leads')
                .send(leadData);

            expect(response.status).toBe(201);
            expect(response.body.message).toBe('Lead registrado exitosamente');
            expect(response.body.leadId).toBeDefined();

            const leadInDb = await LeadModel.findOne({ email: leadData.email });
            expect(leadInDb).toBeDefined();
            expect(leadInDb?.clubName).toBe(leadData.clubName);
        });

        it('debe fallar si faltan campos obligatorios', async () => {
            const incompleteData = {
                clubName: 'C',
                // Falta contactName
                email: 'invalid-email',
            };

            const response = await request(app)
                .post('/api/public/leads')
                .send(incompleteData);

            expect(response.status).toBe(400);
            expect(response.body.message).toBe('Error de validación');
            expect(response.body.errors).toBeDefined();
        });

        it('debe fallar si el formato de teléfono es inválido', async () => {
            const invalidPhone = {
                clubName: 'Club Tenis',
                contactName: 'Juan',
                email: 'juan@tenis.com',
                phone: 'esto-no-es-un-telefono'
            };

            const response = await request(app)
                .post('/api/public/leads')
                .send(invalidPhone);

            expect(response.status).toBe(400);
        });
    });
});
