import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import User, { IUser } from '../models/user';
import dotenv from 'dotenv';
import path from "path";
dotenv.config({ path: path.resolve(__dirname, '../../.env') });

const JWT_SECRET = process.env.JWT_SECRET as string;

export interface AuthRequest extends Request {
    user?: IUser;
}

export const authenticate = async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
    const token = req.header('Authorization')?.replace('Bearer ', '');
    // console.log("token");
    // console.log(token);
    if (!token) {
        res.status(401).json({ message: 'Access denied. Token missing.' });
        return;
    }

    try {
        const decoded = jwt.verify(token, JWT_SECRET) as { id: string };
        const user = await User.findById(decoded.id);

        if (!user) {
            res.status(404).json({ message: 'User not found.' });
            return;
        }

        req.user = user;
        // console.log("req.user");
        // console.log(req.user);
        next();
    } catch (error) {
        res.status(401).json({ message: 'Invalid token.' });
    }
};