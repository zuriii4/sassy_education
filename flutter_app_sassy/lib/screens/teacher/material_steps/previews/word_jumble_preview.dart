import 'package:flutter/material.dart';
import 'dart:math';

class WordJumblePreview extends StatefulWidget {
  final List<String> words;
  final List<String> correctOrder;
  final bool isInteractive;
  final Function(List<String>)? onReordered;
  
  const WordJumblePreview({
    Key? key,
    required this.words,
    required this.correctOrder,
    this.isInteractive = false,
    this.onReordered,
  }) : super(key: key);

  @override
  State<WordJumblePreview> createState() => _WordJumblePreviewState();
}

class _WordJumblePreviewState extends State<WordJumblePreview> {
  late List<String> _displayedWords;
  
  @override
  void initState() {
    super.initState();
    if (widget.isInteractive) {
      _displayedWords = List<String>.from(widget.words);
      _displayedWords.shuffle();
    } else {
      _displayedWords = List<String>.from(widget.correctOrder);
    }
  }
  
  @override
  void didUpdateWidget(WordJumblePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.words, widget.words) ||
        !listEquals(oldWidget.correctOrder, widget.correctOrder)) {
      if (widget.isInteractive) {
        _displayedWords = List<String>.from(widget.words);
        _displayedWords.shuffle();
      } else {
        _displayedWords = List<String>.from(widget.correctOrder);
      }
    }
  }
  
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.words.isEmpty) {
      return const Center(
        child: Text('Žiadne slová nie sú vytvorené'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Náhľad slovného prešmyčku',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.isInteractive)
              ElevatedButton.icon(
                onPressed: _shuffleWords,
                icon: const Icon(Icons.shuffle),
                label: const Text('Zamiešať'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF67E4A),
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Zobrazenie slov
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey),
          ),
          child: widget.isInteractive
              ? _buildInteractiveWordList()
              : _buildPreviewWordList(),
        ),
        
        const SizedBox(height: 16),
        
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Informácie o úlohe',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Počet slov: ${widget.words.length}'),
              if (!widget.isInteractive) ...[
                const SizedBox(height: 8),
                const Text(
                  'Správne poradie:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(widget.correctOrder.join(' ')),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreviewWordList() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _displayedWords.map((word) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: Text(
            word,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildInteractiveWordList() {
    return ReorderableWrap(
      spacing: 8,
      runSpacing: 12,
      onReorder: (oldIndex, newIndex) {
        setState(() {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          final String item = _displayedWords.removeAt(oldIndex);
          _displayedWords.insert(newIndex, item);
          
          if (widget.onReordered != null) {
            widget.onReordered!(_displayedWords);
          }
        });
      },
      children: _displayedWords.map((word) {
        return Container(
          key: ValueKey(word + Random().nextInt(1000).toString()),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                word,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.drag_handle, size: 16, color: Colors.grey),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  void _shuffleWords() {
    setState(() {
      _displayedWords.shuffle();
      
      if (widget.onReordered != null) {
        widget.onReordered!(_displayedWords);
      }
    });
  }
}

class ReorderableWrap extends StatefulWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final Function(int oldIndex, int newIndex) onReorder;

  const ReorderableWrap({
    Key? key,
    required this.children,
    required this.onReorder,
    this.spacing = 0.0,
    this.runSpacing = 0.0,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
  }) : super(key: key);

  @override
  State<ReorderableWrap> createState() => _ReorderableWrapState();
}

class _ReorderableWrapState extends State<ReorderableWrap> {
  int? _draggedIndex;
  int? _targetIndex;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: widget.spacing,
      runSpacing: widget.runSpacing,
      alignment: widget.alignment,
      runAlignment: widget.runAlignment,
      children: List.generate(widget.children.length, (index) {
        final child = widget.children[index];
        
        return LongPressDraggable<int>(
          data: index,
          dragAnchorStrategy: (draggable, context, position) {
            return const Offset(20, 20);
          },
          feedback: Material(
            elevation: 4.0,
            child: Container(
              padding: const EdgeInsets.all(4.0),
              child: child,
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: child,
          ),
          onDragStarted: () {
            setState(() {
              _draggedIndex = index;
            });
          },
          onDragCompleted: () {
            setState(() {
              _draggedIndex = null;
            });
          },
          onDraggableCanceled: (_, __) {
            setState(() {
              _draggedIndex = null;
            });
          },
          child: DragTarget<int>(
            builder: (context, candidateData, rejectedData) {
              return _targetIndex == index && _draggedIndex != null
                  ? Container(
                      margin: const EdgeInsets.all(4.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      width: 8,
                      height: 30,
                    )
                  : child;
            },
            onWillAccept: (data) => data != index,
            onAccept: (draggedIndex) {
              widget.onReorder(draggedIndex, index);
              setState(() {
                _targetIndex = null;
              });
            },
            onMove: (details) {
              setState(() {
                _targetIndex = index;
              });
            },
            onLeave: (_) {
              setState(() {
                _targetIndex = null;
              });
            },
          ),
        );
      }),
    );
  }
}