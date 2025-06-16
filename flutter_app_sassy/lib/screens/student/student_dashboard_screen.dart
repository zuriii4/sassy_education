import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sassy/screens/student/material_completion.dart';
import 'package:sassy/services/api_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:math' as math;
import 'package:sassy/widgets/material_card.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<dynamic> _materials = [];
  bool _isLoading = true;
  String? _errorMessage;
  late AnimationController _animationController;
  final Random _random = math.Random();

  late Animation<double> _animation;


  @override
  void initState() {
    super.initState();
    _loadData();

    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(begin: 0, end: 2 * math.pi).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final materialsResult = await _apiService.getStudentMaterials('');

      setState(() {
        _materials = materialsResult;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Nepodarilo sa načítať materiály: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  Color _getRandomPastelColor() {
    final hue = _random.nextInt(360);
    return HSLColor.fromAHSL(1.0, hue.toDouble(), 0.7, 0.8).toColor();
  }

  Color _getColorForType(String type) {
    final color = MaterialUtils.getTypeColor(type);
    return color != Colors.grey ? color : _getRandomPastelColor();
  }

  IconData _getIconForType(String type) {
    return MaterialUtils.getMaterialIcon(type);
  }

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Dnes';
    } else if (difference.inDays == 1) {
      return 'Včera';
    } else if (difference.inDays < 7) {
      return 'Pred ${difference.inDays} dňami';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(244, 231, 219, 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _buildDashboard(),
    );
  }

  Widget _buildErrorState() {
    return ErrorStateWidget(
      errorMessage: _errorMessage!,
      onRetry: _loadData,
    );
  }

  Widget _buildDashboard() {
    return Stack(
      children: [
        // Animované pozadie
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: BackgroundPainter(_animation.value),
              );
            },
          ),
        ),

        // Hlavný obsah
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildWelcomeCard(),
              _buildMaterialsSection(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Tvoje aktivity',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2E2E48),
            ),
          ),
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.orange,
            child: IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _loadData,
              tooltip: 'Obnoviť',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE88D3D), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.purple.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ahoj!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Máš ${_materials.length} ${_getMaterialsText(_materials.length)} na učenie.',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_materials.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MaterialCompletionScreen(
                            material: _materials[0],
                            materialId: _materials[0]['_id'] ?? '',
                          ),
                        ),
                      ).then((_) => _loadData());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF6A3DE8),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text('Začať učenie', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: SvgPicture.asset(
              'assets/img/Sassy.svg',
              height: 100,
              width: 100,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsSection() {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Moje materiály',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E2E48),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _materials.isEmpty
                  ? _buildEmptyState()
                  : _buildMaterialsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      title: 'Zatiaľ nemáš žiadne materiály',
      description: 'Všetky učebné materiály sa zobrazia tu',
      icon: Icons.assignment_outlined,
      buttonText: 'Obnoviť',
      onButtonPressed: _loadData,
    );
  }

  Widget _buildMaterialsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 800
            ? 2
            : 1;

        double childAspectRatio = crossAxisCount == 1 ? 1.3 : 2;
        
        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: childAspectRatio,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _materials.length,
          itemBuilder: (context, index) {
            final material = _materials[index];
            final String materialId = material['_id'] ?? '';
            final String title = material['title'] ?? 'Bez názvu';
            final String description = material['description'] ?? '';
            final String type = material['type'] ?? 'unknown';

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaterialCompletionScreen(
                      material: material,
                      materialId: materialId,
                    ),
                  ),
                ).then((_) => _loadData());
              },
              child: Hero(
                tag: 'material-$materialId',
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: _random.nextDouble() * 10 + 4,
                        offset: Offset(0, _random.nextDouble() * 4 + 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 100,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: _getColorForType(type),
                              ),
                              child: Center(
                                child: Icon(
                                  _getIconForType(type),
                                  size: 48,
                                  color: Colors.white,
                                ),
                              )
                            ),

                            // Štítok pre typ materiálu
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getIconForType(type),
                                      size: 12,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      type.toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Informácie o materiáli
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Názov materiálu
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E2E48),
                                  ),
                                ),
                                const SizedBox(height: 4),

                                // Popis materiálu
                                if (description.isNotEmpty) ...[
                                  Expanded(
                                    child: Text(
                                      description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                ],

                                Text(
                                  'Vytvorené: ${_formatDate(material['createdAt'] ?? DateTime.now().toIso8601String())}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Tlačidlo zobrazenia
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: _getColorForType(type).withOpacity(0.1),
                            border: Border(
                              top: BorderSide(
                                color: _getColorForType(type).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              'ZOBRAZIŤ',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _getColorForType(type),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }
    );
  }

  String _getMaterialsText(int count) {
    if (count == 1) {
      return 'materiál';
    } else if (count > 1 && count < 5) {
      return 'materiály';
    } else {
      return 'materiálov';
    }
  }
}

// Animované pozadie
class BackgroundPainter extends CustomPainter {
  final double animation;

  BackgroundPainter(this.animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.04)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final path = Path();
      final offset = i * 0.5;
      final waveHeight = size.height / 15;

      path.moveTo(0, size.height * 0.3 + math.sin(animation + offset) * waveHeight);

      for (double x = 0; x <= size.width; x += size.width / 20) {
        path.lineTo(
            x,
            size.height * 0.3 + math.sin(animation + offset + x / size.width * 4 * math.pi) * waveHeight
        );
      }

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) => true;
}