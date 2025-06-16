import { Request, Response } from 'express';
import { Teacher } from '../models/teacher';
import { Group } from '../models/group';
import User from '../models/user';
import { AuthRequest } from "../middleware/auth";
import bcrypt from "bcryptjs";
import Material from "../models/material";

export const registerTeacher = async (req: Request, res: Response): Promise<void> => {
    const { name, email, password, dateOfBirth, specialization = '' } = req.body;

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
            role: 'teacher',
            dateOfBirth: new Date(dateOfBirth),
            lastActive: new Date(),
        });
        await newUser.save();

        const newTeacher = new Teacher({
            user: newUser._id,
            specialization
        });
        await newTeacher.save();

        res.status(201).json({ message: `Teacher registered successfully`, user: newUser });
    } catch (error) {
        res.status(500).json({ message: 'Teacher registration failed.', error: (error as Error).message });
    }
};

export const getAllTeachers = async (req: Request, res: Response): Promise<void> => {
    try {
        const teachers = await Teacher.find()
            .populate({
                path: 'user',
                select: 'name email role'
            })
            .exec();

        const formattedTeachers = teachers
            .filter(teacher => {
                const user = teacher.user as any;
                return user.role !== 'admin';
            })
            .map(teacher => {
                const user = teacher.user as any;
                return {
                    id: teacher._id,
                    name: user.name,
                    email: user.email,
                    specialization: teacher.specialization
                };
            });

        res.status(200).json(formattedTeachers);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching teachers', error });
    }
};

export const getTeacherDetails = async (req: Request, res: Response): Promise<void> => {
    const { teacherId } = req.params;

    try {
        const teacher = await Teacher.findById(teacherId)
            .populate({
                path: 'user',
                select: 'name email'
            })
            .exec();

        if (!teacher) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }

        const user = teacher.user as any;
        const teacherDetails = {
            id: teacher._id,
            name: user.name,
            email: user.email,
            specialization: teacher.specialization
        };

        res.status(200).json(teacherDetails);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching teacher details', error });
    }
};

export const deleteTeacher = async (req: AuthRequest, res: Response): Promise<void> => {
    const { teacherId } = req.params;

    try {
        const teacher = await Teacher.findById(teacherId);
        if (!teacher) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }

        const user = await User.findById(teacher.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        const teacherGroups = await Group.find({ teacher: teacherId });
        if (teacherGroups && teacherGroups.length > 0) {
            res.status(400).json({
                message: 'Cannot delete teacher with assigned groups. Please reassign or delete the groups first.',
                groups: teacherGroups.map(group => ({ id: group._id, name: group.name }))
            });
            return;
        }

        const teacherMaterials = await Material.find({ author: teacherId });
        if (teacherMaterials && teacherMaterials.length > 0) {
            res.status(400).json({
                message: 'Cannot delete teacher with created materials. Please reassign or delete the materials first.',
                materialsCount: teacherMaterials.length
            });
            return;
        }

        await Teacher.deleteOne({ _id: teacherId });
        await User.deleteOne({ _id: user._id });

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
    } catch (error) {
        res.status(500).json({
            message: 'Error deleting teacher',
            error: (error as Error).message
        });
    }
};

