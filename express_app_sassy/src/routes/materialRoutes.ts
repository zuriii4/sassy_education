import { Router } from 'express';
import {
    createMaterial,
    deleteMaterial, getAllStudentProgress, getAllTeachersMaterials, getAllTemplates, getMaterialDetails,
    getStudentMaterials, saveAsTemplate,
    submitMaterial,
    updateMaterial
} from '../controllers/materialController';
import {authenticate} from "../middleware/auth";
import {checkPermission} from "../middleware/checkPer";
import {getImage, uploadImage} from "../controllers/uploadController";
import {getStudentGroups} from "../controllers/groupController";

const router = Router();

router.post('/create', authenticate, checkPermission('manage_groups'), createMaterial);
router.put('/:id', authenticate, checkPermission('manage_groups'), updateMaterial);
router.delete('/:id', authenticate, checkPermission('manage_groups'), deleteMaterial);
router.get('/details/:materialId',authenticate, checkPermission('view_material'), getMaterialDetails);
router.post('/image', authenticate, checkPermission('manage_groups'), uploadImage);
router.post('/get-image', authenticate, getImage);
router.get('', authenticate, checkPermission('manage_groups'), getAllTeachersMaterials);
router.get('/student',authenticate , getStudentMaterials);
router.post('/submit-material', authenticate, checkPermission('complete_task') , submitMaterial);
router.post('/save-as-template', authenticate, checkPermission('manage_groups'), saveAsTemplate);
router.get('/templates',authenticate, checkPermission('manage_groups') , getAllTemplates);
router.get('/progress/:studentId',getAllStudentProgress);
export default router;