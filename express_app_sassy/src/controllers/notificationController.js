"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendNotificationStudent = exports.deleteNotification = exports.markAllNotificationsAsRead = exports.markNotificationAsRead = exports.getUserNotifications = exports.createNotification = void 0;
const notification_1 = __importDefault(require("../models/notification"));
const mongoose_1 = require("mongoose");
const websocketService_1 = require("../utils/websocketService");
// Create a new notification (internal use)
const createNotification = (recipientId, type, title, message, relatedId) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const notification = new notification_1.default({
            recipient: recipientId,
            type,
            title,
            message,
            relatedId: relatedId ? new mongoose_1.Types.ObjectId(relatedId) : undefined,
            isRead: false
        });
        yield notification.save();
        // Check if user is online to determine if we should send real-time notification
        const status = (0, websocketService_1.getUserStatus)(recipientId);
        status.isOnline;
        return;
    }
    catch (error) {
        console.error('Error creating notification:', error);
    }
});
exports.createNotification = createNotification;
// Get all notifications for the current user
const getUserNotifications = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        const { page = 1, limit = 10, unreadOnly = false } = req.query;
        const query = { recipient: req.user._id };
        if (unreadOnly === 'true') {
            query.isRead = false;
        }
        const options = {
            sort: { createdAt: -1 },
            limit: Number(limit),
            skip: (Number(page) - 1) * Number(limit)
        };
        const notifications = yield notification_1.default.find(query, null, options);
        const total = yield notification_1.default.countDocuments(query);
        res.status(200).json({
            notifications,
            totalPages: Math.ceil(total / Number(limit)),
            currentPage: Number(page),
            totalNotifications: total
        });
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching notifications', error });
    }
});
exports.getUserNotifications = getUserNotifications;
// Mark a notification as read
const markNotificationAsRead = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        const { notificationId } = req.params;
        const notification = yield notification_1.default.findById(notificationId);
        if (!notification) {
            res.status(404).json({ message: 'Notification not found' });
            return;
        }
        // Ensure the notification belongs to the current user
        if (!notification.recipient.equals(req.user.id)) {
            res.status(403).json({ message: 'Unauthorized. This notification does not belong to you.' });
            return;
        }
        notification.isRead = true;
        yield notification.save();
        res.status(200).json({ message: 'Notification marked as read', notification });
    }
    catch (error) {
        res.status(500).json({ message: 'Error marking notification as read', error });
    }
});
exports.markNotificationAsRead = markNotificationAsRead;
// Mark all notifications as read
const markAllNotificationsAsRead = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        yield notification_1.default.updateMany({ recipient: req.user._id, isRead: false }, { $set: { isRead: true } });
        res.status(200).json({ message: 'All notifications marked as read' });
    }
    catch (error) {
        res.status(500).json({ message: 'Error marking all notifications as read', error });
    }
});
exports.markAllNotificationsAsRead = markAllNotificationsAsRead;
// Delete a notification
const deleteNotification = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        const { notificationId } = req.params;
        const notification = yield notification_1.default.findById(notificationId);
        if (!notification) {
            res.status(404).json({ message: 'Notification not found' });
            return;
        }
        // Ensure the notification belongs to the current user
        if (!notification.recipient.equals(req.user.id)) {
            res.status(403).json({ message: 'Unauthorized. This notification does not belong to you.' });
            return;
        }
        yield notification.deleteOne();
        res.status(200).json({ message: 'Notification deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ message: 'Error deleting notification', error });
    }
});
exports.deleteNotification = deleteNotification;
const sendNotificationStudent = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
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
        yield (0, exports.createNotification)(studentId, type, title, notifMessage, relatedId);
        res.status(200).json({ message: 'Notification sent successfully' });
    }
    catch (error) {
        res.status(500).json({ message: 'Error sending notification', error });
    }
});
exports.sendNotificationStudent = sendNotificationStudent;
