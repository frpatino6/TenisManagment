import mongoose, { Types } from 'mongoose';
import { Tournament, TournamentCategory } from '../../domain/entities/Tournament';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { TournamentModel, TournamentDocument } from '../database/models/TournamentModel';

export class MongoTournamentRepository implements ITournamentRepository {
    async create(tournament: Tournament): Promise<Tournament> {
        const doc = new TournamentModel({
            ...tournament,
            tenantId: new Types.ObjectId(tournament.tenantId),
            categories: tournament.categories.map(cat => ({
                ...cat,
                participants: cat.participants.map(p => new Types.ObjectId(p))
            }))
        });
        const saved = await doc.save();
        return this.mapToEntity(saved);
    }

    async findById(id: string): Promise<Tournament | null> {
        const doc = await TournamentModel.findById(id).lean();
        if (!doc) return null;

        const tournament = this.mapToEntity(doc as any);
        // Enriquecer con información de brackets
        for (const cat of tournament.categories) {
            const hasBracket = await mongoose.model('Bracket').exists({
                tournamentId: id,
                categoryId: cat.id
            });
            cat.hasBracket = !!hasBracket;
        }
        return tournament;
    }

    async findAllByTenant(tenantId: string): Promise<Tournament[]> {
        const docs = await TournamentModel.find({ tenantId: new Types.ObjectId(tenantId) })
            .sort({ startDate: -1 })
            .lean();

        const tournaments = docs.map(doc => this.mapToEntity(doc as any));

        // Enriquecer cada torneo con info de brackets (esto puede ser lento en listas largas, 
        // pero para el flujo actual de panel admin es necesario)
        for (const tournament of tournaments) {
            for (const cat of tournament.categories) {
                const hasBracket = await mongoose.model('Bracket').exists({
                    tournamentId: tournament.id,
                    categoryId: cat.id
                });
                cat.hasBracket = !!hasBracket;
            }
        }

        return tournaments;
    }

    async update(id: string, tournament: Partial<Tournament>): Promise<Tournament | null> {
        const updateData: any = { ...tournament };
        if (tournament.tenantId) updateData.tenantId = new Types.ObjectId(tournament.tenantId);

        if (tournament.categories) {
            updateData.categories = tournament.categories.map(cat => {
                const mappedCategory: any = {
                    ...cat,
                    _id: cat.id ? new Types.ObjectId(cat.id) : undefined,
                    participants: cat.participants.map(p => new Types.ObjectId(p)),
                    hasGroupStage: cat.hasGroupStage,
                    hasBracket: cat.hasBracket
                };
                delete mappedCategory.id;
                return mappedCategory;
            });
        }

        const updated = await TournamentModel.findByIdAndUpdate(
            id,
            { $set: updateData },
            { new: true }
        ).lean();

        return updated ? this.mapToEntity(updated as any) : null;
    }

    async delete(id: string): Promise<boolean> {
        const result = await TournamentModel.findByIdAndDelete(id);
        return result !== null;
    }

    async addParticipantToCategory(
        tournamentId: string,
        categoryId: string,
        userId: string
    ): Promise<Tournament | null> {
        const updated = await TournamentModel.findOneAndUpdate(
            { _id: tournamentId, "categories._id": categoryId },
            { $addToSet: { "categories.$.participants": new Types.ObjectId(userId) } },
            { new: true }
        ).lean();

        return updated ? this.mapToEntity(updated as any) : null;
    }

    async removeParticipantFromCategory(
        tournamentId: string,
        categoryId: string,
        userId: string
    ): Promise<Tournament | null> {
        const updated = await TournamentModel.findOneAndUpdate(
            { _id: tournamentId, "categories._id": categoryId },
            { $pull: { "categories.$.participants": new Types.ObjectId(userId) } },
            { new: true }
        ).lean();

        return updated ? this.mapToEntity(updated as any) : null;
    }

    private mapToEntity(doc: TournamentDocument): Tournament {
        try {
            if (!doc) throw new Error('Document is null or undefined');

            return {
                id: doc._id?.toString() ?? 'UNKNOWN_ID',
                tenantId: doc.tenantId?.toString() ?? 'UNKNOWN_TENANT',
                name: doc.name || 'Sin Nombre',
                description: doc.description || '',
                startDate: doc.startDate,
                endDate: doc.endDate,
                status: doc.status as any,
                categories: (doc.categories || []).map((cat: any) => ({
                    id: cat._id?.toString() ?? 'UNKNOWN_CAT_ID',
                    name: cat.name || 'Sin Categoría',
                    gender: cat.gender || 'MIXED',
                    minElo: cat.minElo,
                    maxElo: cat.maxElo,
                    participants: (cat.participants || []).map((p: any) => p?.toString() ?? ''),
                    format: cat.format || 'SINGLE_ELIMINATION',
                    groupStageConfig: cat.groupStageConfig,
                    hasGroupStage: cat.hasGroupStage || false,
                    hasBracket: cat.hasBracket || false,
                    championId: cat.championId?.toString(),
                    championName: cat.championName,
                    runnerUpId: cat.runnerUpId?.toString(),
                    runnerUpName: cat.runnerUpName,
                })),
                metadata: doc.metadata,
                createdAt: doc.createdAt,
                updatedAt: doc.updatedAt
            };
        } catch (error) {
            console.error('Error mapping tournament doc:', JSON.stringify(doc, null, 2));
            console.error('Mapping error details:', error);
            throw error;
        }
    }
}
