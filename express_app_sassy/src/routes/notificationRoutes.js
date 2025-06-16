"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const notificationController_1 = require("../controllers/notificationController");
const auth_1 = require("../middleware/auth");
const router = express_1.default.Router();
router.use(auth_1.authenticate);
router.post('/', notificationController_1.sendNotificationStudent);
router.get('/', notificationController_1.getUserNotifications);
router.patch('/:notificationId/read', notificationController_1.markNotificationAsRead);
router.patch('/read-all', notificationController_1.markAllNotificationsAsRead);
router.delete('/:notificationId', notificationController_1.deleteNotification);
exports.default = router;
