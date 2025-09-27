import mongoose from 'mongoose';
export async function connectMongo(uri) {
    await mongoose.connect(uri);
}
export { mongoose };
//# sourceMappingURL=mongoose.js.map