"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const authController_1 = require("../controllers/authController");
const auth_1 = require("../middleware/auth");
const checkPer_1 = require("../middleware/checkPer");
const router = express_1.default.Router();
router.post('/student/login/pin', authController_1.studentPinLogin);
router.post('/student/login/colorcode', authController_1.studentColorCodeLogin);
router.post('/student/:studentId/pin', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_students'), authController_1.setStudentPin);
router.post('/student/:studentId/colorcode', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_students'), authController_1.setStudentColorCode);
router.post('/student/:studentId/generate-pin', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_students'), authController_1.generateRandomPin);
router.post('/student/:studentId/generate-colorcode', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_students'), authController_1.generateRandomColorCode);
router.get('/student/:studentId/auth-method', auth_1.authenticate, authController_1.checkStudentAuthMethod);
router.get('/student/:studentId', auth_1.authenticate, authController_1.getStudentAuth);
exports.default = router;
