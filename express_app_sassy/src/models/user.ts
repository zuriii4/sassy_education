import mongoose, { Document, Schema, Model } from 'mongoose';
import bcrypt from 'bcryptjs';

export interface IUser extends Document {
    name: string;
    email: string;
    password: string;
    role: 'student' | 'teacher' | 'admin';
    dateOfBirth: Date;
    lastActive: Date;
    comparePassword(inputPassword: string): Promise<boolean>;
}

const UserSchema = new Schema<IUser>({
    name: { type: String, required: true },
    email: { type: String, required: true, unique: true },
    password: { type: String, required: true },
    role: { type: String, enum: ['student', 'teacher', 'admin'], default: 'student' },
    dateOfBirth: { type: Date, required: true },
    lastActive: { type: Date, default: Date.now },
}, { timestamps: true });

UserSchema.methods.comparePassword = async function (inputPassword: string): Promise<boolean> {
    return bcrypt.compare(inputPassword, this.password);
};

const User: Model<IUser> = mongoose.model<IUser>('User', UserSchema);
export default User;