import { Response, NextFunction } from 'express';
import { AuthRequest } from "./auth";
import { Permission } from "../models/permission";

export const checkPermission = (action: string) => {
    return async (req: AuthRequest, res: Response, next: NextFunction): Promise<void> => {
        try {
            if (!req.user) {
                console.error('checkPermission: User not found in request');
                res.status(401).json({ message: 'Unauthorized. No user found in request.' });
                return;
            }

            console.log(`Checking permissions for user: ${req.user._id} (Role: ${req.user.role})`);

            const permission = await Permission.findOne({ role: req.user.role });
            console.log(permission);

            if (!permission) {
                console.error(`No permissions found for role: ${req.user.role}`);
                res.status(403).json({ message: 'Access denied. No permissions assigned to this role.' });
                return;
            }

            if (!permission.actions.includes(action)) {
                console.error(`User ${req.user._id} (Role: ${req.user.role}) does not have permission for action: ${action}`);
                res.status(403).json({ message: 'Access denied. You do not have permission for this action.' });
                return;
            }

            console.log(`Permission granted for user: ${req.user._id} to perform action: ${action}`);
            next();
        } catch (error) {
            console.error('Server error in checkPermission:', error);
            res.status(500).json({ message: 'Server error during permission check.', error });
        }
    };
};