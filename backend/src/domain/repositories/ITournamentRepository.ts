import { Tournament } from '../entities/Tournament';

export interface ITournamentRepository {
    create(tournament: Tournament): Promise<Tournament>;
    findById(id: string): Promise<Tournament | null>;
    findAllByTenant(tenantId: string): Promise<Tournament[]>;
    update(id: string, tournament: Partial<Tournament>): Promise<Tournament | null>;
    delete(id: string): Promise<boolean>;

    // Métodos específicos para participantes
    addParticipantToCategory(
        tournamentId: string,
        categoryId: string,
        userId: string
    ): Promise<Tournament | null>;

    removeParticipantFromCategory(
        tournamentId: string,
        categoryId: string,
        userId: string
    ): Promise<Tournament | null>;
}
