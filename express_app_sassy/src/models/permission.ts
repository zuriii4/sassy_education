import mongoose, { Schema, Document } from 'mongoose';

export interface IPermission extends Document {
    role: string;
    actions: string[];
}

const PermissionSchema: Schema = new Schema({
    role: { type: String, required: true, unique: true },
    actions: { type: [String], required: true }
});

export const Permission = mongoose.model<IPermission>('Permission', PermissionSchema);