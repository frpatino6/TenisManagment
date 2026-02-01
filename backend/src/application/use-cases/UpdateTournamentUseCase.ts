import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { UpdateTournamentDto } from '../dtos/UpdateTournamentDto';
import { Logger } from '../../infrastructure/services/Logger';
import { Tournament } from '../../domain/entities/Tournament';

interface UpdateTournamentInput {
    tournamentId: string;
    tenantId: string;
    updateData: UpdateTournamentDto;
}

/**
 * Caso de uso para actualizar un torneo existente.
 * Valida que no se pueda cambiar el formato de una categoría si tiene participantes.
 */
export class UpdateTournamentUseCase {
    private readonly logger = new Logger({ service: 'UpdateTournamentUseCase' });

    constructor(private readonly tournamentRepository: ITournamentRepository) { }

    async execute(input: UpdateTournamentInput): Promise<Tournament> {
        const { tournamentId, tenantId, updateData } = input;

        this.logger.info('Actualizando torneo', { tournamentId, tenantId });

        // Obtener torneo existente
        const tournament = await this.tournamentRepository.findById(tournamentId);
        if (!tournament) {
            throw new Error('Torneo no encontrado');
        }

        // Verificar que pertenece al tenant
        if (tournament.tenantId !== tenantId) {
            throw new Error('No tiene permisos para actualizar este torneo');
        }

        // Validar cambios y sincronizar categorías
        if (updateData.categories) {
            const finalCategories: any[] = [];
            const incomingIds = updateData.categories
                .filter(c => c.id)
                .map(c => c.id);

            // 1. Identificar categorías a eliminar y validar que no tengan participantes
            for (const existingCat of tournament.categories) {
                if (!incomingIds.includes(existingCat.id)) {
                    if (existingCat.participants.length > 0) {
                        throw new Error(
                            `No se puede eliminar la categoría "${existingCat.name}" porque tiene ${existingCat.participants.length} participantes inscritos`
                        );
                    }
                    this.logger.info('Eliminando categoría', { tournamentId, categoryId: existingCat.id });
                }
            }

            // 2. Procesar actualizaciones y nuevas categorías
            for (const categoryUpdate of updateData.categories) {
                if (categoryUpdate.id) {
                    // Actualizar existente
                    const existingCategory = tournament.categories.find(
                        (cat) => cat.id === categoryUpdate.id
                    );

                    if (!existingCategory) {
                        throw new Error(`Categoría ${categoryUpdate.id} no encontrada`);
                    }

                    // VALIDACIÓN CRÍTICA: No permitir cambio de formato si ya hay un cuadro o grupos
                    if (
                        categoryUpdate.format &&
                        existingCategory.format !== categoryUpdate.format
                    ) {
                        if (existingCategory.hasBracket || existingCategory.hasGroupStage) {
                            throw new Error(
                                `No se puede cambiar el formato de la categoría "${existingCategory.name}" ` +
                                `porque ya tiene un cuadro o fase de grupos generada.`
                            );
                        }
                    }

                    // Aplicar actualizaciones a la categoría existente
                    finalCategories.push({
                        ...existingCategory,
                        name: categoryUpdate.name !== undefined ? categoryUpdate.name : existingCategory.name,
                        gender: categoryUpdate.gender !== undefined ? categoryUpdate.gender : existingCategory.gender,
                        format: categoryUpdate.format !== undefined ? categoryUpdate.format : existingCategory.format,
                        groupStageConfig: categoryUpdate.groupStageConfig !== undefined ? categoryUpdate.groupStageConfig : existingCategory.groupStageConfig,
                        hasGroupStage: categoryUpdate.groupStageConfig !== undefined ? !!categoryUpdate.groupStageConfig : existingCategory.hasGroupStage,
                    });
                } else {
                    // Nueva categoría
                    const newCategory = {
                        id: Math.random().toString(36).substring(2, 11),
                        name: categoryUpdate.name || 'Nueva Categoría',
                        gender: categoryUpdate.gender || 'MIXED',
                        participants: [],
                        format: categoryUpdate.format || 'SINGLE_ELIMINATION',
                        groupStageConfig: categoryUpdate.groupStageConfig,
                        hasGroupStage: !!categoryUpdate.groupStageConfig,
                        hasBracket: false,
                    };
                    this.logger.info('Agregando nueva categoría', { tournamentId, categoryName: newCategory.name });
                    finalCategories.push(newCategory);
                }
            }

            tournament.categories = finalCategories;
        }

        // Crear objeto de actualización
        const updates: Partial<Tournament> = {};

        if (updateData.name !== undefined) {
            updates.name = updateData.name;
        }
        if (updateData.description !== undefined) {
            updates.description = updateData.description;
        }
        if (updateData.startDate !== undefined) {
            updates.startDate = updateData.startDate;
        }
        if (updateData.endDate !== undefined) {
            updates.endDate = updateData.endDate;
        }
        if (updateData.categories) {
            updates.categories = tournament.categories;
        }

        // Actualizar usando el repositorio
        const updated = await this.tournamentRepository.update(tournamentId, updates);

        if (!updated) {
            throw new Error('Error al actualizar el torneo');
        }

        this.logger.info('Torneo actualizado exitosamente', { tournamentId });

        return updated;
    }
}
