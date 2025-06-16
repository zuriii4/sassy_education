import 'dart:async';

import 'package:flutter/material.dart';

class WordJumbleWorkspace extends StatefulWidget {
  final List<String> words;
  final List<String> correctOrder;
  final Color primaryColor;
  final Color secondaryColor;
  final String instruction;
  final Function(bool, int)? onCompleted;

  const WordJumbleWorkspace({
    Key? key,
    required this.words,
    required this.correctOrder,
    this.primaryColor = const Color(0xFF5D69BE),
    this.secondaryColor = const Color(0xFF42A5F5),
    this.instruction = 'Poskladaj vetu:',
    this.onCompleted,
  }) : super(key: key);

  @override
  State<WordJumbleWorkspace> createState() => _WordJumbleWorkspaceState();
}

class _WordJumbleWorkspaceState extends State<WordJumbleWorkspace> with SingleTickerProviderStateMixin {
  late List<String> _shuffledWords;
  List<String> _selectedWords = [];
  List<int> _selectedIndices = [];
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _completed = false;
  int _startTime = 0;
  int _elapsedTime = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _shuffledWords = List.from(widget.words)..shuffle();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
    
    _startTime = DateTime.now().millisecondsSinceEpoch;
    _startTimer();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_completed) {
        setState(() {
          _elapsedTime = DateTime.now().millisecondsSinceEpoch - _startTime;
        });
      }
    });
  }
  
  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _onWordTap(String word, int index) {
    if (_selectedWords.contains(word) || _isCorrect) return;
    
    setState(() {
      _selectedWords.add(word);
      _selectedIndices.add(index);
    });
    

    if (_selectedWords.length == widget.correctOrder.length) {
      if (_isCorrect) {
        _animationController.forward(from: 0.0);
        _completed = true;
        _timer?.cancel();
        

        if (widget.onCompleted != null) {
          widget.onCompleted!(true, _elapsedTime);
        }
      }
    }
  }

  void _removeSelectedWord(int index) {
    if (_isCorrect) return;
    
    setState(() {
      _selectedWords.removeAt(index);
      _selectedIndices.removeAt(index);
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedWords.clear();
      _selectedIndices.clear();
      _shuffledWords = List.from(widget.words)..shuffle();
    });
  }

  bool get _isCorrect {
    return _selectedWords.length == widget.correctOrder.length &&
        List.generate(_selectedWords.length,
            (i) => _selectedWords[i] == widget.correctOrder[i])
            .every((e) => e);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.primaryColor.withOpacity(0.05),
            widget.secondaryColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Header s info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: widget.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.sort_by_alpha,
                      color: widget.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.instruction,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: widget.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Čas: ${_formatTime(_elapsedTime)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isCorrect)
                    Tooltip(
                      message: 'Resetovat',
                      child: IconButton(
                        onPressed: _resetSelection,
                        icon: Icon(
                          Icons.refresh,
                          color: widget.secondaryColor,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Shuffled words
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: List.generate(_shuffledWords.length, (index) {
                    final word = _shuffledWords[index];
                    final isUsed = _selectedIndices.contains(index);
                    
                    return AnimatedOpacity(
                      opacity: isUsed ? 0.5 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      child: Material(
                        elevation: isUsed ? 0 : 2,
                        color: isUsed ? Colors.grey.shade200 : widget.secondaryColor,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: isUsed ? null : () => _onWordTap(word, index),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              word,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: isUsed ? Colors.grey.shade600 : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: _isCorrect ? Colors.green : Colors.transparent,
                  width: _isCorrect ? 2 : 0,
                ),
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Tvoja odpoveď:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: widget.primaryColor,
                          ),
                        ),
                        const Spacer(),
                        if (_isCorrect)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 4),
                                Text(
                                  'Správne',
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Selected words display
                    if (_selectedWords.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Text(
                          'Klikni na slová vyššie, aby si vytvoril vetu',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _isCorrect ? Colors.green.withOpacity(0.05) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _isCorrect ? Colors.green.shade200 : Colors.grey.shade300,
                          ),
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: List.generate(_selectedWords.length, (index) {
                            return GestureDetector(
                              onTap: () => _removeSelectedWord(index),
                              child: Chip(
                                label: Text(
                                  _selectedWords[index],
                                  style: TextStyle(
                                    color: _isCorrect ? Colors.green.shade700 : Colors.black87,
                                    fontWeight: _isCorrect ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                backgroundColor: _isCorrect
                                    ? Colors.green.shade50
                                    : widget.secondaryColor.withOpacity(0.1),
                                elevation: 0,
                                side: BorderSide(
                                  color: _isCorrect
                                      ? Colors.green.shade200
                                      : widget.secondaryColor.withOpacity(0.3),
                                ),
                                deleteIcon: _isCorrect
                                    ? null
                                    : const Icon(Icons.close, size: 18),
                                onDeleted: _isCorrect ? null : () => _removeSelectedWord(index),
                              ),
                            );
                          }),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            if (_isCorrect)
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 + 0.2 * _animation.value,
                    child: child,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Colors.amber,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Výborne!',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vyriešil si túto úlohu za ${_formatTime(_elapsedTime)}',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

Color _getColorFromString(dynamic colorStr, Color defaultColor) {
  if (colorStr == null) return defaultColor;
  
  String hexColor = colorStr.toString().replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  
  try {
    return Color(int.parse(hexColor, radix: 16));
  } catch (e) {
    return defaultColor;
  }
}