import { Router } from 'express';
import { authenticate } from '../middleware/auth';
import {checkPermission} from "../middleware/checkPer";
import {
    deleteStudent,
    getAllStudents,
    getStudentDetails,
    getStudentGroups, getStudentsNames, registerStudent, searchStudents, updateUserById
} from "../controllers/studentController";
import {removeStudentFromGroup} from "../controllers/groupController";

const router = Router();

router.post('/register',authenticate, checkPermission('manage_students'),registerStudent);
router.get('/',authenticate, checkPermission('manage_students'), getAllStudents);
router.get('/names', getStudentsNames);
router.get('/:studentId',authenticate, checkPermission('manage_students'), getStudentDetails);
router.get('/:studentId/groups',authenticate, checkPermission('manage_students'), getStudentGroups);
router.get('/:q', authenticate, checkPermission('manage_students'), searchStudents);
router.delete('/groups/:groupId/students/:studentId', authenticate, checkPermission('manage_students'), removeStudentFromGroup);
router.put('/update/:studentId',authenticate, checkPermission('manage_students'), updateUserById);
router.delete('/delete/:studentId',authenticate, checkPermission('manage_students'), deleteStudent);

export default router;