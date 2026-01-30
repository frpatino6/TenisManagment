import { CreateLeadUseCase, CreateLeadInput } from '../../application/use-cases/CreateLeadUseCase';
import { LeadRepository } from '../../domain/repositories/index';
import { Lead } from '../../domain/entities/Lead';

describe('CreateLeadUseCase', () => {
    let useCase: CreateLeadUseCase;
    let mockLeadRepository: jest.Mocked<LeadRepository>;

    beforeEach(() => {
        mockLeadRepository = {
            create: jest.fn(),
            findById: jest.fn(),
            findByEmail: jest.fn(),
            list: jest.fn(),
        };
        useCase = new CreateLeadUseCase(mockLeadRepository);
    });

    it('debe crear un lead exitosamente', async () => {
        const input: CreateLeadInput = {
            clubName: 'Club de Tenis Gigante',
            contactName: 'Fernando Corbatta',
            email: 'fernando@gigante.com',
            phone: '+573001234567',
        };

        const expectedLead: Lead = {
            id: 'lead-123',
            ...input,
            status: 'nuevo',
            createdAt: new Date(),
            updatedAt: new Date(),
        };

        mockLeadRepository.create.mockResolvedValue(expectedLead);
        mockLeadRepository.findByEmail.mockResolvedValue(null);

        const result = await useCase.execute(input);

        expect(result).toEqual(expectedLead);
        expect(mockLeadRepository.create).toHaveBeenCalledWith({
            ...input,
            status: 'nuevo',
        });
    });

    it('debe registrar un warning si el email ya existe pero proceder con la creación', async () => {
        const input: CreateLeadInput = {
            clubName: 'Club Repetido',
            contactName: 'Juan Perez',
            email: 'juan@perez.com',
            phone: '123456789',
        };

        const existingLead: Lead = {
            id: 'existing-123',
            ...input,
            status: 'nuevo',
        };

        mockLeadRepository.findByEmail.mockResolvedValue(existingLead);
        mockLeadRepository.create.mockResolvedValue({ id: 'new-123', ...input, status: 'nuevo' });

        const result = await useCase.execute(input);

        expect(result.id).toBe('new-123');
        expect(mockLeadRepository.findByEmail).toHaveBeenCalledWith(input.email);
        expect(mockLeadRepository.create).toHaveBeenCalled();
    });
});
