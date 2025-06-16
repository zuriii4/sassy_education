import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/models/student.dart';
import 'package:sassy/widgets/search_bar.dart';
import 'package:sassy/widgets/stat_card.dart';
import 'package:sassy/screens/teacher/students/student_detail_screen.dart';
import 'package:sassy/screens/teacher/students/create_group_screen.dart';
import 'package:sassy/screens/teacher/students/create_student_screen.dart';
import 'package:sassy/screens/teacher/group_screen.dart';

class StudentsPage extends StatefulWidget {
  const StudentsPage({Key? key}) : super(key: key);

  @override
  State<StudentsPage> createState() => _StudentsPageState();
}

class _StudentsPageState extends State<StudentsPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Student> _allStudents = [];
  List<Student> _filteredStudents = [];
  List<String> _selectedStudentIds = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudents();

    _searchController.addListener(() {
      _filterStudents(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // načítame všetkých študentov
      final data = await _apiService.getStudents();
      _allStudents = data.map((json) => Student.fromJson(json)).toList();

      // získame online statusy všetkých študentov
      await _updateStudentsOnlineStatus();

      // Aktualizujeme filtrovaný zoznam
      _filteredStudents = List.from(_allStudents);
    } catch (e) {
      setState(() {
        _errorMessage = "Nepodarilo sa načítať študentov: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Nová metóda pre aktualizáciu online statusov
  Future<void> _updateStudentsOnlineStatus() async {
    try {
      // Získame online študentov
      final onlineStudents = await _apiService.getOnlineStudents();
      final offlineStudents = await _apiService.getOfflineStudents();

      // označíme všetkých študentov ako offline
      for (var i = 0; i < _allStudents.length; i++) {
        _allStudents[i] = Student.fromJson({
          ..._allStudents[i].toJson(),
          'lastActive': 'Offline',
        });
      }

      // Aktualizujeme online študentov
      for (var i = 0; i < _allStudents.length; i++) {
        final student = _allStudents[i];

        // Hľadáme zhodu v online študentoch
        final onlineMatch = onlineStudents.firstWhere(
                (item) => item['studentId'] == student.id || item['userId'] == student.id,
            orElse: () => null
        );

        if (onlineMatch != null) {
          // Študent je online
          _allStudents[i] = Student.fromJson({
            ...student.toJson(),
            'lastActive': 'Online',
          });
          continue;
        }

        // Hľadáme zhodu v offline študentoch
        final offlineMatch = offlineStudents.firstWhere(
                (item) => item['studentId'] == student.id || item['userId'] == student.id,
            orElse: () => null
        );

        if (offlineMatch != null && offlineMatch['lastActive'] != null) {
          // Formátovanie času poslednej aktivity
          try {
            final lastActive = DateTime.parse(offlineMatch['lastActive']);
            final now = DateTime.now();
            final diff = now.difference(lastActive);

            String formattedTime;
            if (diff.inHours < 24) {
              formattedTime = 'Dnes ${lastActive.hour}:${lastActive.minute.toString().padLeft(2, '0')}';
            } else if (diff.inDays < 2) {
              formattedTime = 'Včera ${lastActive.hour}:${lastActive.minute.toString().padLeft(2, '0')}';
            } else {
              formattedTime = '${lastActive.day}.${lastActive.month}.${lastActive.year}';
            }

            _allStudents[i] = Student.fromJson({
              ...student.toJson(),
              'lastActive': formattedTime,
            });
          } catch (e) {
          }
        }
      }
    } catch (e) {
      print('Chyba pri získavaní statusov: $e');
    }
  }
  
  void _filterStudents(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredStudents = List.from(_allStudents);
      } else {
        _filteredStudents = _allStudents
            .where((student) => student.name.toLowerCase()
            .contains(searchTerm.toLowerCase()))
            .toList();
      }
    });
  }
  
  void _toggleStudentSelection(String studentId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedStudentIds.add(studentId);
      } else {
        _selectedStudentIds.remove(studentId);
      }
    });
  }
  
  void _navigateToGroupsScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const GroupsScreen(),
      ),
    );
    _loadStudents();
  }
  
  void _createNewStudent() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateStudentScreen(),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Študent bol úspešne vytvorený')),
      );
    }
    _loadStudents();
  }

  void _createNewGroup() async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyberte aspoň jedného študenta pre vytvorenie skupiny')),
      );
      return;
    }
    
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateGroupScreen(selectedStudentIds: _selectedStudentIds),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skupina bola úspešne vytvorená')),
      );
      setState(() {
        _selectedStudentIds = [];
      });
    }
    _loadStudents();
  }

  @override
  Widget build(BuildContext context) {
    // Počítame štatistiky
    final specialNeedsCount = _allStudents.where((s) => s.hasSpecialNeeds).length;
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
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
          padding: const EdgeInsets.all(20.0),
          child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Štatistiky a tlačidlo pre skupiny
                        Row(
                          children: [
                            // Štatistiky
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  StatCard(
                                    count: _allStudents.length.toString(),
                                    label: "Študenti",
                                  ),
                                  StatCard(
                                    count: specialNeedsCount.toString(),
                                    label: "Špeciálne potreby",
                                  ),
                                ],
                              ),
                            ),
                            
                            // Tlačidlo pre zobrazenie skupín
                            ElevatedButton.icon(
                              onPressed: _navigateToGroupsScreen,
                              icon: const Icon(Icons.group),
                              label: const Text(
                                "Skupiny",
                                style: TextStyle(color : Colors.white70),
                                ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A90E2),
                                iconColor: Colors.white70,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Vyhľadávanie a akcie
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: CustomSearchBar(
                                controller: _searchController,
                                hintText: "Hľadať študenta",
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _selectedStudentIds.isNotEmpty 
                                  ? _createNewGroup
                                  : null,
                              icon: const Icon(Icons.group_add),
                              label: const Text(
                                "Vytvoriť skupinu",
                                style: TextStyle( color: Colors.black54),
                                ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 244, 211, 186),
                                disabledBackgroundColor: Colors.grey.shade300,
                                iconColor: Colors.black54,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            PopupMenuButton(
                              icon: const Icon(Icons.more_vert),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'select_all',
                                  child: Text('Vybrať všetkých'),
                                ),
                                const PopupMenuItem(
                                  value: 'deselect_all',
                                  child: Text('Zrušiť výber'),
                                ),
                                const PopupMenuItem(
                                  value: 'refresh',
                                  child: Text('Obnoviť'),
                                ),
                                const PopupMenuItem(
                                  value: 'newStudent',
                                  child: Text('Vytvoriť nového študenta'),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'select_all') {
                                  setState(() {
                                    _selectedStudentIds = _filteredStudents
                                        .map((s) => s.id)
                                        .toList();
                                  });
                                } else if (value == 'deselect_all') {
                                  setState(() {
                                    _selectedStudentIds = [];
                                  });
                                } else if (value == 'refresh') {
                                  _loadStudents();
                                } else if (value == 'newStudent') {
                                  _createNewStudent();
                                }
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tabuľka študentov
                        Expanded(
                          child: _buildStudentsTable(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildStudentsTable() {
    if (_filteredStudents.isEmpty) {
      return const Center(
        child: Text(
          "Nenašli sa žiadni študenti",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text("")),
          DataColumn(label: Text("Študenti")),
          DataColumn(label: Text("Status")),
          DataColumn(label: Text("Potreby")),
          DataColumn(label: Text("Aktívny")),
        ],
        rows: _filteredStudents.map((student) {
          final isSelected = _selectedStudentIds.contains(student.id);
          final isOnline = student.lastActive == 'Online';

          return DataRow(
            selected: isSelected,
            cells: [
              DataCell(
                Checkbox(
                  value: isSelected,
                  activeColor: Colors.orange,
                  onChanged: (value) => _toggleStudentSelection(student.id, value ?? false),
                ),
              ),
              DataCell(
                InkWell(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => StudentDetailScreen(student: student),
                      ),
                    );
                    _loadStudents();
                  },
                  child: Row(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            backgroundColor: student.hasSpecialNeeds
                                ? Colors.orange
                                : Colors.blue,
                            child: const Icon(Icons.person, color: Colors.white),
                          ),
                          // Indikátor online statusu
                          if (isOnline)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      Text(student.name),
                    ],
                  ),
                ),
              ),
              DataCell(Text(student.status)),
              DataCell(Text(student.needsDescription)),
              DataCell(
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isOnline ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(student.lastActive),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}