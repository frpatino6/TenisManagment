
const { MongoClient, ObjectId } = require('mongodb');

async function run() {
    const uri = "mongodb+srv://frpatino6Coffe:s4ntiago@mycoffecluster.yerjpro.mongodb.net/tennis_mgmt";
    const client = new MongoClient(uri);

    try {
        await client.connect();
        const db = client.db('tennis_mgmt');

        // Clean
        await db.collection('tournaments').deleteMany({});
        await db.collection('groupstages').deleteMany({});
        await db.collection('brackets').deleteMany({});

        const tenantId = new ObjectId("69338a1f75213a463ce0429a");
        const studentIds = [
            "68dab2c0e3fc440497f5097e", "68de09378fb993a9949d29ea", "68df317e36c511a9bf56d6b7",
            "68df33ff36c511a9bf56d6d3", "68e12bba37c008597139ac82", "69312228e55dcefc45ca019e",
            "6959cfc590084ee92d54d7ea", "695ac2835323d6d41728ad0c", "695c5d5d554849fe2979f2fb",
            "695d306b4fa71a24d3f58a0f", "696d45caad1199b2c909dea2", "6976a8c2d16fc6dd5853ca49"
        ].map(id => new ObjectId(id));

        const categoryId = new ObjectId();

        const tournament = {
            name: "Súper Torneo Híbrido 2026",
            description: "Torneo generado automáticamente para Hacienda el Carmen.",
            startDate: new Date("2026-02-01T09:00:00Z"),
            endDate: new Date("2026-02-15T18:00:00Z"),
            status: "IN_PROGRESS",
            tenantId: tenantId,
            categories: [{
                _id: categoryId,
                name: "Abierto Mixto Híbrido",
                gender: "MIXED",
                format: "HYBRID",
                participants: studentIds,
                hasGroupStage: true,
                hasBracket: false,
                groupStageConfig: {
                    numberOfGroups: 3,
                    pointsForWin: 3,
                    pointsForDraw: 1,
                    pointsForLoss: 0,
                    seedingMethod: "RANKING"
                }
            }],
            createdAt: new Date(),
            updatedAt: new Date()
        };

        const tResult = await db.collection('tournaments').insertOne(tournament);
        console.log(`Tournament created: ${tResult.insertedId}`);

        // Groups
        const groups = [
            { id: 'group_a', name: 'Grupo A', seed: 1, participants: studentIds.slice(0, 4) },
            { id: 'group_b', name: 'Grupo B', seed: 2, participants: studentIds.slice(4, 8) },
            { id: 'group_c', name: 'Grupo C', seed: 3, participants: studentIds.slice(8, 12) }
        ];

        const matches = [];
        groups.forEach(g => {
            const p = g.participants;
            // Round robin for each group (4 players -> 6 matches)
            const pairings = [[0, 1], [2, 3], [0, 2], [1, 3], [0, 3], [1, 2]];
            pairings.forEach((pair, idx) => {
                const p1Id = p[pair[0]];
                const p2Id = p[pair[1]];
                matches.push({
                    id: `m_${g.id}_${idx}`,
                    groupId: g.id,
                    player1Id: p1Id,
                    player2Id: p2Id,
                    winnerId: p1Id, // A bit of bias for p1
                    score: "6-4 6-2",
                    matchDate: new Date(),
                    round: 1 + Math.floor(idx / 2)
                });
            });
        });

        const gs = {
            tournamentId: tResult.insertedId,
            categoryId: categoryId.toString(),
            status: "IN_PROGRESS",
            groups: groups.map(g => ({
                ...g,
                matches: matches.filter(m => m.groupId === g.id)
            })),
            createdAt: new Date(),
            updatedAt: new Date()
        };

        await db.collection('groupstages').insertOne(gs);
        console.log("Group stage seeded.");

    } finally {
        await client.close();
    }
}

run().catch(console.dir);
