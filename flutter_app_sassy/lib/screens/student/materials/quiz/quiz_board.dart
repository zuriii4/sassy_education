import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'dart:typed_data';

class QuizWorkspace extends StatefulWidget {
  final List<dynamic> questions;
  final String materialId;
  final Function(List<Map<String, dynamic>>, int) onQuizCompleted;

  const QuizWorkspace({
    Key? key,
    required this.questions,
    required this.materialId,
    required this.onQuizCompleted,
  }) : super(key: key);

  @override
  State<QuizWorkspace> createState() => _QuizWorkspaceState();
}

class _QuizWorkspaceState extends State<QuizWorkspace> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;

  Map<String, Map<String, dynamic>> _userAnswers = {};
  bool _quizCompleted = false;
  int _currentQuestionIndex = 0;

  final Map<String, Uint8List?> _imageCache = {};

  final int _startTime = DateTime.now().millisecondsSinceEpoch;
  int _timeSpent = 0;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _preloadImages();
    _pageController = PageController(initialPage: 0);

    _initializeAnswers();

    _startTimer();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeAnswers() {
    for (int i = 0; i < widget.questions.length; i++) {
      final question = widget.questions[i];
      final questionId = question['_id'] ?? 'q$i';

      String? correctAnswerId;
      final List<dynamic> answers = question['answers'] ?? [];
      for (var answer in answers) {
        if (answer['correct'] == true) {
          correctAnswerId = answer['_id'] ?? answers.indexOf(answer).toString();
          break;
        }
      }

      _userAnswers[questionId] = {
        'question': question['text'] ?? 'Otázka ${i + 1}',
        'questionId': questionId,
        'answerId': null,
        'answer': null,
        'correctAnswerId': correctAnswerId,
        'isCorrect': false,
      };
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _preloadImages() async {
    for (var question in widget.questions) {
      final questionImage = question['image'];
      if (questionImage != null && questionImage.isNotEmpty) {
        try {
          final bytes = await _apiService.getImageBytes(questionImage);
          _imageCache[questionImage] = bytes;
        } catch (e) {
          print('Error preloading question image: $e');
        }
      }

      final List<dynamic> answersData = question['answers'] ?? [];
      for (var answer in answersData) {
        final answerImage = answer['image'];
        if (answerImage != null && answerImage.isNotEmpty) {
          try {
            final bytes = await _apiService.getImageBytes(answerImage);
            _imageCache[answerImage] = bytes;
          } catch (e) {
            print('Error preloading answer image: $e');
          }
        }
      }
    }
  }

  Widget buildImageWidget(String? imagePath, {double height = 150}) {
    if (imagePath == null || imagePath.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_imageCache.containsKey(imagePath) && _imageCache[imagePath] != null) {
      return Container(
        height: height,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            _imageCache[imagePath]!,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: FutureBuilder<Uint8List?>(
        future: _loadAndCacheImage(imagePath),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
            );
          } else {
            return ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                snapshot.data!,
                fit: BoxFit.contain,
              ),
            );
          }
        },
      ),
    );
  }

  Future<Uint8List?> _loadAndCacheImage(String imagePath) async {
    try {
      final bytes = await _apiService.getImageBytes(imagePath);
      _imageCache[imagePath] = bytes;
      return bytes;
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_quizCompleted) {
        setState(() {
          _timeSpent = DateTime.now().millisecondsSinceEpoch - _startTime;
        });
        _startTimer();
      }
    });
  }

  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  bool _areAllQuestionsAnswered() {
    return _userAnswers.values.every((answer) => answer['answerId'] != null);
  }

  int _getCorrectAnswersCount() {
    return _userAnswers.values.where((answer) => answer['isCorrect'] == true).length;
  }

  void _submitQuiz() {
    setState(() {
      _quizCompleted = true;
      _timeSpent = DateTime.now().millisecondsSinceEpoch - _startTime;
    });

    List<Map<String, dynamic>> answerList = _userAnswers.values.map((answer) {
      answer['timeSpent'] = _timeSpent;
      answer['completed'] = true;
      return Map<String, dynamic>.from(answer);
    }).toList();

    _showQuizResultDialog(answerList);
  }

  void _showQuizResultDialog(List<Map<String, dynamic>> answerList) {
    final correctCount = _getCorrectAnswersCount();
    final totalCount = widget.questions.length;
    final percentScore = (correctCount / totalCount * 100).round();
    final perfectScore = correctCount == totalCount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(perfectScore ? 'Výborne!' : 'Kvíz dokončený'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              perfectScore ? Icons.emoji_events : Icons.check_circle_outline,
              color: perfectScore ? Colors.amber : Colors.green,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              perfectScore
                  ? 'Úspešne si dokončil/a kvíz bez chyby!'
                  : 'Úspešne si dokončil/a kvíz!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Tvoje skóre: $correctCount/$totalCount ($percentScore%)',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Čas: ${_formatTime(_timeSpent)}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                widget.onQuizCompleted(answerList, _timeSpent);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Dokončiť', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _goToNextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                },
                child: const Text('Skúsiť znova'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Informačný panel
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Text(
                'Otázka ${_currentQuestionIndex + 1}/${widget.questions.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Čas: ${_formatTime(_timeSpent)}',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.questions.length,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        // Obsah kvízu
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(), 
            onPageChanged: (index) {
              setState(() {
                _currentQuestionIndex = index;
              });
            },
            itemCount: widget.questions.length,
            itemBuilder: (context, index) {
              if (index < 0 || index >= widget.questions.length) {
                return const Center(child: Text('Chyba: Otázka nenájdená'));
              }

              final question = widget.questions[index];
              final questionId = question['_id'] ?? 'q$index';
              final questionImage = question['image'];
              final answersData = question['answers'] ?? [];

              if (!_userAnswers.containsKey(questionId)) {
                return const Center(child: Text('Chyba pri načítaní otázky'));
              }

              final userAnswer = _userAnswers[questionId]!;
              final answeredId = userAnswer['answerId'];
              final isAnswered = answeredId != null;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text otázky
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              question['text'] ?? 'Otázka ${index + 1}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            if (questionImage != null && questionImage.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              buildImageWidget(questionImage, height: 200),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Text o výbere odpovede
                    Text(
                      isAnswered ? 'Vaša odpoveď:' : 'Vyberte správnu odpoveď:',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Možnosti odpovedí
                    ...List.generate(answersData.length, (answerIndex) {
                      final answer = answersData[answerIndex];
                      final answerId = answer['_id'] ?? answerIndex.toString();
                      final answerText = answer['text'] ?? 'Odpoveď ${answerIndex + 1}';
                      final answerImage = answer['image'];
                      final isCorrect = answerId == userAnswer['correctAnswerId'];
                      final isSelected = answerId == answeredId;

                      Color? cardColor;
                      if (isAnswered) {
                        if (isSelected && isCorrect) {
                          cardColor = Colors.green.shade100;
                        } else if (isSelected && !isCorrect) {
                          cardColor = Colors.red.shade100;
                        } else if (isCorrect) {
                          cardColor = Colors.green.shade50;
                        }
                      } else if (isSelected) {
                        cardColor = Colors.blue.shade100;
                      }

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: isSelected
                              ? BorderSide(color: isCorrect ? Colors.green : Colors.red, width: 2)
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: isAnswered
                              ? null
                              : () {
                            setState(() {
                              _userAnswers[questionId]!['answerId'] = answerId;
                              _userAnswers[questionId]!['answer'] = answerText;
                              _userAnswers[questionId]!['isCorrect'] = isCorrect;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Indikátor výberu
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? (isCorrect ? Colors.green : Colors.red)
                                              : Colors.grey,
                                          width: 2,
                                        ),
                                        color: isSelected ? Colors.white : null,
                                      ),
                                      child: isSelected
                                          ? Icon(
                                        isAnswered
                                            ? (isCorrect ? Icons.check : Icons.close)
                                            : Icons.circle,
                                        size: 16,
                                        color: isAnswered
                                            ? (isCorrect ? Colors.green : Colors.red)
                                            : Colors.blue,
                                      )
                                          : null,
                                    ),

                                    const SizedBox(width: 12),

                                    // Text odpovede
                                    Expanded(
                                      child: Text(
                                        answerText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Obrázok odpovede (ak existuje)
                                if (answerImage != null && answerImage.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 36.0),
                                    child: buildImageWidget(answerImage, height: 120),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),

        // Navigačné tlačidlá
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Tlačidlo Predchádzajúca
              ElevatedButton.icon(
                onPressed: _currentQuestionIndex > 0
                    ? _goToPreviousQuestion
                    : null,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Späť'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade700,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
              ),

              // Tlačidlo Ďalej alebo Dokončiť
              if (_currentQuestionIndex < widget.questions.length - 1)
                ElevatedButton.icon(
                  onPressed: _goToNextQuestion,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Ďalej'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: _areAllQuestionsAnswered() ? _submitQuiz : null,
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Dokončiť'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}