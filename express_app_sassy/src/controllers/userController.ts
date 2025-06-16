import { Request, Response } from 'express';
import User, {IUser} from '../models/user';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';
import {Teacher} from "../models/teacher";
import {Student} from "../models/student";
import {AuthRequest} from "../middleware/auth";
import { Group } from '../models/group';
import Material from '../models/material';
import Progress from '../models/progress';
dotenv.config();

const JWT_SECRET = process.env.JWT_SECRET as string || 'secret-key';

export const generateToken = (userId: string) => {
    return jwt.sign({ id: userId }, JWT_SECRET, { expiresIn: '3h' });
};

export const deleteUser = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        const userId = req.user._id;
        const user = await User.findById(userId);

        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        if (user.role === 'teacher') {
            await Teacher.deleteOne({ user: userId });

            await Group.updateMany({ teacher: userId }, { $unset: { teacher: '' } });

            await Material.deleteMany({ author: userId });
        } else if (user.role === 'student') {
            const studentDoc = await Student.findOne({ user: userId });

            if (studentDoc) {
                await Group.updateMany({ students: userId }, { $pull: { students: userId } });

                await Material.updateMany({}, { $pull: { assignedTo: studentDoc._id } });

                await Progress.deleteMany({ student: studentDoc._id });

                await Student.deleteOne({ user: userId });
            }
        }

        await User.deleteOne({ _id: userId });

        res.status(200).json({ message: 'User deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting user', error: (error as Error).message });
    }
};

export const registerUser = async (req: Request, res: Response): Promise<void> => {
    const { name, email, password, role, specialization = '', dateOfBirth, notes = '', hasSpecialNeeds = false, needsDescription = '' } = req.body;

    try {
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            res.status(400).json({ message: 'User already exists.' });
            return;
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const newUser = new User({
            name,
            email,
            password: hashedPassword,
            role,
            dateOfBirth: new Date(dateOfBirth),
            lastActive: new Date(),
        });
        await newUser.save();

        if (role === 'teacher') {
            const newTeacher = new Teacher({
                user: newUser._id,
                specialization
            });
            await newTeacher.save();
        } else if (role === 'student') {
        const newStudent = new Student({
            user: newUser._id,
            notes,
            hasSpecialNeeds,
            needsDescription
        });
            await newStudent.save();
        } else {
            res.status(400).json({ message: 'Invalid role. Role must be "teacher" or "student".' });
            return;
        }

        res.status(201).json({ message: `${role} registered successfully`, user: newUser });
    } catch (error) {
        res.status(500).json({ message: 'Registration failed.', error: (error as Error).message });
    }
};


export const loginUser = async (req: Request, res: Response): Promise<void> => {
    const { email, password } = req.body;

    try {
        const user = await User.findOne({ email }) as IUser | null;

        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        const isMatched = await user.comparePassword(password);
        if (!isMatched) {
            res.status(401).json({ message: 'Invalid credentials' });
            return;
        }

        const token = generateToken(user.id);
        res.status(200).json({ message: 'User logged in', token });
    } catch (error) {
        res.status(500).json({ message: 'Error during login', error });
    }
};

export const logoutUser = async (req: Request, res: Response): Promise<void> => {
    res.clearCookie('token', { httpOnly: true, secure: true, sameSite: 'strict' });
    res.status(200).json({ message: 'User logged out' });
};

export const updateUser = async (req: AuthRequest, res: Response): Promise<void> => {
    const { name, email, password, role, specialization, notes, dateOfBirth, hasSpecialNeeds, needsDescription } = req.body;

    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        const user = await User.findById(req.user.id);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        if (email && email !== user.email) {
            const existingUser = await User.findOne({ email });
            if (existingUser) {
                res.status(400).json({ message: 'Email already in use' });
                return;
            }
            user.email = email;
        }

        if (name) user.name = name;
        if (password) {
            user.password = await bcrypt.hash(password, 10);
        }
        if (dateOfBirth) user.dateOfBirth = dateOfBirth;

        await user.save();

        if (role === 'teacher') {
            await Teacher.findOneAndUpdate({ user: user._id }, { specialization }, { new: true, upsert: true });
        } else if (role === 'student') {
            await Student.findOneAndUpdate({ user: user._id }, { notes, hasSpecialNeeds, needsDescription }, { new: true, upsert: true });
        }

        res.status(200).json({ message: 'User updated successfully', user });
    } catch (error) {
        res.status(500).json({ message: 'Error during updateUser', error: (error as Error).message });
    }
};

export const getUser = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        const role = req.user.role === 'student'
            ? await Student.findOne({ user: req.user._id })
            : await Teacher.findOne({ user: req.user._id });

        if (!role) {
            res.status(404).json({ message: 'User role not found' });
            return;
        }

        res.status(200).json({ user: req.user, role: role });

        // console.log(role);
    } catch (error) {
        res.status(500).json({ message: 'Error retrieving user', error: (error as Error).message });
    }
};

export const validateToken = (req: Request, res: Response): void => {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
        res.status(401).json({ valid: false, message: 'Token missing' });
        return;
    }

    try {
        jwt.verify(token, JWT_SECRET);
        res.status(200).json({ valid: true });
    } catch (err) {
        res.status(401).json({ valid: false, message: 'Invalid token' });
    }
};

export const getCurrentTeacher = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized' });
            return;
        }

        const teacher = await Teacher.findOne({ user: req.user._id });

        if (!teacher) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }

        res.status(200).json({ teacher });
    } catch {
        res.status(404).json({ message: 'Not found' });
    }
};

