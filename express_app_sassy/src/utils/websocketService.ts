import { Server as HTTPServer } from 'http';
import { Server as SocketIOServer, Socket } from 'socket.io';
import { IMaterial } from '../models/material';
import { IUser } from '../models/user';

interface ConnectedUser {
    userId: string;
    socketId: string;
    role: 'student' | 'teacher';
    lastActive: Date;
}

let io: SocketIOServer;
const connectedUsers: Map<string, ConnectedUser> = new Map();

export const initializeWebSocket = (server: HTTPServer) => {
    io = new SocketIOServer(server, {
        cors: {
            origin: "*",
            methods: ["GET", "POST"]
        }
    });

    io.on('connection', (socket: Socket) => {
        console.log(`Client connected: ${socket.id}`);

        socket.on('authenticate', (userData: { userId: string, role: 'student' | 'teacher' }) => {
            const { userId, role } = userData;

            if (userId) {
                connectedUsers.set(userId, {
                    userId,
                    socketId: socket.id,
                    role,
                    lastActive: new Date()
                });

                socket.join(`${role}-${userId}`);
                socket.join(role === 'student' ? 'students' : 'teachers');

                console.log(`User ${userId} authenticated as ${role}`);

                io.to('teachers').emit('userStatusChanged', {
                    userId,
                    status: 'online',
                    timestamp: new Date()
                });
            }
        });

        socket.on('activity', (userId: string) => {
            const user = connectedUsers.get(userId);
            if (user) {
                user.lastActive = new Date();
                connectedUsers.set(userId, user);
            }
        });

        socket.on('disconnect', () => {
            console.log(`Client disconnected: ${socket.id}`);

            for (const [userId, user] of connectedUsers.entries()) {
                if (user.socketId === socket.id) {
                    connectedUsers.delete(userId);

                    io.to('teachers').emit('userStatusChanged', {
                        userId,
                        status: 'offline',
                        timestamp: new Date()
                    });

                    break;
                }
            }
        });
    });

    console.log('WebSocket server initialized');
    return io;
};

export const notifyMaterialAssigned = async (studentId: string, material: any) => {
    const studentRoom = `student-${studentId}`;
    io.to(studentRoom).emit('materialAssigned', {
        materialId: material._id,
        title: material.title,
        timestamp: new Date()
    });

    const { createNotification } = require('../controllers/notificationController');

    const isOnline = await createNotification(
        studentId,
        'material_assigned',
        'Priradenie nového materiálu',
        `Bol vám pridelený nový materiál: ${material.title}`,
        material._id.toString()
    );

    if (isOnline) {
        console.log(`Real-time notification sent to student ${studentId} for material ${material._id}`);
    } else {
        console.log(`Offline notification stored for student ${studentId} for material ${material._id}`);
    }
};

export const notifyMaterialCompleted = async (teacherId: string, studentId: string, materialId: string, studentName: string, materialTitle: string) => {
    const teacherRoom = `teacher-${teacherId}`;
    io.to(teacherRoom).emit('materialCompleted', {
        studentId,
        studentName,
        materialId,
        materialTitle,
        timestamp: new Date()
    });

    const { createNotification } = require('../controllers/notificationController');

    const isOnline = await createNotification(
        teacherId,
        'material_completed',
        'Dokončený materiál',
        `Študent ${studentName} dokončil materiál:: ${materialTitle}`,
        materialId
    );

    if (isOnline) {
        console.log(`Real-time notification sent to teacher ${teacherId} about completion by student ${studentId}`);
    } else {
        console.log(`Offline notification stored for teacher ${teacherId} about completion by student ${studentId}`);
    }
};

export const getUserStatus = (userId: string): { isOnline: boolean, lastActive: Date | null } => {
    const user = connectedUsers.get(userId);
    if (user) {
        return { isOnline: true, lastActive: user.lastActive };
    }
    return { isOnline: false, lastActive: null };
};

export const getOnlineUsers = (role?: 'student' | 'teacher'): ConnectedUser[] => {
    const users: ConnectedUser[] = [];
    for (const user of connectedUsers.values()) {
        if (!role || user.role === role) {
            users.push(user);
        }
    }
    return users;
};

export const getIO = (): SocketIOServer => {
    if (!io) {
        throw new Error('Socket.IO has not been initialized');
    }
    return io;
};