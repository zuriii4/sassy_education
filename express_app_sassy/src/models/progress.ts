import mongoose, { Schema, Document, Types } from 'mongoose';

export interface IProgress extends Document {
    student: Types.ObjectId;
    material: Types.ObjectId;
    answers: any;
    score: number;
    createdAt: Date;
}

const ProgressSchema: Schema = new Schema(
    {
        student: { type: Schema.Types.ObjectId, ref: 'Student', required: true },
        material: { type: Schema.Types.ObjectId, ref: 'Material', required: true },
        answers: [{  type: Schema.Types.Mixed, required: true }],
        score: { type: Number, default: 0 },
        createdAt : { type: Date , default: Date.now },
    },
    { timestamps: true }
);

export default mongoose.model<IProgress>('Progress', ProgressSchema);