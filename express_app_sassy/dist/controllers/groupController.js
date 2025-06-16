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
exports.removeStudentFromGroup = exports.getStudentGroups = exports.deleteGroup = exports.addStudentToGroup = exports.createGroup = exports.getGroup = exports.getGroups = void 0;
const group_1 = require("../models/group");
const user_1 = __importDefault(require("../models/user"));
const teacher_1 = require("../models/teacher");
const student_1 = require("../models/student");
const mongoose_1 = __importDefault(require("mongoose"));
const getGroups = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const groups = yield group_1.Group.find();
        const groupDetails = yield Promise.all(groups.map((group) => __awaiter(void 0, void 0, void 0, function* () {
            const teacher = yield teacher_1.Teacher.findById(group.teacher);
            const teacherUser = teacher ? yield user_1.default.findById(teacher.user) : null;
            const teacherInfo = teacherUser ? {
                id: teacherUser._id,
                name: teacherUser.name
            } : { id: group.teacher, name: 'Unknown Teacher' };
            const studentModels = yield student_1.Student.find({
                _id: { $in: group.students }
            });
            const studentUsers = yield user_1.default.find({
                _id: { $in: studentModels.map(s => s.user) }
            }).select('_id name');
            const formattedStudents = studentModels.map(student => {
                const user = studentUsers.find((u) => u._id.equals(student.user));
                return {
                    id: student._id,
                    name: user ? user.name : 'Neznámy študent'
                };
            });
            return {
                id: group._id,
                name: group.name,
                teacher: teacherInfo,
                students: formattedStudents
            };
        })));
        res.status(200).json(groupDetails);
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching groups', error });
    }
});
exports.getGroups = getGroups;
const getGroup = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { groupId } = req.params;
    try {
        const group = yield group_1.Group.findById(groupId);
        if (!group) {
            res.status(404).json({ message: 'Group not found' });
            return;
        }
        const teacherUser = yield teacher_1.Teacher.findById(group.teacher);
        // console.log(teacherUser);
        if (!teacherUser) {
            res.status(404).json({ message: 'teacher not found' });
            return;
        }
        const user = yield user_1.default.findById(teacherUser.user);
        const teacherDetails = user ? {
            id: user._id,
            name: user.name
        } : { id: group.teacher, name: 'Unknown Teacher' };
        const studentModels = yield student_1.Student.find({
            _id: { $in: group.students }
        });
        const studentUsers = yield user_1.default.find({
            _id: { $in: studentModels.map(s => s.user) }
        }).select('_id name');
        const formattedStudents = studentModels.map(student => {
            const user = studentUsers.find((u) => u._id.equals(student.user));
            return {
                id: student._id,
                name: (user === null || user === void 0 ? void 0 : user.name) || 'Neznámy študent'
            };
        });
        res.status(200).json({
            id: group._id,
            name: group.name,
            teacher: teacherDetails,
            students: formattedStudents
        });
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching group info', error });
    }
});
exports.getGroup = getGroup;
const createGroup = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { name, teacherId, studentIds } = req.body;
    try {
        const teacher = yield teacher_1.Teacher.findById(teacherId);
        if (!teacher) {
            res.status(400).json({ message: 'Teacher not found or invalid role' });
            return;
        }
        const students = yield student_1.Student.find({ _id: { $in: studentIds } });
        if (students.length !== studentIds.length) {
            res.status(400).json({ message: 'One or more students not found' });
            return;
        }
        const newGroup = new group_1.Group({ name, teacher: teacherId, students: studentIds });
        yield newGroup.save();
        res.status(201).json({ message: 'Group created successfully', group: newGroup });
    }
    catch (error) {
        res.status(500).json({ message: 'Error creating group', error });
    }
});
exports.createGroup = createGroup;
const addStudentToGroup = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { groupId, studentId } = req.body;
    try {
        const group = yield group_1.Group.findById(groupId);
        if (!group) {
            res.status(404).json({ message: 'Group not found' });
            return;
        }
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(400).json({ message: 'Student not found or invalid role' });
            return;
        }
        if (!group.students.includes(studentId)) {
            group.students.push(studentId);
            yield group.save();
        }
        res.status(200).json({ message: 'Student added to group', group });
    }
    catch (error) {
        res.status(500).json({ message: 'Error adding student', error });
    }
});
exports.addStudentToGroup = addStudentToGroup;
const deleteGroup = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { groupId } = req.params;
    try {
        const deletedGroup = yield group_1.Group.findByIdAndDelete(groupId);
        if (!deletedGroup) {
            res.status(404).json({ message: 'Group not found' });
            return;
        }
        res.status(200).json({ message: 'Group deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ message: 'Error deleting group', error });
    }
});
exports.deleteGroup = deleteGroup;
const getStudentGroups = (studentId) => __awaiter(void 0, void 0, void 0, function* () {
    const groups = yield group_1.Group.find({ members: studentId });
    return groups.map(group => group._id.toString());
});
exports.getStudentGroups = getStudentGroups;
const removeStudentFromGroup = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { groupId, studentId } = req.params;
    try {
        const group = yield group_1.Group.findById(groupId);
        if (!group) {
            res.status(404).json({ message: 'Group not found' });
            return;
        }
        if (!group.students.includes(new mongoose_1.default.Types.ObjectId(studentId))) {
            res.status(400).json({ message: 'Student is not a member of this group' });
            return;
        }
        group.students = group.students.filter(student => student.toString() !== studentId);
        yield group.save();
        res.status(200).json({
            message: 'Student successfully removed from group',
            group: {
                id: group._id,
                name: group.name,
                studentCount: group.students.length
            }
        });
    }
    catch (error) {
        res.status(500).json({ message: 'Error removing student from group', error });
    }
});
exports.removeStudentFromGroup = removeStudentFromGroup;
