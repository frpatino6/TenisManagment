import { Types } from 'mongoose';
import { IUserRankingRepository } from '../../domain/repositories/IUserRankingRepository';
import { UserRanking, UserRankingWithDetails } from '../../domain/entities/UserRanking';
import { UserRankingModel } from '../database/models/UserRankingModel';

export class MongoUserRankingRepository implements IUserRankingRepository {
    async findByUserAndTenant(tenantId: string, userId: string): Promise<UserRanking | null> {
        const doc = await UserRankingModel.findOne({
            tenantId: new Types.ObjectId(tenantId),
            userId: new Types.ObjectId(userId)
        }).lean();

        return doc ? this.mapToEntity(doc) : null;
    }

    async create(ranking: UserRanking): Promise<UserRanking> {
        const doc = new UserRankingModel({
            ...ranking,
            tenantId: new Types.ObjectId(ranking.tenantId),
            userId: new Types.ObjectId(ranking.userId)
        });
        await doc.save();
        return this.mapToEntity(doc.toObject());
    }

    async update(id: string, ranking: Partial<UserRanking>): Promise<UserRanking | null> {
        const updateData: any = { ...ranking };
        if (ranking.tenantId) updateData.tenantId = new Types.ObjectId(ranking.tenantId);
        if (ranking.userId) updateData.userId = new Types.ObjectId(ranking.userId);

        const doc = await UserRankingModel.findByIdAndUpdate(
            id,
            { $set: updateData },
            { new: true }
        ).lean();

        return doc ? this.mapToEntity(doc) : null;
    }

    async getTopByElo(tenantId: string, limit: number): Promise<UserRanking[]> {
        const docs = await UserRankingModel.find({ tenantId: new Types.ObjectId(tenantId) })
            .sort({ eloScore: -1 })
            .limit(limit)
            .lean();

        return docs.map(doc => this.mapToEntity(doc));
    }

    async getRankingsWithUsers(tenantId: string, type: 'elo' | 'race', limit: number): Promise<UserRankingWithDetails[]> {
        const sortField = type === 'elo' ? 'eloScore' : 'monthlyRacePoints';
        const docs = await UserRankingModel.find({ tenantId: new Types.ObjectId(tenantId) })
            .sort({ [sortField]: -1 })
            .limit(limit)
            .populate('userId', 'name profilePicture')
            .lean();

        return docs.map((doc: any, index: number) => ({
            ...this.mapToEntity(doc),
            userName: doc.userId?.name || 'Usuario desconocido',
            userAvatar: doc.userId?.profilePicture,
            position: index + 1
        }));
    }

    async resetMonthlyRace(tenantId?: string): Promise<void> {
        const query = tenantId ? { tenantId: new Types.ObjectId(tenantId) } : {};
        await UserRankingModel.updateMany(query, {
            $set: { monthlyRacePoints: 0, lastResetDate: new Date() }
        });
    }

    private mapToEntity(doc: any): UserRanking {
        const userId = doc.userId?._id ? doc.userId._id.toString() : doc.userId.toString();
        return {
            id: doc._id.toString(),
            userId: userId,
            tenantId: doc.tenantId.toString(),
            eloScore: doc.eloScore,
            monthlyRacePoints: doc.monthlyRacePoints,
            totalMatches: doc.totalMatches,
            winRate: doc.winRate,
            lastResetDate: doc.lastResetDate,
            createdAt: doc.createdAt,
            updatedAt: doc.updatedAt
        };
    }
}
