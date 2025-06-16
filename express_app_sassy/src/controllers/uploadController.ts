import { Response, Request } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { AuthRequest } from '../middleware/auth';


interface FileRequest extends AuthRequest {
    file?: Express.Multer.File;
}

const storage = multer.diskStorage({
    destination: (req: Express.Request, file: Express.Multer.File, cb: (error: Error | null, destination: string) => void) => {
        const uploadDir = path.resolve(process.cwd(), 'public/uploads');
        // console.log(uploadDir);

        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }

        cb(null, uploadDir);
    },
    filename: (req: Express.Request, file: Express.Multer.File, cb: (error: Error | null, filename: string) => void) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        const ext = path.extname(file.originalname);
        cb(null, uniqueSuffix + ext);
    }
});

const fileFilter = (
    req: Express.Request,
    file: Express.Multer.File,
    cb: multer.FileFilterCallback
) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];

    if (allowedTypes.includes(file.mimetype)) {
        cb(null, true);
    } else {
        cb(new Error('Invalid file type. Only JPEG, PNG, GIF and WEBP images are allowed.'));
    }
};

const upload = multer({
    storage,
    fileFilter,
    limits: {
        fileSize: 5 * 1024 * 1024
    }
});

export const uploadImage = (req: AuthRequest, res: Response) => {
    const uploadSingle = upload.single('image');

    uploadSingle(req as Request, res, (err: any) => {
        if (err) {
            if (err instanceof multer.MulterError) {
                if (err.code === 'LIMIT_FILE_SIZE') {
                    res.status(400).json({ message: 'File size too large. Max 5MB allowed.' });
                    return;
                }
            }
            res.status(400).json({ message: err.message });
            return;
        }

        const fileReq = req as FileRequest;

        if (!fileReq.file) {
            res.status(400).json({ message: 'No file uploaded' });
            return;
        }

        const filePath = `/uploads/${fileReq.file.filename}`;

        res.status(200).json({
            message: 'File uploaded successfully',
            filePath
        });
    });
};

export const getImage = (req: AuthRequest, res: Response) => {
    const { path: filePath } = req.body;

    if (!filePath) {
        res.status(400).json({ message: 'File path is required in request body.' });
        return;
    }

    const filename = path.basename(filePath);
    const imagePath = path.resolve(process.cwd(), 'public/uploads', filename);

    if (!fs.existsSync(imagePath)) {
        res.status(404).json({ message: 'File not found' });
        console.log(imagePath);
        console.log(filePath);
        console.log('File not found');
        return;
    }
    // console.log(imagePath);
    res.sendFile(imagePath);
};
