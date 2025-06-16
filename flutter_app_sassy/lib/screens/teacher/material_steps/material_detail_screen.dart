import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/widgets/search_bar.dart';
import 'package:sassy/screens/teacher/material_steps/material_edit_screen.dart';
import 'package:sassy/screens/teacher/material_steps/previews/preview_builder.dart';

class MaterialDetailScreen extends StatefulWidget {
  final String materialId;
  
  const MaterialDetailScreen({Key? key, required this.materialId}) : super(key: key);

  @override
  State<MaterialDetailScreen> createState() => _MaterialDetailScreenState();
}

class _MaterialDetailScreenState extends State<MaterialDetailScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _material;
  List<dynamic> _students = [];
  List<Map<String, dynamic>> _groups = [];
  bool _isInteractivePreview = false;

  @override
  void initState() {
    super.initState();
    _loadMaterialData();
  }

  Future<void> _loadMaterialData() async {
    setState(() => _isLoading = true);
    
    try {
      final materialData = await _apiService.getMaterialDetails(widget.materialId);
      final studentsData = await _apiService.getStudents();
      final groupsData = await _apiService.getAllGroupsWithDetails();

      setState(() {
        _material = materialData;
        _students = studentsData;
        _groups = groupsData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba pri načítaní dát: $e')),
        );
      }
    }
  }

  Future<void> _saveAsTemplate() async {
    try {
      await _apiService.saveMaterialAsTemplate(widget.materialId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Materiál bol uložený ako šablona')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba pri ukladaní materiálu: $e')),
        );
      }
    }
  }

  Future<void> _deleteMaterial() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Potvrdiť odstránenie'),
        content: const Text('Naozaj chcete odstrániť tento materiál? Túto akciu nie je možné vrátiť späť.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Zrušiť',
              style: TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Odstrániť'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _apiService.deleteMaterial(widget.materialId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Materiál bol úspešne odstránený')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Chyba pri odstraňovaní materiálu: $e')),
          );
        }
      }
    }
  }

  Future<void> _showAssignDialog() async {
    final List<Map<String, dynamic>> currentStudents =
        List<Map<String, dynamic>>.from(_material?['students'] ?? []);
    final List<Map<String, dynamic>> currentGroups =
        List<Map<String, dynamic>>.from(_material?['groups'] ?? []);
        
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => UserAssignmentDialog(
        currentStudents: currentStudents,
        currentGroups: currentGroups,
        materialId: widget.materialId,
        allStudents: _students,
        allGroups: _groups,
      ),
    );
    
    if (result != null) {
      final List<String> studentIds = [];
      for (var student in result['students']) {
        final id = student['id'] ?? student['_id'] ?? '';
        if (id.isNotEmpty) {
          studentIds.add(id);
        }
      }
      
      final List<String> groupIds = [];
      for (var group in result['groups']) {
        final id = group['id'] ?? '';
        if (id.isNotEmpty) {
          groupIds.add(id);
        }
      }
      
      try {
        setState(() => _isLoading = true);
        
        final success = await _apiService.updateMaterial(
          materialId: widget.materialId,
          assignedTo: studentIds.isEmpty ? null : studentIds,
          assignedGroups: groupIds.isEmpty ? null : groupIds,
        );
        
        setState(() {
          _isLoading = false;
          if (success) {
            _material?['students'] = result['students'];
            _material?['groups'] = result['groups'];
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Priradenia boli úspešne aktualizované')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nepodarilo sa aktualizovať priradenia')),
            );
          }
        });
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba pri aktualizácii priradení: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_material?['title'] ?? 'Detail materiálu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Upraviť materiál',
            onPressed: _material == null ? null : () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MaterialEditScreen(material: _material!, materialId: widget.materialId,),
                ),
              );
              
              if (result == true) {
                _loadMaterialData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Odstrániť materiál',
            onPressed: _isLoading ? null : _deleteMaterial,
          ),
          IconButton(
            onPressed: _isLoading ? null : _saveAsTemplate, 
            icon: Icon(Icons.library_add),
            tooltip: 'Uložiť ako šablonu',
          )
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : _material == null 
          ? const Center(child: Text('Materiál sa nenašiel'))
          : _buildMaterialDetail(),
      floatingActionButton: FloatingActionButton(
        onPressed: _isLoading ? null : _showAssignDialog,
        backgroundColor: const Color(0xFFF67E4A),
        child: const Icon(
          Icons.person_add,
          color: Colors.white,
          ),
        tooltip: 'Prideliť používateľom/skupinám',
      ),
    );
  }

  Widget _buildMaterialDetail() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_material?['content']?['image'] != null)
            _buildImagePreview(),

          const SizedBox(height: 24),
          
          _buildInfoCard(),

          const SizedBox(height: 24),
          
          _buildContentCard(),

          const SizedBox(height: 24),
          
          _buildStudentsCard(),
          
          const SizedBox(height: 24),
          
          _buildGroupsCard(),
        ],
      ),
    );
  }

  // Náhľad obrázka
  Widget _buildImagePreview() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: NetworkImageFromBytes(
            imagePath: _material!['content']['image'],
            apiService: _apiService,
          ),
        ),
      ),
    );
  }

  // Karta so základnými informáciami
  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _material?['title'] ?? 'Bez názvu',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            _buildInfoRow('Typ:', _material?['type'] ?? 'Neurčený'),
            
            if (_material?['teacher'] != null) 
              _buildInfoRow('Autor:', _material!['teacher']['name']),
            
            const SizedBox(height: 16),
            
            if (_material!['description'] != null && _material!['description'].toString().isNotEmpty) ...[
              const Text(
                'Popis',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _material!['description'].toString(),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Karta s detailami obsahu
  Widget _buildContentCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Náhľad materiálu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    const Text('Interaktívny režim'),
                    Switch(
                      value: _isInteractivePreview,
                      onChanged: (value) {
                        setState(() {
                          _isInteractivePreview = value;
                        });
                      },
                      activeColor: const Color(0xFFF67E4A),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            MaterialPreviewBuilder.buildPreview(
              _material?['type'] ?? '', 
              _material?['content'] ?? {}, 
              _apiService,
              isInteractive: _isInteractivePreview
            ),
          ],
        ),
      ),
    );
  }

  // Karta pridelených študentov
  Widget _buildStudentsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pridelení študenti',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showAssignDialog,
                  tooltip: 'Upraviť pridelenia',
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            _material?['students'] == null || (_material!['students'] as List).isEmpty
                ? const Text('Žiadni pridelení študenti')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (_material!['students'] as List).length,
                    itemBuilder: (context, index) {
                      final student = _material!['students'][index];
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: student['hasSpecialNeeds'] == true
                              ? Colors.orange
                              : Colors.blue,
                          child: const Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                        title: Text(student['name'] ?? 'Neznámy študent'),
                        subtitle: student['needsDescription'] != null &&
                                student['needsDescription'].toString().isNotEmpty
                            ? Text(student['needsDescription'])
                            : null,
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // Karta pridelených skupín
  Widget _buildGroupsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pridelené skupiny',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showAssignDialog,
                  tooltip: 'Upraviť pridelenia',
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            _material?['groups'] == null || (_material!['groups'] as List).isEmpty
                ? const Text('Žiadne pridelené skupiny')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: (_material!['groups'] as List).length,
                    itemBuilder: (context, index) {
                      final group = _material!['groups'][index];
                      final studentCount = group['students'] != null ?
                          (group['students'] as List).length : 0;
                      
                      return ListTile(
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF3F51B5),
                          child: Icon(Icons.group, color: Colors.white, size: 18),
                        ),
                        title: Text(group['name'] ?? 'Neznáma skupina'),
                        subtitle: Text('Počet študentov: $studentCount'),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
  
  // Widget pre zobrazenie obsahu podľa typu materiálu
  Widget _buildMaterialContent() {
    final String type = _material?['type']?.toString().toLowerCase() ?? '';
    
    switch (type) {
      case 'puzzle': return _buildPuzzleContent();
      case 'quiz': return _buildQuizContent();
      case 'word jumble': return _buildWordJumbleContent();
      case 'connections': return _buildConnectionsContent();
      default: return const Text('Neznámy typ materiálu');
    }
  }
  
  // Puzzle obsah
  Widget _buildPuzzleContent() {
    final content = _material?['content'];
    if (content == null) return const Text('Žiadne puzzle dáta');
    
    final gridData = content['grid'];
    if (gridData == null) return const Text('Chýbajú údaje o mriežke');
    
    final int columns = gridData['columns'] ?? 0;
    final int rows = gridData['rows'] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Typ:', 'Puzzle'),
        _buildInfoRow('Veľkosť:', '$columns x $rows'),
      ],
    );
  }
  
  // Quiz obsah
  Widget _buildQuizContent() {
    final content = _material?['content'];
    if (content == null) return const Text('Žiadne quiz dáta');
    
    final questions = content['questions'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Typ:', 'Quiz'),
        _buildInfoRow('Počet otázok:', questions.length.toString()),
      ],
    );
  }
  
  // Word Jumble obsah
  Widget _buildWordJumbleContent() {
    final content = _material?['content'];
    if (content == null) return const Text('Žiadne dáta');
    
    final words = content['words'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Typ:', 'Word Jumble'),
        _buildInfoRow('Počet slov:', words.length.toString()),
      ],
    );
  }
  
  // Connections obsah (párovanie)
  Widget _buildConnectionsContent() {
    final content = _material?['content'];
    if (content == null) return const Text('Žiadne dáta');
    
    final pairs = content['pairs'] as List? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Typ:', 'Párovanie (Connections)'),
        _buildInfoRow('Počet párov:', pairs.length.toString()),
      ],
    );
  }
  
  // Pomocný widget pre zobrazenie riadku s informáciou
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontWeight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }
}

// Dialóg pre priradenie používateľov a skupín
class UserAssignmentDialog extends StatefulWidget {
  final List<Map<String, dynamic>> currentStudents;
  final List<Map<String, dynamic>> currentGroups;
  final String materialId;
  final List<dynamic> allStudents;
  final List<Map<String, dynamic>> allGroups;
  
  const UserAssignmentDialog({
    Key? key,
    required this.currentStudents,
    required this.currentGroups,
    required this.materialId,
    required this.allStudents,
    required this.allGroups,
  }) : super(key: key);
  
  @override
  State<UserAssignmentDialog> createState() => _UserAssignmentDialogState();
}

class _UserAssignmentDialogState extends State<UserAssignmentDialog> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<dynamic> _allStudents = [];
  List<dynamic> _filteredStudents = [];
  List<Map<String, dynamic>> _selectedStudents = [];
  
  List<Map<String, dynamic>> _allGroups = [];
  List<Map<String, dynamic>> _filteredGroups = [];
  List<Map<String, dynamic>> _selectedGroups = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedStudents = List.from(widget.currentStudents);
    _selectedGroups = List.from(widget.currentGroups);
    
    _allStudents = List.from(widget.allStudents);
    _filteredStudents = List.from(widget.allStudents);
    _allGroups = List.from(widget.allGroups);
    _filteredGroups = List.from(widget.allGroups);
    
    _tabController.addListener(() {
      _searchController.clear();
      _filterContent('');
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }
  
  void _filterContent(String query) {
    setState(() {
      if (_tabController.index == 0) {
        _filteredStudents = query.isEmpty 
            ? List.from(_allStudents)
            : _allStudents.where((student) {
                final name = student['name'] as String? ?? '';
                return name.toLowerCase().contains(query.toLowerCase());
              }).toList();
      } else {
        _filteredGroups = query.isEmpty
            ? List.from(_allGroups)
            : _allGroups.where((group) {
                final name = group['name'] as String? ?? '';
                return name.toLowerCase().contains(query.toLowerCase());
              }).toList();
      }
    });
  }
  
  void _toggleStudentSelection(Map<String, dynamic> student) {
    final String id = student['id'] ?? student['_id'] ?? '';
    if (id.isEmpty) return;
    
    final int index = _selectedStudents.indexWhere((s) => (s['id'] ?? s['_id']) == id);
    
    setState(() {
      if (index >= 0) {
        _selectedStudents.removeAt(index);
      } else {
        _selectedStudents.add(student);
      }
    });
  }
  
  void _toggleGroupSelection(Map<String, dynamic> group) {
    final String id = group['_id'] ?? group['id'] ?? '';
    if (id.isEmpty) return;
    
    final int index = _selectedGroups.indexWhere((g) {
      final gid = g['_id'] ?? g['id'] ?? '';
      return gid == id;
    });
    
    setState(() {
      if (index >= 0) {
        _selectedGroups.removeAt(index);
      } else {
        _selectedGroups.add(group);
      }
    });
  }
  
  bool _isStudentSelected(Map<String, dynamic> student) {
    final String id = student['id'] ?? student['_id'] ?? '';
    return _selectedStudents.any((s) => (s['id'] ?? s['_id']) == id);
  }
  
  bool _isGroupSelected(Map<String, dynamic> group) {
    final String id = group['_id'] ?? group['id'] ?? '';
    return _selectedGroups.any((g) {
      final gid = g['_id'] ?? g['id'] ?? '';
      return gid == id;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Priradiť materiál',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // TabBar
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Študenti (${_selectedStudents.length})'),
                Tab(text: 'Skupiny (${_selectedGroups.length})'),
              ],
              labelColor: const Color(0xFFF67E4A),
              indicatorColor: const Color(0xFFF67E4A),
            ),
            
            // Vyhľadávanie
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBox(),
            ),
            
            // Obsah
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildStudentsTab(),
                  _buildGroupsTab(),
                ],
              ),
            ),
            
            // Tlačidlá
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Zrušiť',
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop({
                      'students': _selectedStudents,
                      'groups': _selectedGroups,
                    }),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF67E4A),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Uložiť'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchBox() {
  return CustomSearchBar(
    controller: _searchController,
    hintText: _tabController.index == 0 ? 'Vyhľadať študenta' : 'Vyhľadať skupinu',
    onChanged: _filterContent,
    onClear: () => _filterContent(''),
  );
}
  
  Widget _buildStudentsTab() {
    if (_filteredStudents.isEmpty) {
      return Center(
        child: Text('Žiadni študenti neboli nájdení', style: TextStyle(color: Colors.grey[600])),
      );
    }
    
    return ListView.builder(
      itemCount: _filteredStudents.length,
      itemBuilder: (context, index) {
        final student = _filteredStudents[index];
        final isSelected = _isStudentSelected(student);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isSelected ? Colors.blue[50] : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: student['hasSpecialNeeds'] == true
                  ? Colors.orange
                  : (isSelected ? Colors.blue : Colors.grey[300]),
              child: const Icon(Icons.person, color: Colors.white),
            ),
            title: Text(student['name'] ?? 'Neznámy študent'),
            subtitle: student['needsDescription'] != null && 
                      student['needsDescription'].toString().isNotEmpty
                ? Text(student['needsDescription'])
                : null,
            trailing: Checkbox(
              value: isSelected,
              activeColor: const Color(0xFFF67E4A),
              onChanged: (_) => _toggleStudentSelection(student),
            ),
            onTap: () => _toggleStudentSelection(student),
          ),
        );
      },
    );
  }
  
  Widget _buildGroupsTab() {
    if (_filteredGroups.isEmpty) {
      return Center(
        child: Text('Žiadne skupiny neboli nájdené', style: TextStyle(color: Colors.grey[600])),
      );
    }
    
    return ListView.builder(
      itemCount: _filteredGroups.length,
      itemBuilder: (context, index) {
        final group = _filteredGroups[index];
        final isSelected = _isGroupSelected(group);
        final studentCount = group['students'] != null ? (group['students'] as List).length : 0;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          color: isSelected ? Colors.green[50] : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSelected ? const Color(0xFF3F51B5) : Colors.grey[300],
              child: const Icon(Icons.group, color: Colors.white),
            ),
            title: Text(group['name'] ?? 'Neznáma skupina'),
            subtitle: Text('Počet študentov: $studentCount'),
            trailing: Checkbox(
              value: isSelected,
              activeColor: const Color(0xFFF67E4A),
              onChanged: (_) => _toggleGroupSelection(group),
            ),
            onTap: () => _toggleGroupSelection(group),
          ),
        );
      },
    );
  }
}