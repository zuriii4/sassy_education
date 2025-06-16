import { Router } from 'express';
import {
    registerUser,
    loginUser,
    getUser,
    updateUser,
    logoutUser,
    validateToken,
    getCurrentTeacher, deleteUser
} from '../controllers/userController';
import { authenticate } from '../middleware/auth';
import {checkPermission} from "../middleware/checkPer";

const router = Router();

router.post('/register', registerUser);
router.post('/login', loginUser);
router.post('/logout', logoutUser);
router.get('/', authenticate, getUser);
router.put('/update/', authenticate, checkPermission('manage_materials'), updateUser);
router.get('/validate-token', validateToken);
router.get('/teacher', authenticate, checkPermission('manage_materials'), getCurrentTeacher);
router.delete('/delete', authenticate, checkPermission('manage_materials'), deleteUser);

export default router;