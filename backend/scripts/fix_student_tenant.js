const mongoose = require('mongoose');

async function run() {
  const uri = 'mongodb+srv://frpatino6Coffe:s4ntiago@mycoffecluster.yerjpro.mongodb.net/tennis_mgmt';
  try {
    await mongoose.connect(uri);
    console.log('Connected to MongoDB');
    
    const studentId = new mongoose.Types.ObjectId('696d45caad1199b2c909dea2');
    const tenantId = new mongoose.Types.ObjectId('69338a1f75213a463ce0429a');

    // Delete existing if any (just in case there's an inconsistency)
    await mongoose.connection.collection('studenttenants').deleteMany({ studentId, tenantId });

    // Create a new one with 50000 balance
    const stResult = await mongoose.connection.collection('studenttenants').insertOne({ 
      studentId,
      tenantId,
      balance: 50000,
      isActive: true,
      joinedAt: new Date(),
      createdAt: new Date(),
      updatedAt: new Date()
    });
    console.log('StudentTenant created/updated:', stResult);

    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

run();
