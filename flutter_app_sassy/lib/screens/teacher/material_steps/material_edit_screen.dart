import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/screens/teacher/material_steps/previews/preview_builder.dart';
import 'package:image_picker/image_picker.dart';

class MaterialEditScreen extends StatefulWidget {
  final Map<String, dynamic> material;
  final String materialId;

  
  const MaterialEditScreen({super.key, required this.material, required this.materialId});

  @override
  State<MaterialEditScreen> createState() => _MaterialEditScreenState();
}

class _MaterialEditScreenState extends State<MaterialEditScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _isInteractivePreview = false;
  File? _imageFile;
  String? _serverImagePath;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late String _selectedType;
  late Map<String, dynamic> _content;
  
  late TextEditingController _gridSizeController;
  
  // Quiz
  final List<Map<String, dynamic>> _questions = [];
  final TextEditingController _questionController = TextEditingController();
  String? _questionImagePath;
  
  // Word Jumble
  final TextEditingController _wordController = TextEditingController();
  List<String> _words = [];
  List<String> _correctOrder = [];
  
  // Connections
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();
  List<Map<String, String>> _pairs = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.material['title'] ?? '');
    _descriptionController = TextEditingController(text: widget.material['description'] ?? '');
    _selectedType = widget.material['type'] ?? 'puzzle';
    _content = Map<String, dynamic>.from(widget.material['content'] ?? {});
    
    _initializeTypeSpecificData();
  }

  void _initializeTypeSpecificData() {
    switch (_selectedType.toLowerCase()) {
      case 'puzzle':
        _initializePuzzleData();
        break;
      case 'quiz':
        _initializeQuizData();
        break;
      case 'word-jumble':
        _initializeWordJumbleData();
        break;
      case 'connection':
        _initializeConnectionsData();
        break;
    }
  }

  void _initializePuzzleData() {
    if (_content.containsKey('image')) {
      _serverImagePath = _content['image'];
    }
    
    final gridData = _content['grid'] ?? {};
    final int gridSize = gridData['columns'] ?? 3;
    _gridSizeController = TextEditingController(text: gridSize.toString());
  }

  void _initializeQuizData() {
    if (_content.containsKey('questions')) {
      _questions.addAll(List<Map<String, dynamic>>.from(_content['questions']));
    }
  }

  void _initializeWordJumbleData() {
    if (_content.containsKey('words')) {
      _words = List<String>.from(_content['words']);
    }
    
    if (_content.containsKey('correct_order')) {
      _correctOrder = List<String>.from(_content['correct_order']);
    } else {
      _correctOrder = List<String>.from(_words);
    }
  }

  void _initializeConnectionsData() {
    if (_content.containsKey('pairs')) {
      final List<dynamic> rawPairs = _content['pairs'];
      _pairs = rawPairs.map((pair) => {
        'left': pair['left'] as String,
        'right': pair['right'] as String,
      }).toList();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _gridSizeController.dispose();
    _questionController.dispose();
    _wordController.dispose();
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _updateGridSize() async {
    try {
      int newSize = int.parse(_gridSizeController.text);
      
      if (newSize > 0) {
        setState(() {
          _content['grid'] = {
            'columns': newSize,
            'rows': newSize
          };
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veľkosť mriežky bola aktualizovaná')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veľkosť musí byť väčšia ako 0')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Neplatná hodnota pre veľkosť mriežky')),
      );
    }
  }

  // Quiz methods
  void _addQuestion() {
    if (_questionController.text.isEmpty) return;
    
    setState(() {
      final newQuestion = {
        'text': _questionController.text,
        'answers': [],
      };
      
      if (_questionImagePath != null) {
        newQuestion['image'] = _questionImagePath as Object;
      }
      
      _questions.add(newQuestion);
      _questionController.clear();
      _questionImagePath = null;
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _addAnswer(int questionIndex) {
    final TextEditingController answerController = TextEditingController();
    bool isCorrect = false;
    String? answerImagePath;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final double screenWidth = MediaQuery.of(dialogContext).size.width;
          final double dialogWidth = screenWidth > 600 ? 500 : screenWidth * 0.8;
          
          return AlertDialog(
            title: const Text('Pridať odpoveď'),
            content: Container(
              width: dialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.7,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: answerController,
                      decoration: const InputDecoration(
                        labelText: 'Text odpovede',
                        hintText: 'Zadajte text odpovede',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text('Správna odpoveď'),
                      value: isCorrect,
                      onChanged: (value) {
                        setDialogState(() {
                          isCorrect = value ?? false;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    FormImagePicker(
                      label: 'Obrázok odpovede',
                      onImagePathSelected: (path) {
                        setDialogState(() {
                          answerImagePath = path;
                        });
                      },
                      initialImagePath: answerImagePath,
                      cropToSquare: false,
                    ),
                    
                    if (answerImagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text('Vybraný obrázok: ${answerImagePath!.split('/').last}'),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Zrušiť'),
              ),
              TextButton(
                onPressed: () {
                  if (answerController.text.isNotEmpty) {
                    final Map<String, dynamic> answer = {
                      'text': answerController.text,
                      'correct': isCorrect,
                    };
                    
                    if (answerImagePath != null) {
                      answer['image'] = answerImagePath;
                    }
                    
                    Navigator.of(dialogContext).pop();
                    
                    setState(() {
                      if (_questions[questionIndex]['answers'] == null) {
                        _questions[questionIndex]['answers'] = [];
                      }
                      _questions[questionIndex]['answers'].add(answer);
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Prosím, zadajte text odpovede')),
                    );
                  }
                },
                child: const Text('Pridať'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _onQuestionImageSelected() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _questionImagePath = image.path;
      });
    }
  }

  // Word Jumble methods
  void _addWord() {
    if (_wordController.text.isEmpty) return;
    
    setState(() {
      final newWord = _wordController.text.trim();
      _words.add(newWord);
      _correctOrder.add(newWord);
      _wordController.clear();
    });
  }

  void _removeWord(int index) {
    setState(() {
      final removedWord = _words[index];
      _words.removeAt(index);
      _correctOrder.remove(removedWord);
    });
  }

  void _shuffleWords() {
    setState(() {
      _correctOrder = List<String>.from(_words);
      _correctOrder.shuffle();
    });
  }

  // Connections methods
  void _addPair() {
    if (_leftController.text.isEmpty || _rightController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vyplňte obe strany páru')),
      );
      return;
    }
    
    setState(() {
      _pairs.add({
        'left': _leftController.text.trim(),
        'right': _rightController.text.trim(),
      });
      
      _leftController.clear();
      _rightController.clear();
    });
  }

  void _removePair(int index) {
    setState(() {
      _pairs.removeAt(index);
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
            TextField(
              controller: _leftController,
              decoration: const InputDecoration(
                labelText: 'Ľavá strana',
                hintText: 'Zadajte ľavú stranu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _rightController,
              decoration: const InputDecoration(
                labelText: 'Pravá strana',
                hintText: 'Zadajte pravú stranu',
                border: OutlineInputBorder(),
              ),
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
                });
                Navigator.pop(context);
                _leftController.clear();
                _rightController.clear();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Vyplňte obe strany páru')),
                );
              }
            },
            child: const Text('Uložiť'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveMaterial() async {
    setState(() => _isLoading = true);
    
    try {
      _updateContentBasedOnType();
      

      final success = await _apiService.updateMaterial(
        materialId: widget.materialId,
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        content: _content,
        imageFile: _imageFile,
      );
      
      setState(() => _isLoading = false);
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Materiál bol úspešne aktualizovaný')),
          );
          Navigator.of(context).pop(true); // Return success
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nepodarilo sa aktualizovať materiál')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba pri aktualizácii materiálu: $e')),
        );
      }
    }
  }

  void _updateContentBasedOnType() {
    switch (_selectedType.toLowerCase()) {
      case 'puzzle':
        _content = {
          'image': _serverImagePath, // Keep original image path
          'grid': {
            'columns': int.parse(_gridSizeController.text),
            'rows': int.parse(_gridSizeController.text)
          }
        };
        break;
      case 'quiz':
        _content = {
          'questions': _questions
        };
        break;
      case 'word-jumble':
        _content = {
          'words': _words,
          'correct_order': _correctOrder
        };
        break;
      case 'connection':
        _content = {
          'pairs': _pairs
        };
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upraviť materiál'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Uložiť zmeny',
            onPressed: _saveMaterial,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Základné informácie',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Názov',
                              hintText: 'Zadajte názov materiálu',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Popis',
                              hintText: 'Zadajte popis materiálu',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Typ materiálu',
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedType,
                            items: const [
                              DropdownMenuItem(
                                  value: 'puzzle', child: Text('Puzzle')),
                              DropdownMenuItem(
                                  value: 'quiz', child: Text('Quiz')),
                              DropdownMenuItem(
                                  value: 'word-jumble',
                                  child: Text('Word Jumble')),
                              DropdownMenuItem(
                                  value: 'connection',
                                  child: Text('Connections')),
                            ],
                            onChanged: null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTypeSpecificSettings(),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
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
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
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
                            _selectedType,
                            _content,
                            _apiService,
                            isInteractive: _isInteractivePreview,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeSpecificSettings() {
    switch (_selectedType.toLowerCase()) {
      case 'puzzle':
        return _buildPuzzleSettings();
      case 'quiz':
        return _buildQuizSettings();
      case 'word-jumble':
        return _buildWordJumbleSettings();
      case 'connection':
        return _buildConnectionsSettings();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPuzzleSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nastavenia puzzle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // Výber obrázkov
            FormImagePicker(
              label: 'Obrázok puzzle',
              onImagePathSelected: (path) {
                setState(() {
                  _serverImagePath = path;
                });
              },
              initialImagePath: _serverImagePath,
              cropToSquare: true,
            ),
            
            const SizedBox(height: 16),

            // Veľkosť mriežky
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Veľkosť mriežky'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _gridSizeController,
                        decoration: const InputDecoration(
                          labelText: 'Počet stĺpcov/riadkov',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _updateGridSize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF67E4A),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aktualizovať'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionsSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nastavenia spojení (connections)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _leftController,
              decoration: const InputDecoration(
                labelText: 'Ľavá strana',
                hintText: 'Zadajte ľavú stranu',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _rightController,
              decoration: const InputDecoration(
                labelText: 'Pravá strana',
                hintText: 'Zadajte pravú stranu',
                border: OutlineInputBorder(),
              ),
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
            
            const SizedBox(height: 16),
            
            if (_pairs.isNotEmpty) ...[
              const Text(
                'Existujúce páry',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _pairs.length,
                itemBuilder: (context, index) {
                  final pair = _pairs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.grey[100],
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
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Zatiaľ nie sú pridané žiadne páry',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nastavenia kvízu',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: _questionController,
              decoration: const InputDecoration(
                labelText: 'Text otázky',
                hintText: 'Zadajte text otázky',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            FormImagePicker(
              label: 'Obrázok otázky',
              onImagePathSelected: (path) {
                setState(() {
                  _questionImagePath = path;
                });
              },
              initialImagePath: _questionImagePath,
              cropToSquare: false,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _addQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF67E4A),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Pridať otázku'),
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (_questions.isNotEmpty) ...[
              const Text(
                'Existujúce otázky',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final question = _questions[index];
                  final answers = List<Map<String, dynamic>>.from(question['answers'] ?? []);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.grey[100],
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Otázka ${index+1}: ${question['text']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeQuestion(index),
                              ),
                            ],
                          ),
                          
                          if (answers.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Odpovede:', style: TextStyle(fontWeight: FontWeight.w500)),
                            ...answers.map((answer) {
                              final isCorrect = answer['correct'] == true;
                              return Padding(
                                padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      isCorrect ? Icons.check_circle : Icons.circle_outlined,
                                      color: isCorrect ? Colors.green : Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(child: Text(answer['text'])),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => _addAnswer(index),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF67E4A),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Pridať odpoveď'),
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
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Zatiaľ nie sú pridané žiadne otázky',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordJumbleSettings() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nastavenia word jumble',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordController,
                    decoration: const InputDecoration(
                      labelText: 'Nové slovo',
                      hintText: 'Zadajte nové slovo',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addWord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF67E4A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Pridať'),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _words.isNotEmpty ? _shuffleWords : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF67E4A),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Zamiešať slová'),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // List of words
            if (_words.isNotEmpty) ...[
              const Text(
                'Existujúce slová',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _words.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.grey[100],
                    child: ListTile(
                      title: Text(_words[index]),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeWord(index),
                      ),
                    ),
                  );
                },
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Zatiaľ nie sú pridané žiadne slová',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              ),
              
            if (_words.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Správne poradie slov',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toto je poradie, v ktorom musia byť slová zoradené:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _correctOrder.asMap().entries.map((entry) {
                        final index = entry.key;
                        final word = entry.value;
                        return Chip(
                          label: Text('${index + 1}. $word'),
                          backgroundColor: Colors.white,
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}