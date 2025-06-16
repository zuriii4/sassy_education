import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/form_fields.dart';

class PuzzlePreview extends StatelessWidget {
  final String? imagePath;
  final int gridSize;
  final ApiService apiService;
  final bool isInteractive;
  
  const PuzzlePreview({
    Key? key,
    required this.imagePath,
    required this.gridSize,
    required this.apiService,
    this.isInteractive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePath == null) {
      return const Center(
        child: Text('Nie je vybraný žiadny obrázok'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Náhľad puzzle',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        // Náhľad puzzle s obrázkom a mriežkou
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkImageFromBytes(
                    imagePath: imagePath!,
                    apiService: apiService,
                  ),
                  // Mriežka
                  CustomPaint(
                    painter: GridPainter(
                      size: gridSize,
                    ),
                  ),
                  if (isInteractive)
                    _buildInteractivePuzzlePieces(),
                ],
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Informácie o nastavení
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
                'Aktuálne nastavenie',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Mriežka: $gridSize × $gridSize'),
              const SizedBox(height: 4),
              const Text('Obrázok: Vybraný'),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildInteractivePuzzlePieces() {
    return Container(); // Placeholder
  }
}

class GridPainter extends CustomPainter {
  final int size;
  
  GridPainter({required this.size});
  
  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final cellWidth = canvasSize.width / size;
    final cellHeight = canvasSize.height / size;
    
    // Nakreslenie zvislých čiar
    for (int i = 1; i < size; i++) {
      canvas.drawLine(
        Offset(cellWidth * i, 0),
        Offset(cellWidth * i, canvasSize.height),
        paint,
      );
    }
    
    // Nakreslenie vodorovných čiar
    for (int i = 1; i < size; i++) {
      canvas.drawLine(
        Offset(0, cellHeight * i),
        Offset(canvasSize.width, cellHeight * i),
        paint,
      );
    }
    
    // Nakreslenie vonkajšieho obdĺžnika
    canvas.drawRect(
      Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is GridPainter) {
      return oldDelegate.size != size;
    }
    return true;
  }
}