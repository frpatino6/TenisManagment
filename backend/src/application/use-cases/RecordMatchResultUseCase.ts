import { IMatchRepository } from '../../domain/repositories/IMatchRepository';
import { RankingService } from '../services/RankingService';
import { Match } from '../../domain/entities/Match';
import { MatchProcessResponse } from './ProcessMatchResultUseCase';
import { Logger } from '../../infrastructure/services/Logger';

export interface RecordMatchInput {
    tenantId: string;
    winnerId: string;
    loserId: string;
    score: string;
    isTournament: boolean;
    isOffPeak: boolean;
    isMatchmakingChallenge?: boolean;
}

export interface RecordMatchResultResponse {
    match: Match;
    rankingChanges: MatchProcessResponse;
}

export class RecordMatchResultUseCase {
    private readonly logger = new Logger({ service: 'RecordMatchResultUseCase' });

    constructor(
        private readonly matchRepository: IMatchRepository,
        private readonly rankingService: RankingService
    ) { }

    public async execute(input: RecordMatchInput): Promise<RecordMatchResultResponse> {
        this.logger.info('Registrando resultado de partido y actualizando rankings', {
            winnerId: input.winnerId,
            loserId: input.loserId
        });

        // 1. Persistir el partido
        const matchData: Match = {
            ...input,
            date: new Date(),
        };
        const savedMatch = await this.matchRepository.save(matchData);

        // 2. Actualizar Rankings
        // El RankingService ya tiene la lógica de cálculo (ELO y Race)
        const rankingChanges = await this.rankingService.processMatchResult({
            tenantId: input.tenantId,
            winnerId: input.winnerId,
            loserId: input.loserId,
            isTournament: input.isTournament,
            isOffPeak: input.isOffPeak,
            isMatchmakingChallenge: input.isMatchmakingChallenge
        });

        return {
            match: savedMatch,
            rankingChanges
        };
    }
}
