import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/search_bar.dart';   // Importujeme vlastný search bar
import 'package:sassy/widgets/message_display.dart';

class AddStudentScreen extends StatefulWidget {
  final String groupId;

  const AddStudentScreen({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isAdding = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _availableStudents = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadAvailableStudents();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableStudents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final allStudents = await _apiService.getStudents();
      
      final groupDetails = await _apiService.getGroupDetails(widget.groupId);
      final groupStudents = List<Map<String, dynamic>>.from(groupDetails['students'] ?? []);
      
      final groupStudentIds = groupStudents.map((student) => student['id'] as String).toSet();
      
      final availableStudents = allStudents
          .where((student) => !groupStudentIds.contains(student['id']))
          .toList();
      
      setState(() {
        _availableStudents = List<Map<String, dynamic>>.from(availableStudents);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Nepodarilo sa načítať dostupných študentov: ${e.toString()}";
        _isLoading = false;
      });
    }
  }
  
  List<Map<String, dynamic>> get _filteredStudents {
    if (_searchQuery.isEmpty) {
      return _availableStudents;
    }
    
    final query = _searchQuery.toLowerCase();
    return _availableStudents.where((student) {
      final name = (student['name'] as String?) ?? '';
      final email = (student['email'] as String?) ?? '';
      return name.toLowerCase().contains(query) || 
             email.toLowerCase().contains(query);
    }).toList();
  }
  
  Future<void> _addStudentToGroup(String studentId, String studentName) async {
    setState(() {
      _isAdding = true;
    });
    
    try {
      final success = await _apiService.addStudentToGroup(
        groupId: widget.groupId,
        studentId: studentId,
      );
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Študent $studentName bol pridaný do skupiny')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nepodarilo sa pridať študenta do skupiny')),
        );
        setState(() {
          _isAdding = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: ${e.toString()}')),
      );
      setState(() {
        _isAdding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: const Text('Pridať študenta do skupiny'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomSearchBar(
              controller: _searchController,
              hintText: 'Vyhľadať študenta...',
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Expanded(
              child: Center(
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
                      onPressed: _loadAvailableStudents,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Skúsiť znova'),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: MessageDisplay(
                        message: _errorMessage!,
                        type: MessageType.error,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (_filteredStudents.isEmpty)
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_off,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Žiadni dostupní študenti',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            // List of available students
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredStudents.length,
                itemBuilder: (context, index) {
                  final student = _filteredStudents[index];
                  final studentName = student['name'] ?? 'Neznámy študent';
                  final studentEmail = student['email'] ?? '';
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue,
                        child: Text(
                          studentName.isNotEmpty 
                              ? studentName[0].toUpperCase() 
                              : '?',
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(studentName),
                      subtitle: Text(studentEmail),
                      trailing: ElevatedButton(
                        onPressed: _isAdding
                            ? null
                            : () => _addStudentToGroup(student['id'], studentName),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF4A261),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Pridať'),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isAdding 
          ? Container(
              height: 4,
              child: const LinearProgressIndicator(),
            )
          : null,
    );
  }
}