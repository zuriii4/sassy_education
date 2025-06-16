import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/material_card.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({Key? key}) : super(key: key);

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _templates = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final templatesResult = await _apiService.getAllTemplates();
      
      setState(() {
        _templates = templatesResult;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _templates = [];
        _errorMessage = "Nepodarilo sa načítať šablóny: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  void _handleUseTemplate(Map<String, dynamic> template) {
    // Implementácia použitia šablóny
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Táto funkcia ešte nie je implementovaná')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: const Text('Šablóny materiálov'),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Obnoviť',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : _errorMessage != null
              ? ErrorStateWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _loadData,
                )
              : _templates.isEmpty
                  ? EmptyStateWidget(
                      title: "Zatiaľ nemáte žiadne šablóny",
                      description: "Šablóny môžete vytvoriť uložením existujúcich materiálov ako šablóny",
                      icon: Icons.folder_off,
                      buttonText: 'Prejsť na materiály',
                      onButtonPressed: () => Navigator.pop(context),
                    )
                  : _buildTemplatesGrid(),
    );
  }

  Widget _buildTemplatesGrid() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: _templates.length,
              itemBuilder: (context, index) {
                final template = _templates[index];
                return TemplateCard(
                  template: template,
                  onUseTemplate: () => _handleUseTemplate(template),
                  onRefresh: _loadData,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}