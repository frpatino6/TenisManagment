import { UpdateTournamentUseCase } from '../../../application/use-cases/UpdateTournamentUseCase';
import { ITournamentRepository } from '../../../domain/repositories/ITournamentRepository';
import { Tournament } from '../../../domain/entities/Tournament';

describe('UpdateTournamentUseCase', () => {
    let useCase: UpdateTournamentUseCase;
    let mockRepository: jest.Mocked<ITournamentRepository>;

    const mockTournament: Tournament = {
        id: 'tournament-123',
        tenantId: 'tenant-456',
        name: 'Torneo Original',
        description: 'Descripción original',
        startDate: new Date('2024-06-01'),
        endDate: new Date('2024-06-15'),
        status: 'DRAFT',
        categories: [
            {
                id: 'cat-1',
                name: 'Masculino A',
                gender: 'MALE',
                participants: [],
                format: 'SINGLE_ELIMINATION',
            },
            {
                id: 'cat-2',
                name: 'Femenino A',
                gender: 'FEMALE',
                participants: ['user-1', 'user-2'],
                format: 'SINGLE_ELIMINATION',
            },
        ],
    };

    beforeEach(() => {
        mockRepository = {
            findById: jest.fn(),
            update: jest.fn(),
            create: jest.fn(),
            findAllByTenant: jest.fn(),
            delete: jest.fn(),
            addParticipantToCategory: jest.fn(),
            removeParticipantFromCategory: jest.fn(),
        };

        useCase = new UpdateTournamentUseCase(mockRepository);
    });

    describe('Actualización exitosa', () => {
        it('debe actualizar nombre y descripción exitosamente', async () => {
            const updatedTournament = {
                ...mockTournament,
                name: 'Torneo Actualizado',
                description: 'Nueva descripción',
            };

            mockRepository.findById.mockResolvedValue(mockTournament);
            mockRepository.update.mockResolvedValue(updatedTournament);

            const result = await useCase.execute({
                tournamentId: 'tournament-123',
                tenantId: 'tenant-456',
                updateData: {
                    name: 'Torneo Actualizado',
                    description: 'Nueva descripción',
                },
            });

            expect(result.name).toBe('Torneo Actualizado');
            expect(result.description).toBe('Nueva descripción');
            expect(mockRepository.update).toHaveBeenCalledWith(
                'tournament-123',
                expect.objectContaining({
                    name: 'Torneo Actualizado',
                    description: 'Nueva descripción',
                })
            );
        });

        it('debe actualizar fechas exitosamente', async () => {
            const newStartDate = new Date('2024-07-01');
            const newEndDate = new Date('2024-07-15');
            const updatedTournament = {
                ...mockTournament,
                startDate: newStartDate,
                endDate: newEndDate,
            };

            mockRepository.findById.mockResolvedValue(mockTournament);
            mockRepository.update.mockResolvedValue(updatedTournament);

            const result = await useCase.execute({
                tournamentId: 'tournament-123',
                tenantId: 'tenant-456',
                updateData: {
                    startDate: newStartDate,
                    endDate: newEndDate,
                },
            });

            expect(result.startDate).toEqual(newStartDate);
            expect(result.endDate).toEqual(newEndDate);
        });

        it('debe cambiar formato de categoría sin participantes', async () => {
            const updatedCategories = [...mockTournament.categories];
            updatedCategories[0].format = 'HYBRID';

            const updatedTournament = {
                ...mockTournament,
                categories: updatedCategories,
            };

            mockRepository.findById.mockResolvedValue(mockTournament);
            mockRepository.update.mockResolvedValue(updatedTournament);

            const result = await useCase.execute({
                tournamentId: 'tournament-123',
                tenantId: 'tenant-456',
                updateData: {
                    categories: [
                        {
                            id: 'cat-1',
                            format: 'HYBRID',
                        },
                        {
                            id: 'cat-2',
                        }
                    ],
                },
            });

            expect(result.categories[0].format).toBe('HYBRID');
        });
    });

    describe('Validaciones de seguridad', () => {
        it('debe rechazar actualización de torneo inexistente', async () => {
            mockRepository.findById.mockResolvedValue(null);

            await expect(
                useCase.execute({
                    tournamentId: 'inexistente',
                    tenantId: 'tenant-456',
                    updateData: { name: 'Nuevo nombre' },
                })
            ).rejects.toThrow('Torneo no encontrado');
        });

        it('debe rechazar actualización de torneo de otro tenant', async () => {
            mockRepository.findById.mockResolvedValue(mockTournament);

            await expect(
                useCase.execute({
                    tournamentId: 'tournament-123',
                    tenantId: 'otro-tenant',
                    updateData: { name: 'Nuevo nombre' },
                })
            ).rejects.toThrow('No tiene permisos para actualizar este torneo');
        });

        it('debe rechazar cambio de formato con participantes inscritos', async () => {
            mockRepository.findById.mockResolvedValue(mockTournament);

            await expect(
                useCase.execute({
                    tournamentId: 'tournament-123',
                    tenantId: 'tenant-456',
                    updateData: {
                        categories: [
                            {
                                id: 'cat-1',
                            },
                            {
                                id: 'cat-2', // Esta categoría tiene participantes
                                format: 'HYBRID',
                            },
                        ],
                    },
                })
            ).rejects.toThrow('No se puede cambiar el formato de la categoría "Femenino A"');
        });

        it('debe rechazar actualización de categoría inexistente', async () => {
            mockRepository.findById.mockResolvedValue(mockTournament);

            await expect(
                useCase.execute({
                    tournamentId: 'tournament-123',
                    tenantId: 'tenant-456',
                    updateData: {
                        categories: [
                            {
                                id: 'cat-1',
                            },
                            {
                                id: 'cat-2',
                            },
                            {
                                id: 'cat-inexistente',
                                name: 'Nueva categoría',
                            },
                        ],
                    },
                })
            ).rejects.toThrow('Categoría cat-inexistente no encontrada');
        });

        it('debe lanzar error si el repositorio falla al actualizar', async () => {
            mockRepository.findById.mockResolvedValue(mockTournament);
            mockRepository.update.mockResolvedValue(null);

            await expect(
                useCase.execute({
                    tournamentId: 'tournament-123',
                    tenantId: 'tenant-456',
                    updateData: { name: 'Nuevo nombre' },
                })
            ).rejects.toThrow('Error al actualizar el torneo');
        });
    });

    describe('Actualización de categorías', () => {
        it('debe actualizar nombre de categoría', async () => {
            const updatedCategories = [...mockTournament.categories];
            updatedCategories[0].name = 'Masculino Premium';

            const updatedTournament = {
                ...mockTournament,
                categories: updatedCategories,
            };

            mockRepository.findById.mockResolvedValue(mockTournament);
            mockRepository.update.mockResolvedValue(updatedTournament);

            const result = await useCase.execute({
                tournamentId: 'tournament-123',
                tenantId: 'tenant-456',
                updateData: {
                    categories: [
                        {
                            id: 'cat-1',
                            name: 'Masculino Premium',
                        },
                        {
                            id: 'cat-2',
                        }
                    ],
                },
            });

            expect(result.categories[0].name).toBe('Masculino Premium');
        });

        it('debe actualizar género de categoría', async () => {
            const updatedCategories = [...mockTournament.categories];
            updatedCategories[0].gender = 'MIXED';

            const updatedTournament = {
                ...mockTournament,
                categories: updatedCategories,
            };

            mockRepository.findById.mockResolvedValue(mockTournament);
            mockRepository.update.mockResolvedValue(updatedTournament);

            const result = await useCase.execute({
                tournamentId: 'tournament-123',
                tenantId: 'tenant-456',
                updateData: {
                    categories: [
                        {
                            id: 'cat-1',
                            gender: 'MIXED',
                        },
                        {
                            id: 'cat-2',
                        }
                    ],
                },
            });

            expect(result.categories[0].gender).toBe('MIXED');
        });

        it('debe agregar una nueva categoría', async () => {
            mockRepository.findById.mockResolvedValue(mockTournament);
            mockRepository.update.mockImplementation((id, updates) => Promise.resolve({ ...mockTournament, ...updates } as Tournament));

            const result = await useCase.execute({
                tournamentId: 'tournament-123',
                tenantId: 'tenant-456',
                updateData: {
                    categories: [
                        { id: 'cat-1' },
                        { id: 'cat-2' },
                        { name: 'Nueva' }
                    ],
                },
            });

            expect(result.categories).toHaveLength(3);
            expect(result.categories.find(c => c.name === 'Nueva')).toBeDefined();
        });

        it('debe eliminar una categoría sin participantes', async () => {
            mockRepository.findById.mockResolvedValue(mockTournament);
            mockRepository.update.mockImplementation((id, updates) => Promise.resolve({ ...mockTournament, ...updates } as Tournament));

            const result = await useCase.execute({
                tournamentId: 'tournament-123',
                tenantId: 'tenant-456',
                updateData: {
                    categories: [
                        { id: 'cat-2' } // Eliminamos cat-1
                    ],
                },
            });

            expect(result.categories).toHaveLength(1);
            expect(result.categories[0].id).toBe('cat-2');
        });

        it('debe rechazar eliminar una categoría con participantes', async () => {
            mockRepository.findById.mockResolvedValue(mockTournament);

            await expect(
                useCase.execute({
                    tournamentId: 'tournament-123',
                    tenantId: 'tenant-456',
                    updateData: {
                        categories: [
                            { id: 'cat-1' } // Intentamos eliminar cat-2 (que tiene participantes)
                        ],
                    },
                })
            ).rejects.toThrow('No se puede eliminar la categoría "Femenino A"');
        });
    });
});
