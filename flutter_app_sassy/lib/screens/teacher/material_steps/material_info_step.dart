import 'package:flutter/material.dart';
import 'package:sassy/models/material.dart';
import 'package:sassy/widgets/form_fields.dart';

class TaskInfoStep extends StatefulWidget {
  final TaskModel taskModel;
  
  const TaskInfoStep({Key? key, required this.taskModel}) : super(key: key);
  
  @override
  State<TaskInfoStep> createState() => _TaskInfoStepState();
}

class _TaskInfoStepState extends State<TaskInfoStep> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  bool _isTitleValid = true;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.taskModel.title ?? '');
    _descriptionController = TextEditingController(text: widget.taskModel.description ?? '');
    
    _titleController.addListener(() {
      setState(() {
        _isTitleValid = _titleController.text.isNotEmpty;
        widget.taskModel.title = _titleController.text;
      });
    });
    
    _descriptionController.addListener(() {
      widget.taskModel.description = _descriptionController.text;
    });
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Základné informácie o úlohe',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF67E4A),
              ),
            ),
            const SizedBox(height: 30),
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Názov úlohy',
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '*',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Zadajte názov úlohy',
                    filled: true,
                    fillColor: const Color(0xFFF4F4F4),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    errorText: !_isTitleValid ? 'Názov úlohy je povinný' : null,
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            FormTextField(
              label: 'Popis úlohy',
              placeholder: 'Zadajte popis úlohy',
              controller: _descriptionController,
              keyboardType: TextInputType.multiline,
            ),
          ],
        ),
      ),
    );
  }
}