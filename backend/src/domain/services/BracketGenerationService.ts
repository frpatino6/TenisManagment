import { BracketMatch } from '../entities/Bracket';
import { v4 as uuidv4 } from 'uuid';

interface ParticipantWithSeed {
    userId: string;
    seed: number; // Posición en el ranking (1 = mejor)
}

/**
 * Servicio de dominio para generación de brackets de eliminación simple.
 */
export class BracketGenerationService {
    /**
     * Genera un bracket de eliminación simple con siembra basada en ranking.
     * 
     * @param participants - Lista de participantes ordenados por ELO descendente
     * @returns Array de matches que conforman el bracket
     */
    generateSingleEliminationBracket(participants: string[]): BracketMatch[] {
        if (participants.length < 2) {
            throw new Error('Se requieren al menos 2 participantes para generar un bracket');
        }

        const participantsWithSeeds: ParticipantWithSeed[] = participants.map((userId, index) => ({
            userId,
            seed: index + 1
        }));

        const bracketSize = this.getNextPowerOfTwo(participants.length);
        const totalRounds = Math.log2(bracketSize);

        const matches: BracketMatch[] = [];

        // Generar matches de todas las rondas (de la final hacia la primera ronda)
        // Round 1 = Final (1 match)
        // Round totalRounds = Primera ronda (más matches)
        for (let round = 1; round <= totalRounds; round++) {
            const matchesInRound = Math.pow(2, round - 1);

            for (let position = 0; position < matchesInRound; position++) {
                const matchId = uuidv4();

                matches.push({
                    id: matchId,
                    round,
                    position,
                    nextMatchId: undefined // Se asignará después
                });
            }
        }

        // Asignar nextMatchId ahora que todos los matches existen
        for (const match of matches) {
            if (match.round < totalRounds) {
                const nextRound = match.round + 1;
                const nextPosition = match.position * 2;

                // Encontrar los matches que avanzan a este
                const childMatch1 = matches.find(m => m.round === nextRound && m.position === nextPosition);
                const childMatch2 = matches.find(m => m.round === nextRound && m.position === nextPosition + 1);

                if (childMatch1) childMatch1.nextMatchId = match.id;
                if (childMatch2) childMatch2.nextMatchId = match.id;
            }
        }

        // Asignar participantes a la primera ronda usando patrón de siembra
        const firstRoundMatches = matches.filter(m => m.round === totalRounds);
        const seedPairs = this.createSeedingPairs(bracketSize);

        firstRoundMatches.forEach((match, index) => {
            const [seed1, seed2] = seedPairs[index];

            // Asignar jugador si existe (si seed > participants.length, es BYE)
            match.player1Id = seed1 <= participants.length
                ? participantsWithSeeds[seed1 - 1].userId
                : undefined;

            match.player2Id = seed2 <= participants.length
                ? participantsWithSeeds[seed2 - 1].userId
                : undefined;

            // Si uno de los jugadores es BYE, auto-avanzar al otro
            if (!match.player1Id && match.player2Id) {
                match.winnerId = match.player2Id;
                this.advanceWinnerToNextRound(match, matches);
            } else if (match.player1Id && !match.player2Id) {
                match.winnerId = match.player1Id;
                this.advanceWinnerToNextRound(match, matches);
            }
        });

        return matches;
    }

    /**
     * Avanza al ganador de un match al siguiente match en el bracket.
     * Esta función es recursiva para manejar BYEs en cadena si fuera necesario.
     */
    private advanceWinnerToNextRound(match: BracketMatch, allMatches: BracketMatch[]): void {
        const winnerId = match.winnerId;
        if (!winnerId || !match.nextMatchId) return;

        const nextMatch = allMatches.find(m => m.id === match.nextMatchId);
        if (!nextMatch) return;

        // Determinar si va a player1 o player2 según la posición del match anterior
        if (match.position % 2 === 0) {
            nextMatch.player1Id = winnerId;
        } else {
            nextMatch.player2Id = winnerId;
        }

        // Si el próximo match también se convirtió en un "virtual" BYE 
        // (ya tiene un jugador y el otro branch garantiza que no habrá oponente)
        // NOTA: En la generación inicial, solo avanzamos si el otro branch es nulo
        // pero usualmente los BYEs se resuelven en la primera ronda.
        // Si quisiéramos auto-avanzar más, necesitaríamos chequear el estado del otro match hijo.
    }

    /**
     * Calcula la siguiente potencia de 2 mayor o igual al número dado.
     */
    private getNextPowerOfTwo(n: number): number {
        return Math.pow(2, Math.ceil(Math.log2(n)));
    }

    /**
     * Crea pares de siembras siguiendo el patrón estándar de torneos.
     * Algoritmo: Comienza con [1,2] y en cada iteración intercala los números
     * para mantener el balance del bracket.
     * 
     * Ejemplo:
     * - Tamaño 2: [1,2] -> [[1,2]]
     * - Tamaño 4: [1,4,2,3] -> [[1,4], [2,3]]
     * - Tamaño 8: [1,8,4,5,2,7,3,6] -> [[1,8], [4,5], [2,7], [3,6]]
     */
    private createSeedingPairs(bracketSize: number): [number, number][] {
        // Generar la secuencia de siembras usando el algoritmo estándar
        let seeds = [1, 2];

        // Expandir la lista hasta alcanzar el tamaño del bracket
        while (seeds.length < bracketSize) {
            const expanded: number[] = [];
            const nextMax = seeds.length * 2 + 1;

            for (const seed of seeds) {
                expanded.push(seed);
                expanded.push(nextMax - seed);
            }

            seeds = expanded;
        }

        // Convertir la lista en pares
        const pairs: [number, number][] = [];
        for (let i = 0; i < seeds.length; i += 2) {
            pairs.push([seeds[i], seeds[i + 1]]);
        }

        return pairs;
    }
}
