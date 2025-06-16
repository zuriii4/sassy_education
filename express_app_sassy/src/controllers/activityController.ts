import { Request, Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import { getUserStatus, getOnlineUsers } from '../utils/websocketService';
import User from '../models/user';
import { Student } from '../models/student';
import { Teacher } from '../models/teacher';

export const getUserOnlineStatus = async (req: Request, res: Response): Promise<void> => {
    try {
        const { userId } = req.params;

        if (!userId) {
            res.status(400).json({ message: 'User ID is required' });
            return;
        }

        const student = await Student.findById(userId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        const user = await User.findById(student.user);
        if (!user) {
            res.status(404).json({ message: 'User not found' });
            return;
        }

        const status = getUserStatus(userId);

        res.status(200).json({
            userId,
            name: user.name,
            isOnline: status.isOnline,
            lastActive: status.lastActive
        });
    } catch (error) {
        res.status(500).json({ message: 'Error fetching user status', error });
    }
};

export const getOnlineStudents = async (req: Request, res: Response): Promise<void> => {
    try {
        // if (!req.user || req.user.role !== 'teacher') {
        //     res.status(403).json({ message: 'Unauthorized. Only teachers can access this resource.' });
        //     return;
        // }
        // console.log(req.user._id);
        //
        // const teacher = await Teacher.findOne({ user: req.user._id });
        // if (!teacher) {
        //     res.status(404).json({ message: 'Teacher not found' });
        //     return;
        // }

        const onlineUsers = getOnlineUsers('student');

        const onlineStudentsDetails = await Promise.all(
            onlineUsers.map(async (user) => {
                const student = await Student.findById(user.userId);
                const userDetails = student ? await User.findById(student.user).select('name email') : null;

                return {
                    userId: student?.user || user.userId,
                    studentId: student?._id || null,
                    name: userDetails?.name || 'Unknown',
                    lastActive: user.lastActive
                };
            })
        );

        res.status(200).json(onlineStudentsDetails);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching online students', error });
    }
};

export const getOfflineStudents = async (req: Request, res: Response): Promise<void> => {
    try {
        // if (!req.user || req.user.role !== 'teacher') {
        //     res.status(403).json({ message: 'Unauthorized. Only teachers can access this resource.' });
        //     return;
        // }
        //
        // const teacher = await Teacher.findOne({ user: req.user._id });
        // if (!teacher) {
        //     res.status(404).json({ message: 'Teacher not found' });
        //     return;
        // }

        const onlineUserIds = getOnlineUsers('student').map(user => user.userId.toString());

        const offlineUsers = await User.find({
            role: 'student',
            _id: { $nin: onlineUserIds }
        }).select('_id name email lastActive');

        const offlineStudentsDetails = await Promise.all(
            offlineUsers.map(async (user) => {
                const student = await Student.findOne({ user: user._id });

                return {
                    userId: user._id,
                    studentId: student?._id || null,
                    name: user.name || 'Unknown',
                    lastActive: user.lastActive || null
                };
            })
        );

        res.status(200).json(offlineStudentsDetails);
    } catch (error) {
        res.status(500).json({
            message: 'Error fetching offline students',
            error: (error as Error).message
        });
    }
};

export const recordUserActivity = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        // console.log("recording user activity:");
        // console.log(req.user);
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        await User.findByIdAndUpdate(req.user._id, {
            lastActive: new Date(),
        });

        res.status(200).json({ message: 'Activity recorded successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Error recording activity', error });
    }
};