import {Request, response, Response} from 'express';
import { Student } from '../models/student';
import User from '../models/user';
import bcrypt from 'bcryptjs';
import { generateToken } from './userController';

export const setStudentPin = async (req: Request, res: Response): Promise<void> => {
    const { studentId } = req.params;
    const { pin } = req.body;

    if (!pin || !/^\d{4,6}$/.test(pin)) {
        res.status(400).json({ message: 'PIN must be a 4 to 6-digit number' });
        return;
    }

    try {
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        student.pin = pin;

        await student.save();

        res.status(200).json({
            message: 'Student PIN set successfully',
            studentId: student._id
        });
    } catch (error) {
        res.status(500).json({
            message: 'Error setting student PIN',
            error: (error as Error).message
        });
    }
};

export const setStudentColorCode = async (req: Request, res: Response): Promise<void> => {
    const { studentId } = req.params;
    const { colorCode } = req.body;

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
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        student.colorCode = colorCode;

        student.pin = '';

        await student.save();

        res.status(200).json({
            message: 'Student color code set successfully',
            studentId: student._id
        });
    } catch (error) {
        res.status(500).json({
            message: 'Error setting student color code',
            error: (error as Error).message
        });
    }
};

export const studentPinLogin = async (req: Request, res: Response): Promise<void> => {
    const { studentId, pin } = req.body;

    // console.log(studentId);
    // console.log(pin);

    if (!studentId || !pin) {
        res.status(400).json({ message: 'Student ID and PIN are required' });
        return;
    }
    try {
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        if (!student.pin) {
            res.status(400).json({ message: 'Student does not have a PIN set' });
            return;
        }

        const isMatch = pin === student.pin;
        if (!isMatch) {
            res.status(401).json({ message: 'Invalid PIN' });
            return;
        }

        const user = await User.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        const token = generateToken(user.id);
        res.status(200).json({
            message: 'Student logged in successfully',
            token,
            studentId: student._id,
            name: user.name
        });
    } catch (error) {
        res.status(500).json({
            message: 'Error during student login',
            error: (error as Error).message
        });
    }
};

export const studentColorCodeLogin = async (req: Request, res: Response): Promise<void> => {
    const { studentId, colorCode } = req.body;

    if (!studentId || !colorCode || !Array.isArray(colorCode)) {
        res.status(400).json({ message: 'Student ID and color code array are required' });
        return;
    }

    try {
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        if (!student.colorCode || student.colorCode.length === 0) {
            res.status(400).json({ message: 'Student does not have a color code set' });
            return;
        }

        if (student.colorCode.length !== colorCode.length) {
            res.status(401).json({ message: 'Invalid color code' });
            return;
        }

        const isMatch = student.colorCode.every((color, index) => color === colorCode[index]);
        if (!isMatch) {
            res.status(401).json({ message: 'Invalid color code' });
            return;
        }

        const user = await User.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        const token = generateToken(user.id);

        res.status(200).json({
            message: 'Student logged in successfully',
            token,
            studentId: student._id,
            name: user.name
        });
    } catch (error) {
        res.status(500).json({
            message: 'Error during student login',
            error: (error as Error).message
        });
    }
};

export const generateRandomPin = async (req: Request, res: Response): Promise<void> => {
    const { studentId } = req.params;

    try {
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        const pinLength = Math.floor(Math.random() * 3) + 4;
        const pin = Array.from({ length: pinLength }, () => Math.floor(Math.random() * 10)).join('');

        student.pin = pin;

        await student.save();

        res.status(200).json({
            message: 'Random PIN generated successfully',
            studentId: student._id,
            pin
        });
    } catch (error) {
        res.status(500).json({
            message: 'Error generating random PIN',
            error: (error as Error).message
        });
    }
};

export const generateRandomColorCode = async (req: Request, res: Response): Promise<void> => {
    const { studentId } = req.params;

    try {
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        const validColors = ['red', 'green', 'blue', 'yellow', 'orange', 'purple'];
        const colorCode: string[] = [];

        const colorCodeLength = Math.floor(Math.random() * 3) + 4;
        for (let i = 0; i < colorCodeLength; i++) {
            const randomIndex = Math.floor(Math.random() * validColors.length);
            colorCode.push(validColors[randomIndex]);
        }

        student.colorCode = colorCode;

        student.pin = '';

        await student.save();

        res.status(200).json({
            message: 'Random color code generated successfully',
            studentId: student._id,
            colorCode
        });
    } catch (error) {
        res.status(500).json({
            message: 'Error generating random color code',
            error: (error as Error).message
        });
    }
};

export const checkStudentAuthMethod = async (req: Request, res: Response): Promise<void> => {
    const { studentId } = req.params;

    try {
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        const authMethod = {
            hasPin: Boolean(student.pin),
            hasColorCode: Boolean(student.colorCode && student.colorCode.length > 0)
        };

        res.status(200).json(authMethod);
    } catch (error) {
        res.status(500).json({
            message: 'Error checking student authentication method',
            error: (error as Error).message
        });
    }
};

export const getStudentAuth = async (req: Request, res: Response): Promise<void> => {
    const { studentId } = req.params;

    try {
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        res.status(200).json({
            studentId: student._id,
            pinSet: student.pin || null,
            colorCode: student.colorCode || []
        });
    } catch (error) {
        res.status(500).json({
            message: 'Error retrieving student authentication credentials',
            error: (error as Error).message
        });
    }
};