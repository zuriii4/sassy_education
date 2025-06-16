import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/models/teacher.dart';
import 'package:sassy/widgets/search_bar.dart';
import 'package:sassy/widgets/stat_card.dart';
import 'package:sassy/screens/admin/create_teacher_screen.dart';
import 'package:sassy/screens/admin/edit_teacher_screen.dart';

class TeachersPage extends StatefulWidget {
  const TeachersPage({Key? key}) : super(key: key);

  @override
  State<TeachersPage> createState() => _TeachersPageState();
}

class _TeachersPageState extends State<TeachersPage> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();

  List<Teacher> _allTeachers = [];
  List<Teacher> _filteredTeachers = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTeachers();

    _searchController.addListener(() {
      _filterTeachers(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.getTeachers();
      _allTeachers = data.map((json) => Teacher.fromJson(json)).toList();
      _filteredTeachers = List.from(_allTeachers);
    } catch (e) {
      setState(() {
        _errorMessage = "Nepodarilo sa načítať učiteľov: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _filterTeachers(String searchTerm) {
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredTeachers = List.from(_allTeachers);
      } else {
        _filteredTeachers = _allTeachers
            .where((teacher) => 
                teacher.name.toLowerCase().contains(searchTerm.toLowerCase()) ||
                teacher.email.toLowerCase().contains(searchTerm.toLowerCase()) ||
                teacher.specialization.toLowerCase().contains(searchTerm.toLowerCase()))
            .toList();
      }
    });
  }
  
  void _createNewTeacher() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTeacherScreen(),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Učiteľ bol úspešne vytvorený')),
      );
      _loadTeachers();
    }
  }

  Future<void> _deleteTeacher(Teacher teacher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vymazať učiteľa'),
        content: Text('Naozaj chcete vymazať učiteľa ${teacher.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť', style: TextStyle(color: Colors.black38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Vymazať', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.deleteTeacher(teacher.id);
      
      _loadTeachers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Učiteľ ${teacher.name} bol vymazaný')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chyba: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editTeacher(Teacher teacher) async {
    final updatedTeacher = await Navigator.push<Teacher>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTeacherScreen(teacher: teacher),
      ),
    );
    
    if (updatedTeacher != null) {
      setState(() {
        final index = _allTeachers.indexWhere((t) => t.id == updatedTeacher.id);
        if (index != -1) {
          _allTeachers[index] = updatedTeacher;
          _filterTeachers(_searchController.text);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Údaje učiteľa boli aktualizované')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chyba pri načítaní',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: _loadTeachers,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Skúsiť znova'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Štatistiky
                        Row(
                          children: [
                            // Štatistiky
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  StatCard(
                                    count: _allTeachers.length.toString(),
                                    label: "Učitelia",
                                  ),
                                ],
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
                                hintText: "Hľadať učiteľa",
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: _createNewTeacher,
                              icon: const Icon(Icons.person_add),
                              label: const Text(
                                "Pridať učiteľa",
                                style: TextStyle(color: Colors.black54),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 244, 211, 186),
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
                                  value: 'refresh',
                                  child: Text('Obnoviť'),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'refresh') {
                                  _loadTeachers();
                                }
                              },
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Tabuľka učiteľov
                        Expanded(
                          child: _buildTeachersTable(),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  Widget _buildTeachersTable() {
    if (_filteredTeachers.isEmpty) {
      return const Center(
        child: Text(
          "Nenašli sa žiadni učitelia",
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
      );
    }

    return SingleChildScrollView(
      child: DataTable(
        columns: const [
          DataColumn(label: Text("Učiteľ")),
          DataColumn(label: Text("Email")),
          DataColumn(label: Text("Špecializácia")),
          DataColumn(label: Text("Akcie")),
        ],
        rows: _filteredTeachers.map((teacher) {
          return DataRow(
            cells: [
              DataCell(
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Text(teacher.name),
                  ],
                ),
              ),
              DataCell(Text(teacher.email)),
              DataCell(Text(teacher.specialization)),
              DataCell(
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editTeacher(teacher),
                      tooltip: 'Upraviť',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTeacher(teacher),
                      tooltip: 'Vymazať',
                    ),
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