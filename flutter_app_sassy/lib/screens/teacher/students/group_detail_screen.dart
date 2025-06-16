import 'package:flutter/material.dart';
import 'package:sassy/screens/teacher/students/add_student_screen.dart';
import 'package:sassy/services/api_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  bool _isActionInProgress = false;
  String? _errorMessage;
  Map<String, dynamic>? _groupDetails;
  List<Map<String, dynamic>> _students = [];
  
  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }
  
  Future<void> _loadGroupDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final details = await _apiService.getGroupDetails(widget.groupId);
      setState(() {
        _groupDetails = details;
        _students = List<Map<String, dynamic>>.from(details['students'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Nepodarilo sa načítať detaily skupiny: ${e.toString()}";
        _isLoading = false;
      });
    }
  }
  
  Future<void> _removeStudentFromGroup(String studentId, String studentName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odstrániť študenta'),
        content: Text('Naozaj chcete odstrániť študenta $studentName zo skupiny?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť', style: TextStyle(color: Colors.black54)),
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
      _isActionInProgress = true;
    });
    
    try {
      final success = await _apiService.removeStudentFromGroup(widget.groupId, studentId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Študent $studentName bol odstránený zo skupiny')),
        );
        _loadGroupDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nepodarilo sa odstrániť študenta zo skupiny')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isActionInProgress = false;
      });
    }
  }
  
  Future<void> _addStudentToGroup() async {
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => AddStudentScreen(
        groupId: widget.groupId,
      ),
    ),
  );
  
  if (result == true) {
    _loadGroupDetails();
  }
}
  
  Future<String?> _showAddStudentDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pridať študenta'),
        content: const Text('Táto funkcionalita by normálne zobrazila zoznam študentov na pridanie.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Zavrieť'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _deleteGroup() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odstrániť skupinu'),
        content: Text('Naozaj chcete odstrániť skupinu ${_groupDetails?['name'] ?? widget.groupName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť', style: TextStyle(color: Colors.black54)),
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
      _isActionInProgress = true;
    });
    
    try {
      final success = await _apiService.deleteGroup(widget.groupId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Skupina bola odstránená')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nepodarilo sa odstrániť skupinu')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chyba: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isActionInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: Text(_groupDetails?['name'] ?? widget.groupName),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadGroupDetails,
            tooltip: 'Obnoviť',
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Odstrániť skupinu', style: TextStyle(color: Colors.red)),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _deleteGroup();
              }
            },
          ),
        ],
      ),
      body: _isLoading
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
                        onPressed: _loadGroupDetails,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Skúsiť znova'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sekcia s informáciami o skupine
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Informácie o skupine',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.group, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Názov: ${_groupDetails?['name'] ?? 'Neznámy'}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Učiteľ: ${_groupDetails?['teacher']?['name'] ?? 'Neznámy'}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.people, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Počet študentov: ${_students.length}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Sekcia so študentmi
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Študenti v skupine',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _isActionInProgress ? null : _addStudentToGroup,
                            icon: const Icon(Icons.person_add),
                            label: const Text(
                              'Pridať študenta',
                              style: TextStyle(color: Colors.white),
                              ),
                            style: ElevatedButton.styleFrom(
                              iconColor: Colors.white,
                              backgroundColor: const Color(0xFFF4A261),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      if (_students.isEmpty)
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.group_off,
                                    size: 48,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'V tejto skupine nie sú žiadni študenti',
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
                        )
                      else
                        ..._students.map((student) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Colors.blue,
                              child: Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(student['name'] ?? 'Neznámy študent'),
                            trailing: IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                              onPressed: _isActionInProgress 
                                  ? null 
                                  : () => _removeStudentFromGroup(
                                        student['id'],
                                        student['name'] ?? 'Neznámy študent',
                                      ),
                              tooltip: 'Odstrániť zo skupiny',
                            ),
                          ),
                        )).toList(),
                    ],
                  ),
                ),
      bottomNavigationBar: _isActionInProgress 
        ? Container(
            height: 4,
            child: const LinearProgressIndicator(),
          )
        : null,
    );
  }
}