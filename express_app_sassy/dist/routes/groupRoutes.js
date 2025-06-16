"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const groupController_1 = require("../controllers/groupController");
const auth_1 = require("../middleware/auth");
const checkPer_1 = require("../middleware/checkPer");
const router = express_1.default.Router();
router.post('/create', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_groups'), groupController_1.createGroup); // Vytvorenie skupiny
router.put('/groups/add-student', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_groups'), groupController_1.addStudentToGroup); // Pridanie študenta do skupiny
router.delete('/groups/:groupId', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_groups'), groupController_1.deleteGroup); // Odstránenie skupiny
router.get('/group/:groupId', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_groups'), groupController_1.getGroup);
router.get('/groups', auth_1.authenticate, (0, checkPer_1.checkPermission)('manage_groups'), groupController_1.getGroups);
exports.default = router;
