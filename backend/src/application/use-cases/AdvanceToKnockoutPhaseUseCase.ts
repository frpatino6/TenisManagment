import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { BracketGenerationService } from '../../domain/services/BracketGenerationService';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';
import { Bracket } from '../../domain/entities/Bracket';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { Types } from 'mongoose';

interface AdvanceToKnockoutInput {
    tournamentId: string;
    categoryId: string;
}

/**
 * Caso de uso para avanzar a la fase de eliminación directa.
 * 
 * Flujo:
 * 1. Obtiene clasificados de cada grupo (top N según config)
 * 2. Genera seeding para bracket según posiciones finales
 * 3. Crea bracket con los clasificados
 * 4. Marca GroupStage como COMPLETED
 */
export class AdvanceToKnockoutPhaseUseCase {
    constructor(
        private readonly groupStageRepository: GroupStageRepository,
        private readonly tournamentRepository: ITournamentRepository,
        private readonly bracketRepository: IBracketRepository,
        private readonly bracketGenerationService: BracketGenerationService
    ) { }

    async execute(input: AdvanceToKnockoutInput): Promise<Bracket> {
        const { tournamentId, categoryId } = input;

        // 1. Obtener GroupStage
        const groupStage = await this.groupStageRepository.findByTournamentAndCategory(
            tournamentId,
            categoryId
        );

        if (!groupStage) {
            throw new Error('Fase de grupos no encontrada');
        }

        if (groupStage.status !== 'COMPLETED') {
            throw new Error('La fase de grupos no está completada');
        }

        // 2. Obtener torneo y configuración
        const tournament = await this.tournamentRepository.findById(tournamentId);
        if (!tournament) {
            throw new Error('Torneo no encontrado');
        }

        const category = tournament.categories.find((c: any) => c.id === categoryId);
        if (!category || !category.groupStageConfig) {
            throw new Error('Configuración de grupos no encontrada');
        }

        // 3. Obtener clasificados de cada grupo (ordenados por posición)
        const qualified: Array<{ userId: string; groupSeed: number; position: number }> = [];

        groupStage.groups.forEach(group => {
            const topN = group.standings
                .sort((a, b) => a.position - b.position)
                .slice(0, category.groupStageConfig!.advancePerGroup);

            topN.forEach(standing => {
                standing.qualifiedForKnockout = true;
                qualified.push({
                    userId: standing.playerId.toString(), // Forzado a string
                    groupSeed: group.seed,
                    position: standing.position,
                });
            });
        });

        // 4. Generar seeding para bracket según posiciones
        // Lógica: 1° Grupo A vs 2° Grupo B, 1° Grupo C vs 2° Grupo D, etc.
        const seededParticipants = this.generateKnockoutSeeding(
            qualified,
            groupStage.groups.length,
            category.groupStageConfig.advancePerGroup
        );

        // 5. Obtener nombres de los clasificados
        const participantsData = await AuthUserModel.find({
            _id: { $in: seededParticipants.map(p => new Types.ObjectId(p)) },
        });

        const participantsWithNames = seededParticipants.map(userId => {
            const user = participantsData.find(u => u._id.toString() === userId.toString());
            return {
                userId,
                name: user?.name || 'Jugador',
            };
        });

        // 6. Generar bracket con los clasificados
        const matches = this.bracketGenerationService.generateSingleEliminationBracket(
            participantsWithNames.map(p => p.userId)
        );

        // Enriquecer matches con nombres
        matches.forEach(match => {
            if (match.player1Id) {
                const p1 = participantsWithNames.find(p => p.userId.toString() === match.player1Id!.toString());
                match.player1Name = p1?.name;
            }
            if (match.player2Id) {
                const p2 = participantsWithNames.find(p => p.userId.toString() === match.player2Id!.toString());
                match.player2Name = p2?.name;
            }
        });

        const bracket: Bracket = {
            tournamentId,
            categoryId,
            matches,
            status: 'PENDING',
        };

        // 7. Guardar bracket
        const savedBracket = await this.bracketRepository.create(bracket);

        // 8. Actualizar GroupStage (marcar clasificados)
        await this.groupStageRepository.update(groupStage);

        // 9. Actualizar categoría (marcar que tiene bracket)
        category.hasBracket = true;
        await this.tournamentRepository.update(tournamentId, { categories: tournament.categories });

        return savedBracket;
    }

    /**
     * Genera seeding para bracket según posiciones de grupos.
     * Evita que jugadores del mismo grupo se enfrenten en primera ronda.
     * 
     * Ejemplo con 4 grupos y 2 clasificados por grupo (8 total):
     * - Cuarto 1: 1° Grupo A vs 2° Grupo B
     * - Cuarto 2: 1° Grupo B vs 2° Grupo A
     * - Cuarto 3: 1° Grupo C vs 2° Grupo D
     * - Cuarto 4: 1° Grupo D vs 2° Grupo C
     */
    private generateKnockoutSeeding(
        qualified: Array<{ userId: string; groupSeed: number; position: number }>,
        numberOfGroups: number,
        advancePerGroup: number
    ): string[] {
        const seeded: string[] = [];

        // Separar por posición
        const byPosition: Record<number, Array<{ userId: string; groupSeed: number }>> = {};

        qualified.forEach(q => {
            if (!byPosition[q.position]) {
                byPosition[q.position] = [];
            }
            byPosition[q.position].push({ userId: q.userId, groupSeed: q.groupSeed });
        });

        // Ordenar cada posición por seed de grupo
        Object.keys(byPosition).forEach(pos => {
            byPosition[parseInt(pos)].sort((a, b) => a.groupSeed - b.groupSeed);
        });

        // Generar seeding: 1° de un grupo vs 2° de otro grupo
        if (advancePerGroup === 2) {
            const firsts = byPosition[1] || [];
            const seconds = byPosition[2] || [];

            // Emparejar 1° de grupo par con 2° de grupo impar
            for (let i = 0; i < firsts.length; i++) {
                const first = firsts[i];
                // Buscar el segundo de un grupo diferente
                const secondIndex = i % 2 === 0 ? i + 1 : i - 1;
                const second = seconds[secondIndex] || seconds[0];

                seeded.push(first.userId);
                if (second) {
                    seeded.push(second.userId);
                }
            }
        } else {
            // Para otros casos, simplemente ordenar por posición y grupo
            qualified
                .sort((a, b) => {
                    if (a.position !== b.position) return a.position - b.position;
                    return a.groupSeed - b.groupSeed;
                })
                .forEach(q => seeded.push(q.userId));
        }

        return seeded;
    }
}
