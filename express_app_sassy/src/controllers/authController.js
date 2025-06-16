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
exports.getStudentAuth = exports.checkStudentAuthMethod = exports.generateRandomColorCode = exports.generateRandomPin = exports.studentColorCodeLogin = exports.studentPinLogin = exports.setStudentColorCode = exports.setStudentPin = void 0;
const student_1 = require("../models/student");
const user_1 = __importDefault(require("../models/user"));
const userController_1 = require("./userController");
// Set or update a student's PIN
const setStudentPin = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    const { pin } = req.body;
    // Validate PIN format (4-digit number)
    if (!pin || !/^\d{4,6}$/.test(pin)) {
        res.status(400).json({ message: 'PIN must be a 4 to 6-digit number' });
        return;
    }
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        // Store the PIN directly
        student.pin = pin;
        yield student.save();
        res.status(200).json({
            message: 'Student PIN set successfully',
            studentId: student._id
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error setting student PIN',
            error: error.message
        });
    }
});
exports.setStudentPin = setStudentPin;
// Set or update a student's color code
const setStudentColorCode = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    const { colorCode } = req.body;
    // Validate color code format (array of 4 to 6 colors)
    const validColors = ['red', 'green', 'blue', 'yellow', 'orange', 'purple'];
    if (!colorCode || !Array.isArray(colorCode) || colorCode.length < 4 || colorCode.length > 6) {
        res.status(400).json({ message: 'Color code must be an array of 4 to 6 colors' });
        return;
    }
    for (const color of colorCode) {
        if (!validColors.includes(color)) {
            res.status(400).json({
                message: `Invalid color: ${color}. Valid colors are: ${validColors.join(', ')}`
            });
            return;
        }
    }
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        // Store the color code
        student.colorCode = colorCode;
        // Clear PIN if color code is set
        student.pin = '';
        yield student.save();
        res.status(200).json({
            message: 'Student color code set successfully',
            studentId: student._id
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error setting student color code',
            error: error.message
        });
    }
});
exports.setStudentColorCode = setStudentColorCode;
// Student login with PIN
const studentPinLogin = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId, pin } = req.body;
    // console.log(studentId);
    // console.log(pin);
    if (!studentId || !pin) {
        res.status(400).json({ message: 'Student ID and PIN are required' });
        return;
    }
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        // Check if the student has a PIN set
        if (!student.pin) {
            res.status(400).json({ message: 'Student does not have a PIN set' });
            return;
        }
        // Compare the provided PIN with the stored PIN
        const isMatch = pin === student.pin;
        if (!isMatch) {
            res.status(401).json({ message: 'Invalid PIN' });
            return;
        }
        // Get the user associated with the student
        const user = yield user_1.default.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        // Generate a token for the student
        const token = (0, userController_1.generateToken)(user.id);
        res.status(200).json({
            message: 'Student logged in successfully',
            token,
            studentId: student._id,
            name: user.name
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error during student login',
            error: error.message
        });
    }
});
exports.studentPinLogin = studentPinLogin;
// Student login with color code
const studentColorCodeLogin = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId, colorCode } = req.body;
    if (!studentId || !colorCode || !Array.isArray(colorCode)) {
        res.status(400).json({ message: 'Student ID and color code array are required' });
        return;
    }
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        // Check if the student has a color code set
        if (!student.colorCode || student.colorCode.length === 0) {
            res.status(400).json({ message: 'Student does not have a color code set' });
            return;
        }
        // Compare the provided color code with the stored one
        if (student.colorCode.length !== colorCode.length) {
            res.status(401).json({ message: 'Invalid color code' });
            return;
        }
        const isMatch = student.colorCode.every((color, index) => color === colorCode[index]);
        if (!isMatch) {
            res.status(401).json({ message: 'Invalid color code' });
            return;
        }
        // Get the user associated with the student
        const user = yield user_1.default.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }
        // Generate a token for the student
        const token = (0, userController_1.generateToken)(user.id);
        res.status(200).json({
            message: 'Student logged in successfully',
            token,
            studentId: student._id,
            name: user.name
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error during student login',
            error: error.message
        });
    }
});
exports.studentColorCodeLogin = studentColorCodeLogin;
// Generate a random PIN for a student
const generateRandomPin = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        // Generate a random 4 to 6-digit PIN
        const pinLength = Math.floor(Math.random() * 3) + 4; // random number between 4 and 6
        const pin = Array.from({ length: pinLength }, () => Math.floor(Math.random() * 10)).join('');
        // Store the PIN directly
        student.pin = pin;
        yield student.save();
        res.status(200).json({
            message: 'Random PIN generated successfully',
            studentId: student._id,
            pin // Return the unhashed PIN so the teacher can share it with the student
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error generating random PIN',
            error: error.message
        });
    }
});
exports.generateRandomPin = generateRandomPin;
// Generate a random color code for a student
const generateRandomColorCode = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        const validColors = ['red', 'green', 'blue', 'yellow', 'orange', 'purple'];
        const colorCode = [];
        // Generate a random sequence of 4 to 6 colors
        const colorCodeLength = Math.floor(Math.random() * 3) + 4; // random number between 4 and 6
        for (let i = 0; i < colorCodeLength; i++) {
            const randomIndex = Math.floor(Math.random() * validColors.length);
            colorCode.push(validColors[randomIndex]);
        }
        // Store the color code
        student.colorCode = colorCode;
        // Clear PIN if color code is set
        student.pin = '';
        yield student.save();
        res.status(200).json({
            message: 'Random color code generated successfully',
            studentId: student._id,
            colorCode
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error generating random color code',
            error: error.message
        });
    }
});
exports.generateRandomColorCode = generateRandomColorCode;
// Route to check if student has authentication method set
const checkStudentAuthMethod = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        const authMethod = {
            hasPin: Boolean(student.pin),
            hasColorCode: Boolean(student.colorCode && student.colorCode.length > 0)
        };
        res.status(200).json(authMethod);
    }
    catch (error) {
        res.status(500).json({
            message: 'Error checking student authentication method',
            error: error.message
        });
    }
});
exports.checkStudentAuthMethod = checkStudentAuthMethod;
// Get student's authentication credentials (PIN and color code)
const getStudentAuth = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    const { studentId } = req.params;
    try {
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        res.status(200).json({
            studentId: student._id,
            pinSet: student.pin || null,
            colorCode: student.colorCode || []
        });
    }
    catch (error) {
        res.status(500).json({
            message: 'Error retrieving student authentication credentials',
            error: error.message
        });
    }
});
exports.getStudentAuth = getStudentAuth;
