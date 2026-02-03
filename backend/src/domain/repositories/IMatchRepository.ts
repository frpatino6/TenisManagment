import { Match } from '../entities/Match';

export interface IMatchRepository {
    save(match: Match): Promise<Match>;
    findById(id: string): Promise<Match | null>;
    findByTenant(tenantId: string, limit?: number): Promise<Match[]>;
    findByUser(userId: string, tenantId: string): Promise<Match[]>;
}
