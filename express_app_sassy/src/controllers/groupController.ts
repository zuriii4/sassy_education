import { Request, Response } from 'express';
import { Group } from '../models/group';
import User from "../models/user";
import {Teacher} from "../models/teacher";
import {Student} from "../models/student";
import mongoose from "mongoose";

export const getGroups = async (req: Request, res: Response): Promise<void> => {
    try {
        const groups = await Group.find();
        const groupDetails = await Promise.all(groups.map(async group => {
            const teacher = await Teacher.findById(group.teacher);
            const teacherUser = teacher ? await User.findById(teacher.user) : null;
            const teacherInfo = teacherUser ? {
                id: teacherUser._id,
                name: teacherUser.name
            } : { id: group.teacher, name: 'Unknown Teacher' };

            const studentModels = await Student.find({
                _id: { $in: group.students }
            });

            const studentUsers = await User.find({
                _id: { $in: studentModels.map(s => s.user) }
            }).select('_id name');

            const formattedStudents = studentModels.map(student => {
                const user = studentUsers.find((u: any) => u._id.equals(student.user));
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
        }));

        res.status(200).json(groupDetails);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching groups', error });
    }
}

export const getGroup = async (req: Request, res: Response): Promise<void> => {
    const { groupId } = req.params;

    try {
        const group = await Group.findById(groupId);

        if (!group) {
            res.status(404).json({ message: 'Group not found' });
            return;
        }

        const teacherUser = await Teacher.findById(group.teacher);
        // console.log(teacherUser);
        if (!teacherUser) {
            res.status(404).json({ message: 'teacher not found' });
            return;
        }
        const user = await User.findById(teacherUser.user);
        const teacherDetails = user ? {
            id: user._id,
            name: user.name
        } : { id: group.teacher, name: 'Unknown Teacher' };

        const studentModels = await Student.find({
            _id: { $in: group.students }
        });

        const studentUsers = await User.find({
            _id: { $in: studentModels.map(s => s.user) }
        }).select('_id name');

        const formattedStudents = studentModels.map(student => {
            const user = studentUsers.find((u: any) => u._id.equals(student.user));
            return {
                id: student._id,
                name: user?.name || 'Neznámy študent'
            };
        });

        res.status(200).json({
            id: group._id,
            name: group.name,
            teacher: teacherDetails,
            students: formattedStudents
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching group info', error });
    }
};

export const createGroup = async (req: Request, res: Response): Promise<void> => {
    const { name, teacherId, studentIds } = req.body;

    try {
        const teacher = await Teacher.findById(teacherId);
        if (!teacher) {
            res.status(400).json({ message: 'Teacher not found or invalid role' });
            return;
        }

        const students = await Student.find({ _id: { $in: studentIds }});
        if (students.length !== studentIds.length) {
            res.status(400).json({ message: 'One or more students not found' });
            return;
        }

        const newGroup = new Group({ name, teacher: teacherId, students: studentIds });
        await newGroup.save();

        res.status(201).json({ message: 'Group created successfully', group: newGroup });
    } catch (error) {
        res.status(500).json({ message: 'Error creating group', error });
    }
};

export const addStudentToGroup = async (req: Request, res: Response): Promise<void> => {
    const { groupId, studentId } = req.body;

    try {
        const group = await Group.findById(groupId);
        if (!group) {
            res.status(404).json({ message: 'Group not found' });
            return;
        }

        const student = await Student.findById(studentId);
        if (!student) {
            res.status(400).json({ message: 'Student not found or invalid role' });
            return;
        }

        if (!group.students.includes(studentId)) {
            group.students.push(studentId);
            await group.save();
        }

        res.status(200).json({ message: 'Student added to group', group });
    } catch (error) {
        res.status(500).json({ message: 'Error adding student', error });
    }
};

export const deleteGroup = async (req: Request, res: Response): Promise<void> => {
    const { groupId } = req.params;

    try {
        const deletedGroup = await Group.findByIdAndDelete(groupId);
        if (!deletedGroup) {
            res.status(404).json({ message: 'Group not found' });
            return;
        }

        res.status(200).json({ message: 'Group deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error deleting group', error });
    }
};

export const getStudentGroups = async (studentId: string): Promise<string[]> => {
    const groups = await Group.find({ members: studentId });
    return groups.map(group => group._id.toString());
};

export const removeStudentFromGroup = async (req: Request, res: Response): Promise<void> => {
    const { groupId, studentId } = req.params;

    try {
        const group = await Group.findById(groupId);

        if (!group) {
            res.status(404).json({ message: 'Group not found' });
            return;
        }

        if (!group.students.includes(new mongoose.Types.ObjectId(studentId))) {
            res.status(400).json({ message: 'Student is not a member of this group' });
            return;
        }

        group.students = group.students.filter(
            student => student.toString() !== studentId
        );

        await group.save();

        res.status(200).json({
            message: 'Student successfully removed from group',
            group: {
                id: group._id,
                name: group.name,
                studentCount: group.students.length
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Error removing student from group', error });
    }
};