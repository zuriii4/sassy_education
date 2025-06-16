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
exports.deleteTeacher = exports.getTeacherDetails = exports.getAllTeachers = exports.registerTeacher = void 0;
const teacher_1 = require("../models/teacher");
const group_1 = require("../models/group");
const user_1 = __importDefault(require("../models/user"));
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const material_1 = __importDefault(require("../models/material"));
// Registrácia nového učiteľa
const registerTeacher = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { name, email, password, dateOfBirth, specialization = '' } = req.body;
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
            role: 'teacher',
            dateOfBirth: new Date(dateOfBirth),
            lastActive: new Date(),
        });
        yield newUser.save();
        const newTeacher = new teacher_1.Teacher({
            user: newUser._id,
            specialization
        });
        yield newTeacher.save();
        res.status(201).json({ message: `Teacher registered successfully`, user: newUser });
    }
    catch (error) {
        res.status(500).json({ message: 'Teacher registration failed.', error: error.message });
    }
});
exports.registerTeacher = registerTeacher;
// Získanie všetkých učiteľov
const getAllTeachers = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const teachers = yield teacher_1.Teacher.find()
            .populate({
            path: 'user',
            select: 'name email role'
        })
            .exec();
        const formattedTeachers = teachers
            .filter(teacher => {
            const user = teacher.user;
            return user.role !== 'admin';
        })
            .map(teacher => {
            const user = teacher.user;
            return {
                id: teacher._id,
                name: user.name,
                email: user.email,
                specialization: teacher.specialization
            };
        });
        res.status(200).json(formattedTeachers);
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching teachers', error });
    }
});
exports.getAllTeachers = getAllTeachers;
// Získanie detailov konkrétneho učiteľa
const getTeacherDetails = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { teacherId } = req.params;
    try {
        const teacher = yield teacher_1.Teacher.findById(teacherId)
            .populate({
            path: 'user',
            select: 'name email'
        })
            .exec();
        if (!teacher) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }
        const user = teacher.user;
        const teacherDetails = {
            id: teacher._id,
            name: user.name,
            email: user.email,
            specialization: teacher.specialization
        };
        res.status(200).json(teacherDetails);
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching teacher details', error });
    }
});
exports.getTeacherDetails = getTeacherDetails;
// Vymazanie učiteľa
const deleteTeacher = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { teacherId } = req.params;
    try {
        const teacher = yield teacher_1.Teacher.findById(teacherId);
        if (!teacher) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }
        const user = yield user_1.default.findById(teacher.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        // Kontrola či učiteľ nemá priradené skupiny
        const teacherGroups = yield group_1.Group.find({ teacher: teacherId });
        if (teacherGroups && teacherGroups.length > 0) {
            res.status(400).json({
                message: 'Cannot delete teacher with assigned groups. Please reassign or delete the groups first.',
                groups: teacherGroups.map(group => ({ id: group._id, name: group.name }))
            });
            return;
        }
        // Kontrola či učiteľ nemá vytvorené materiály
        const teacherMaterials = yield material_1.default.find({ author: teacherId });
        if (teacherMaterials && teacherMaterials.length > 0) {
            res.status(400).json({
                message: 'Cannot delete teacher with created materials. Please reassign or delete the materials first.',
                materialsCount: teacherMaterials.length
            });
            return;
        }
        // Vymazanie učiteľa a užívateľa
        yield teacher_1.Teacher.deleteOne({ _id: teacherId });
        yield user_1.default.deleteOne({ _id: user._id });
        res.status(200).json({
            message: 'User and teacher deleted successfully',
            user: {
                id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                dateOfBirth: user.dateOfBirth
            },
            teacher: {
                id: teacher._id,
                specialization: teacher.specialization
            }
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error deleting teacher',
            error: error.message
        });
    }
});
exports.deleteTeacher = deleteTeacher;
