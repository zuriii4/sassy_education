import express from 'express';
import {
    getUserNotifications,
    markNotificationAsRead,
    markAllNotificationsAsRead,
    deleteNotification, sendNotificationStudent
} from '../controllers/notificationController';
import { authenticate } from '../middleware/auth';
import {checkPermission} from "../middleware/checkPer";

const router = express.Router();

router.use(authenticate);
router.post('/', sendNotificationStudent);
router.get('/', getUserNotifications);
router.patch('/:notificationId/read', markNotificationAsRead);
router.patch('/read-all', markAllNotificationsAsRead);
router.delete('/:notificationId', deleteNotification);

export default router;