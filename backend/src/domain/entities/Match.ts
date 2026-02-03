export interface Match {
    id?: string;
    tenantId: string;
    winnerId: string;
    loserId: string;
    score: string; // Formato sugerido: "6-2, 6-4"
    date: Date;
    isTournament: boolean;
    isOffPeak: boolean;
    isMatchmakingChallenge?: boolean;
    metadata?: Record<string, any>;
}
