import { Bracket, BracketMatch } from '../entities/Bracket';

export interface IBracketRepository {
    create(bracket: Bracket): Promise<Bracket>;
    findById(id: string): Promise<Bracket | null>;
    findByTournamentAndCategory(tournamentId: string, categoryId: string): Promise<Bracket | null>;
    update(id: string, bracket: Partial<Bracket>): Promise<Bracket | null>;

    // Métodos específicos para actualización de matches
    updateMatch(
        bracketId: string,
        matchId: string,
        update: Partial<BracketMatch>
    ): Promise<Bracket | null>;
    delete(tournamentId: string, categoryId: string): Promise<void>;
}
