import mongoose, { Schema, Document, Types } from 'mongoose';

export interface INotification extends Document {
    recipient: Types.ObjectId;  // User ID of the recipient
    type: 'material_assigned' | 'material_completed' | 'system';
    title: string;
    message: string;
    relatedId?: Types.ObjectId;
    isRead: boolean;
    createdAt: Date;
}

const NotificationSchema: Schema = new Schema(
    {
        recipient: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        type: { type: String, enum: ['material_assigned', 'material_completed', 'system'], required: true },
        title: { type: String, required: true },
        message: { type: String, required: true },
        relatedId: { type: Schema.Types.ObjectId, required: false },
        isRead: { type: Boolean, default: false }
    },
    { timestamps: true }
);

// Create index for faster querying of unread notifications
NotificationSchema.index({ recipient: 1, isRead: 1 });

export default mongoose.model<INotification>('Notification', NotificationSchema);