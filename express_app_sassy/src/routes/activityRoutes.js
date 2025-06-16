"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const activityController_1 = require("../controllers/activityController");
const auth_1 = require("../middleware/auth");
const checkPer_1 = require("../middleware/checkPer");
const router = express_1.default.Router();
// Get user online status
router.get('/status/:userId', activityController_1.getUserOnlineStatus);
// Get all online students (for teachers)
router.get('/online-students', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_groups'), activityController_1.getOnlineStudents);
// Record user activity
router.post('/record', auth_1.authenticate, activityController_1.recordUserActivity);
// Record user activity
router.get('/offline-students', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_groups'), activityController_1.getOfflineStudents);
exports.default = router;
