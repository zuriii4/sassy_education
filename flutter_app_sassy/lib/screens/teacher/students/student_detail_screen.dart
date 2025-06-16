import 'package:flutter/material.dart';
import 'package:sassy/models/student.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/stat_card.dart';
import 'package:sassy/screens/teacher/students/group_detail_screen.dart';
import 'package:sassy/screens/teacher/students/edit_student_screen.dart';
import 'package:intl/intl.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  
  const StudentDetailScreen({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final ApiService _apiService = ApiService();
  late Student _student;
  bool _isLoading = false;
  bool _isLoadingProgress = true;
  bool _isOnline = false;
  Map<String, dynamic>? _progressData;
  String? _progressErrorMessage;

  @override
  void initState() {
    super.initState();
    _student = widget.student;
    _checkOnlineStatus();
    _loadStudentProgress();
  }

  Future<void> _loadStudentProgress() async {
    setState(() {
      _isLoadingProgress = true;
      _progressErrorMessage = null;
    });

    try {
      final progressData = await _apiService.getStudentProgresses(_student.id);
      setState(() {
        _progressData = progressData;
        _isLoadingProgress = false;
      });
    } catch (e) {
      setState(() {
        _progressErrorMessage = e.toString();
        _isLoadingProgress = false;
      });
      print('Error fetching student progress: $e');
    }
  }

  Future<void> _checkOnlineStatus() async {
    try {
      final statusData = await _apiService.getStudentOnlineStatus(_student.id);
      setState(() {
        _isOnline = statusData['isOnline'] ?? false;
      });
    } catch (e) {
      print('Error fetching online status: $e');
    }
  }

  Future<void> _editStudent() async {
    final updatedStudent = await Navigator.push<Student>(
      context,
      MaterialPageRoute(
        builder: (context) => EditStudentScreen(
          student: _student,
        ),
      ),
    );

    if (updatedStudent != null) {
      setState(() {
        _student = updatedStudent;
      });
    }
  }

  Future<void> _deleteStudent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odstrániť študenta'),
        content: Text('Naozaj chcete odstrániť študenta ${_student.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť', style: TextStyle(color: Colors.black38)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Odstrániť', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await _apiService.deleteStudentById(_student.id);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Študent bol odstránený')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nepodarilo sa odstrániť študenta')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: Text(_student.name),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            onPressed: _editStudent, 
            icon: const Icon(Icons.edit, color: Colors.black,),
            tooltip: "Upraviť",
          ),
          IconButton(
            onPressed: _deleteStudent, 
            icon: const Icon(Icons.delete, color: Colors.black,),
            tooltip: "Vymazať",
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Hlavička s informáciami o študentovi
                      _buildStudentHeader(),
                      const SizedBox(height: 24),
                      
                      // Štatistiky
                      _buildStatistics(),
                      const SizedBox(height: 24),
                      
                      // Údaje o progrese
                      _buildProgressSection(),
                      const SizedBox(height: 24),
                      
                      // Skupiny, do ktorých študent patrí
                      _buildGroupsSection(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStudentHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _student.hasSpecialNeeds ? Colors.orange : Colors.blue,
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            if (_isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _student.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _isOnline ? 'Aktívny' : 'Neaktívny',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _isOnline
                        ? Colors.green.shade800
                        : Colors.grey.shade700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_student.hasSpecialNeeds) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _student.needsDescription,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Poznámky: ${_student.notes}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatistics() {
    if (_isLoadingProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Štatistiky',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_progressErrorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Štatistiky',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nepodarilo sa načítať štatistiky: $_progressErrorMessage',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              onPressed: _loadStudentProgress,
              icon: const Icon(Icons.refresh),
              label: const Text('Skúsiť znova'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4A261),
              ),
            ),
          ),
        ],
      );
    }

    final totalAssignments = _progressData?['totalAssignments'] ?? 0;
    final completedAssignments = _progressData?['completedAssignments'] ?? 0;
    
    // Vypočítať priemernú úspešnosť
    double averageScore = 0;
    if (_progressData != null && _progressData!['progresses'] != null) {
      final progresses = _progressData!['progresses'] as List;
      if (progresses.isNotEmpty) {
        int totalScores = 0;
        int validProgressCount = 0;
        
        for (var progress in progresses) {
          if (progress['score'] != null && progress['score'] is num) {
            totalScores += (progress['score'] as num).toInt();
            validProgressCount++;
          }
        }
        
        if (validProgressCount > 0) {
          averageScore = totalScores / validProgressCount;
        }
      }
    }
    final roundedAvgScore = averageScore.round();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Štatistiky',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StatCard(
              count: totalAssignments.toString(),
              label: "Celkové lekcie",
              countColor: Colors.blue,
            ),
            StatCard(
              count: completedAssignments.toString(),
              label: "Dokončené",
              countColor: Colors.green,
            ),
            StatCard(
              count: "$roundedAvgScore%",
              label: "Úspešnosť",
              countColor: _getScoreColor(roundedAvgScore),
            ),
          ],
        ),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green;
    if (score >= 75) return Colors.lightGreen;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
  
  Widget _buildProgressSection() {
    if (_isLoadingProgress) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres študenta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    if (_progressErrorMessage != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres študenta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nepodarilo sa načítať progres: $_progressErrorMessage',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final progresses = _progressData?['progresses'] as List? ?? [];

    // Ak nemáme dáta o progrese
    if (progresses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres študenta',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Žiadne údaje o progrese',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Zoraďme progres podľa dátumu od najnovšieho
    progresses.sort((a, b) {
      final aDate = DateTime.parse(a['submittedAt'] ?? '2000-01-01');
      final bDate = DateTime.parse(b['submittedAt'] ?? '2000-01-01');
      return bDate.compareTo(aDate);
    });

    // Zobrazme najnovších 5 aktivít
    final latestActivities = progresses.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progres študenta',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade800),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Študent dokončil ${_progressData?['completedAssignments'] ?? 0} z ${_progressData?['totalAssignments'] ?? 0} aktivít.',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Tabuľka progresu
        const Text(
          "Posledné aktivity",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: latestActivities.length,
          itemBuilder: (context, index) {
            final progress = latestActivities[index];
            final materialId = progress['material'] ?? 'Neznámy materiál';
            final submittedAt = progress['submittedAt'] != null
                ? DateFormat('dd.MM.yyyy HH:mm').format(DateTime.parse(progress['submittedAt']))
                : 'Neznámy dátum';
            final score = progress['score'] ?? 0;
            final timeSpent = progress['timeSpent'];
            
            String materialType = 'Neznámy typ';
            if (progress['answers'] != null && (progress['answers'] as List).isNotEmpty) {
              final answer = (progress['answers'] as List).first;
              if (answer.containsKey('question')) {
                materialType = 'Kvíz';
              } else if (answer.containsKey('solvedGrid')) {
                materialType = 'Puzzle';
              } else if (answer.containsKey('connections')) {
                materialType = 'Spojovačka';
              } else if (answer.containsKey('arrangedWords')) {
                materialType = 'Slovná hádanka';
              }
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getMaterialTypeColor(materialType).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getMaterialTypeIcon(materialType),
                        color: _getMaterialTypeColor(materialType),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Informácie o aktivite
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Materiál $materialId',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$materialType • $submittedAt',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (timeSpent != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Čas: ${_formatTime(timeSpent)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Skóre
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getScoreColor(score as int).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$score%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getScoreColor(score as int),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatTime(int milliseconds) {
    final seconds = (milliseconds / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  IconData _getMaterialTypeIcon(String type) {
    switch (type) {
      case 'Kvíz':
        return Icons.quiz;
      case 'Puzzle':
        return Icons.extension;
      case 'Spojovačka':
        return Icons.compare_arrows;
      case 'Slovná hádanka':
        return Icons.sort_by_alpha;
      default:
        return Icons.description;
    }
  }

  Color _getMaterialTypeColor(String type) {
    switch (type) {
      case 'Kvíz':
        return Colors.blue;
      case 'Puzzle':
        return Colors.purple;
      case 'Spojovačka':
        return Colors.orange;
      case 'Slovná hádanka':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildGroupsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _apiService.getStudentGroups(_student.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Skupiny študenta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              ),
            ],
          );
        }

        // Zobrazenie chyby
        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Skupiny študenta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade700),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Nepodarilo sa načítať skupiny: ${snapshot.error}',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Spustí refresh stránky
                    setState(() {});
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Skúsiť znova'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF4A261),
                  ),
                ),
              ),
            ],
          );
        }

        final groups = snapshot.data ?? [];

        // Zobrazenie prázdneho stavu
        if (groups.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Skupiny študenta',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.group_off,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Študent nie je členom žiadnej skupiny',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }

        // Zobrazenie zoznamu skupín
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Skupiny študenta',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...groups.map((group) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GroupDetailScreen(
                        groupId: group['id'],
                        groupName: group['name'] ?? 'Neznáma skupina',
                      ),
                    ),
                  );
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: const Icon(Icons.group, color: Colors.blue),
                  ),
                  title: Text(
                    group['name'] ?? 'Neznáma skupina',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('${group['studentCount'] ?? 0} študentov'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            )).toList(),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}