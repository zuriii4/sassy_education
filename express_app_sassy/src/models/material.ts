import mongoose, { Schema, Document, Types } from 'mongoose';

export interface IMaterial extends Document {
    title: string;
    description: string;
    type: 'puzzle' | 'word-jumble' | 'quiz' | 'connection';
    content: any;
    author: Types.ObjectId;
}

const MaterialSchema: Schema = new Schema(
    {
        title: { type: String, required: true },
        description: { type: String },
        type: { type: String, enum: ['puzzle', 'word-jumble', 'quiz', 'connection'], required: true },
        content: { type: Schema.Types.Mixed, required: true },
        author: { type: Schema.Types.ObjectId, ref: 'User', required: true },
    },
    { timestamps: true }
);

export default mongoose.model<IMaterial>('Material', MaterialSchema);


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