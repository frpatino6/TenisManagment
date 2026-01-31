import { Bracket, BracketMatch } from '../../domain/entities/Bracket';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';
import { BracketModel } from '../database/models/BracketModel';
import { AuthUserModel } from '../database/models/AuthUserModel';
import { Types } from 'mongoose';

export class MongoBracketRepository implements IBracketRepository {
    async create(bracket: Bracket): Promise<Bracket> {
        const doc = await BracketModel.create(bracket);
        return this.toEntityWithNames(doc.toObject());
    }

    async findById(id: string): Promise<Bracket | null> {
        if (!Types.ObjectId.isValid(id)) {
            return null;
        }

        const doc = await BracketModel.findById(id).lean();
        return doc ? this.toEntityWithNames(doc) : null;
    }

    async findByTournamentAndCategory(
        tournamentId: string,
        categoryId: string
    ): Promise<Bracket | null> {
        const doc = await BracketModel.findOne({ tournamentId, categoryId }).lean();
        return doc ? this.toEntityWithNames(doc) : null;
    }

    async update(id: string, bracket: Partial<Bracket>): Promise<Bracket | null> {
        if (!Types.ObjectId.isValid(id)) {
            return null;
        }

        const doc = await BracketModel.findByIdAndUpdate(
            id,
            { $set: bracket },
            { new: true }
        ).lean();

        return doc ? this.toEntityWithNames(doc) : null;
    }

    async updateMatch(
        bracketId: string,
        matchId: string,
        update: Partial<BracketMatch>
    ): Promise<Bracket | null> {
        if (!Types.ObjectId.isValid(bracketId)) {
            return null;
        }

        const doc = await BracketModel.findOneAndUpdate(
            { _id: bracketId, 'matches.id': matchId },
            {
                $set: {
                    'matches.$.winnerId': update.winnerId,
                    'matches.$.score': update.score,
                    'matches.$.matchDate': update.matchDate
                }
            },
            { new: true }
        ).lean();
        return doc ? this.toEntityWithNames(doc) : null;
    }

    async delete(tournamentId: string, categoryId: string): Promise<void> {
        await BracketModel.deleteOne({ tournamentId, categoryId });
    }

    private async toEntityWithNames(doc: any): Promise<Bracket> {
        const bracket: Bracket = {
            id: doc._id.toString(),
            tournamentId: doc.tournamentId,
            categoryId: doc.categoryId,
            matches: JSON.parse(JSON.stringify(doc.matches)), // Deep copy 
            status: doc.status,
            createdAt: doc.createdAt,
            updatedAt: doc.updatedAt
        };

        for (const match of bracket.matches) {
            if (match.player1Id) {
                const user = await AuthUserModel.findById(match.player1Id).select('name').lean() as any;
                if (user) match.player1Name = user.name;
            }
            if (match.player2Id) {
                const user = await AuthUserModel.findById(match.player2Id).select('name').lean() as any;
                if (user) match.player2Name = user.name;
            }
            if (match.winnerId) {
                const user = await AuthUserModel.findById(match.winnerId).select('name').lean() as any;
                if (user) match.winnerName = user.name;
            }
        }

        return bracket;
    }
}
