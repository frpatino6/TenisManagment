import { GroupStageModel } from '../models/GroupStageModel';
import { GroupStageRepository } from '../../../domain/repositories/GroupStageRepository';
import { GroupStage } from '../../../domain/entities/GroupStage';
import { Types } from 'mongoose';

/**
 * Implementación de MongoDB para GroupStageRepository.
 */
export class MongoGroupStageRepository implements GroupStageRepository {
    async create(groupStage: GroupStage): Promise<GroupStage> {
        const doc = new GroupStageModel({
            tournamentId: new Types.ObjectId(groupStage.tournamentId),
            categoryId: groupStage.categoryId,
            groups: groupStage.groups.map(group => ({
                ...group,
                participants: group.participants.map(p => new Types.ObjectId(p)),
                matches: group.matches.map(match => ({
                    ...match,
                    player1Id: new Types.ObjectId(match.player1Id),
                    player2Id: new Types.ObjectId(match.player2Id),
                    winnerId: match.winnerId ? new Types.ObjectId(match.winnerId) : undefined,
                })),
                standings: group.standings.map(standing => ({
                    ...standing,
                    playerId: new Types.ObjectId(standing.playerId),
                })),
            })),
            status: groupStage.status,
        });

        const saved = await doc.save();
        return this.mapToEntity(saved);
    }

    async findByTournamentAndCategory(
        tournamentId: string,
        categoryId: string
    ): Promise<GroupStage | null> {
        const doc = await GroupStageModel.findOne({
            tournamentId: new Types.ObjectId(tournamentId),
            categoryId,
        });

        return doc ? this.mapToEntity(doc) : null;
    }

    async update(groupStage: GroupStage): Promise<GroupStage> {
        const updated = await GroupStageModel.findOneAndUpdate(
            {
                tournamentId: new Types.ObjectId(groupStage.tournamentId),
                categoryId: groupStage.categoryId,
            },
            {
                groups: groupStage.groups.map(group => ({
                    ...group,
                    participants: group.participants.map(p => new Types.ObjectId(p)),
                    matches: group.matches.map(match => ({
                        ...match,
                        player1Id: new Types.ObjectId(match.player1Id),
                        player2Id: new Types.ObjectId(match.player2Id),
                        winnerId: match.winnerId ? new Types.ObjectId(match.winnerId) : undefined,
                    })),
                    standings: group.standings.map(standing => ({
                        ...standing,
                        playerId: new Types.ObjectId(standing.playerId),
                    })),
                })),
                status: groupStage.status,
            },
            { new: true }
        );

        if (!updated) {
            throw new Error('GroupStage not found');
        }

        return this.mapToEntity(updated);
    }

    async delete(tournamentId: string, categoryId: string): Promise<void> {
        await GroupStageModel.deleteOne({
            tournamentId: new Types.ObjectId(tournamentId),
            categoryId,
        });
    }

    private mapToEntity(doc: any): GroupStage {
        return {
            id: doc._id.toString(),
            tournamentId: doc.tournamentId.toString(),
            categoryId: doc.categoryId,
            groups: doc.groups.map((group: any) => ({
                id: group.id,
                name: group.name,
                seed: group.seed,
                participants: group.participants.map((p: any) => p.toString()),
                matches: group.matches.map((match: any) => ({
                    id: match.id,
                    groupId: match.groupId,
                    player1Id: match.player1Id.toString(),
                    player1Name: match.player1Name,
                    player1Elo: match.player1Elo,
                    player2Id: match.player2Id.toString(),
                    player2Name: match.player2Name,
                    player2Elo: match.player2Elo,
                    winnerId: match.winnerId?.toString(),
                    score: match.score,
                    matchDate: match.matchDate,
                    round: match.round,
                })),
                standings: group.standings.map((standing: any) => ({
                    playerId: standing.playerId.toString(),
                    playerName: standing.playerName,
                    playerElo: standing.playerElo,
                    position: standing.position,
                    matchesPlayed: standing.matchesPlayed,
                    wins: standing.wins,
                    draws: standing.draws,
                    losses: standing.losses,
                    points: standing.points,
                    setsWon: standing.setsWon,
                    setsLost: standing.setsLost,
                    gamesWon: standing.gamesWon,
                    gamesLost: standing.gamesLost,
                    setDifference: standing.setDifference,
                    gameDifference: standing.gameDifference,
                    qualifiedForKnockout: standing.qualifiedForKnockout,
                })),
            })),
            status: doc.status,
            createdAt: doc.createdAt,
            updatedAt: doc.updatedAt,
        };
    }
}
