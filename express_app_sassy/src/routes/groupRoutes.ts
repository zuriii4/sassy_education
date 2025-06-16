import express from 'express';
import {addStudentToGroup, createGroup, deleteGroup, getGroup, getGroups} from "../controllers/groupController";
import {authenticate} from "../middleware/auth";
import {checkPermission} from "../middleware/checkPer";

const router = express.Router();

router.post('/create', authenticate,checkPermission('manage_groups'), createGroup); // Vytvorenie skupiny
router.put('/groups/add-student', authenticate,checkPermission('manage_groups'), addStudentToGroup); // Pridanie študenta do skupiny
router.delete('/groups/:groupId', authenticate,checkPermission('manage_groups'), deleteGroup); // Odstránenie skupiny
router.get('/group/:groupId', authenticate,checkPermission('manage_groups'), getGroup);
router.get('/groups', authenticate,checkPermission('manage_groups'), getGroups);

export default router;