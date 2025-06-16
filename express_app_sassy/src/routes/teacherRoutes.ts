import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {checkPermission} from "../middleware/checkPer";
import {
    deleteTeacher, getAllTeachers, getTeacherDetails, registerTeacher
} from "../controllers/teacherController";
import {updateUserById} from "../controllers/studentController";

const router = Router();

router.post('/register',authenticate, checkPermission('manage_teachers'),registerTeacher);
router.get('/',authenticate, checkPermission('manage_teachers'), getAllTeachers);
router.get('/:teacherId',authenticate, checkPermission('manage_teachers'), getTeacherDetails);
router.put('/update/:teacherId',authenticate, checkPermission('manage_teachers'), updateUserById);
router.delete('/delete/:teacherId',authenticate, checkPermission('manage_teachers'), deleteTeacher);

export default router;