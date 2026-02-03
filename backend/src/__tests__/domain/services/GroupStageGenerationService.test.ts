import { GroupStageGenerationService } from '@/domain/services/GroupStageGenerationService';
import type { GroupStanding, Group } from '@/domain/entities/GroupStage';

interface ParticipantWithElo {
    userId: string;
    userName: string;
    elo: number;
}

describe('GroupStageGenerationService', () => {
    let service: GroupStageGenerationService;

    beforeEach(() => {
        service = new GroupStageGenerationService();
    });

    describe('generateBalancedGroups', () => {
        it('should generate 4 balanced groups with snake seeding', () => {
            // Arrange: 16 jugadores con ELO descendente
            const participants: ParticipantWithElo[] = Array.from({ length: 16 }, (_, i) => ({
                userId: `user${i + 1}`,
                userName: `Player ${i + 1}`,
                elo: 2000 - (i * 50), // 2000, 1950, 1900, ..., 1250
            }));

            // Act
            const groups = service.generateBalancedGroups(participants, 4);

            // Assert
            expect(groups).toHaveLength(4);

            // Verificar nombres de grupos
            expect(groups[0].name).toBe('Grupo A');
            expect(groups[1].name).toBe('Grupo B');
            expect(groups[2].name).toBe('Grupo C');
            expect(groups[3].name).toBe('Grupo D');

            // Verificar que cada grupo tiene 4 jugadores
            groups.forEach((group: Group) => {
                expect(group.participants).toHaveLength(4);
                expect(group.standings).toHaveLength(4);
            });

            // Verificar snake seeding: Grupo A debe tener seeds 1, 8, 9, 16
            expect(groups[0].participants).toContain('user1');  // Seed 1
            expect(groups[0].participants).toContain('user8');  // Seed 8
            expect(groups[0].participants).toContain('user9');  // Seed 9
            expect(groups[0].participants).toContain('user16'); // Seed 16
        });

        it('should handle uneven distribution (15 players in 4 groups)', () => {
            // Arrange: 15 jugadores
            const participants: ParticipantWithElo[] = Array.from({ length: 15 }, (_, i) => ({
                userId: `user${i + 1}`,
                userName: `Player ${i + 1}`,
                elo: 2000 - (i * 50),
            }));

            // Act
            const groups = service.generateBalancedGroups(participants, 4);

            // Assert
            expect(groups).toHaveLength(4);

            const groupSizes = groups.map((g: Group) => g.participants.length);
            // Debe haber 3 grupos de 4 y 1 grupo de 3
            expect(groupSizes.filter((size: number) => size === 4)).toHaveLength(3);
            expect(groupSizes.filter((size: number) => size === 3)).toHaveLength(1);
        });

        it('should initialize standings with zero values', () => {
            // Arrange
            const participants: ParticipantWithElo[] = [
                { userId: 'user1', userName: 'Player 1', elo: 2000 },
                { userId: 'user2', userName: 'Player 2', elo: 1900 },
            ];

            // Act
            const groups = service.generateBalancedGroups(participants, 1);

            // Assert
            const standings = groups[0].standings;
            expect(standings).toHaveLength(2);

            standings.forEach((standing: GroupStanding) => {
                expect(standing.points).toBe(0);
                expect(standing.wins).toBe(0);
                expect(standing.losses).toBe(0);
                expect(standing.draws).toBe(0);
                expect(standing.setsWon).toBe(0);
                expect(standing.setsLost).toBe(0);
                expect(standing.gamesWon).toBe(0);
                expect(standing.gamesLost).toBe(0);
            });
        });
    });

    describe('generateRoundRobinFixtures', () => {
        it('should generate correct number of matches for 4 players', () => {
            // Arrange
            const participants = ['user1', 'user2', 'user3', 'user4'];
            const groupId = 'group-A';

            // Act
            const matches = service.generateRoundRobinFixtures(participants, groupId);

            // Assert
            // Con 4 jugadores: C(4,2) = 6 partidos
            expect(matches).toHaveLength(6);
        });

        it('should ensure all players face each other exactly once', () => {
            // Arrange
            const participants = ['user1', 'user2', 'user3'];
            const groupId = 'group-A';

            // Act
            const matches = service.generateRoundRobinFixtures(participants, groupId);

            // Assert
            expect(matches).toHaveLength(3); // C(3,2) = 3

            // Verificar que cada par se enfrenta exactamente una vez
            const pairs = matches.map((m: any) => [m.player1Id, m.player2Id].sort().join('-'));
            expect(new Set(pairs).size).toBe(3); // No duplicados
            expect(pairs).toContain('user1-user2');
            expect(pairs).toContain('user1-user3');
            expect(pairs).toContain('user2-user3');
        });

        it('should initialize matches with undefined winnerId and score', () => {
            // Arrange
            const participants = ['user1', 'user2'];
            const groupId = 'group-A';

            // Act
            const matches = service.generateRoundRobinFixtures(participants, groupId);

            // Assert
            matches.forEach(match => {
                expect(match.winnerId).toBeUndefined();
                expect(match.score).toBeUndefined();
                expect(match.groupId).toBe(groupId);
            });
        });
    });

    describe('recalculateStandings', () => {
        it('should sort by points descending', () => {
            // Arrange
            const standings: GroupStanding[] = [
                {
                    playerId: 'user1',
                    playerName: 'Player 1',
                    points: 3,
                    wins: 1,
                    losses: 0,
                    draws: 0,
                    matchesPlayed: 1,
                    setsWon: 2,
                    setsLost: 0,
                    setDifference: 2,
                    gamesWon: 12,
                    gamesLost: 6,
                    gameDifference: 6,
                    position: 0,
                    qualifiedForKnockout: false,
                },
                {
                    playerId: 'user2',
                    playerName: 'Player 2',
                    points: 6,
                    wins: 2,
                    losses: 0,
                    draws: 0,
                    matchesPlayed: 2,
                    setsWon: 4,
                    setsLost: 0,
                    setDifference: 4,
                    gamesWon: 24,
                    gamesLost: 10,
                    gameDifference: 14,
                    position: 0,
                    qualifiedForKnockout: false,
                },
            ];

            // Act
            const sorted = service.recalculateStandings(standings);

            // Assert
            expect(sorted[0].playerId).toBe('user2'); // 6 puntos
            expect(sorted[0].position).toBe(1);
            expect(sorted[1].playerId).toBe('user1'); // 3 puntos
            expect(sorted[1].position).toBe(2);
        });

        it('should use set difference as tiebreaker', () => {
            // Arrange: Ambos con 3 puntos
            const standings: GroupStanding[] = [
                {
                    playerId: 'user1',
                    playerName: 'Player 1',
                    points: 3,
                    wins: 1,
                    losses: 0,
                    draws: 0,
                    matchesPlayed: 1,
                    setsWon: 2,
                    setsLost: 1,
                    setDifference: 1,
                    gamesWon: 12,
                    gamesLost: 10,
                    gameDifference: 2,
                    position: 0,
                    qualifiedForKnockout: false,
                },
                {
                    playerId: 'user2',
                    playerName: 'Player 2',
                    points: 3,
                    wins: 1,
                    losses: 0,
                    draws: 0,
                    matchesPlayed: 1,
                    setsWon: 2,
                    setsLost: 0,
                    setDifference: 2,
                    gamesWon: 12,
                    gamesLost: 8,
                    gameDifference: 4,
                    position: 0,
                    qualifiedForKnockout: false,
                },
            ];

            // Act
            const sorted = service.recalculateStandings(standings);

            // Assert
            expect(sorted[0].playerId).toBe('user2'); // Mejor diferencia de sets
            expect(sorted[1].playerId).toBe('user1');
        });

        it('should use game difference as secondary tiebreaker', () => {
            // Arrange: Mismos puntos y diferencia de sets
            const standings: GroupStanding[] = [
                {
                    playerId: 'user1',
                    playerName: 'Player 1',
                    points: 3,
                    wins: 1,
                    losses: 0,
                    draws: 0,
                    matchesPlayed: 1,
                    setsWon: 2,
                    setsLost: 1,
                    setDifference: 1,
                    gamesWon: 14,
                    gamesLost: 10,
                    gameDifference: 4,
                    position: 0,
                    qualifiedForKnockout: false,
                },
                {
                    playerId: 'user2',
                    playerName: 'Player 2',
                    points: 3,
                    wins: 1,
                    losses: 0,
                    draws: 0,
                    matchesPlayed: 1,
                    setsWon: 2,
                    setsLost: 1,
                    setDifference: 1,
                    gamesWon: 16,
                    gamesLost: 10,
                    gameDifference: 6,
                    position: 0,
                    qualifiedForKnockout: false,
                },
            ];

            // Act
            const sorted = service.recalculateStandings(standings);

            // Assert
            expect(sorted[0].playerId).toBe('user2'); // Mejor diferencia de games
            expect(sorted[1].playerId).toBe('user1');
        });
    });
});
