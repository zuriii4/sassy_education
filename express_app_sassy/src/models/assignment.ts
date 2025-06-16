import mongoose, { Schema, Document, Types } from 'mongoose';

export interface IAssignment extends Document {
    material: Types.ObjectId;
    student: Types.ObjectId;
    group: Types.ObjectId;
    assignedBy: Types.ObjectId;
    assignedAt: Date;
    status: 'pending' | 'completed' | 'overdue';
    completedAt: Date;
    progressRef: Types.ObjectId;
}

const AssignmentSchema: Schema = new Schema(
    {
        material: { type: Schema.Types.ObjectId, ref: 'Material', required: true },
        student: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        group: { type: Schema.Types.ObjectId, ref: 'Group', required: false },
        assignedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        assignedAt: { type: Date, default: Date.now },
        status: { type: String, enum: ['pending', 'completed', 'overdue'], default: 'pending' },
        completedAt: { type: Date, required: false },
        progressRef: { type: Schema.Types.ObjectId, ref: 'Progress', required: false }
    },
    { timestamps: true }
);

AssignmentSchema.index({ student: 1, status: 1 });
AssignmentSchema.index({ material: 1, group: 1 });

export default mongoose.model<IAssignment>('Assignment', AssignmentSchema);