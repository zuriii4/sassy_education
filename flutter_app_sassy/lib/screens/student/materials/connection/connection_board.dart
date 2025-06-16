import 'package:flutter/material.dart';
import 'dart:async';

class ConnectionWorkspace extends StatefulWidget {
  final List<ConnectionPair> pairs;
  final Color primaryColor;
  final Color secondaryColor;
  final String instruction;
  final Function(bool, int)? onCompleted;

  const ConnectionWorkspace({
    Key? key,
    required this.pairs,
    this.primaryColor = const Color(0xFF5D69BE),
    this.secondaryColor = const Color(0xFF42A5F5),
    this.instruction = 'Spoj k sebe zodpovedajúce položky:',
    this.onCompleted,
  }) : super(key: key);

  @override
  State<ConnectionWorkspace> createState() => _ConnectionWorkspaceState();
}

class _ConnectionWorkspaceState extends State<ConnectionWorkspace> with SingleTickerProviderStateMixin {
  late List<int> _rightItemsOrder;
  List<Connection> _connections = [];
  int? _selectedLeftIndex;
  int? _selectedRightIndex;
  Offset? _mousePosition;
  List<bool> _leftItemsConnected = [];
  List<bool> _rightItemsConnected = [];

  final int _startTime = DateTime.now().millisecondsSinceEpoch;
  int _timeSpent = 0;
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    _startTimer();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && !_isCompleted) {
        setState(() {
          _timeSpent = DateTime.now().millisecondsSinceEpoch - _startTime;
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
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ConnectionWorkspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pairs != oldWidget.pairs) {
      _initializeGame();
    }
  }

  void _initializeGame() {
    _rightItemsOrder = List.generate(widget.pairs.length, (index) => index)..shuffle();
    _connections = [];
    _selectedLeftIndex = null;
    _selectedRightIndex = null;
    _leftItemsConnected = List.filled(widget.pairs.length, false);
    _rightItemsConnected = List.filled(widget.pairs.length, false);
    for (var pair in widget.pairs) {
      pair.isConnected = false;
    }
  }

  void _selectLeftItem(int index) {
    if (_leftItemsConnected[index]) return;

    setState(() {
      _selectedLeftIndex = index;

      if (_selectedRightIndex != null) {
        _createConnection();
      }
    });
  }

  void _selectRightItem(int index) {
    if (_rightItemsConnected[index]) return;

    setState(() {
      _selectedRightIndex = index;

      if (_selectedLeftIndex != null) {
        _createConnection();
      }
    });
  }

  void _createConnection() {
    final leftIndex = _selectedLeftIndex!;
    final rightIndex = _selectedRightIndex!;
    final rightItemIndex = _rightItemsOrder[rightIndex];

    final isCorrect = widget.pairs[leftIndex].right == widget.pairs[rightItemIndex].right;

    setState(() {
      _connections.add(Connection(
        leftIndex: leftIndex,
        rightIndex: rightIndex,
        isCorrect: isCorrect,
      ));

      _leftItemsConnected[leftIndex] = true;
      _rightItemsConnected[rightIndex] = true;
      widget.pairs[leftIndex].isConnected = true;

      _selectedLeftIndex = null;
      _selectedRightIndex = null;
    });

    if (_connections.length == widget.pairs.length) {
      _checkCompletion();
    }
  }

  void _checkCompletion() {
    final allCorrect = _connections.every((connection) => connection.isCorrect);

    setState(() {
      _isCompleted = true;
      _timer?.cancel();
    });

    _animationController.forward(from: 0.0);

    if (widget.onCompleted != null) {
      widget.onCompleted!(allCorrect, _timeSpent);
    }
  }

  void _removeConnection(int index) {
    if (_isCompleted) return;

    final connection = _connections[index];

    setState(() {
      _leftItemsConnected[connection.leftIndex] = false;
      _rightItemsConnected[connection.rightIndex] = false;
      widget.pairs[connection.leftIndex].isConnected = false;

      _connections.removeAt(index);
    });
  }

  void _updateMousePosition(PointerEvent event) {
    setState(() {
      _mousePosition = event.localPosition;
    });
  }

  void _resetGame() {
    setState(() {
      _initializeGame();
      _isCompleted = false;
      _startTimer();
    });
  }

  Widget _buildItem({
    required String text,
    required bool isConnected,
    required bool isSelected,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isConnected
              ? Colors.grey.shade400
              : isSelected
                  ? backgroundColor?.withOpacity(0.7)
                  : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isConnected || isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
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
      child: Column(
        children: [
          // Header s info
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
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
                    Icons.connect_without_contact,
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: widget.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Spojené: ${_connections.length}/${widget.pairs.length}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Čas: ${_formatTime(_timeSpent)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_isCompleted)
                  Tooltip(
                    message: 'Resetovať',
                    child: IconButton(
                      onPressed: _resetGame,
                      icon: Icon(
                        Icons.refresh,
                        color: widget.secondaryColor,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return MouseRegion(
                  onHover: _updateMousePosition,
                  child: Listener(
                    onPointerMove: _updateMousePosition,
                    child: Stack(
                      children: [
                        CustomPaint(
                          size: Size(constraints.maxWidth, constraints.maxHeight),
                          painter: EnhancedConnectionLinesPainter(
                            connections: _connections,
                            leftItemsPositions: List.generate(
                              widget.pairs.length,
                              (i) => Offset(
                                150, // Item width
                                i * 70 + 35,
                              ),
                            ),
                            rightItemsPositions: List.generate(
                              widget.pairs.length,
                              (i) => Offset(
                                constraints.maxWidth - 150,
                                i * 70 + 35,
                              ),
                            ),
                            correctLineColor: Colors.green.shade400,
                            incorrectLineColor: Colors.red.shade300,
                            lineWidth: 3,
                          ),
                        ),

                        if (!_isCompleted && (_selectedLeftIndex != null || _selectedRightIndex != null))
                          CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: ActiveConnectionLinePainter(
                              leftIndex: _selectedLeftIndex,
                              rightIndex: _selectedRightIndex,
                              leftItemsPositions: List.generate(
                                widget.pairs.length,
                                (i) => Offset(150, i * 70 + 35),
                              ),
                              rightItemsPositions: List.generate(
                                widget.pairs.length,
                                (i) => Offset(constraints.maxWidth - 150, i * 70 + 35),
                              ),
                              mousePosition: _mousePosition,
                              lineColor: widget.secondaryColor.withOpacity(0.7),
                              lineWidth: 2,
                            ),
                          ),

                        // Tlačítka pro smazání spojení
                        if (!_isCompleted)
                          ...List.generate(
                            _connections.length,
                            (index) {
                              final connection = _connections[index];
                              final leftPos = Offset(
                                150, // Item width
                                connection.leftIndex * 70 + 35,
                              );
                              final rightPos = Offset(
                                constraints.maxWidth - 150,
                                connection.rightIndex * 70 + 35,
                              );
                              final centerPos = Offset(
                                (leftPos.dx + rightPos.dx) / 2,
                                (leftPos.dy + rightPos.dy) / 2,
                              );

                              return Positioned(
                                left: centerPos.dx - 15,
                                top: centerPos.dy - 15,
                                child: GestureDetector(
                                  onTap: () => _removeConnection(index),
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 3,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      connection.isCorrect ? Icons.check : Icons.close,
                                      size: 16,
                                      color: connection.isCorrect ? Colors.green : Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left items
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: List.generate(
                                  widget.pairs.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: _buildItem(
                                      text: widget.pairs[index].left,
                                      isConnected: _leftItemsConnected[index],
                                      isSelected: _selectedLeftIndex == index,
                                      onTap: _isCompleted ? () {} : () => _selectLeftItem(index),
                                      backgroundColor: widget.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Right items
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                children: List.generate(
                                  widget.pairs.length,
                                  (index) => Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    child: _buildItem(
                                      text: widget.pairs[_rightItemsOrder[index]].right,
                                      isConnected: _rightItemsConnected[index],
                                      isSelected: _selectedRightIndex == index,
                                      onTap: _isCompleted ? () {} : () => _selectRightItem(index),
                                      backgroundColor: widget.secondaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isCompleted)
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
                margin: const EdgeInsets.all(16),
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
                      'Vyriešil si túto úlohu za ${_formatTime(_timeSpent)}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                    // Zobrazit skóre
                    const SizedBox(height: 8),
                    Text(
                      'Správnych spojení: ${_connections.where((c) => c.isCorrect).length}/${_connections.length}',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Tlačítko "Dokončiť"
          if (!_isCompleted && _connections.length == widget.pairs.length)
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _checkCompletion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Dokončiť',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class Connection {
  final int leftIndex;
  final int rightIndex;
  final bool isCorrect;

  Connection({
    required this.leftIndex,
    required this.rightIndex,
    required this.isCorrect
  });
}

class EnhancedConnectionLinesPainter extends CustomPainter {
  final List<Connection> connections;
  final List<Offset> leftItemsPositions;
  final List<Offset> rightItemsPositions;
  final Color correctLineColor;
  final Color incorrectLineColor;
  final double lineWidth;

  EnhancedConnectionLinesPainter({
    required this.connections,
    required this.leftItemsPositions,
    required this.rightItemsPositions,
    required this.correctLineColor,
    required this.incorrectLineColor,
    this.lineWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final connection in connections) {
      final leftIndex = connection.leftIndex;
      final rightIndex = connection.rightIndex;

      final startPoint = leftItemsPositions[leftIndex];
      final endPoint = rightItemsPositions[rightIndex];

      final paint = Paint()
        ..color = connection.isCorrect ? correctLineColor : incorrectLineColor
        ..strokeWidth = lineWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final controlPointX = (startPoint.dx + endPoint.dx) / 2;
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);

      path.cubicTo(
        controlPointX, startPoint.dy,
        controlPointX, endPoint.dy,
        endPoint.dx, endPoint.dy
      );

      canvas.drawPath(path, paint);

      final dotPaint = Paint()
        ..color = connection.isCorrect ? correctLineColor : incorrectLineColor
        ..style = PaintingStyle.fill;

      canvas.drawCircle(startPoint, lineWidth + 1, dotPaint);
      canvas.drawCircle(endPoint, lineWidth + 1, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ActiveConnectionLinePainter extends CustomPainter {
  final int? leftIndex;
  final int? rightIndex;
  final List<Offset> leftItemsPositions;
  final List<Offset> rightItemsPositions;
  final Offset? mousePosition;
  final Color lineColor;
  final double lineWidth;

  ActiveConnectionLinePainter({
    required this.leftIndex,
    required this.rightIndex,
    required this.leftItemsPositions,
    required this.rightItemsPositions,
    required this.mousePosition,
    required this.lineColor,
    this.lineWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = lineWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (leftIndex != null && rightIndex != null) {
      final startPoint = leftItemsPositions[leftIndex!];
      final endPoint = rightItemsPositions[rightIndex!];

      final controlPointX = (startPoint.dx + endPoint.dx) / 2;
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);

      path.cubicTo(
        controlPointX, startPoint.dy,
        controlPointX, endPoint.dy,
        endPoint.dx, endPoint.dy
      );

      canvas.drawPath(path, paint);

    } else if (leftIndex != null && mousePosition != null) {
      final startPoint = leftItemsPositions[leftIndex!];

      final controlPointX = (startPoint.dx + mousePosition!.dx) / 2;
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      path.cubicTo(
        controlPointX, startPoint.dy,
        controlPointX, mousePosition!.dy,
        mousePosition!.dx, mousePosition!.dy
      );
      
      canvas.drawPath(path, paint);
      
    } else if (rightIndex != null && mousePosition != null) {
      final startPoint = rightItemsPositions[rightIndex!];
      
      final controlPointX = (startPoint.dx + mousePosition!.dx) / 2;
      final path = Path();
      path.moveTo(startPoint.dx, startPoint.dy);
      path.cubicTo(
        controlPointX, startPoint.dy,
        controlPointX, mousePosition!.dy,
        mousePosition!.dx, mousePosition!.dy
      );
      
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class ConnectionPair {
  final String left;
  final String right;
  bool isConnected;

  ConnectionPair({
    required this.left,
    required this.right,
    this.isConnected = false,
  });
}