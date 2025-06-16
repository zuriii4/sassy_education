import 'package:flutter/material.dart';
import 'package:sassy/models/material.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/screens/teacher/material_steps/previews/quiz_preview.dart';

class QuizContent extends StatefulWidget {
  final TaskModel taskModel;
  
  const QuizContent({Key? key, required this.taskModel}) : super(key: key);

  @override
  State<QuizContent> createState() => _QuizContentState();
}

class _QuizContentState extends State<QuizContent> {
  final List<Map<String, dynamic>> _questions = [];
  final TextEditingController _questionController = TextEditingController();
  String? _questionImagePath;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    if (widget.taskModel.content.containsKey('questions')) {
      _questions.addAll(List<Map<String, dynamic>>.from(widget.taskModel.content['questions']));
    } else {
      widget.taskModel.content['questions'] = _questions;
    }
  }

  void _addQuestion() {
    if (_questionController.text.isEmpty) return;
    
    setState(() {
      final newQuestion = {
        'text': _questionController.text,
        'answers': [],
        if (_questionImagePath != null) 'image': _questionImagePath,
      };
      
      _questions.add(newQuestion);
      widget.taskModel.content['questions'] = _questions;
      
      // Reset fields
      _questionController.clear();
      _questionImagePath = null;
    });
  }

  void _addAnswer(int questionIndex) {
    final TextEditingController answerController = TextEditingController();
    bool isCorrect = false;
    String? answerImagePath;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final double screenWidth = MediaQuery.of(dialogContext).size.width;
          final double dialogWidth = screenWidth > 600 ? 500 : screenWidth * 0.8;
          
          return AlertDialog(
            title: const Text('Pridať odpoveď'),
            content: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FormTextField(
                      label: 'Text odpovede',
                      placeholder: 'Zadajte text odpovede',
                      controller: answerController,
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Správna odpoveď'),
                      value: isCorrect,
                      onChanged: (value) {
                        setDialogState(() {
                          isCorrect = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: dialogWidth - 32,
                      ),
                      child: FormImagePicker(
                        label: 'Obrázok odpovede',
                        onImagePathSelected: (path) {
                          setDialogState(() {
                            answerImagePath = path;
                          });
                        },
                        initialImagePath: answerImagePath,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Zrušiť'),
              ),
              TextButton(
                onPressed: () {
                  if (answerController.text.isNotEmpty) {

                    final Map<String, dynamic> answer = {
                      'text': answerController.text,
                      'correct': isCorrect,
                    };
                    
                    if (answerImagePath != null) {
                      answer['image'] = answerImagePath;
                    }
                    

                    Navigator.of(dialogContext).pop();
                    

                    setState(() {
                      if (_questions[questionIndex]['answers'] == null) {
                        _questions[questionIndex]['answers'] = [];
                      }
                      _questions[questionIndex]['answers'].add(answer);
                      

                      widget.taskModel.content['questions'] = _questions;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prosím, zadajte text odpovede')),
                    );
                  }
                },
                child: const Text('Pridať'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
      widget.taskModel.content['questions'] = _questions;
    });
  }

  void _onQuestionImageSelected(String path) {
    setState(() {
      _questionImagePath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vytvorenie kvízu',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF67E4A),
              ),
            ),
            const SizedBox(height: 20),
            
            // Pridanie novej otázky
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nová otázka',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FormTextField(
                      label: 'Text otázky',
                      placeholder: 'Zadajte text otázky',
                      controller: _questionController,
                    ),
                    const SizedBox(height: 16),
                    
                    FormImagePicker(
                      label: 'Obrázok otázky',
                      onImagePathSelected: _onQuestionImageSelected,
                      initialImagePath: _questionImagePath,
                    ),
                    
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF67E4A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Pridať otázku'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_questions.isNotEmpty) ...[
              _buildQuestionList(),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Zatiaľ nie sú pridané žiadne otázky',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuestionList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Existujúce otázky',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _questions.length,
          itemBuilder: (context, index) {
            final question = _questions[index];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: Text(
                      'Otázka ${index + 1}: ${question['text']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Color(0xFFF67E4A)),
                          onPressed: () => _addAnswer(index),
                          tooltip: 'Pridať odpoveď',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeQuestion(index),
                          tooltip: 'Odstrániť otázku',
                        ),
                      ],
                    ),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: QuizPreview(
                      questions: [question],
                      apiService: _apiService,
                      isInteractive: false,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        const SizedBox(height: 32),
        const Text(
          'Náhľad celého kvízu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: QuizPreview(
              questions: _questions,
              apiService: _apiService,
              isInteractive: false,
            ),
          ),
        ),
      ],
    );
  }
}