import mongoose, {Schema, Types} from "mongoose";
import {IStudent} from "./student";


export interface IGroup extends Document {
    name: string;
    teacher: Types.ObjectId;
    students: Types.ObjectId[];
}

const GroupSchema = new Schema<IGroup>({
    name: { type: String, required: true },
    teacher: { type: Schema.Types.ObjectId,  ref: 'User', required: true },
    students: [{ type: Schema.Types.ObjectId, ref: 'User', required: true }]
})

export const Group = mongoose.model<IGroup>('Group', GroupSchema);