"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const database_1 = __importDefault(require("./config/database"));
const materialRoutes_1 = __importDefault(require("./routes/materialRoutes"));
const userRoutes_1 = __importDefault(require("./routes/userRoutes"));
const groupRoutes_1 = __importDefault(require("./routes/groupRoutes"));
const seed_1 = require("./config/seed");
const http = __importStar(require("http"));
const websocketService_1 = require("./utils/websocketService");
const studentRoutes_1 = __importDefault(require("./routes/studentRoutes"));
const path_1 = __importDefault(require("path"));
const activityRoutes_1 = __importDefault(require("./routes/activityRoutes"));
const notificationRoutes_1 = __importDefault(require("./routes/notificationRoutes"));
const authRoutes_1 = __importDefault(require("./routes/authRoutes"));
const teacherRoutes_1 = __importDefault(require("./routes/teacherRoutes"));
dotenv_1.default.config({ path: path_1.default.resolve(__dirname, '../.env') });
console.log(process.env.MONGO_URI);
const app = (0, express_1.default)();
const PORT = process.env.PORT;
const server = http.createServer(app);
// ⬇️ WebSocket inicializácia
(0, websocketService_1.initializeWebSocket)(server);
// Middleware
app.use((0, cors_1.default)());
app.use(express_1.default.json());
// Flutter web
const flutterBuildPath = path_1.default.join(__dirname, 'frontend');
console.log(flutterBuildPath);
app.use(express_1.default.static(flutterBuildPath));
// API routes
app.use('/api/users', userRoutes_1.default);
app.use('/api/materials', materialRoutes_1.default);
app.use('/api/groups', groupRoutes_1.default);
app.use('/api/students', studentRoutes_1.default);
app.use('/api/teachers', teacherRoutes_1.default);
app.use('/api/notifications', notificationRoutes_1.default);
app.use('/api/activity', activityRoutes_1.default);
app.use('/api/auth', authRoutes_1.default);
// Test route
app.get('/', (req, res) => {
    // res.status(200).send('API beží');
    res.sendFile(path_1.default.join(flutterBuildPath, 'index.html'));
});
app.use('/uploads', express_1.default.static(path_1.default.join(__dirname, 'public/uploads')));
(0, database_1.default)().then(() => {
    (0, seed_1.seedPermissions)();
});
server.listen(PORT, () => console.log(`🚀 Server is running on port ${PORT}`));
