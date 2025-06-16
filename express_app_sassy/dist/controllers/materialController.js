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
exports.getAllStudentProgress = exports.getAllTemplates = exports.saveAsTemplate = exports.getAllTeachersMaterials = exports.assignMaterialToStudent = exports.submitMaterial = exports.getStudentMaterials = exports.getMaterialDetails = exports.deleteMaterial = exports.updateMaterial = exports.createMaterial = void 0;
const material_1 = __importDefault(require("../models/material"));
const assignment_1 = __importDefault(require("../models/assignment"));
const progress_1 = __importDefault(require("../models/progress"));
const teacher_1 = require("../models/teacher");
const user_1 = __importDefault(require("../models/user"));
const student_1 = require("../models/student");
const group_1 = require("../models/group");
const template_1 = require("../models/template");
const websocketService_1 = require("../utils/websocketService");
const validateMaterialContent = (type, content) => {
    switch (type) {
        case 'puzzle':
            return (content.image &&
                typeof content.image === 'string' &&
                content.grid &&
                Number.isInteger(content.grid.columns) &&
                Number.isInteger(content.grid.rows) &&
                content.grid.columns > 0 &&
                content.grid.rows > 0);
        case 'quiz':
            return (Array.isArray(content.questions) &&
                content.questions.every((question) => (question.text || question.image) &&
                    Array.isArray(question.answers) &&
                    question.answers.length >= 2 &&
                    question.answers.some((ans) => ans.correct === true)));
        case 'word-jumble':
            return (Array.isArray(content.words) &&
                Array.isArray(content.correct_order) &&
                content.words.length === content.correct_order.length);
        case 'connection':
            return (Array.isArray(content.pairs) &&
                content.pairs.every((pair) => pair.left && pair.right));
        default:
            return false;
    }
};
const createMaterial = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a, _b, _c, _d;
    try {
        const { title, description, type, content, assignedTo, assignedGroups } = req.body;
        const teacher = yield teacher_1.Teacher.findOne({ user: (_a = req.user) === null || _a === void 0 ? void 0 : _a._id });
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
        const newMaterial = new material_1.default({
            title,
            description,
            type,
            content,
            author
        });
        yield newMaterial.save();
        const assignments = [];
        if (assignedTo && assignedTo.length > 0) {
            for (const studentId of assignedTo) {
                assignments.push({
                    material: newMaterial._id,
                    student: studentId,
                    assignedBy: teacher._id,
                    status: 'pending'
                });
                yield (0, websocketService_1.notifyMaterialAssigned)(((_c = (_b = (yield student_1.Student.findById(studentId))) === null || _b === void 0 ? void 0 : _b.user) === null || _c === void 0 ? void 0 : _c.toString()) || 'UNKNOWN', newMaterial);
            }
        }
        if (assignedGroups && assignedGroups.length > 0) {
            for (const groupId of assignedGroups) {
                const group = yield group_1.Group.findById(groupId);
                if (group && group.students.length > 0) {
                    for (const studentId of group.students) {
                        if (!assignments.some(a => a.student.toString() === studentId.toString())) {
                            assignments.push({
                                material: newMaterial._id,
                                student: studentId,
                                group: groupId,
                                assignedBy: (_d = req.user) === null || _d === void 0 ? void 0 : _d._id,
                                status: 'pending'
                            });
                            yield (0, websocketService_1.notifyMaterialAssigned)(studentId.toString(), newMaterial);
                        }
                    }
                }
            }
        }
        if (assignments.length > 0) {
            yield assignment_1.default.insertMany(assignments);
        }
        const responseObj = {
            message: 'Material created successfully',
            material: Object.assign(Object.assign({}, newMaterial.toObject()), { assignedTo: assignedTo || [], assignedGroups: assignedGroups || [] })
        };
        res.status(201).json(responseObj);
    }
    catch (error) {
        res.status(500).json({ message: 'Failed to create material', error });
    }
});
exports.createMaterial = createMaterial;
const updateMaterial = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a, _b, _c, _d;
    try {
        const { id } = req.params;
        const { title, description, type, content, assignedTo, assignedGroups } = req.body;
        const existingMaterial = yield material_1.default.findById(id);
        if (!existingMaterial) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }
        if (type && !validateMaterialContent(type, content)) {
            res.status(400).json({ message: 'Invalid content structure for the selected type.' });
            return;
        }
        if (title)
            existingMaterial.title = title;
        if (description)
            existingMaterial.description = description;
        if (type)
            existingMaterial.type = type;
        if (content)
            existingMaterial.content = content;
        yield existingMaterial.save();
        if (assignedTo !== undefined || assignedGroups !== undefined) {
            const newAssignedTo = assignedTo || [];
            const newAssignedGroups = assignedGroups || [];
            const currentIndividualAssignments = yield assignment_1.default.find({
                material: id,
                group: null
            });
            const newlyAssignedStudents = new Set(newAssignedTo.map((s) => s.toString()));
            const individualAssignmentsToRemove = currentIndividualAssignments.filter(assignment => !newlyAssignedStudents.has(assignment.student.toString()));
            if (individualAssignmentsToRemove.length > 0) {
                yield assignment_1.default.deleteMany({
                    _id: { $in: individualAssignmentsToRemove.map(a => a._id) }
                });
            }
            const currentAssignedStudentIds = new Set(currentIndividualAssignments
                .filter(a => a.status === 'pending' && !individualAssignmentsToRemove.includes(a))
                .map(a => a.student.toString()));
            const newIndividualAssignments = [];
            for (const studentId of newAssignedTo) {
                if (!currentAssignedStudentIds.has(studentId.toString())) {
                    newIndividualAssignments.push({
                        material: id,
                        student: studentId,
                        assignedBy: (_a = req.user) === null || _a === void 0 ? void 0 : _a.id,
                        status: 'pending'
                    });
                    yield (0, websocketService_1.notifyMaterialAssigned)(((_c = (_b = (yield student_1.Student.findById(studentId))) === null || _b === void 0 ? void 0 : _b.user) === null || _c === void 0 ? void 0 : _c.toString()) || 'UNKNOWN', existingMaterial);
                }
            }
            const currentGroupAssignments = yield assignment_1.default.find({
                material: id,
                group: { $ne: null }
            });
            const currentGroupIds = new Set(currentGroupAssignments.map(a => a.group.toString()));
            const newGroupIds = new Set(newAssignedGroups.map((g) => g.toString()));
            const groupsToRemove = [];
            for (const groupId of currentGroupIds) {
                if (!newGroupIds.has(groupId)) {
                    groupsToRemove.push(groupId);
                }
            }
            if (groupsToRemove.length > 0) {
                yield assignment_1.default.deleteMany({
                    material: id,
                    group: { $in: groupsToRemove }
                });
            }
            const newGroupAssignments = [];
            for (const groupId of newAssignedGroups) {
                const groupAssignments = currentGroupAssignments.filter(a => { var _a; return ((_a = a.group) === null || _a === void 0 ? void 0 : _a.toString()) === groupId.toString(); });
                const allCompleted = groupAssignments.every(a => a.status === 'completed');
                if (!allCompleted && groupAssignments.length > 0) {
                    continue;
                }
                const group = yield group_1.Group.findById(groupId);
                if (group && group.students.length > 0) {
                    for (const studentId of group.students) {
                        newGroupAssignments.push({
                            material: id,
                            student: studentId,
                            group: groupId,
                            assignedBy: (_d = req.user) === null || _d === void 0 ? void 0 : _d._id,
                            status: 'pending'
                        });
                        yield (0, websocketService_1.notifyMaterialAssigned)(studentId.toString(), existingMaterial);
                    }
                }
            }
            const allNewAssignments = [...newIndividualAssignments, ...newGroupAssignments];
            if (allNewAssignments.length > 0) {
                yield assignment_1.default.insertMany(allNewAssignments);
            }
        }
        const updatedAssignments = yield assignment_1.default.find({ material: id });
        const individualAssignments = updatedAssignments.filter(a => !a.group);
        const returnAssignedTo = individualAssignments.map(a => a.student);
        const returnAssignedGroups = [...new Set(updatedAssignments
                .filter(a => a.group)
                .map(a => a.group.toString()))];
        const responseObj = {
            message: 'Material updated successfully',
            material: Object.assign(Object.assign({}, existingMaterial.toObject()), { assignedTo: returnAssignedTo, assignedGroups: returnAssignedGroups })
        };
        res.status(200).json(responseObj);
    }
    catch (error) {
        res.status(500).json({ message: 'Failed to update material', error });
    }
});
exports.updateMaterial = updateMaterial;
const deleteMaterial = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { id } = req.params;
        const deletedMaterial = yield material_1.default.findByIdAndDelete(id);
        if (!deletedMaterial) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }
        yield assignment_1.default.deleteMany({ material: id });
        res.status(200).json({ message: 'Material deleted successfully' });
    }
    catch (error) {
        res.status(500).json({ message: 'Failed to delete material', error });
    }
});
exports.deleteMaterial = deleteMaterial;
const getMaterialDetails = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { materialId } = req.params;
        const material = yield material_1.default.findById(materialId);
        if (!material) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }
        const teacher = yield teacher_1.Teacher.findById(material.author);
        if (!teacher) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }
        const userTeacher = yield user_1.default.findById(teacher.user);
        if (!userTeacher) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }
        const assignments = yield assignment_1.default.find({ material: materialId, status: 'pending' });
        const studentIds = [...new Set(assignments.map(a => a.student.toString()))];
        const groupIds = [...new Set(assignments.filter(a => a.group).map(a => a.group.toString()))];
        // console.log(studentIds);
        const studentModels = yield student_1.Student.find({
            _id: { $in: studentIds }
        });
        // console.log(studentModels);
        const studentUsers = yield user_1.default.find({
            _id: { $in: studentModels.map(s => s.user) }
        }).select('_id name');
        const groupModels = yield group_1.Group.find({
            _id: { $in: groupIds }
        });
        const formattedStudents = studentModels.map(student => {
            const user = studentUsers.find((u) => u._id.equals(student.user));
            return {
                id: student._id,
                name: (user === null || user === void 0 ? void 0 : user.name) || 'Neznamy student',
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
    }
    catch (error) {
        res.status(500).json({ message: 'Failed to get material', error });
    }
});
exports.getMaterialDetails = getMaterialDetails;
const getStudentMaterials = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(403).json({ message: 'Unauthorized. No user found in request' });
            return;
        }
        const student = yield student_1.Student.findOne({ user: req.user._id });
        if (!student) {
            res.status(400).json({ message: 'Unauthorized. No student found in request' });
            return;
        }
        const assignments = yield assignment_1.default.find({
            student: student._id,
            status: 'pending'
        });
        if (!assignments || assignments.length === 0) {
            res.status(200).json([]);
            return;
        }
        const materialIds = assignments.map(a => a.material);
        const materials = yield material_1.default.find({
            _id: { $in: materialIds }
        });
        res.status(200).json(materials);
    }
    catch (error) {
        res.status(500).json({ message: 'Error fetching materials', error });
    }
});
exports.getStudentMaterials = getStudentMaterials;
const submitMaterial = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    var _a, _b;
    // console.log('submitMaterial called', req.body);
    try {
        const { studentId, materialId, answers } = req.body;
        if (!studentId || !materialId || !answers) {
            res.status(400).json({ message: 'Missing required fields' });
            return;
        }
        const material = yield material_1.default.findById(materialId);
        if (!material) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }
        const teacher = yield teacher_1.Teacher.findById(material.author);
        if (!teacher) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }
        const student = yield student_1.Student.findById(studentId);
        if (!student) {
            res.status(404).json({ message: 'Student not found' });
            return;
        }
        const studentUser = yield user_1.default.findById(student.user);
        if (!studentUser) {
            res.status(404).json({ message: 'Student user not found' });
            return;
        }
        let score = 0;
        let maxScore = 100;
        const materialType = material.type.toLowerCase();
        if (materialType === 'quiz') {
            const correctAnswers = answers.filter((ans) => ans.isCorrect === true).length;
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
                    const totalPairs = ((_b = (_a = material.content) === null || _a === void 0 ? void 0 : _a.pairs) === null || _b === void 0 ? void 0 : _b.length) || 0;
                    if (totalPairs > 0) {
                        const connectedPairs = connections.filter((conn) => conn.isConnected === true).length;
                        score = Math.round((connectedPairs / totalPairs) * 100);
                    }
                    else {
                        score = 100;
                    }
                }
                else {
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
        const newProgress = new progress_1.default({
            student: studentId,
            material: materialId,
            answers,
            score,
            maxScore,
            timeSpent: totalTimeSpent,
            submittedAt: new Date()
        });
        yield newProgress.save();
        const assignment = yield assignment_1.default.findOne({
            student: studentId,
            material: materialId,
            status: 'pending'
        });
        if (assignment) {
            assignment.status = 'completed';
            assignment.completedAt = new Date();
            assignment.progressRef = newProgress.id;
            yield assignment.save();
        }
        (0, websocketService_1.notifyMaterialCompleted)(teacher.user.toString(), studentId, materialId, studentUser.name, material.title);
        res.status(201).json({
            message: 'Material submitted successfully',
            progress: Object.assign(Object.assign({}, newProgress.toObject()), { score, timeSpent: totalTimeSpent })
        });
    }
    catch (error) {
        res.status(500).json({ message: 'Failed to submit material', error });
    }
});
exports.submitMaterial = submitMaterial;
const assignMaterialToStudent = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { materialId, studentId } = req.body;
        const material = yield material_1.default.findById(materialId);
        if (!material) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }
        const existingAssignment = yield assignment_1.default.findOne({
            material: materialId,
            student: studentId,
            status: 'pending'
        });
        if (!existingAssignment) {
            const newAssignment = new assignment_1.default({
                material: materialId,
                student: studentId,
                assignedBy: material.author,
                status: 'pending'
            });
            yield newAssignment.save();
            (0, websocketService_1.notifyMaterialAssigned)(studentId, material);
        }
        const responseObj = {
            message: 'Material assigned successfully',
            material: Object.assign(Object.assign({}, material.toObject()), { assignedTo: [studentId] })
        };
        res.status(200).json(responseObj);
    }
    catch (error) {
        res.status(500).json({ message: 'Failed to assign material', error });
    }
});
exports.assignMaterialToStudent = assignMaterialToStudent;
const getAllTeachersMaterials = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }
        const teachers = yield teacher_1.Teacher.find({ "user": req.user._id });
        if (!teachers || teachers.length === 0) {
            res.status(404).json({ message: 'Teacher not found' });
            return;
        }
        const teacherId = teachers[0]._id;
        const materials = yield material_1.default.find({ author: teacherId });
        const formattedMaterials = materials.map((material) => ({
            _id: material._id,
            title: material.title,
            description: material.description,
            type: material.type,
        }));
        res.status(200).json(formattedMaterials);
    }
    catch (error) {
        res.status(500).json({ message: 'Error getting materials', error });
    }
});
exports.getAllTeachersMaterials = getAllTeachersMaterials;
const saveAsTemplate = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }
        const { materialId } = req.body;
        const material = yield material_1.default.findById(materialId);
        if (!material) {
            res.status(404).json({ message: 'Material not found' });
            return;
        }
        const existingTemplate = yield template_1.Template.findOne({ materialId });
        if (existingTemplate) {
            res.status(400).json({ message: 'Template already exists for this material' });
            return;
        }
        const newTemplate = new template_1.Template({ materialId });
        yield newTemplate.save();
        res.status(201).json({ message: 'Template saved successfully', template: newTemplate });
    }
    catch (error) {
        res.status(500).json({ message: 'Failed to save template', error });
    }
});
exports.saveAsTemplate = saveAsTemplate;
const getAllTemplates = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        if (!req.user) {
            res.status(401).json({ message: 'Unauthorized. No user found in request' });
            return;
        }
        const templates = yield template_1.Template.find();
        // if (!templates || templates.length === 0) {
        //     res.status(404).json({ message: 'No Templates found' });
        //     return;
        // }
        const materialIds = templates.map(template => template.materialId);
        const materials = yield material_1.default.find({
            _id: { $in: materialIds }
        });
        const formattedMaterials = materials.map((material) => {
            var _a;
            return ({
                _id: material._id,
                title: material.title,
                description: material.description,
                type: material.type,
                templateId: (_a = templates.find(t => t.materialId.equals(material.id))) === null || _a === void 0 ? void 0 : _a._id
            });
        });
        res.status(200).json(formattedMaterials);
    }
    catch (error) {
        res.status(500).json({ message: 'Error getting templates', error });
    }
});
exports.getAllTemplates = getAllTemplates;
const getAllStudentProgress = (req, res) => __awaiter(void 0, void 0, void 0, function* () {
    try {
        const { studentId } = req.params;
        // console.log(studentId);
        const progresses = yield progress_1.default.find({ student: studentId });
        const assignments = yield assignment_1.default.find({ student: studentId });
        const totalAssignments = assignments.length;
        const completedAssignments = assignments.filter(a => a.status === 'completed').length;
        const averageScore = progresses.length > 0
            ? Math.round(progresses.reduce((sum, progress) => sum + (progress.score || 0), 0) / progresses.length)
            : 0;
        const formattedProgresses = {
            totalAssignments,
            completedAssignments,
            averageScore,
            progresses: yield Promise.all(progresses.map((progress) => __awaiter(void 0, void 0, void 0, function* () {
                var _a;
                return ({
                    material: ((_a = (yield material_1.default.findById(progress.material))) === null || _a === void 0 ? void 0 : _a.title) || 'Unknown',
                    score: progress.score,
                    submittedAt: progress.createdAt,
                    timeSpent: progress.answers.timeSpent || null,
                    answers: progress.answers
                });
            })))
        };
        res.status(200).json(formattedProgresses);
    }
    catch (error) {
        res.status(500).json({ message: 'Error getting progresses', error });
    }
});
exports.getAllStudentProgress = getAllStudentProgress;
