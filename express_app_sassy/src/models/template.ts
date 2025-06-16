import mongoose, { Schema, Document, Types } from 'mongoose';

export interface ITemplate extends Document {
    materialId: Types.ObjectId;
    // rating?: number;
}

const TemplateSchema = new Schema<ITemplate>({
    materialId: { type: Schema.Types.ObjectId, ref: 'Material', required: true },
    // rating: { type: Number, default: null }
}, { timestamps: true });

export const Template = mongoose.model<ITemplate>('Template', TemplateSchema);