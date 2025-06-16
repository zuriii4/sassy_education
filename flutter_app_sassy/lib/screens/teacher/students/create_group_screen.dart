import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/models/student.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/widgets/message_display.dart';

class CreateGroupScreen extends StatefulWidget {
  final List<String> selectedStudentIds;
  
  const CreateGroupScreen({
    Key? key,
    required this.selectedStudentIds,
  }) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _groupNameController = TextEditingController();
  
  List<Student> _selectedStudents = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  String _teacherId = "";
  
  @override
  void initState() {
    super.initState();
    _loadTeacherId();
    _loadSelectedStudents();
  }
  
  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }
  
  Future<void> _loadTeacherId() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teacher = await _apiService.getTeacher();
      if (teacher != null && teacher['_id'] != null) {
        setState(() {
          _teacherId = teacher['_id'].toString();
        });
      } else {
        setState(() {
          _errorMessage = "Nepodarilo sa získať ID učiteľa";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Chyba pri získavaní ID učiteľa: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadSelectedStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      _selectedStudents = [];
      
      for (String id in widget.selectedStudentIds) {
        try {
          final studentData = await _apiService.getStudentDetails(id);
          
          final student = Student(
            id: studentData['id'],
            name: studentData['name'],
            email: studentData['email'] ?? '',
            notes: studentData['notes'] ?? '',
            status: studentData['status'] ?? 'Aktívny',
            needsDescription: studentData['needsDescription'] ?? '',
            lastActive: studentData['lastActive'] ?? 'Nedávno',
            hasSpecialNeeds: studentData['hasSpecialNeeds'] ?? false,
            dateOfBirth: studentData['dateOfBirth'] != null 
                ? DateTime.parse(studentData['dateOfBirth']) 
                : null,
          );
          
          setState(() {
            _selectedStudents.add(student);
          });
        } catch (e) {
          print('Chyba pri načítaní študenta $id: $e');
        }
      }
      
      if (_selectedStudents.isEmpty && widget.selectedStudentIds.isNotEmpty) {
        setState(() {
          _errorMessage = "Nepodarilo sa načítať žiadnych študentov";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Chyba pri načítaní študentov: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Zadajte názov skupiny";
      });
      return;
    }
    
    if (_teacherId.isEmpty) {
      setState(() {
        _errorMessage = "Nemôžeme vytvoriť skupinu bez ID učiteľa";
      });
      return;
    }
    
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    
    try {
      final success = await _apiService.createGroup(
        name: _groupNameController.text.trim(),
        teacherId: _teacherId,
        studentIds: widget.selectedStudentIds,
      );
      
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = "Nepodarilo sa vytvoriť skupinu";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Chyba pri vytváraní skupiny: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: const Text(
          'Vytvoriť novú skupinu',
          ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    MessageDisplay(
                      message: _errorMessage!,
                      type: MessageType.error,
                    ),
                  
                  // Sekcia pre informácie o skupine
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informácie o skupine',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        
                        FormTextField(
                          label: 'Názov skupiny',
                          placeholder: 'Zadajte názov skupiny',
                          controller: _groupNameController,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Sekcia pre vybraných študentov
                  Text(
                    'Vybraní študenti (${_selectedStudents.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _selectedStudents.isEmpty 
                          ? const Center(
                              child: Text(
                                'Žiadni študenti neboli vybraní',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _selectedStudents.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                final student = _selectedStudents[index];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: student.hasSpecialNeeds 
                                          ? Colors.orange 
                                          : Colors.blue,
                                      child: const Icon(Icons.person, color: Colors.white),
                                    ),
                                    title: Text(student.name),
                                    subtitle: Text(student.needsDescription),
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Tlačidlo na vytvorenie skupiny
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _createGroup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF4A261),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Vytvoriť skupinu',
                              style: TextStyle(fontSize: 16, color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}