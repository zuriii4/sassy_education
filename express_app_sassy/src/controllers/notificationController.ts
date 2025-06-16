import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import Notification from '../models/notification';
import { Types } from 'mongoose';
import { getUserStatus } from '../utils/websocketService';

export const createNotification = async (
    recipientId: string,
    type: 'material_assigned' | 'material_completed' | 'system',
    title: string,
    message: string,
    relatedId?: string
): Promise<void> => {
    try {
        const notification = new Notification({
            recipient: recipientId,
            type,
            title,
            message,
            relatedId: relatedId ? new Types.ObjectId(relatedId) : undefined,
            isRead: false
        });

        await notification.save();

        const status = getUserStatus(recipientId);
        status.isOnline;
        return;
    } catch (error) {
        console.error('Error creating notification:', error);
    }
};

export const getUserNotifications = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        const { page = 1, limit = 10, unreadOnly = false } = req.query;

        const query: any = { recipient: req.user._id };
        if (unreadOnly === 'true') {
            query.isRead = false;
        }

        const options = {
            sort: { createdAt: -1 },
            limit: Number(limit),
            skip: (Number(page) - 1) * Number(limit)
        };

        const notifications = await Notification.find(query, null, options);
        const total = await Notification.countDocuments(query);

        res.status(200).json({
            notifications,
            totalPages: Math.ceil(total / Number(limit)),
            currentPage: Number(page),
            totalNotifications: total
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching notifications', error });
    }
};

export const markNotificationAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        const { notificationId } = req.params;

        const notification = await Notification.findById(notificationId);

        if (!notification) {
            res.status(404).json({ message: 'Notification not found' });
            return;
        }

        if (!notification.recipient.equals(req.user.id)) {
            res.status(403).json({ message: 'Unauthorized. This notification does not belong to you.' });
            return;
        }

        notification.isRead = true;
        await notification.save();

        res.status(200).json({ message: 'Notification marked as read', notification });
    } catch (error) {
        res.status(500).json({ message: 'Error marking notification as read', error });
    }
};

export const markAllNotificationsAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        await Notification.updateMany(
            { recipient: req.user._id, isRead: false },
            { $set: { isRead: true } }
        );

        res.status(200).json({ message: 'All notifications marked as read' });
    } catch (error) {
        res.status(500).json({ message: 'Error marking all notifications as read', error });
    }
};

export const deleteNotification = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        const { notificationId } = req.params;

        const notification = await Notification.findById(notificationId);

        if (!notification) {
            res.status(404).json({ message: 'Notification not found' });
            return;
        }

        if (!notification.recipient.equals(req.user.id)) {
            res.status(403).json({ message: 'Unauthorized. This notification does not belong to you.' });
            return;
        }

        await notification.deleteOne();

        res.status(200).json({ message: 'Notification deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting notification', error });
    }
};

export const sendNotificationStudent = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        const { studentId, notifMessage, title, type, relatedId } = req.body;

        if (!notifMessage || !studentId || !title || !type) {
            res.status(400).json({ message: 'Missing required fields: studentId, notifMessage, title, or type.' });
            return;
        }

        await createNotification(
            studentId,
            type,
            title,
            notifMessage,
            relatedId
        );

        res.status(200).json({ message: 'Notification sent successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error sending notification', error });
    }
};