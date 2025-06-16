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
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.seedPermissions = void 0;
const permission_1 = require("../models/permission");
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const user_1 = __importDefault(require("../models/user"));
const teacher_1 = require("../models/teacher");
const material_1 = __importDefault(require("../models/material"));
const defaultPermissions = [
    { role: 'admin', actions: ['view_material', 'assign_task', 'view_progress', 'manage_groups', 'manage_materials', 'manage_students', 'manage_teachers'] },
    { role: 'teacher', actions: ['view_material', 'assign_task', 'view_progress', 'manage_groups', 'manage_materials', 'manage_students'] },
    { role: 'student', actions: ['view_material', 'complete_task'] }
];
const sampleMaterials = [
    {
        title: 'Puzzle obrázok',
        description: 'Puzzle so 4x4 obrázkom',
        type: 'puzzle',
        content: {
            image: '/uploads/Eiffel.jpg',
            grid: { columns: 4, rows: 4 }
        }
    },
    {
        title: 'Kvíz o Eiffelovke',
        description: 'Vizualný a textový kvíz o Eiffelovej veži a Francúzsku',
        type: 'quiz',
        content: {
            questions: [
                {
                    text: 'Ktorý obrázok zobrazuje Eiffelovu vežu?',
                    image: '/uploads/Eiffel_cartoon.jpg',
                    answers: [
                        { text: 'Obrázok 1', image: '/uploads/Eiffel.jpg', correct: true },
                        { text: 'Obrázok 2', image: '/uploads/Pisa.jpg', correct: false },
                        { text: 'Obrázok 3', image: '/uploads/Tatras.jpg', correct: false },
                        { text: 'Žiadna z možností', image: null, correct: false }
                    ]
                },
                {
                    text: 'Ktoré mesto je hlavné mesto Francúzska?',
                    answers: [
                        { text: 'Paríž', correct: true },
                        { text: 'Lyon', correct: false },
                        { text: 'Marseille', correct: false }
                    ]
                }
            ]
        }
    },
    {
        title: 'Slovosled – Pes beží',
        description: 'Zoradenie slov do správneho poradia',
        type: 'word-jumble',
        content: {
            words: ['pes', 'beží', 'po', 'dome'],
            correct_order: ['pes', 'beží', 'po', 'dome']
        }
    },
    {
        title: 'Spoj obrázky',
        description: 'Spoj zvieratá s ich obrázkami',
        type: 'connection',
        content: {
            pairs: [
                { left: 'Slon', right: '🐘' },
                { left: 'Pes', right: '🐕' },
                { left: 'Mačka', right: '🐈' }
            ]
        }
    }
];
const seedPermissions = () => __awaiter(void 0, void 0, void 0, function* () {
    for (const perm of defaultPermissions) {
        const exists = yield permission_1.Permission.findOne({ role: perm.role });
        if (!exists) {
            yield new permission_1.Permission(perm).save();
        }
        else {
            yield permission_1.Permission.updateOne({ role: perm.role }, { $set: { actions: perm.actions } });
        }
    }
    const adminExists = yield user_1.default.findOne({ email: 'admin' });
    let adminTeacher;
    if (!adminExists) {
        const plainPassword = 'admin123';
        const hashedPassword = yield bcryptjs_1.default.hash(plainPassword, 10);
        const defaultAccountAdmin = new user_1.default({
            name: 'admin',
            email: 'admin',
            password: hashedPassword,
            role: 'admin',
            dateOfBirth: new Date(),
            lastActive: new Date(),
        });
        yield defaultAccountAdmin.save();
        adminTeacher = new teacher_1.Teacher({
            user: defaultAccountAdmin._id,
            specialization: ''
        });
        yield adminTeacher.save();
        console.log('Admin created with password: admin123');
    }
    else {
        adminTeacher = yield teacher_1.Teacher.findOne({ user: adminExists._id });
    }
    if (!adminTeacher) {
        throw new Error('Admin teacher not found or could not be created.');
    }
    for (const mat of sampleMaterials) {
        const exists = yield material_1.default.findOne({ title: mat.title });
        if (!exists) {
            yield new material_1.default(Object.assign(Object.assign({}, mat), { author: adminTeacher._id })).save();
        }
    }
    console.log('Materials initialized.');
    console.log('Permissions initialized.');
});
exports.seedPermissions = seedPermissions;
