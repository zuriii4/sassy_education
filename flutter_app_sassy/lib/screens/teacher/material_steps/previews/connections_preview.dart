import 'package:flutter/material.dart';

class ConnectionsPreview extends StatefulWidget {
  final List<Map<String, String>> pairs;
  final bool isInteractive;
  final Function(Map<String, String> leftItem, String rightItem)? onConnection;
  
  const ConnectionsPreview({
    Key? key,
    required this.pairs,
    this.isInteractive = false,
    this.onConnection,
  }) : super(key: key);

  @override
  State<ConnectionsPreview> createState() => _ConnectionsPreviewState();
}

class _ConnectionsPreviewState extends State<ConnectionsPreview> {
  String? _selectedLeft;
  String? _selectedRight;
  List<Map<String, String>> _connectedPairs = [];
  List<String> _shuffledRightItems = [];
  
  @override
  void initState() {
    super.initState();
    _initializePreview();
  }
  
  @override
  void didUpdateWidget(ConnectionsPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.pairs, widget.pairs)) {
      _initializePreview();
    }
  }
  
  void _initializePreview() {
    if (widget.isInteractive) {
      _connectedPairs = [];
      _shuffledRightItems = widget.pairs.map((pair) => pair['right'] ?? '').toList();
      _shuffledRightItems.shuffle();
    }
  }
  
  bool listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    
    if (T == Map<String, String>) {
      for (int i = 0; i < a.length; i++) {
        final mapA = a[i] as Map<String, String>;
        final mapB = b[i] as Map<String, String>;
        if (mapA['left'] != mapB['left'] || mapA['right'] != mapB['right']) {
          return false;
        }
      }
    } else {
      for (int i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
    }
    
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pairs.isEmpty) {
      return const Center(
        child: Text('Žiadne páry nie sú vytvorené'),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Náhľad spojení',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        widget.isInteractive 
            ? _buildInteractiveConnections() 
            : _buildPreviewConnections(),
        
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
              Text('Počet párov: ${widget.pairs.length}'),
              if (widget.isInteractive) ...[
                const SizedBox(height: 4),
                Text('Spojené páry: ${_connectedPairs.length}/${widget.pairs.length}'),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildPreviewConnections() {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ľavá strana
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: widget.pairs.map((pair) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    pair['left'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
          ),
          
          CustomPaint(
            size: const Size(40, 300),
            painter: ConnectionPainter(
              pairCount: widget.pairs.length,
              isShuffled: false,
            ),
          ),
          
          // Pravá strana
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: widget.pairs.map((pair) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Text(
                    pair['right'] ?? '',
                    textAlign: TextAlign.right,
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInteractiveConnections() {
    final unconnectedLeftItems = widget.pairs
        .where((pair) => !_connectedPairs.any((connected) => connected['left'] == pair['left']))
        .toList();
    
    final unconnectedRightItems = _shuffledRightItems
        .where((right) => !_connectedPairs.any((connected) => connected['right'] == right))
        .toList();
    
    return Column(
      children: [
        // Už spojené páry
        if (_connectedPairs.isNotEmpty) ...[
          const SizedBox(height: 8),
          const Text(
            'Spojené páry:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green),
            ),
            child: Column(
              children: _connectedPairs.map((pair) {
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          pair['left'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Icon(Icons.arrow_forward),
                      Expanded(
                        child: Text(
                          pair['right'] ?? '',
                          textAlign: TextAlign.right,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red, size: 16),
                        onPressed: () {
                          setState(() {
                            _connectedPairs.remove(pair);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Nespojené páry pre interakciu
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ľavá strana
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: unconnectedLeftItems.map((pair) {
                    final isSelected = _selectedLeft == pair['left'];
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedLeft = isSelected ? null : pair['left'];
                          
                          if (_selectedLeft != null && _selectedRight != null) {
                            _createConnection();
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF67E4A).withOpacity(0.2) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFF67E4A) : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          pair['left'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            color: isSelected ? const Color(0xFFF67E4A) : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(width: 20),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: unconnectedRightItems.map((rightItem) {
                    final isSelected = _selectedRight == rightItem;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedRight = isSelected ? null : rightItem;
                          
                          if (_selectedLeft != null && _selectedRight != null) {
                            _createConnection();
                          }
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF67E4A).withOpacity(0.2) : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFF67E4A) : Colors.grey,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          rightItem,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFFF67E4A) : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  void _createConnection() {
    final leftPair = widget.pairs.firstWhere(
      (pair) => pair['left'] == _selectedLeft,
      orElse: () => {'left': '', 'right': ''},
    );
    
    if (leftPair['left']!.isNotEmpty) {
      setState(() {
        _connectedPairs.add({
          'left': _selectedLeft!,
          'right': _selectedRight!,
        });
        
        // Resetujeme výber
        _selectedLeft = null;
        _selectedRight = null;
        
        if (widget.onConnection != null) {
          widget.onConnection!(leftPair, _selectedRight!);
        }
      });
    }
  }
}

class ConnectionPainter extends CustomPainter {
  final int pairCount;
  final bool isShuffled;
  
  ConnectionPainter({
    required this.pairCount,
    this.isShuffled = true,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (pairCount == 0) return;
    
    final paint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    final itemHeight = size.height / pairCount;
    
    for (int i = 0; i < pairCount; i++) {
      final startY = i * itemHeight + itemHeight / 2;
      
      if (!isShuffled) {
        final endY = startY;
        canvas.drawLine(
          Offset(0, startY),
          Offset(size.width, endY),
          paint,
        );
      } else {
        final endY = (i + 1) % pairCount * itemHeight + itemHeight / 2;
        canvas.drawLine(
          Offset(0, startY),
          Offset(size.width, endY),
          paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is ConnectionPainter) {
      return oldDelegate.pairCount != pairCount || 
             oldDelegate.isShuffled != isShuffled;
    }
    return true;
  }
}