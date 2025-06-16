import express from 'express';
import {
    setStudentPin,
    setStudentColorCode,
    studentPinLogin,
    studentColorCodeLogin,
    generateRandomPin,
    generateRandomColorCode,
    checkStudentAuthMethod, getStudentAuth
} from '../controllers/authController';
import {authenticate} from '../middleware/auth';
import {checkPermission} from "../middleware/checkPer";

const router = express.Router();

router.post('/student/login/pin', studentPinLogin);
router.post('/student/login/colorcode', studentColorCodeLogin);

router.post('/student/:studentId/pin', authenticate, checkPermission('manage_students'), setStudentPin);
router.post('/student/:studentId/colorcode', authenticate, checkPermission('manage_students'), setStudentColorCode);
router.post('/student/:studentId/generate-pin', authenticate, checkPermission('manage_students'), generateRandomPin);
router.post('/student/:studentId/generate-colorcode', authenticate, checkPermission('manage_students'), generateRandomColorCode);
router.get('/student/:studentId/auth-method', authenticate, checkStudentAuthMethod);
router.get('/student/:studentId', authenticate, getStudentAuth);



export default router;