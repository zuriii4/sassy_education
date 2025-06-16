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
Object.defineProperty(exports, "__esModule", { value: true });
const mongoose_1 = __importStar(require("mongoose"));
const MaterialSchema = new mongoose_1.Schema({
    title: { type: String, required: true },
    description: { type: String },
    type: { type: String, enum: ['puzzle', 'word-jumble', 'quiz', 'connection'], required: true },
    content: { type: mongoose_1.Schema.Types.Mixed, required: true },
    author: { type: mongoose_1.Schema.Types.ObjectId, ref: 'User', required: true },
}, { timestamps: true });
exports.default = mongoose_1.default.model('Material', MaterialSchema);
// puzzle
// {
//     "image": "puzzle-image.jpg",
//     "grid": { "columns": 4, "rows": 4 }
// }
// quiz
// {
//     "questions": [
//     {
//         "text": "Ktorý obrázok zobrazuje Eiffelovu vežu?",
//         "image": "eiffel-question.jpg",
//         "answers": [
//             { "text": "Obrázok 1", "image": "eiffel1.jpg", "correct": false },
//             { "text": "Obrázok 2", "image": "eiffel2.jpg", "correct": true },
//             { "text": "Obrázok 3", "image": "eiffel3.jpg", "correct": false },
//             { "text": "Žiadna z možností", "image": null, "correct": false }
//         ]
//     },
//     {
//         "text": "Ktoré mesto je hlavné mesto Francúzska?",
//         "answers": [
//             { "text": "Paríž", "correct": true },
//             { "text": "Lyon", "correct": false },
//             { "text": "Marseille", "correct": false }
//         ]
//     }
// ]
// }
// word jumble
// {
//     "words": ["pes", "beží", "po", "dome"],
//     "correct_order": ["pes", "beží", "po", "dome"]
// }
// connerctions
// {
//     "pairs": [
//     { "left": "Slon", "right": "🐘" },
//     { "left": "Pes", "right": "🐕" },
//     { "left": "Mačka", "right": "🐈" }
// ]
// }
