
import 'reflect-metadata';
import dotenv from 'dotenv';
import mongoose, { Types } from 'mongoose';
import { TournamentModel } from './infrastructure/database/models/TournamentModel';
import { GroupStageModel } from './infrastructure/database/models/GroupStageModel';

dotenv.config();

const StudentSchema = new mongoose.Schema({
    authUserId: mongoose.Schema.Types.ObjectId,
    name: String,
    fullName: String
}, { collection: 'students' });

const StudentModel = mongoose.models.Student || mongoose.model('Student', StudentSchema);

async function seed() {
    const mongoUri = process.env.MONGO_URI;
    if (!mongoUri) throw new Error('MONGO_URI not found');

    await mongoose.connect(mongoUri);
    console.log('Connected to MongoDB');

    const tenantId = new Types.ObjectId("69338a1f75213a463ce0429a"); // Hacienda el Carmen

    // OBTENER TODOS LOS ALUMNOS DIRECTAMENTE DE LA COLECCIÓN STUDENTS
    const studentsFromDb = await StudentModel.find({});

    // IMPORTANTE: Los participantes en el torneo deben ser los IDs de AuthUser
    const studentIds = studentsFromDb
        .filter(s => s.authUserId)
        .map(s => s.authUserId as Types.ObjectId);

    const studentMap = new Map(studentsFromDb
        .filter(s => s.authUserId)
        .map(s => [s.authUserId!.toString(), s.name || (s as any).fullName || 'Alumno']));

    if (studentIds.length === 0) {
        console.error('No se encontraron alumnos con authUserId en la colección students.');
        await mongoose.disconnect();
        return;
    }

    console.log(`Utilizando ${studentIds.length} alumnos de la colección 'students'.`);

    // Limpiar anteriores
    await TournamentModel.deleteMany({});
    await GroupStageModel.deleteMany({});

    console.log('Base de datos limpia.');

    const categoryId = new Types.ObjectId();

    const tournament = await TournamentModel.create({
        tenantId,
        name: "Torneo de Prueba Hacienda",
        description: "Torneo generado con los 12 alumnos oficiales de la colección students.",
        startDate: new Date("2026-02-01"),
        endDate: new Date("2026-03-01"),
        status: 'IN_PROGRESS',
        categories: [{
            _id: categoryId,
            name: "Categoría Alumnos",
            gender: 'MIXED',
            format: 'HYBRID',
            participants: studentIds,
            hasGroupStage: true,
            hasBracket: false,
            groupStageConfig: {
                numberOfGroups: 4,
                advancePerGroup: 2,
                pointsForWin: 3,
                pointsForDraw: 1,
                pointsForLoss: 0,
                seedingMethod: 'RANDOM'
            }
        }]
    });

    console.log(`Torneo creado: ${tournament.id}`);

    const config = tournament.categories[0].groupStageConfig!;
    const numGroups = config.numberOfGroups;
    const participantsPerGroup = Math.ceil(studentIds.length / numGroups);

    // Generar grupos dinámicamente
    const groups = [];
    for (let i = 0; i < numGroups; i++) {
        const start = i * participantsPerGroup;
        const end = Math.min(start + participantsPerGroup, studentIds.length);
        const groupParticipants = studentIds.slice(start, end);

        if (groupParticipants.length > 0) {
            groups.push({
                id: `group_${String.fromCharCode(97 + i)}`,
                name: `Grupo ${String.fromCharCode(65 + i)}`,
                seed: i + 1,
                participants: groupParticipants
            });
        }
    }

    const processedGroups = groups.map(g => {
        const p = g.participants;
        const matches = [];

        // Generar partidos round-robin
        for (let i = 0; i < p.length; i++) {
            for (let j = i + 1; j < p.length; j++) {
                matches.push({
                    id: `m_${g.id}_${i}_${j}`,
                    groupId: g.id,
                    player1Id: p[i],
                    player1Name: studentMap.get(p[i].toString()),
                    player2Id: p[j],
                    player2Name: studentMap.get(p[j].toString()),
                    winnerId: p[i], // El primero siempre gana para la simulación
                    score: "6-4 6-4",
                    matchDate: new Date(),
                    round: 1
                });
            }
        }

        return {
            id: g.id,
            name: g.name,
            seed: g.seed,
            participants: g.participants,
            matches: matches,
            standings: g.participants.map((pid, idx) => {
                const name = studentMap.get(pid.toString());
                const matchesPlayed = p.length - 1;
                const wins = p.length - 1 - idx;
                const losses = idx;

                return {
                    playerId: pid,
                    playerName: name,
                    playerElo: 1200,
                    position: idx + 1,
                    matchesPlayed: matchesPlayed,
                    wins: wins,
                    draws: 0,
                    losses: losses,
                    points: wins * config.pointsForWin,
                    setsWon: wins * 2,
                    setsLost: losses * 2,
                    gamesWon: wins * 12,
                    gamesLost: losses * 12,
                    setDifference: (wins * 2) - (losses * 2),
                    gameDifference: (wins * 12) - (losses * 12),
                    qualifiedForKnockout: idx < config.advancePerGroup
                };
            })
        };
    });

    await GroupStageModel.create({
        tournamentId: tournament.id,
        categoryId: categoryId.toString(),
        status: 'COMPLETED',
        groups: processedGroups
    });

    console.log('Siembra completada con alumnos reales y partidos simulados.');

    await mongoose.disconnect();
}

seed().catch(err => {
    console.error(err);
    process.exit(1);
});
