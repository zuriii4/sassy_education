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
exports.getCurrentTeacher = exports.validateToken = exports.getUser = exports.updateUser = exports.logoutUser = exports.loginUser = exports.registerUser = exports.deleteUser = exports.generateToken = void 0;
const user_1 = __importDefault(require("../models/user"));
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const dotenv_1 = __importDefault(require("dotenv"));
const teacher_1 = require("../models/teacher");
const student_1 = require("../models/student");
const group_1 = require("../models/group");
const material_1 = __importDefault(require("../models/material"));
const progress_1 = __importDefault(require("../models/progress"));
dotenv_1.default.config();
const JWT_SECRET = process.env.JWT_SECRET || 'secret-key';
const generateToken = (userId) => {
    return jsonwebtoken_1.default.sign({ id: userId }, JWT_SECRET, { expiresIn: '3h' });
};
exports.generateToken = generateToken;
const deleteUser = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        const userId = req.user._id;
        const user = yield user_1.default.findById(userId);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        // Delete Teacher or Student document
        if (user.role === 'teacher') {
            yield teacher_1.Teacher.deleteOne({ user: userId });
            // Remove teacher from any groups
            yield group_1.Group.updateMany({ teacher: userId }, { $unset: { teacher: '' } });
            // Remove materials authored by teacher
            yield material_1.default.deleteMany({ author: userId });
        }
        else if (user.role === 'student') {
            const studentDoc = yield student_1.Student.findOne({ user: userId });
            if (studentDoc) {
                // Remove student from groups
                yield group_1.Group.updateMany({ students: userId }, { $pull: { students: userId } });
                // Remove student from materials
                yield material_1.default.updateMany({}, { $pull: { assignedTo: studentDoc._id } });
                // Remove progress records
                yield progress_1.default.deleteMany({ student: studentDoc._id });
                // Remove student document
                yield student_1.Student.deleteOne({ user: userId });
            }
        }
        // Delete the user
        yield user_1.default.deleteOne({ _id: userId });
        res.status(200).json({ message: 'User deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ message: 'Error deleting user', error: error.message });
    }
});
exports.deleteUser = deleteUser;
const registerUser = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { name, email, password, role, specialization = '', dateOfBirth, notes = '', hasSpecialNeeds = false, needsDescription = '' } = req.body;
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
            role,
            dateOfBirth: new Date(dateOfBirth),
            lastActive: new Date(),
        });
        yield newUser.save();
        if (role === 'teacher') {
            const newTeacher = new teacher_1.Teacher({
                user: newUser._id,
                specialization
            });
            yield newTeacher.save();
        }
        else if (role === 'student') {
            const newStudent = new student_1.Student({
                user: newUser._id,
                notes,
                hasSpecialNeeds,
                needsDescription
            });
            yield newStudent.save();
        }
        else {
            res.status(400).json({ message: 'Invalid role. Role must be "teacher" or "student".' });
            return;
        }
        res.status(201).json({ message: `${role} registered successfully`, user: newUser });
    }
    catch (error) {
        res.status(500).json({ message: 'Registration failed.', error: error.message });
    }
});
exports.registerUser = registerUser;
const loginUser = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { email, password } = req.body;
    try {
        const user = yield user_1.default.findOne({ email });
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        const isMatched = yield user.comparePassword(password);
        if (!isMatched) {
            res.status(401).json({ message: 'Invalid credentials' });
            return;
        }
        const token = (0, exports.generateToken)(user.id);
        res.status(200).json({ message: 'User logged in', token });
    }
    catch (error) {
        res.status(500).json({ message: 'Error during login', error });
    }
});
exports.loginUser = loginUser;
const logoutUser = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    res.clearCookie('token', { httpOnly: true, secure: true, sameSite: 'strict' });
    res.status(200).json({ message: 'User logged out' });
});
exports.logoutUser = logoutUser;
const updateUser = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { name, email, password, role, specialization, notes, dateOfBirth, hasSpecialNeeds, needsDescription } = req.body;
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        const user = yield user_1.default.findById(req.user.id);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        if (email && email !== user.email) {
            const existingUser = yield user_1.default.findOne({ email });
            if (existingUser) {
                res.status(400).json({ message: 'Email already in use' });
                return;
            }
            user.email = email;
        }
        if (name)
            user.name = name;
        if (password) {
            user.password = yield bcryptjs_1.default.hash(password, 10);
        }
        if (dateOfBirth)
            user.dateOfBirth = dateOfBirth;
        yield user.save();
        if (role === 'teacher') {
            yield teacher_1.Teacher.findOneAndUpdate({ user: user._id }, { specialization }, { new: true, upsert: true });
        }
        else if (role === 'student') {
            yield student_1.Student.findOneAndUpdate({ user: user._id }, { notes, hasSpecialNeeds, needsDescription }, { new: true, upsert: true });
        }
        res.status(200).json({ message: 'User updated successfully', user });
    }
    catch (error) {
        res.status(500).json({ message: 'Error during updateUser', error: error.message });
    }
});
exports.updateUser = updateUser;
const getUser = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        const role = req.user.role === 'student'
            ? yield student_1.Student.findOne({ user: req.user._id })
            : yield teacher_1.Teacher.findOne({ user: req.user._id });
        if (!role) {
            res.status(404).json({ message: 'User role not found' });
            return;
        }
        res.status(200).json({ user: req.user, role: role });
        // console.log(role);
    }
    catch (error) {
        res.status(500).json({ message: 'Error retrieving user', error: error.message });
    }
});
exports.getUser = getUser;
const validateToken = (req, res) => {
    var _a;
    const token = (_a = req.header('Authorization')) === null || _a === void 0 ? void 0 : _a.replace('Bearer ', '');
    if (!token) {
        res.status(401).json({ valid: false, message: 'Token missing' });
        return;
    }
    try {
        jsonwebtoken_1.default.verify(token, JWT_SECRET);
        res.status(200).json({ valid: true });
    }
    catch (err) {
        res.status(401).json({ valid: false, message: 'Invalid token' });
    }
};
exports.validateToken = validateToken;
const getCurrentTeacher = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized' });
            return;
        }
        const teacher = yield teacher_1.Teacher.findOne({ user: req.user._id });
        if (!teacher) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }
        res.status(200).json({ teacher });
    }
    catch (_a) {
        res.status(404).json({ message: 'Not found' });
    }
});
exports.getCurrentTeacher = getCurrentTeacher;
