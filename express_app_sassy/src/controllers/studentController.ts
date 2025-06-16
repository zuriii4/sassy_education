import { Request, Response } from 'express';
import { Student } from '../models/student';
import { Group } from '../models/group';
import User from '../models/user';
import {AuthRequest} from "../middleware/auth";
import bcrypt from "bcryptjs";
import Material from "../models/material";
import Progress from "../models/progress";


export const registerStudent = async (req: Request, res: Response): Promise<void> => {
    const { name, email, password, dateOfBirth, notes = '', hasSpecialNeeds = false, needsDescription = '' } = req.body;

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
            role : 'student',
            dateOfBirth: new Date(dateOfBirth),
            lastActive: new Date(),
        });
        await newUser.save();

        const newStudent = new Student({
            user: newUser._id,
            notes,
            hasSpecialNeeds,
            needsDescription
        });
        await newStudent.save();


        res.status(201).json({ message: `Student registered successfully`, user: newUser });
    } catch (error) {
        res.status(500).json({ message: 'Student registration failed.', error: (error as Error).message });
    }
};

export const getAllStudents = async (req: Request, res: Response): Promise<void> => {
    try {
        const students = await Student.find()
            .populate({
                path: 'user',
                select: 'name email'
            })
            .exec();

        const formattedStudents = students.map(student => {
            const user = student.user as any;
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
    } catch (error) {
        res.status(500).json({ message: 'Error fetching students', error });
    }
};

export const getStudentDetails = async (req: Request, res: Response): Promise<void> => {
    const { studentId } = req.params;

    try {
        const student = await Student.findById(studentId)
            .populate({
                path: 'user',
                select: 'name email'
            })
            .exec();

        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        const user = student.user as any;
        const studentDetails = {
            id: student._id,
            name: user.name,
            email: user.email,
            notes: student.notes,
            hasSpecialNeeds: student.hasSpecialNeeds,
            needsDescription: student.needsDescription
        };

        res.status(200).json(studentDetails);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching student details', error });
    }
};

export const getStudentGroups = async (req: Request, res: Response): Promise<void> => {
    const { studentId } = req.params;

    try {
        const groups = await Group.find({ students: studentId })
            .exec();

        const formattedGroups = groups.map(group => {
            const teacher = group.teacher as any;
            const user = teacher?.user as any;
            return {
                id: group._id,
                name: group.name,
                studentCount: group.students.length
            };
        });

        res.status(200).json(formattedGroups);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching student groups', error });
    }
};

export const searchStudents = async (req: Request, res: Response): Promise<void> => {
    const { q } = req.query;

    if (!q || typeof q !== 'string') {
        res.status(400).json({ message: 'Search query is required' });
        return;
    }

    try {
        const users = await User.find({
            name: { $regex: q, $options: 'i' }
        }).select('_id');

        const userIds = users.map(user => user._id);

        const students = await Student.find({ user: { $in: userIds } })
            .populate({
                path: 'user',
                select: 'name email'
            })
            .exec();

        const formattedStudents = students.map(student => {
            const user = student.user as any;
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
    } catch (error) {
        res.status(500).json({ message: 'Error searching students', error });
    }
};

export const updateUserById = async (req: AuthRequest, res: Response): Promise<void> => {
    const { studentId } = req.params;
    const { name, email, password, role, notes, dateOfBirth, hasSpecialNeeds, needsDescription } = req.body;

    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        const user = await User.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        if (email && email !== user.email) {
            const existingUser = await User.findOne({ email, _id: { $ne: student.user } });
            if (existingUser) {
                res.status(400).json({ message: 'Email already in use' });
                return;
            }
            user.email = email;
        }

        if (name) user.name = name;
        if (password) user.password = await bcrypt.hash(password, 10);
        if (dateOfBirth) user.dateOfBirth = dateOfBirth;
        if (role) user.role = role;

        await user.save();

        if (user.role === 'student') {
            if (notes !== undefined) student.notes = notes;
            if (hasSpecialNeeds !== undefined) student.hasSpecialNeeds = hasSpecialNeeds;
            if (needsDescription !== undefined) student.needsDescription = needsDescription;

            await student.save();
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
    } catch (error) {
        res.status(500).json({
            message: 'Error during updateUserById',
            error: (error as Error).message
        });
    }
};

export const deleteStudent = async (req: AuthRequest, res: Response): Promise<void> => {
    const { studentId } = req.params;

    try {
        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        const user = await User.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        await Group.updateMany({ students: user._id }, { $pull: { students: user._id } });

        await Material.updateMany({}, { $pull: { assignedTo: student._id } });

        await Progress.deleteMany({ student: student._id });

        await Student.deleteOne({ _id: studentId });
        await User.deleteOne({ _id: user._id });

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
    } catch (error) {
        res.status(500).json({
            message: 'Error deleting student',
            error: (error as Error).message
        });
    }
};


export const getStudentsNames = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const students = await Student.find().exec();

        let studentsWithNames = [];

        for (const student of students) {
            const user = await User.findById(student.user).select('name').exec();

            if (user) {
                studentsWithNames.push({
                    id: student._id,
                    name: user.name
                });
            }
        }

        studentsWithNames.sort((a, b) => a.name.localeCompare(b.name));

        res.status(200).json(studentsWithNames);
    } catch (error) {
        res.status(500).json({ message: 'Error getting students names', error });
    }
}