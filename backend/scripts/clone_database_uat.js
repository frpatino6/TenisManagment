const mongoose = require('mongoose');
const { MongoClient } = mongoose.mongo;

// Configuration
const SOURCE_DB = 'tennis_mgmt';
const TARGET_DB = 'tenisManagment_uat';
// Using the URI from .env but without the database name to allow switching
const MONGO_URI = 'mongodb+srv://frpatino6Coffe:s4ntiago@mycoffecluster.yerjpro.mongodb.net/';

async function cloneDatabase() {
    console.log(`Starting database clone process...`);
    console.log(`Source: ${SOURCE_DB}`);
    console.log(`Target: ${TARGET_DB}`);

    const client = new MongoClient(MONGO_URI);

    try {
        await client.connect();
        console.log('Connected to MongoDB cluster.');

        const sourceDb = client.db(SOURCE_DB);
        const targetDb = client.db(TARGET_DB);

        // Get list of collections from source
        const collections = await sourceDb.listCollections().toArray();
        console.log(`Found ${collections.length} collections to clone.`);

        for (const collectionInfo of collections) {
            const collName = collectionInfo.name;
            if (collName === 'system.views') continue; // Skip views for now

            console.log(`\nProcessing collection: ${collName}`);

            const sourceColl = sourceDb.collection(collName);
            const targetColl = targetDb.collection(collName);

            // 1. Drop target collection if exists
            try {
                await targetColl.drop();
                console.log(`  - Dropped existing target collection.`);
            } catch (e) {
                if (e.code !== 26) { // 26 = NamespaceNotFound
                    console.warn(`  - Warning dropping collection: ${e.message}`);
                }
            }

            // 2. Bulk Copy Documents
            const count = await sourceColl.countDocuments();
            if (count > 0) {
                console.log(`  - Copying ${count} documents...`);
                // Use default batch size for cursor
                const cursor = sourceColl.find({});

                // Process in batches manually if needed, or just insertMany if memory allows. 
                // For safety with 4MB data, insertMany is fine, but streaming is better practice.
                // We'll use a simple array approach for this size (4.6MB is small).
                const docs = await cursor.toArray();
                await targetColl.insertMany(docs);
                console.log(`  - Inserted ${docs.length} documents.`);
            } else {
                console.log(`  - Collection is empty, skipping data copy.`);
            }

            // 3. Copy Indexes
            const indexes = await sourceColl.indexes();
            // Filter out default _id index which is created automatically
            const indexesToCreate = indexes.filter(idx => idx.name !== '_id_');

            if (indexesToCreate.length > 0) {
                console.log(`  - Copying ${indexesToCreate.length} indexes...`);
                // We need to transform the index definition slightly strictly for createIndexes
                const formattedIndexes = indexesToCreate.map(idx => {
                    const { v, ns, ...indexSpec } = idx; // Remove version and namespace
                    return indexSpec;
                });

                for (const idxSpec of formattedIndexes) {
                    try {
                        await targetColl.createIndex(idxSpec.key, idxSpec);
                    } catch (err) {
                        console.warn(`  - Error creating index ${idxSpec.name}: ${err.message}`);
                    }
                }
                console.log(`  - Indexes created.`);
            }
        }

        console.log('\n---------------------------------------------------');
        console.log('Database verification:');

        // Final Verification
        const targetCollections = await targetDb.listCollections().toArray();
        console.log(`Target database now has ${targetCollections.length} collections.`);

        // Check a random sample
        if (targetCollections.length > 0) {
            const sampleCollName = collections[0].name;
            const srcCount = await sourceDb.collection(sampleCollName).countDocuments();
            const tgtCount = await targetDb.collection(sampleCollName).countDocuments();
            console.log(`Verification [${sampleCollName}]: Source=${srcCount}, Target=${tgtCount}`);
            if (srcCount === tgtCount) {
                console.log('SUCCESS: Sample collection counts match.');
            } else {
                console.error('WARNING: Sample collection counts DO NOT match!');
            }
        }

    } catch (error) {
        console.error('Fatal Error during cloning:', error);
        process.exit(1);
    } finally {
        await client.close();
        console.log('Connection closed.');
    }
}

cloneDatabase();
