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
exports.getStudentsNames = exports.deleteStudent = exports.updateUserById = exports.searchStudents = exports.getStudentGroups = exports.getStudentDetails = exports.getAllStudents = exports.registerStudent = void 0;
const student_1 = require("../models/student");
const group_1 = require("../models/group");
const user_1 = __importDefault(require("../models/user"));
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const material_1 = __importDefault(require("../models/material"));
const progress_1 = __importDefault(require("../models/progress"));
const registerStudent = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { name, email, password, dateOfBirth, notes = '', hasSpecialNeeds = false, needsDescription = '' } = req.body;
    try {
        const existingUser = yield user_1.default.findOne({ email });
        if (existingUser) {
            res.status(400).json({ message: 'User already exists.' });
            return;
        }
        const hashedPassword = yield bcryptjs_1.default.hash(password, 10);
        const newUser = new user_1.default({
            name,
            email,
            password: hashedPassword,
            role: 'student',
            dateOfBirth: new Date(dateOfBirth),
            lastActive: new Date(),
        });
        yield newUser.save();
        const newStudent = new student_1.Student({
            user: newUser._id,
            notes,
            hasSpecialNeeds,
            needsDescription
        });
        yield newStudent.save();
        res.status(201).json({ message: `Student registered successfully`, user: newUser });
    }
    catch (error) {
        res.status(500).json({ message: 'Student registration failed.', error: error.message });
    }
});
exports.registerStudent = registerStudent;
// Získanie všetkých študentov
const getAllStudents = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const students = yield student_1.Student.find()
            .populate({
            path: 'user',
            select: 'name email'
        })
            .exec();
        const formattedStudents = students.map(student => {
            const user = student.user;
            return {
                id: student._id,
                name: user.name,
                email: user.email,
                notes: student.notes,
                hasSpecialNeeds: student.hasSpecialNeeds,
                needsDescription: student.needsDescription
            };
        });
        res.status(200).json(formattedStudents);
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching students', error });
    }
});
exports.getAllStudents = getAllStudents;
// Získanie detailov konkrétneho študenta
const getStudentDetails = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    try {
        const student = yield student_1.Student.findById(studentId)
            .populate({
            path: 'user',
            select: 'name email'
        })
            .exec();
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        const user = student.user;
        const studentDetails = {
            id: student._id,
            name: user.name,
            email: user.email,
            notes: student.notes,
            hasSpecialNeeds: student.hasSpecialNeeds,
            needsDescription: student.needsDescription
        };
        res.status(200).json(studentDetails);
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching student details', error });
    }
});
exports.getStudentDetails = getStudentDetails;
// Získanie skupín študenta
const getStudentGroups = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    try {
        const groups = yield group_1.Group.find({ students: studentId })
            .exec();
        const formattedGroups = groups.map(group => {
            const teacher = group.teacher;
            const user = teacher === null || teacher === void 0 ? void 0 : teacher.user;
            return {
                id: group._id,
                name: group.name,
                studentCount: group.students.length
            };
        });
        res.status(200).json(formattedGroups);
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching student groups', error });
    }
});
exports.getStudentGroups = getStudentGroups;
// Vyhľadávanie študentov
const searchStudents = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { q } = req.query;
    if (!q || typeof q !== 'string') {
        res.status(400).json({ message: 'Search query is required' });
        return;
    }
    try {
        const users = yield user_1.default.find({
            name: { $regex: q, $options: 'i' }
        }).select('_id');
        const userIds = users.map(user => user._id);
        const students = yield student_1.Student.find({ user: { $in: userIds } })
            .populate({
            path: 'user',
            select: 'name email'
        })
            .exec();
        const formattedStudents = students.map(student => {
            const user = student.user;
            return {
                id: student._id,
                name: user.name,
                email: user.email,
                notes: student.notes,
                hasSpecialNeeds: student.hasSpecialNeeds,
                needsDescription: student.needsDescription
            };
        });
        res.status(200).json(formattedStudents);
    }
    catch (error) {
        res.status(500).json({ message: 'Error searching students', error });
    }
});
exports.searchStudents = searchStudents;
const updateUserById = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    const { name, email, password, role, notes, dateOfBirth, hasSpecialNeeds, needsDescription } = req.body;
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        const user = yield user_1.default.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        if (email && email !== user.email) {
            const existingUser = yield user_1.default.findOne({ email, _id: { $ne: student.user } });
            if (existingUser) {
                res.status(400).json({ message: 'Email already in use' });
                return;
            }
            user.email = email;
        }
        if (name)
            user.name = name;
        if (password)
            user.password = yield bcryptjs_1.default.hash(password, 10);
        if (dateOfBirth)
            user.dateOfBirth = dateOfBirth;
        if (role)
            user.role = role;
        yield user.save();
        if (user.role === 'student') {
            if (notes !== undefined)
                student.notes = notes;
            if (hasSpecialNeeds !== undefined)
                student.hasSpecialNeeds = hasSpecialNeeds;
            if (needsDescription !== undefined)
                student.needsDescription = needsDescription;
            yield student.save();
        }
        res.status(200).json({
            message: 'User and student updated successfully',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                dateOfBirth: user.dateOfBirth
            },
            student: user.role === 'student' ? {
                id: student._id,
                notes: student.notes,
                hasSpecialNeeds: student.hasSpecialNeeds,
                needsDescription: student.needsDescription
            } : null
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error during updateUserById',
            error: error.message
        });
    }
});
exports.updateUserById = updateUserById;
const deleteStudent = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        const user = yield user_1.default.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        // Remove student from groups
        yield group_1.Group.updateMany({ students: user._id }, { $pull: { students: user._id } });
        // Remove student from materials
        yield material_1.default.updateMany({}, { $pull: { assignedTo: student._id } });
        // Remove progress records
        yield progress_1.default.deleteMany({ student: student._id });
        // Delete student and user
        yield student_1.Student.deleteOne({ _id: studentId });
        yield user_1.default.deleteOne({ _id: user._id });
        res.status(200).json({
            message: 'User and student deleted successfully',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                dateOfBirth: user.dateOfBirth
            },
            student: {
                id: student._id,
                notes: student.notes,
                hasSpecialNeeds: student.hasSpecialNeeds,
                needsDescription: student.needsDescription
            }
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error deleting student',
            error: error.message
        });
    }
});
exports.deleteStudent = deleteStudent;
const getStudentsNames = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        // Najdi všechny studenty
        const students = yield student_1.Student.find().exec();
        let studentsWithNames = [];
        for (const student of students) {
            const user = yield user_1.default.findById(student.user).select('name').exec();
            if (user) {
                studentsWithNames.push({
                    id: student._id,
                    name: user.name
                });
            }
        }
        studentsWithNames.sort((a, b) => a.name.localeCompare(b.name));
        res.status(200).json(studentsWithNames);
    }
    catch (error) {
        res.status(500).json({ message: 'Error getting students names', error });
    }
});
exports.getStudentsNames = getStudentsNames;
