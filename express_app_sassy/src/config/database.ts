import mongoose from 'mongoose';
import dotenv from 'dotenv';
import path from "path";
dotenv.config({ path: path.resolve(__dirname, '../../.env') });


const connectDB = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI!);
        console.log('MongoDB connected');
    } catch (err) {
        console.error('Error connecting to MongoDB:', err);
        process.exit(1);
    }
};

export default connectDB;

