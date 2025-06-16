import mongoose, { Schema, Document, Types } from 'mongoose';

export interface ITeacher extends Document {
    user: Types.ObjectId;
    specialization: string;
}

const TeacherSchema = new Schema<ITeacher>({
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    specialization: { type: String, default: '' }
});

export const Teacher = mongoose.model<ITeacher>('Teacher', TeacherSchema);