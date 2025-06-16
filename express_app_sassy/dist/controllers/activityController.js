"use strict";
var __awaiter = (this && this.__awaiter) || function (thisArg, _arguments, P, generator) {
    function adopt(value) { return value instanceof P ? value : new P(function (resolve) { resolve(value); }); }
    return new (P || (P = Promise))(function (resolve, reject) {
        function fulfilled(value) { try { step(generator.next(value)); } catch (e) { reject(e); } }
        function rejected(value) { try { step(generator["throw"](value)); } catch (e) { reject(e); } }
        function step(result) { result.done ? resolve(result.value) : adopt(result.value).then(fulfilled, rejected); }
        step((generator = generator.apply(thisArg, _arguments || [])).next());
    });
};
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.recordUserActivity = exports.getOfflineStudents = exports.getOnlineStudents = exports.getUserOnlineStatus = void 0;
const websocketService_1 = require("../utils/websocketService");
const user_1 = __importDefault(require("../models/user"));
const student_1 = require("../models/student");
const getUserOnlineStatus = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { userId } = req.params;
        if (!userId) {
            res.status(400).json({ message: 'User ID is required' });
            return;
        }
        const student = yield student_1.Student.findById(userId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        const user = yield user_1.default.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        const status = (0, websocketService_1.getUserStatus)(userId);
        res.status(200).json({
            userId,
            name: user.name,
            isOnline: status.isOnline,
            lastActive: status.lastActive
        });
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching user status', error });
    }
});
exports.getUserOnlineStatus = getUserOnlineStatus;
const getOnlineStudents = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // if (!req.user || req.user.role !== 'teacher') {
        //     res.status(403).json({ message: 'Unauthorized. Only teachers can access this resource.' });
        //     return;
        // }
        // console.log(req.user._id);
        //
        // const teacher = await Teacher.findOne({ user: req.user._id });
        // if (!teacher) {
        //     res.status(404).json({ message: 'Teacher not found' });
        //     return;
        // }
        const onlineUsers = (0, websocketService_1.getOnlineUsers)('student');
        const onlineStudentsDetails = yield Promise.all(onlineUsers.map((user) => __awaiter(void 0, void 0, void 0, function* () {
            const student = yield student_1.Student.findById(user.userId);
            const userDetails = student ? yield user_1.default.findById(student.user).select('name email') : null;
            return {
                userId: (student === null || student === void 0 ? void 0 : student.user) || user.userId,
                studentId: (student === null || student === void 0 ? void 0 : student._id) || null,
                name: (userDetails === null || userDetails === void 0 ? void 0 : userDetails.name) || 'Unknown',
                lastActive: user.lastActive
            };
        })));
        res.status(200).json(onlineStudentsDetails);
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching online students', error });
    }
});
exports.getOnlineStudents = getOnlineStudents;
const getOfflineStudents = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // if (!req.user || req.user.role !== 'teacher') {
        //     res.status(403).json({ message: 'Unauthorized. Only teachers can access this resource.' });
        //     return;
        // }
        //
        // const teacher = await Teacher.findOne({ user: req.user._id });
        // if (!teacher) {
        //     res.status(404).json({ message: 'Teacher not found' });
        //     return;
        // }
        const onlineUserIds = (0, websocketService_1.getOnlineUsers)('student').map(user => user.userId.toString());
        const offlineUsers = yield user_1.default.find({
            role: 'student',
            _id: { $nin: onlineUserIds }
        }).select('_id name email lastActive');
        const offlineStudentsDetails = yield Promise.all(offlineUsers.map((user) => __awaiter(void 0, void 0, void 0, function* () {
            const student = yield student_1.Student.findOne({ user: user._id });
            return {
                userId: user._id,
                studentId: (student === null || student === void 0 ? void 0 : student._id) || null,
                name: user.name || 'Unknown',
                lastActive: user.lastActive || null
            };
        })));
        res.status(200).json(offlineStudentsDetails);
    }
    catch (error) {
        res.status(500).json({
            message: 'Error fetching offline students',
            error: error.message
        });
    }
});
exports.getOfflineStudents = getOfflineStudents;
const recordUserActivity = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // console.log("recording user activity:");
        // console.log(req.user);
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        yield user_1.default.findByIdAndUpdate(req.user._id, {
            lastActive: new Date(),
        });
        res.status(200).json({ message: 'Activity recorded successfully' });
    }
    catch (error) {
        res.status(500).json({ message: 'Error recording activity', error });
    }
});
exports.recordUserActivity = recordUserActivity;
