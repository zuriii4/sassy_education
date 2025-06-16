"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getImage = exports.uploadImage = void 0;
const multer_1 = __importDefault(require("multer"));
const path_1 = __importDefault(require("path"));
const fs_1 = __importDefault(require("fs"));
// Configure storage
const storage = multer_1.default.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = path_1.default.join(__dirname, '../public/uploads');
        // console.log(uploadDir);
        // Ensure directory exists
        if (!fs_1.default.existsSync(uploadDir)) {
            fs_1.default.mkdirSync(uploadDir, { recursive: true });
        }
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        // Create unique filename with original extension
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path_1.default.extname(file.originalname);
        cb(null, uniqueSuffix + ext);
    }
});
// File filter - only accept images
const fileFilter = (req, file, cb) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    }
    else {
        cb(new Error('Invalid file type. Only JPEG, PNG, GIF and WEBP images are allowed.'));
    }
};
// Configure upload middleware
const upload = (0, multer_1.default)({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024 // 5MB size limit
    }
});
// Upload handler
const uploadImage = (req, res) => {
    const uploadSingle = upload.single('image');
    uploadSingle(req, res, (err) => {
        if (err) {
            if (err instanceof multer_1.default.MulterError) {
                if (err.code === 'LIMIT_FILE_SIZE') {
                    res.status(400).json({ message: 'File size too large. Max 5MB allowed.' });
                    return;
                }
            }
            res.status(400).json({ message: err.message });
            return;
        }
        const fileReq = req;
        if (!fileReq.file) {
            res.status(400).json({ message: 'No file uploaded' });
            return;
        }
        // Create URL path to the uploaded file
        const filePath = `/uploads/${fileReq.file.filename}`;
        res.status(200).json({
            message: 'File uploaded successfully',
            filePath
        });
    });
};
exports.uploadImage = uploadImage;
const getImage = (req, res) => {
    const { path: filePath } = req.body;
    if (!filePath) {
        res.status(400).json({ message: 'File path is required in request body.' });
        return;
    }
    // Extrahuj len názov súboru, aby sa predišlo bezpečnostným problémom
    const filename = path_1.default.basename(filePath);
    const imagePath = path_1.default.join(__dirname, '../public/uploads', filename);
    if (!fs_1.default.existsSync(imagePath)) {
        res.status(404).json({ message: 'File not found' });
        return;
    }
    // console.log(imagePath);
    res.sendFile(imagePath);
};
exports.getImage = getImage;
