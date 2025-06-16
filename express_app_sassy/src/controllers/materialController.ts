import { Request, Response } from 'express';
import Material from '../models/material';
import Assignment from '../models/assignment';
import Progress from '../models/progress';
import {AuthRequest} from "../middleware/auth";
import {Teacher} from "../models/teacher";
import User from "../models/user";
import {Student} from "../models/student";
import {Group} from "../models/group";
import {Template} from "../models/template";
import {notifyMaterialAssigned, notifyMaterialCompleted} from "../utils/websocketService";
import {Types} from "mongoose";

const validateMaterialContent = (type: string, content: any): boolean => {
    switch (type) {
        case 'puzzle':
            return (
                content.image &&
                typeof content.image === 'string' &&
                content.grid &&
                Number.isInteger(content.grid.columns) &&
                Number.isInteger(content.grid.rows) &&
                content.grid.columns > 0 &&
                content.grid.rows > 0
            );
        case 'quiz':
            return (
                Array.isArray(content.questions) &&
                content.questions.every((question: any) =>
                    (question.text || question.image) &&
                    Array.isArray(question.answers) &&
                    question.answers.length >= 2 &&
                    question.answers.some((ans: any) => ans.correct === true)
                )
            );
        case 'word-jumble':
            return (
                Array.isArray(content.words) &&
                Array.isArray(content.correct_order) &&
                content.words.length === content.correct_order.length
            );
        case 'connection':
            return (
                Array.isArray(content.pairs) &&
                content.pairs.every((pair: any) => pair.left && pair.right)
            );
        default:
            return false;
    }
};

export const createMaterial = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { title, description, type, content, assignedTo, assignedGroups } = req.body;
        const teacher = await Teacher.findOne({ user: req.user?._id });
        if (!teacher) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }
        const author = teacher._id;
        if (!author) {
            res.status(401).json({ message: 'Unauthorized. No user found in request.' });
            return;
        }

        if (!validateMaterialContent(type, content)) {
            res.status(400).json({ message: 'Invalid content structure for the selected type.' });
            return;
        }

        const newMaterial = new Material({
            title,
            description,
            type,
            content,
            author
        });

        await newMaterial.save();

        const assignments = [];

        if (assignedTo && assignedTo.length > 0) {
            for (const studentId of assignedTo) {
                assignments.push({
                    material: newMaterial._id,
                    student: studentId,
                    assignedBy: teacher._id,
                    status: 'pending'
                });

                await notifyMaterialAssigned((await Student.findById(studentId))?.user?.toString() || 'UNKNOWN', newMaterial);
            }
        }

        if (assignedGroups && assignedGroups.length > 0) {
            for (const groupId of assignedGroups) {
                const group = await Group.findById(groupId);
                if (group && group.students.length > 0) {
                    for (const studentId of group.students) {
                        if (!assignments.some(a => a.student.toString() === studentId.toString())) {
                            assignments.push({
                                material: newMaterial._id,
                                student: studentId,
                                group: groupId,
                                assignedBy: req.user?._id,
                                status: 'pending'
                            });

                            await notifyMaterialAssigned(studentId.toString(), newMaterial);
                        }
                    }
                }
            }
        }

        if (assignments.length > 0) {
            await Assignment.insertMany(assignments);
        }

        const responseObj = {
            message: 'Material created successfully',
            material: {
                ...newMaterial.toObject(),
                assignedTo: assignedTo || [],
                assignedGroups: assignedGroups || []
            }
        };

        res.status(201).json(responseObj);
    } catch (error) {
        res.status(500).json({ message: 'Failed to create material', error });
    }
};

export const updateMaterial = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const { id } = req.params;
        const { title, description, type, content, assignedTo, assignedGroups } = req.body;

        const existingMaterial = await Material.findById(id);
        if (!existingMaterial) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }

        if (type && !validateMaterialContent(type, content)) {
            res.status(400).json({ message: 'Invalid content structure for the selected type.' });
            return;
        }

        if (title) existingMaterial.title = title;
        if (description) existingMaterial.description = description;
        if (type) existingMaterial.type = type;
        if (content) existingMaterial.content = content;

        await existingMaterial.save();

        if (assignedTo !== undefined || assignedGroups !== undefined) {
            const newAssignedTo = assignedTo || [];
            const newAssignedGroups = assignedGroups || [];


            const currentIndividualAssignments = await Assignment.find({
                material: id,
                group: null
            });

            const newlyAssignedStudents = new Set(
                (newAssignedTo as (string | Types.ObjectId)[]).map((s: string | Types.ObjectId) => s.toString())
            );

            const individualAssignmentsToRemove = currentIndividualAssignments.filter(
                assignment => !newlyAssignedStudents.has(assignment.student.toString())
            );

            if (individualAssignmentsToRemove.length > 0) {
                await Assignment.deleteMany({
                    _id: { $in: individualAssignmentsToRemove.map(a => a._id) }
                });
            }

            const currentAssignedStudentIds = new Set(
                currentIndividualAssignments
                    .filter(a => a.status === 'pending' && !individualAssignmentsToRemove.includes(a))
                    .map(a => a.student.toString())
            );

            const newIndividualAssignments = [];
            for (const studentId of newAssignedTo) {
                if (!currentAssignedStudentIds.has(studentId.toString())) {
                    newIndividualAssignments.push({
                        material: id,
                        student: studentId,
                        assignedBy: req.user?.id,
                        status: 'pending'
                    });

                    await notifyMaterialAssigned((await Student.findById(studentId))?.user?.toString() || 'UNKNOWN', existingMaterial);
                }
            }


            const currentGroupAssignments = await Assignment.find({
                material: id,
                group: { $ne: null }
            });

            const currentGroupIds = new Set(
                currentGroupAssignments.map(a => a.group.toString())
            );

            const newGroupIds = new Set(
                (newAssignedGroups as (string | Types.ObjectId)[]).map((g: string | Types.ObjectId) => g.toString())
            );
            const groupsToRemove = [];
            for (const groupId of currentGroupIds) {
                if (!newGroupIds.has(groupId)) {
                    groupsToRemove.push(groupId);
                }
            }

            if (groupsToRemove.length > 0) {
                await Assignment.deleteMany({
                    material: id,
                    group: { $in: groupsToRemove }
                });
            }

            const newGroupAssignments = [];
            for (const groupId of newAssignedGroups) {
                const groupAssignments = currentGroupAssignments.filter(a => a.group?.toString() === groupId.toString());
                const allCompleted = groupAssignments.every(a => a.status === 'completed');

                if (!allCompleted && groupAssignments.length > 0) {
                    continue;
                }

                const group = await Group.findById(groupId);
                if (group && group.students.length > 0) {
                    for (const studentId of group.students) {
                        newGroupAssignments.push({
                            material: id,
                            student: studentId,
                            group: groupId,
                            assignedBy: req.user?._id,
                            status: 'pending'
                        });

                        await notifyMaterialAssigned(studentId.toString(), existingMaterial);
                    }
                }
            }

            const allNewAssignments = [...newIndividualAssignments, ...newGroupAssignments];
            if (allNewAssignments.length > 0) {
                await Assignment.insertMany(allNewAssignments);
            }
        }

        const updatedAssignments = await Assignment.find({ material: id });

        const individualAssignments = updatedAssignments.filter(a => !a.group);
        const returnAssignedTo = individualAssignments.map(a => a.student);

        const returnAssignedGroups = [...new Set(
            updatedAssignments
                .filter(a => a.group)
                .map(a => a.group.toString())
        )];

        const responseObj = {
            message: 'Material updated successfully',
            material: {
                ...existingMaterial.toObject(),
                assignedTo: returnAssignedTo,
                assignedGroups: returnAssignedGroups
            }
        };

        res.status(200).json(responseObj);
    } catch (error) {
        res.status(500).json({ message: 'Failed to update material', error });
    }
};

export const deleteMaterial = async (req: Request, res: Response): Promise<void> => {
    try {
        const { id } = req.params;

        const deletedMaterial = await Material.findByIdAndDelete(id);
        if (!deletedMaterial) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }

        await Assignment.deleteMany({ material: id });

        res.status(200).json({ message: 'Material deleted successfully' });
    } catch (error) {
        res.status(500).json({ message: 'Failed to delete material', error });
    }
};

export const getMaterialDetails = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        const {materialId} = req.params;

        const material = await Material.findById(materialId);
        if (!material) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }

        const teacher = await Teacher.findById(material.author);
        if (!teacher) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }

        const userTeacher = await User.findById(teacher.user);
        if (!userTeacher) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }

        const assignments = await Assignment.find({ material: materialId, status: 'pending' });

        const studentIds = [...new Set(assignments.map(a => a.student.toString()))];
        const groupIds = [...new Set(assignments.filter(a => a.group).map(a => a.group.toString()))];
        // console.log(studentIds);

        const studentModels = await Student.find({
            _id: { $in: studentIds }
        });
        // console.log(studentModels);
        const studentUsers = await User.find({
            _id: { $in: studentModels.map(s => s.user) }
        }).select('_id name');

        const groupModels = await Group.find({
            _id: { $in: groupIds }
        });

        const formattedStudents = studentModels.map(student => {
            const user = studentUsers.find((u: any) => u._id.equals(student.user));
            return {
                id: student._id,
                name: user?.name || 'Neznamy student',
                notes: student.notes,
                hasSpecialNeeds: student.hasSpecialNeeds,
                needsDescription: student.needsDescription
            };
        });

        const formattedTeacher = {
            _id: teacher._id,
            name: userTeacher.name
        };

        res.status(200).json({
            title: material.title,
            description: material.description,
            type: material.type,
            content: material.content,
            teacher: formattedTeacher,
            students: formattedStudents,
            groups: groupModels,
        });

    }catch(error) {
        res.status(500).json({ message: 'Failed to get material', error });
    }
};

export const getStudentMaterials = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(403).json({ message: 'Unauthorized. No user found in request' });
            return;
        }

        const student = await Student.findOne({ user: req.user._id });
        if (!student) {
            res.status(400).json({ message: 'Unauthorized. No student found in request' });
            return;
        }

        const assignments = await Assignment.find({
            student: student._id,
            status: 'pending'
        });

        if (!assignments || assignments.length === 0) {
            res.status(200).json([]);
            return;
        }

        const materialIds = assignments.map(a => a.material);

        const materials = await Material.find({
            _id: { $in: materialIds }
        });


        res.status(200).json(materials);
    } catch (error) {
        res.status(500).json({ message: 'Error fetching materials', error });
    }
};

export const submitMaterial = async (req: Request, res: Response): Promise<void> => {
    // console.log('submitMaterial called', req.body);
    try {
        const { studentId, materialId, answers } = req.body;

        if (!studentId || !materialId || !answers) {
            res.status(400).json({ message: 'Missing required fields' });
            return;
        }

        const material = await Material.findById(materialId);
        if (!material) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }

        const teacher = await Teacher.findById(material.author);
        if (!teacher) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }

        const student = await Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }

        const studentUser = await User.findById(student.user);
        if (!studentUser) {
            res.status(404).json({ message: 'Student user not found' });
            return;
        }

        let score = 0;
        let maxScore = 100;

        const materialType = material.type.toLowerCase();

        if (materialType === 'quiz') {
            const correctAnswers = answers.filter((ans: any) => ans.isCorrect === true).length;
            const totalQuestions = answers.length;
            if (totalQuestions > 0) {
                score = Math.round((correctAnswers / totalQuestions) * 100);
            }
        }
        else if (materialType === 'puzzle') {
            if (answers.length > 0 && answers[0].completed === true) {
                score = 100;
            }
        }
        else if (materialType === 'connection') {
            if (answers.length > 0 && answers[0].completed === true) {
                const connections = answers[0].connections;
                if (connections && Array.isArray(connections)) {
                    const totalPairs = material.content?.pairs?.length || 0;
                    if (totalPairs > 0) {
                        const connectedPairs = connections.filter((conn: any) => conn.isConnected === true).length;
                        score = Math.round((connectedPairs / totalPairs) * 100);
                    } else {
                        score = 100;
                    }
                } else {
                    score = 100;
                }
            }
        }
        else if (materialType === 'word-jumble') {
            if (answers.length > 0 && answers[0].completed === true) {
                score = 100;
            }
        }
        else {
            if (answers.length > 0 && answers[0].completed === true) {
                score = 100;
            }
        }

        let totalTimeSpent = 0;
        if (answers.length > 0 && answers[0].timeSpent) {
            totalTimeSpent = answers[0].timeSpent;
        }

        const newProgress = new Progress({
            student: studentId,
            material: materialId,
            answers,
            score,
            maxScore,
            timeSpent: totalTimeSpent,
            submittedAt: new Date()
        });
        await newProgress.save();

        const assignment = await Assignment.findOne({
            student: studentId,
            material: materialId,
            status: 'pending'
        });

        if (assignment) {
            assignment.status = 'completed';
            assignment.completedAt = new Date();
            assignment.progressRef = newProgress.id;
            await assignment.save();
        }

        notifyMaterialCompleted(
            teacher.user.toString(),
            studentId,
            materialId,
            studentUser.name,
            material.title
        );

        res.status(201).json({
            message: 'Material submitted successfully',
            progress: {
                ...newProgress.toObject(),
                score,
                timeSpent: totalTimeSpent
            }
        });
    } catch (error) {
        res.status(500).json({ message: 'Failed to submit material', error });
    }
};

export const assignMaterialToStudent = async (req: Request, res: Response): Promise<void> => {
    try {
        const { materialId, studentId } = req.body;

        const material = await Material.findById(materialId);
        if (!material) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }

        const existingAssignment = await Assignment.findOne({
            material: materialId,
            student: studentId,
            status: 'pending'
        });

        if (!existingAssignment) {
            const newAssignment = new Assignment({
                material: materialId,
                student: studentId,
                assignedBy: material.author,
                status: 'pending'
            });

            await newAssignment.save();

            notifyMaterialAssigned(studentId, material);
        }

        const responseObj = {
            message: 'Material assigned successfully',
            material: {
                ...material.toObject(),
                assignedTo: [studentId]
            }
        };

        res.status(200).json(responseObj);
    } catch (error) {
        res.status(500).json({ message: 'Failed to assign material', error });
    }
};

export const getAllTeachersMaterials = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }

        const teachers = await Teacher.find({ "user": req.user._id });

        if (!teachers || teachers.length === 0) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }

        const teacherId = teachers[0]._id;
        const materials = await Material.find({ author: teacherId });

        const formattedMaterials = materials.map((material) => ({
            _id: material._id,
            title: material.title,
            description: material.description,
            type: material.type,
        }));

        res.status(200).json(formattedMaterials);
    } catch (error) {
        res.status(500).json({ message: 'Error getting materials', error });
    }
}

export const saveAsTemplate = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }

        const { materialId } = req.body;

        const material = await Material.findById(materialId);
        if (!material) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }

        const existingTemplate = await Template.findOne({ materialId });
        if (existingTemplate) {
            res.status(400).json({ message: 'Template already exists for this material' });
            return;
        }

        const newTemplate = new Template({ materialId });
        await newTemplate.save();

        res.status(201).json({ message: 'Template saved successfully', template: newTemplate });
    } catch (error) {
        res.status(500).json({ message: 'Failed to save template', error });
    }
}

export const getAllTemplates = async (req: AuthRequest, res: Response): Promise<void> => {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }

        const templates = await Template.find();

        // if (!templates || templates.length === 0) {
        //     res.status(404).json({ message: 'No Templates found' });
        //     return;
        // }

        const materialIds = templates.map(template => template.materialId);

        const materials = await Material.find({
            _id: { $in: materialIds }
        });

        const formattedMaterials = materials.map((material) => ({
            _id: material._id,
            title: material.title,
            description: material.description,
            type: material.type,
            templateId: templates.find(t => t.materialId.equals(material.id))?._id
        }));

        res.status(200).json(formattedMaterials);
    } catch (error) {
        res.status(500).json({ message: 'Error getting templates', error });
    }
}

export const getAllStudentProgress = async (req: Request, res: Response): Promise<void> => {
    try {

        const {studentId} = req.params;
        // console.log(studentId);

        const progresses = await Progress.find({student: studentId});
        const assignments = await Assignment.find({student: studentId});

        const totalAssignments = assignments.length;
        const completedAssignments = assignments.filter(a => a.status === 'completed').length;
        const averageScore = progresses.length > 0
            ? Math.round(progresses.reduce((sum, progress) => sum + (progress.score || 0), 0) / progresses.length)
            : 0;

        const formattedProgresses = {
            totalAssignments,
            completedAssignments,
            averageScore,
            progresses: await Promise.all(progresses.map(async (progress) => ({
                material: (await Material.findById(progress.material))?.title || 'Unknown',
                score: progress.score,
                submittedAt: progress.createdAt,
                timeSpent: progress.answers.timeSpent || null,
                answers: progress.answers
            })))
        };

        res.status(200).json(formattedProgresses);
    } catch (error) {
        res.status(500).json({ message: 'Error getting progresses', error });
    }
}