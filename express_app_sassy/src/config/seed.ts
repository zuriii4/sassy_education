import { Permission } from '../models/permission';
import {Document} from "mongoose";
import bcrypt from "bcryptjs";
import User from "../models/user";
import {Teacher} from "../models/teacher";
import Material from "../models/material";

const defaultPermissions = [
    { role: 'admin', actions: ['view_material' ,'assign_task', 'view_progress', 'manage_groups', 'manage_materials','manage_students', 'manage_teachers' ] },
    { role: 'teacher', actions: ['view_material' ,'assign_task', 'view_progress', 'manage_groups', 'manage_materials','manage_students' ] },
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

export const seedPermissions = async () => {
    for (const perm of defaultPermissions) {
        const exists = await Permission.findOne({ role: perm.role });
        if (!exists) {
            await new Permission(perm).save();
        } else {
            await Permission.updateOne({ role: perm.role }, { $set: { actions: perm.actions } });
        }
    }

    const adminExists = await User.findOne({ email: 'admin' });

    let adminTeacher;

    if (!adminExists) {
        const plainPassword = 'admin123';
        const hashedPassword = await bcrypt.hash(plainPassword, 10);

        const defaultAccountAdmin = new User({
            name: 'admin',
            email: 'admin',
            password: hashedPassword,
            role: 'admin',
            dateOfBirth: new Date(),
            lastActive: new Date(),
        });

        await defaultAccountAdmin.save();

        adminTeacher = new Teacher({
            user: defaultAccountAdmin._id,
            specialization: ''
        });

        await adminTeacher.save();

        console.log('Admin created with password: admin123');
    } else {
        adminTeacher = await Teacher.findOne({ user: adminExists._id });
    }

    if (!adminTeacher) {
        throw new Error('Admin teacher not found or could not be created.');
    }

    for (const mat of sampleMaterials) {
        const exists = await Material.findOne({ title: mat.title });
        if (!exists) {
            await new Material({ ...mat, author: adminTeacher._id }).save();
        }
    }

    console.log('Materials initialized.');

    console.log('Permissions initialized.');
};