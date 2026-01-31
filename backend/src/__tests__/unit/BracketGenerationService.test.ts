import { describe, it, expect } from '@jest/globals';
import { BracketGenerationService } from '../../domain/services/BracketGenerationService';

describe('BracketGenerationService', () => {
    let service: BracketGenerationService;

    beforeEach(() => {
        service = new BracketGenerationService();
    });

    describe('generateSingleEliminationBracket', () => {
        it('should throw error with less than 2 participants', () => {
            expect(() => service.generateSingleEliminationBracket(['player1']))
                .toThrow('Se requieren al menos 2 participantes');
        });

        it('should generate bracket for 2 participants (1 match)', () => {
            const participants = ['player1', 'player2'];
            const matches = service.generateSingleEliminationBracket(participants);

            expect(matches).toHaveLength(1);
            expect(matches[0].round).toBe(1);
            expect(matches[0].player1Id).toBe('player1');
            expect(matches[0].player2Id).toBe('player2');
            expect(matches[0].nextMatchId).toBeUndefined();
        });

        it('should generate bracket for 4 participants (3 matches)', () => {
            const participants = ['p1', 'p2', 'p3', 'p4'];
            const matches = service.generateSingleEliminationBracket(participants);

            expect(matches).toHaveLength(3);

            // Round 2 (Semifinales)
            const semifinals = matches.filter(m => m.round === 2);
            expect(semifinals).toHaveLength(2);
            expect(semifinals[0].player1Id).toBe('p1'); // Seed 1
            expect(semifinals[0].player2Id).toBe('p4'); // Seed 4
            expect(semifinals[1].player1Id).toBe('p2'); // Seed 2
            expect(semifinals[1].player2Id).toBe('p3'); // Seed 3

            // Round 1 (Final)
            const final = matches.find(m => m.round === 1);
            expect(final).toBeDefined();
            expect(final!.nextMatchId).toBeUndefined();
        });

        it('should generate bracket for 8 participants with correct seeding', () => {
            const participants = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'];
            const matches = service.generateSingleEliminationBracket(participants);

            expect(matches).toHaveLength(7); // 4 + 2 + 1

            // Round 3 (Primera ronda)
            const firstRound = matches.filter(m => m.round === 3);
            expect(firstRound).toHaveLength(4);

            // Verificar patrón de siembra estándar
            expect(firstRound[0].player1Id).toBe('p1'); // 1 vs 8
            expect(firstRound[0].player2Id).toBe('p8');

            expect(firstRound[1].player1Id).toBe('p4'); // 4 vs 5
            expect(firstRound[1].player2Id).toBe('p5');

            expect(firstRound[2].player1Id).toBe('p2'); // 2 vs 7
            expect(firstRound[2].player2Id).toBe('p7');

            expect(firstRound[3].player1Id).toBe('p3'); // 3 vs 6
            expect(firstRound[3].player2Id).toBe('p6');
        });

        it('should handle byes correctly for 5 participants', () => {
            const participants = ['p1', 'p2', 'p3', 'p4', 'p5'];
            const matches = service.generateSingleEliminationBracket(participants);

            // Bracket de 8 posiciones (3 byes)
            expect(matches).toHaveLength(7);

            const firstRound = matches.filter(m => m.round === 3);

            // Contar matches con BYE (winnerId ya asignado)
            const matchesWithBye = firstRound.filter(m => m.winnerId !== undefined);
            expect(matchesWithBye.length).toBe(3);

            // Verificar que los mejores sembrados reciban BYE
            const byeWinners = matchesWithBye.map(m => m.winnerId);
            expect(byeWinners).toContain('p1'); // Seed 1
            expect(byeWinners).toContain('p2'); // Seed 2
            expect(byeWinners).toContain('p3'); // Seed 3
        });

        it('should create valid tree structure with nextMatchId', () => {
            const participants = ['p1', 'p2', 'p3', 'p4'];
            const matches = service.generateSingleEliminationBracket(participants);

            const semifinals = matches.filter(m => m.round === 2);
            const final = matches.find(m => m.round === 1);

            // Ambas semifinales deben apuntar a la final
            expect(semifinals[0].nextMatchId).toBe(final!.id);
            expect(semifinals[1].nextMatchId).toBe(final!.id);

            // La final no tiene siguiente match
            expect(final!.nextMatchId).toBeUndefined();
        });
    });
});
