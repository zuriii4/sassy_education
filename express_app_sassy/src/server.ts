import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import connectDB from './config/database';
import materialRoutes from './routes/materialRoutes';
import userRoutes from './routes/userRoutes';
import groupRoutes from './routes/groupRoutes';
import { seedPermissions } from './config/seed';
import * as http from 'http';
import { initializeWebSocket } from './utils/websocketService';
import studentRoutes from "./routes/studentRoutes";
import path from "path";
import activityRoutes from "./routes/activityRoutes";
import notificationRoutes from "./routes/notificationRoutes";
import authRoutes from "./routes/authRoutes";
import teacherRoutes from "./routes/teacherRoutes";

dotenv.config({ path: path.resolve(__dirname, '../.env') });
const app = express();
const PORT = process.env.PORT;

const server = http.createServer(app);

// WebSocket inicializácia
initializeWebSocket(server);

// Middleware
app.use(cors());
app.use(express.json());

// Flutter web
const flutterBuildPath = path.resolve(process.cwd(), 'frontend');
// const flutterBuildPath = path.resolve(__dirname, '../frontend');
// console.log(flutterBuildPath);
app.use(express.static(flutterBuildPath));

// API routes
app.use('/api/users', userRoutes);
app.use('/api/materials', materialRoutes);
app.use('/api/groups', groupRoutes);
app.use('/api/students', studentRoutes);
app.use('/api/teachers', teacherRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/activity', activityRoutes);
app.use('/api/auth', authRoutes);

// Test route
app.get('/', (req, res) => {
    // res.status(200).send('API beží');
    res.sendFile(path.resolve(flutterBuildPath, 'index.html'));
});

app.get('/assets/.env', (req, res) => {
    res.type('text/plain').send(`API_URL=http://100.80.162.78:3000/api
WEB_SOCKET_URL=http://100.80.162.78:3000`);
});

app.use('/uploads', express.static(path.resolve(process.cwd(), 'public/uploads')));

connectDB().then(() => {
    seedPermissions();
});

server.listen(PORT, () => console.log(`Server is running on port ${PORT}`));
