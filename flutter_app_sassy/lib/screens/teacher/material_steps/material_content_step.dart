import 'package:flutter/material.dart';
import 'package:sassy/models/material.dart';
import 'package:sassy/screens/teacher/material_steps/content/quiz_content.dart';
import 'package:sassy/screens/teacher/material_steps/content/puzzle_content.dart';
import 'package:sassy/screens/teacher/material_steps/content/word_jumble_content.dart';
import 'package:sassy/screens/teacher/material_steps/content/connection_content.dart';

// Základná abstraktná trieda pre obsahové kroky
abstract class TaskContentStep extends StatefulWidget {
  final TaskModel taskModel;
  const TaskContentStep({Key? key, required this.taskModel}) : super(key: key);
}

// Konkrétna implementácia pre typ Quiz
class TaskContentQuizStep extends TaskContentStep {
  const TaskContentQuizStep({Key? key, required TaskModel taskModel})
      : super(key: key, taskModel: taskModel);
  
  @override
  State<TaskContentQuizStep> createState() => _TaskContentQuizStepState();
}

class _TaskContentQuizStepState extends State<TaskContentQuizStep> {
  @override
  void initState() {
    super.initState();
    if (!widget.taskModel.content.containsKey('questions')) {
      widget.taskModel.content['questions'] = [];
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return QuizContent(taskModel: widget.taskModel);
  }
}

class TaskContentPuzzleStep extends TaskContentStep {
  const TaskContentPuzzleStep({Key? key, required TaskModel taskModel})
      : super(key: key, taskModel: taskModel);
  
  @override
  State<TaskContentPuzzleStep> createState() => _TaskContentPuzzleStepState();
}

class _TaskContentPuzzleStepState extends State<TaskContentPuzzleStep> {
  late Map<String, dynamic> _content;

  @override
  void initState() {
    super.initState();

    _content = Map<String, dynamic>.from(widget.taskModel.content);

    if (!_content.containsKey('grid')) {
      _content['grid'] = {
        'columns': 3,
        'rows': 3
      };
    }

    if (!_content.containsKey('image')) {
      _content['image'] = null;
    }

    widget.taskModel.content = _content;
  }
  
  @override
  Widget build(BuildContext context) {
    return PuzzleContent(taskModel: widget.taskModel);
  }
}

class TaskContentWordJumbleStep extends TaskContentStep {
  const TaskContentWordJumbleStep({Key? key, required TaskModel taskModel})
      : super(key: key, taskModel: taskModel);
  
  @override
  State<TaskContentWordJumbleStep> createState() => _TaskContentWordJumbleStepState();
}

class _TaskContentWordJumbleStepState extends State<TaskContentWordJumbleStep> {
  @override
  void initState() {
    super.initState();
    if (widget.taskModel.content.isEmpty) {
      widget.taskModel.content = {
        'words': [],
        'correct_order': []
      };
    } else {
      if (!widget.taskModel.content.containsKey('words')) {
        widget.taskModel.content['words'] = [];
      }
      if (!widget.taskModel.content.containsKey('correct_order')) {
        widget.taskModel.content['correct_order'] = [];
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return WordJumbleContent(taskModel: widget.taskModel);
  }
}

class TaskContentConnectionStep extends TaskContentStep {
  const TaskContentConnectionStep({Key? key, required TaskModel taskModel})
      : super(key: key, taskModel: taskModel);
  
  @override
  State<TaskContentConnectionStep> createState() => _TaskContentConnectionStepState();
}

class _TaskContentConnectionStepState extends State<TaskContentConnectionStep> {
  @override
  void initState() {
    super.initState();
    if (widget.taskModel.content.isEmpty) {
      widget.taskModel.content = {
        'pairs': []
      };
    } else if (!widget.taskModel.content.containsKey('pairs')) {
      widget.taskModel.content['pairs'] = [];
    }
    
    if (widget.taskModel.content.containsKey('pairs') &&
        widget.taskModel.content['pairs'] is List) {
      
      final List pairs = widget.taskModel.content['pairs'];
      
      for (int i = 0; i < pairs.length; i++) {
        if (pairs[i] is! Map<String, dynamic>) {
          pairs[i] = {};
        }
        
        if (!pairs[i].containsKey('left')) {
          pairs[i]['left'] = '';
        }
        if (!pairs[i].containsKey('right')) {
          pairs[i]['right'] = '';
        }
        
        if (!pairs[i].containsKey('leftImage')) {
          pairs[i]['leftImage'] = null;
        }
        if (!pairs[i].containsKey('rightImage')) {
          pairs[i]['rightImage'] = null;
        }
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return ConnectionContent(taskModel: widget.taskModel);
  }
}