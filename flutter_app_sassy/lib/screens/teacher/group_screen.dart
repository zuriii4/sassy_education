import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/search_bar.dart';
import 'package:sassy/screens/teacher/students/group_detail_screen.dart';

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({Key? key}) : super(key: key);

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _groups = [];
  List<Map<String, dynamic>> _filteredGroups = [];
  
  @override
  void initState() {
    super.initState();
    _loadGroups();
    
    _searchController.addListener(() {
      _filterGroups(_searchController.text);
    });
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final groups = await _apiService.getAllGroupsWithDetails();
      
      setState(() {
        _groups = groups;
        _filteredGroups = List.from(_groups);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Nepodarilo sa načítať skupiny: ${e.toString()}";
        _isLoading = false;
      });
    }
  }
  
  void _filterGroups(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredGroups = List.from(_groups);
      } else {
        _filteredGroups = _groups.where((group) {
          return group['name'].toString().toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }
  
  void _navigateToGroupDetail(Map<String, dynamic> group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GroupDetailScreen(
          groupId: group['id'],
          groupName: group['name'],
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: const Text('Skupiny'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: _loadGroups,
            tooltip: 'Obnoviť',
          ),
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
                            size: 48,
                            color: Colors.red.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Chyba pri načítaní',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadGroups,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Skúsiť znova'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomSearchBar(
                          controller: _searchController,
                          hintText: "Hľadať skupinu",
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Počet skupín: ${_filteredGroups.length}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: _filteredGroups.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.group_off,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _searchController.text.isEmpty
                                            ? 'Žiadne skupiny nie sú k dispozícii'
                                            : 'Žiadne skupiny nezodpovedajú vyhľadávaniu',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                )
                              : GridView.builder(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                    childAspectRatio: 1,
                                  ),
                                  itemCount: _filteredGroups.length,
                                  itemBuilder: (context, index) {
                                    final group = _filteredGroups[index];
                                    return _buildGroupCard(group);
                                  },
                                ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
  
  Widget _buildGroupCard(Map<String, dynamic> group) {
    final String groupName = group['name'] ?? 'Neznáma skupina';
    final int studentCount = (group['students'] as List?)?.length ?? 0;
    
    String formattedDate = 'Nedávno';
    if (group.containsKey('createdAt')) {
      try {
        final DateTime createdDate = DateTime.parse(group['createdAt']);
        formattedDate = "${createdDate.day}.${createdDate.month}.${createdDate.year}";
      } catch (e) {
      }
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => _navigateToGroupDetail(group),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                radius: 24,
                child: Icon(
                  Icons.group,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                groupName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '$studentCount študentov',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
              if (group.containsKey('createdAt')) ...[
                const SizedBox(height: 4),
                Text(
                  'Vytvorené: $formattedDate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              if (group.containsKey('teacher') && group['teacher'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Učiteľ: ${(group['teacher'] as Map<String, dynamic>)['name'] ?? 'Neznámy'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const Spacer(),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => _navigateToGroupDetail(group),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Zobraziť', style: TextStyle(color: Colors.black54)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}