import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/form_fields.dart';


class QuizPreview extends StatefulWidget {
  final List<Map<String, dynamic>> questions;
  final ApiService apiService;
  final bool isInteractive;
  final Function(int, int)? onAnswerSelected;
  
  const QuizPreview({
    Key? key,
    required this.questions,
    required this.apiService,
    this.isInteractive = false,
    this.onAnswerSelected,
  }) : super(key: key);

  @override
  State<QuizPreview> createState() => _QuizPreviewState();
}

class _QuizPreviewState extends State<QuizPreview> {
  final Map<int, int> _selectedAnswers = {};
  
  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return const Center(
        child: Text('Žiadne otázky nie sú vytvorené'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Náhľad kvízu',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Zobrazenie otázok
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.questions.length,
          itemBuilder: (context, questionIndex) {
            final question = widget.questions[questionIndex];
            final answers = List<Map<String, dynamic>>.from(question['answers'] ?? []);
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Otázka ${questionIndex + 1}: ${question['text']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    
                    if (question.containsKey('image') && question['image'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: NetworkImageFromBytes(
                                imagePath: question['image'],
                                apiService: widget.apiService,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 12),
                    
                    // Zobrazenie odpovedí
                    if (answers.isEmpty)
                      const Text('Žiadne odpovede nie sú vytvorené'),
                    ...answers.asMap().entries.map((entry) {
                      final answerIndex = entry.key;
                      final answer = entry.value;
                      final isSelected = _selectedAnswers[questionIndex] == answerIndex;
                      
                      return GestureDetector(
                        onTap: widget.isInteractive ? () => _selectAnswer(questionIndex, answerIndex) : null,
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: isSelected 
                              ? widget.isInteractive 
                                  ? const Color(0xFFF67E4A).withOpacity(0.2) 
                                  : Colors.grey[50]
                              : Colors.grey[50],
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    if (!widget.isInteractive)
                                      Icon(
                                        answer['correct'] ? Icons.check_circle : Icons.cancel,
                                        color: answer['correct'] ? Colors.green : Colors.red,
                                        size: 16,
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        answer['text'],
                                        style: TextStyle(
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                
                                // Zobrazenie obrázka odpovede
                                if (answer.containsKey('image') && answer['image'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8.0, left: 24.0),
                                    child: Container(
                                      height: 80,
                                      width: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: NetworkImageFromBytes(
                                        imagePath: answer['image'].toString(),
                                        apiService: widget.apiService,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  void _selectAnswer(int questionIndex, int answerIndex) {
    if (!widget.isInteractive) return;
    
    setState(() {
      _selectedAnswers[questionIndex] = answerIndex;
    });
    
    if (widget.onAnswerSelected != null) {
      widget.onAnswerSelected!(questionIndex, answerIndex);
    }
  }
}