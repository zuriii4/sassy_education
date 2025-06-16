import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PuzzleWorkspace extends StatefulWidget {
  final String imagePath;
  final int rows;
  final int columns;
  final String materialId;
  final Function(List<int>, int) onPuzzleSolved;

  const PuzzleWorkspace({
    Key? key,
    required this.imagePath,
    required this.rows,
    required this.columns,
    required this.materialId,
    required this.onPuzzleSolved,
  }) : super(key: key);

  @override
  State<PuzzleWorkspace> createState() => _PuzzleWorkspaceState();
}

class _PuzzleWorkspaceState extends State<PuzzleWorkspace> {
  final ApiService _apiService = ApiService();
  Uint8List? _imageBytes;
  bool _isLoading = true;
  String? _errorMessage;
  
  List<PuzzleTile>? _tiles;
  List<int>? _currentArrangement;
  List<int>? _correctArrangement;
  bool _puzzleSolved = false;
  
  final int _startTime = DateTime.now().millisecondsSinceEpoch;
  int _timeSpent = 0;
  
  @override
  void initState() {
    super.initState();
    _loadImage();
    
    _startTimer();
  }
  
  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && !_puzzleSolved) {
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

  Future<void> _loadImage() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final imageData = await _apiService.getImageBytes(widget.imagePath);
      
      if (imageData == null) {
        throw Exception('Nepodarilo sa načítať obrázok');
      }
      
      setState(() {
        _imageBytes = imageData;
        _isLoading = false;
      });
      
      _processImage(imageData);
    } catch (e) {
      setState(() {
        _errorMessage = 'Chyba pri načítaní obrázka: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _processImage(Uint8List imageBytes) async {
    try {
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) throw Exception("Nepodarilo sa dekódovať obrázok");
      
      await _sliceImage(decoded);
    } catch (e) {
      setState(() {
        _errorMessage = 'Chyba pri spracovaní obrázka: ${e.toString()}';
      });
    }
  }
  
  Future<void> _sliceImage(img.Image decoded) async {
    final tileWidth = (decoded.width / widget.columns).floor();
    final tileHeight = (decoded.height / widget.rows).floor();
    List<PuzzleTile> pieces = [];
    final correctOrder = List<int>.generate(widget.rows * widget.columns, (i) => i);

    for (int i = 0; i < widget.rows * widget.columns; i++) {
      final row = i ~/ widget.columns;
      final col = i % widget.columns;
      final piece = img.copyCrop(
        decoded,
        x: col * tileWidth,
        y: row * tileHeight,
        width: tileWidth,
        height: tileHeight,
      );
      final encoded = img.encodePng(piece);
      pieces.add(PuzzleTile(id: i, imageBytes: Uint8List.fromList(encoded)));
    }

    final shuffledIndices = List<int>.generate(pieces.length, (i) => i)..shuffle();

    setState(() {
      _tiles = pieces;
      _currentArrangement = shuffledIndices;
      _correctArrangement = correctOrder;
      _puzzleSolved = false;
    });
  }
  
  void _reshufflePuzzle() {
    if (_tiles == null) return;
    
    setState(() {
      _currentArrangement = List<int>.generate(_tiles!.length, (i) => i)..shuffle();
      _puzzleSolved = false;
    });
  }
  
  void _checkSolution() {
    if (_currentArrangement == null || _correctArrangement == null) return;
    
    bool solved = true;
    for (int i = 0; i < _currentArrangement!.length; i++) {
      if (_currentArrangement![i] != _correctArrangement![i]) {
        solved = false;
        break;
      }
    }
    
    if (solved && !_puzzleSolved) {
      setState(() {
        _puzzleSolved = true;
        _timeSpent = DateTime.now().millisecondsSinceEpoch - _startTime;
      });
      
      _showCongratulationsDialog();
      
    }
  }
  
  void _showCongratulationsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Výborne!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stars,
              color: Colors.amber,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'Úspešne si vyriešil/a puzzle!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                
                widget.onPuzzleSolved(_currentArrangement!, _timeSpent);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('Super!', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
  
  void _swapTiles(int oldIndex, int newIndex) {
    if (_currentArrangement == null || _puzzleSolved) return;
    
    setState(() {
      final temp = _currentArrangement![oldIndex];
      _currentArrangement![oldIndex] = _currentArrangement![newIndex];
      _currentArrangement![newIndex] = temp;
    });
    
    _checkSolution();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Načítavam puzzle...'),
          ],
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Center(
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
              onPressed: _loadImage,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Skúsiť znova'),
            ),
          ],
        ),
      );
    }
    
    if (_tiles == null) {
      return const Center(child: Text('Pripravujem puzzle...'));
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isLandscape = constraints.maxWidth > constraints.maxHeight;
        final bool isLargeScreen = constraints.maxWidth > 900;
        
        return isLargeScreen
            ? _buildLargeScreenLayout(constraints)
            : isLandscape 
                ? _buildLandscapeLayout(constraints)
                : _buildPortraitLayout(constraints);
      },
    );
  }
  
  Widget _buildLargeScreenLayout(BoxConstraints constraints) {
    final maxGridSize = constraints.maxHeight * 0.75;
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ľavý panel s informáciami
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoPanel(),
                const SizedBox(height: 24),
                
                // Preview obrázka
                if (_imageBytes != null) ...[
                  const Text(
                    'Referenčný obrázok:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _imageBytes!,
                      height: constraints.maxHeight * 0.4,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
                
                const Spacer(),
                
                // Inštrukcie a stav dokončenia
                _puzzleSolved
                    ? _buildCompletionMessage()
                    : _buildInstructionsPanel(),
              ],
            ),
          ),
        ),
        
        // Pravý panel s puzzle hrou
        Expanded(
          flex: 7,
          child: Container(
            alignment: Alignment.center,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: maxGridSize,
                maxHeight: maxGridSize,
              ),
              child: Card(
                elevation: 4,
                margin: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _buildPuzzleGrid(),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildLandscapeLayout(BoxConstraints constraints) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ľavý panel s informáciami
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoPanel(),
                const Spacer(),
                _puzzleSolved
                    ? _buildCompletionMessage()
                    : _buildInstructionsPanel(),
              ],
            ),
          ),
        ),
        
        // Pravý panel s puzzle
        Expanded(
          flex: 5,
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: _buildPuzzleGrid(),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildPortraitLayout(BoxConstraints constraints) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Informačný panel
          _buildInfoPanel(),
          
          // Puzzle grid - hlavná časť
          Expanded(
            child: Center(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth * 0.9,
                  maxHeight: constraints.maxHeight * 0.7,
                ),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _buildPuzzleGrid(),
                ),
              ),
            ),
          ),
          
          _puzzleSolved
              ? _buildCompletionMessage()
              : _buildInstructionsPanel(),
        ],
      ),
    );
  }
  
  // Informačný panel s časom a tlačidlami
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Informácie o puzzle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Puzzle ${widget.rows}x${widget.columns}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Čas: ${_formatTime(_timeSpent)}',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
          
          // Tlačidlá akcií
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tlačidlo pre zobrazenie celého obrázka
              if (_imageBytes != null)
                Tooltip(
                  message: 'Ukázať celý obrázok',
                  child: InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => Dialog(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12),
                                ),
                                child: Image.memory(
                                  _imageBytes!,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Zavrieť'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.image,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              
              // Tlačidlo pre zamiešanie puzzle
              if (!_puzzleSolved)
                Tooltip(
                  message: 'Zamiešať puzzle',
                  child: InkWell(
                    onTap: _reshufflePuzzle,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.shuffle,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
  
  // Grid s puzzle dielikmi
  Widget _buildPuzzleGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double tileSize = constraints.maxWidth / widget.columns < constraints.maxHeight / widget.rows
            ? constraints.maxWidth / widget.columns
            : constraints.maxHeight / widget.rows;
            
        return Container(
          padding: const EdgeInsets.all(12),
          child: Center(
            child: SizedBox(
              width: tileSize * widget.columns,
              height: tileSize * widget.rows,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _tiles!.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: widget.columns,
                  mainAxisSpacing: 2,
                  crossAxisSpacing: 2,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final tileIndex = _currentArrangement![index];
                  return SizedBox(
                    width: tileSize,
                    height: tileSize,
                    child: DragTarget<int>(
                      onAccept: (draggedIndex) {
                        _swapTiles(draggedIndex, index);
                      },
                      builder: (context, candidateData, rejectedData) {
                        return Draggable<int>(
                          data: index,
                          feedback: SizedBox(
                            width: tileSize,
                            height: tileSize,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Image.memory(
                                _tiles![tileIndex].imageBytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          childWhenDragging: Container(
                            width: tileSize,
                            height: tileSize,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              border: Border.all(
                                color: Colors.grey.shade400,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          child: Container(
                            width: tileSize,
                            height: tileSize,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: candidateData.isNotEmpty 
                                  ? Colors.blue.shade400 
                                  : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              boxShadow: candidateData.isNotEmpty 
                                ? [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 4,
                                      spreadRadius: 2,
                                    ),
                                  ] 
                                : null,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: Image.memory(
                                _tiles![tileIndex].imageBytes,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInstructionsPanel() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Presúvaj dieliky ťahaním na správne miesta a poskladaj obrázok.',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCompletionMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              'Výborne! Puzzle vyriešené za ${_formatTime(_timeSpent)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class PuzzleTile {
  final int id;
  final Uint8List imageBytes;

  PuzzleTile({
    required this.id,
    required this.imageBytes,
  });
}