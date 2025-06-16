import express from 'express';
import {
    getUserOnlineStatus,
    getOnlineStudents,
    recordUserActivity,
    getOfflineStudents
} from '../controllers/activityController';
import { authenticate } from '../middleware/auth';
import {checkPermission} from "../middleware/checkPer";

const router = express.Router();

router.get('/status/:userId', getUserOnlineStatus);
router.get('/online-students',authenticate, checkPermission('manage_groups'), getOnlineStudents);
router.post('/record',authenticate, recordUserActivity);
router.get('/offline-students', authenticate, checkPermission('manage_groups'), getOfflineStudents);

export default router;