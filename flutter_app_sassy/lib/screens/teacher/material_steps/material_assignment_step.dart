import 'package:flutter/material.dart';
import 'package:sassy/models/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/search_bar.dart';
import 'package:sassy/widgets/message_display.dart';

class TaskAssignmentStep extends StatefulWidget {
  final TaskModel taskModel;
  
  const TaskAssignmentStep({Key? key, required this.taskModel}) : super(key: key);

  @override
  State<TaskAssignmentStep> createState() => _TaskAssignmentStepState();
}

class _TaskAssignmentStepState extends State<TaskAssignmentStep> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filteredStudents = [];
  List<String> _selectedStudentIds = [];
  
  List<Map<String, dynamic>> _allGroups = [];
  List<Map<String, dynamic>> _filteredGroups = [];
  List<String> _selectedGroupIds = [];
  
  bool _isLoading = true;
  bool _showStudentTab = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    if (widget.taskModel.assignedTo.isNotEmpty) {
      _selectedStudentIds = List<String>.from(widget.taskModel.assignedTo);
    }
    
    if (widget.taskModel.assignedGroups.isNotEmpty) {
      _selectedGroupIds = List<String>.from(widget.taskModel.assignedGroups);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final students = await _apiService.getStudents();
      
      final groups = await _apiService.getAllGroupsWithDetails();
      
      setState(() {
        _allStudents = List<Map<String, dynamic>>.from(students);
        _filteredStudents = List<Map<String, dynamic>>.from(students);
        
        _allGroups = List<Map<String, dynamic>>.from(groups);
        _filteredGroups = List<Map<String, dynamic>>.from(groups);
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Chyba pri načítavaní dát: $e';
      });
    }
  }

  void _toggleStudentSelection(String studentId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedStudentIds.add(studentId);
        if (!widget.taskModel.assignedTo.contains(studentId)) {
          widget.taskModel.assignedTo.add(studentId);
        }
      } else {
        _selectedStudentIds.remove(studentId);
        widget.taskModel.assignedTo.remove(studentId);
      }
    });
  }

  void _toggleGroupSelection(String groupId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedGroupIds.add(groupId);
        if (!widget.taskModel.assignedGroups.contains(groupId)) {
          widget.taskModel.assignedGroups.add(groupId);
        }
      } else {
        _selectedGroupIds.remove(groupId);
        widget.taskModel.assignedGroups.remove(groupId);
      }
    });
  }

  void _filterStudents(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredStudents = List<Map<String, dynamic>>.from(_allStudents);
      } else {
        _filteredStudents = _allStudents
            .where((student) {
              final name = student['name'] as String? ?? '';
              final email = student['email'] as String? ?? '';
              return name.toLowerCase().contains(query.toLowerCase()) ||
                email.toLowerCase().contains(query.toLowerCase());
            })
            .toList();
      }
    });
  }

  void _filterGroups(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = List<Map<String, dynamic>>.from(_allGroups);
      } else {
        _filteredGroups = _allGroups
            .where((group) {
              final name = group['name'] as String? ?? '';
              return name.toLowerCase().contains(query.toLowerCase());
            })
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              const Text(
                'Priradenie úlohy',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF67E4A),
                ),
              ),
              const SizedBox(height: 16),
              
              if (_errorMessage != null)
                MessageDisplay(
                  message: _errorMessage!,
                  type: MessageType.error,
                ),
              
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _showStudentTab = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _showStudentTab ? const Color(0xFFF67E4A) : Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Študenti (${_selectedStudentIds.length})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _showStudentTab ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _showStudentTab = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_showStudentTab ? const Color(0xFFF67E4A) : Colors.grey[300],
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Skupiny (${_selectedGroupIds.length})',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: !_showStudentTab ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              CustomSearchBar(
                controller: _searchController,
                hintText: _showStudentTab 
                    ? 'Vyhľadať študenta' 
                    : 'Vyhľadať skupinu',
                onChanged: (value) {
                  _showStudentTab 
                      ? _filterStudents(value) 
                      : _filterGroups(value);
                },
                onClear: () {
                  _showStudentTab 
                      ? _filterStudents('') 
                      : _filterGroups('');
                },
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: _showStudentTab
                    ? _buildStudentsList()
                    : _buildGroupsList(),
              ),
            ],
          );
  }

  Widget _buildStudentsList() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Text(
          'Žiadni študenti neboli nájdení',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final studentId = student['_id'] as String? ?? student['id'] as String? ?? '';
        final studentName = student['name'] as String? ?? 'Neznámy študent';
        final isSelected = _selectedStudentIds.contains(studentId);
        
        String firstLetter = 'N';
        if (studentName.isNotEmpty) {
          firstLetter = studentName[0].toUpperCase();
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Colors.blue[50] : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
            title: Text(studentName),
            trailing: Checkbox(
              value: isSelected,
              activeColor: Colors.blue,
              onChanged: (value) => _toggleStudentSelection(studentId, value ?? false),
            ),
            onTap: () => _toggleStudentSelection(studentId, !isSelected),
          ),
        );
      },
    );
  }

  Widget _buildGroupsList() {
    if (_filteredGroups.isEmpty) {
      return Center(
        child: Text(
          'Žiadne skupiny neboli nájdené',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _filteredGroups[index];
        final groupId = group['_id'] as String? ?? group['id'] as String? ?? '';
        final groupName = group['name'] as String? ?? 'Neznáma skupina';
        final isSelected = _selectedGroupIds.contains(groupId);
        final studentCount = (group['students'] as List?)?.length ?? 0;
        
        String firstLetter = 'S';
        if (groupName.isNotEmpty) {
          firstLetter = groupName[0].toUpperCase();
        }
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected ? Colors.green[50] : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? Colors.green : Colors.grey[300],
              child: Text(
                firstLetter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
            ),
            title: Text(groupName),
            subtitle: Text('Počet študentov: $studentCount'),
            trailing: Checkbox(
              value: isSelected,
              activeColor: Colors.green,
              onChanged: (value) => _toggleGroupSelection(groupId, value ?? false),
            ),
            onTap: () => _toggleGroupSelection(groupId, !isSelected),
          ),
        );
      },
    );
  }
}