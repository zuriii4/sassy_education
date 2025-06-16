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
exports.checkPermission = void 0;
const permission_1 = require("../models/permission");
const checkPermission = (action) => {
    return (req, res, next) => __awaiter(void 0, void 0, void 0, function* () {
        try {
            if (!req.user) {
                console.error('❌ checkPermission: User not found in request');
                res.status(401).json({ message: 'Unauthorized. No user found in request.' });
                return;
            }
            console.log(`🔍 Checking permissions for user: ${req.user._id} (Role: ${req.user.role})`);
            const permission = yield permission_1.Permission.findOne({ role: req.user.role });
            console.log(permission);
            if (!permission) {
                console.error(`❌ No permissions found for role: ${req.user.role}`);
                res.status(403).json({ message: 'Access denied. No permissions assigned to this role.' });
                return;
            }
            if (!permission.actions.includes(action)) {
                console.error(`❌ User ${req.user._id} (Role: ${req.user.role}) does not have permission for action: ${action}`);
                res.status(403).json({ message: 'Access denied. You do not have permission for this action.' });
                return;
            }
            console.log(`✅ Permission granted for user: ${req.user._id} to perform action: ${action}`);
            next();
        }
        catch (error) {
            console.error('🔥 Server error in checkPermission:', error);
            res.status(500).json({ message: 'Server error during permission check.', error });
        }
    });
};
exports.checkPermission = checkPermission;
