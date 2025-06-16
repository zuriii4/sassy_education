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
Object.defineProperty(exports, "__esModule", { value: true });
exports.getIO = exports.getOnlineUsers = exports.getUserStatus = exports.notifyMaterialCompleted = exports.notifyMaterialAssigned = exports.initializeWebSocket = void 0;
const socket_io_1 = require("socket.io");
// Global variables to track users
let io;
const connectedUsers = new Map();
const initializeWebSocket = (server) => {
    io = new socket_io_1.Server(server, {
        cors: {
            origin: "*", // In production, specify your frontend URL
            methods: ["GET", "POST"]
        }
    });
    io.on('connection', (socket) => {
        console.log(`Client connected: ${socket.id}`);
        // Handle user authentication
        socket.on('authenticate', (userData) => {
            const { userId, role } = userData;
            if (userId) {
                // Store user connection info
                connectedUsers.set(userId, {
                    userId,
                    socketId: socket.id,
                    role,
                    lastActive: new Date()
                });
                // Join room based on role and user ID
                socket.join(`${role}-${userId}`);
                socket.join(role === 'student' ? 'students' : 'teachers');
                console.log(`User ${userId} authenticated as ${role}`);
                // Notify admin or teachers about user status change
                io.to('teachers').emit('userStatusChanged', {
                    userId,
                    status: 'online',
                    timestamp: new Date()
                });
            }
        });
        // Update lastActive timestamp when user performs an action
        socket.on('activity', (userId) => {
            const user = connectedUsers.get(userId);
            if (user) {
                user.lastActive = new Date();
                connectedUsers.set(userId, user);
            }
        });
        // Handle disconnection
        socket.on('disconnect', () => {
            console.log(`Client disconnected: ${socket.id}`);
            // Find and remove the disconnected user
            for (const [userId, user] of connectedUsers.entries()) {
                if (user.socketId === socket.id) {
                    connectedUsers.delete(userId);
                    // Notify admin or teachers about user status change
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
exports.initializeWebSocket = initializeWebSocket;
// Function to send material assignment notification
const notifyMaterialAssigned = (studentId, material) => __awaiter(void 0, void 0, void 0, function* () {
    const studentRoom = `student-${studentId}`;
    io.to(studentRoom).emit('materialAssigned', {
        materialId: material._id,
        title: material.title,
        timestamp: new Date()
    });
    // Import here to avoid circular dependency
    const { createNotification } = require('../controllers/notificationController');
    // Store notification for offline students
    const isOnline = yield createNotification(studentId, 'material_assigned', 'Priradenie nového materiálu', `Bol vám pridelený nový materiál: ${material.title}`, material._id.toString());
    if (isOnline) {
        console.log(`Real-time notification sent to student ${studentId} for material ${material._id}`);
    }
    else {
        console.log(`Offline notification stored for student ${studentId} for material ${material._id}`);
    }
});
exports.notifyMaterialAssigned = notifyMaterialAssigned;
// Function to notify teacher when a student completes a material
const notifyMaterialCompleted = (teacherId, studentId, materialId, studentName, materialTitle) => __awaiter(void 0, void 0, void 0, function* () {
    const teacherRoom = `teacher-${teacherId}`;
    io.to(teacherRoom).emit('materialCompleted', {
        studentId,
        studentName,
        materialId,
        materialTitle,
        timestamp: new Date()
    });
    // Import here to avoid circular dependency
    const { createNotification } = require('../controllers/notificationController');
    // Store notification for offline teachers
    const isOnline = yield createNotification(teacherId, 'material_completed', 'Dokončený materiál', `Študent ${studentName} dokončil materiál:: ${materialTitle}`, materialId);
    if (isOnline) {
        console.log(`Real-time notification sent to teacher ${teacherId} about completion by student ${studentId}`);
    }
    else {
        console.log(`Offline notification stored for teacher ${teacherId} about completion by student ${studentId}`);
    }
});
exports.notifyMaterialCompleted = notifyMaterialCompleted;
// Get user's online status
const getUserStatus = (userId) => {
    const user = connectedUsers.get(userId);
    if (user) {
        return { isOnline: true, lastActive: user.lastActive };
    }
    return { isOnline: false, lastActive: null };
};
exports.getUserStatus = getUserStatus;
// Get all online users
const getOnlineUsers = (role) => {
    const users = [];
    for (const user of connectedUsers.values()) {
        if (!role || user.role === role) {
            users.push(user);
        }
    }
    return users;
};
exports.getOnlineUsers = getOnlineUsers;
// Get Socket.IO instance
const getIO = () => {
    if (!io) {
        throw new Error('Socket.IO has not been initialized');
    }
    return io;
};
exports.getIO = getIO;
