import mongoose, { Schema, Document, Types } from 'mongoose';

export interface IStudent extends Document {
    user: Types.ObjectId;
    notes: string;
    hasSpecialNeeds: boolean;
    needsDescription: string;
    pin: string;
    colorCode: string[];
}

const StudentSchema = new Schema<IStudent>({
    user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    notes: { type: String, default: '' },
    hasSpecialNeeds: { type: Boolean, default: false },
    needsDescription: { type: String, default: '' },
    pin: { type: String },
    colorCode: { type: [String], default: [] },
});

export const Student = mongoose.model<IStudent>('Student', StudentSchema);