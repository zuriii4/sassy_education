import 'package:flutter/material.dart';
import 'package:sassy/models/material.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/widgets/message_display.dart';
import 'package:sassy/screens/teacher/material_steps/previews/connections_preview.dart';

class ConnectionContent extends StatefulWidget {
  final TaskModel taskModel;
  
  const ConnectionContent({Key? key, required this.taskModel}) : super(key: key);

  @override
  State<ConnectionContent> createState() => _ConnectionContentState();
}

class _ConnectionContentState extends State<ConnectionContent> {
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();
  List<Map<String, String>> _pairs = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.taskModel.content.isNotEmpty &&
        widget.taskModel.content.containsKey('pairs')) {
      final List<dynamic> rawPairs = widget.taskModel.content['pairs'];
      _pairs = rawPairs
          .map((pair) => {
                'left': pair['left'] as String,
                'right': pair['right'] as String,
              })
          .toList();
    }
  }

  void _updateModel() {
    widget.taskModel.setConnectionContent(_pairs);
  }

  void _addPair() {
    if (_leftController.text.isEmpty || _rightController.text.isEmpty) {
      setState(() {
        _errorMessage = "Vyplňte obe strany páru";
      });
      return;
    }
    
    setState(() {
      _errorMessage = null;
      _pairs.add({
        'left': _leftController.text.trim(),
        'right': _rightController.text.trim(),
      });
      
      _leftController.clear();
      _rightController.clear();
      _updateModel();
    });
  }

  void _removePair(int index) {
    setState(() {
      _pairs.removeAt(index);
      _updateModel();
    });
  }

  void _editPair(int index) {
    _leftController.text = _pairs[index]['left'] ?? '';
    _rightController.text = _pairs[index]['right'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upraviť pár'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FormTextField(
              label: 'Ľavá strana',
              placeholder: 'Zadajte ľavú stranu',
              controller: _leftController,
            ),
            const SizedBox(height: 16),
            FormTextField(
              label: 'Pravá strana',
              placeholder: 'Zadajte pravú stranu',
              controller: _rightController,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _leftController.clear();
              _rightController.clear();
            },
            child: const Text('Zrušiť'),
          ),
          TextButton(
            onPressed: () {
              if (_leftController.text.isNotEmpty && _rightController.text.isNotEmpty) {
                setState(() {
                  _pairs[index] = {
                    'left': _leftController.text.trim(),
                    'right': _rightController.text.trim(),
                  };
                  _updateModel();
                });
                Navigator.pop(context);
                _leftController.clear();
                _rightController.clear();
              } else {
                Navigator.pop(context);
                setState(() {
                  _errorMessage = "Vyplňte obe strany páru";
                });
              }
            },
            child: const Text('Uložiť'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vytvorenie párovacích spojení',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF67E4A),
              ),
            ),
            const SizedBox(height: 20),
            
            if (_errorMessage != null)
              MessageDisplay(
                message: _errorMessage!,
                type: MessageType.error,
              ),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pridať nový pár',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    FormTextField(
                      label: 'Ľavá strana',
                      placeholder: 'Zadajte ľavú stranu',
                      controller: _leftController,
                    ),
                    const SizedBox(height: 16),
                    
                    FormTextField(
                      label: 'Pravá strana',
                      placeholder: 'Zadajte pravú stranu',
                      controller: _rightController,
                    ),
                    const SizedBox(height: 16),
                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _addPair,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF67E4A),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Pridať pár'),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    if (_pairs.isNotEmpty) ...[
                      const Text(
                        'Existujúce páry',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _pairs.length,
                        itemBuilder: (context, index) {
                          final pair = _pairs[index];
                          return Card(
                            color: Colors.grey[100],
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      pair['left'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward),
                                  Expanded(
                                    child: Text(
                                      pair['right'] ?? '',
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () => _editPair(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removePair(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ] else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'Zatiaľ nie sú pridané žiadne páry',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                      
                    if (_pairs.length >= 2) ...[
                      const SizedBox(height: 24),
                      _buildConnectionPreview(),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionPreview() {
    return ConnectionsPreview(
      pairs: _pairs,
      isInteractive: false,
    );
  }
}