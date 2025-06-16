import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sassy/models/student.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/widgets/message_display.dart';

class EditStudentScreen extends StatefulWidget {
  final Student student;

  const EditStudentScreen({
    Key? key,
    required this.student,
  }) : super(key: key);

  @override
  State<EditStudentScreen> createState() => _EditStudentScreenState();
}

class _EditStudentScreenState extends State<EditStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _notesController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _pinController;
  bool _hasSpecialNeeds = false;
  late TextEditingController _needsDescriptionController;

  bool _hasPinAuth = false;
  bool _hasColorCodeAuth = false;
  List<String> _currentColorCode = [];
  String? _currentPin;

  bool _showColorCodePicker = false;
  List<String> _availableColors = [
    'red', 'blue', 'green', 'yellow', 'purple', 'orange'
  ];
  List<String> _selectedColors = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _emailController = TextEditingController(text: widget.student.email);
    _notesController = TextEditingController(text: widget.student.notes);
    _hasSpecialNeeds = widget.student.hasSpecialNeeds;
    _needsDescriptionController = TextEditingController(text: widget.student.needsDescription);
    _pinController = TextEditingController();

    if (widget.student.dateOfBirth != null) {
      final date = widget.student.dateOfBirth!;
      _dateOfBirthController = TextEditingController(
          text: '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
      );
    } else {
      _dateOfBirthController = TextEditingController();
    }

    _loadStudentAuth();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    _needsDescriptionController.dispose();
    _dateOfBirthController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  // Načítanie existujúcej autentifikačnej metódy
  Future<void> _loadStudentAuth() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _apiService.getStudentAuth(widget.student.id);

      setState(() {
        if (result.containsKey('pinSet') && result['pinSet'] != null) {
          _hasPinAuth = true;
          _currentPin = result['pinSet'];
          _pinController.text = _currentPin ?? '';
        } else {
          _hasPinAuth = false;
        }

        // Spracovanie farebného kódu
        if (result.containsKey('colorCode') && result['colorCode'] != null) {
          _hasColorCodeAuth = true;
          _currentColorCode = List<String>.from(result['colorCode']);
          _selectedColors = List<String>.from(_currentColorCode);
        } else {
          _hasColorCodeAuth = false;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nepodarilo sa načítať údaje o autentifikácii: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Nastavenie PIN kódu
  Future<void> _setPin() async {
    final pin = _pinController.text;

    if (pin.isEmpty || pin.length < 4) {
      setState(() {
        _errorMessage = 'PIN musí mať aspoň 4 znaky';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.setStudentPin(widget.student.id, pin);

      setState(() {
        _hasPinAuth = true;
        _currentPin = pin;
        _successMessage = 'PIN bol úspešne nastavený';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nepodarilo sa nastaviť PIN: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Generovanie náhodného PINu
  Future<void> _generateRandomPin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.generateRandomPin(widget.student.id);

      setState(() {
        _hasPinAuth = true;
        _currentPin = result['pin'];
        _pinController.text = _currentPin ?? '';
        _successMessage = 'Bol vygenerovaný náhodný PIN: ${_currentPin}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nepodarilo sa vygenerovať PIN: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Nastavenie farebného kódu
  Future<void> _setColorCode() async {
    if (_selectedColors.isEmpty || _selectedColors.length < 4) {
      setState(() {
        _errorMessage = 'Farebný kód musí obsahovať aspoň 4 farby';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiService.setStudentColorCode(widget.student.id, _selectedColors);

      setState(() {
        _hasColorCodeAuth = true;
        _currentColorCode = List<String>.from(_selectedColors);
        _successMessage = 'Farebný kód bol úspešne nastavený';
        _isLoading = false;
        _showColorCodePicker = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nepodarilo sa nastaviť farebný kód: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Generovanie náhodného farebného kódu
  Future<void> _generateRandomColorCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _apiService.generateRandomColorCode(widget.student.id);

      setState(() {
        _hasColorCodeAuth = true;
        _currentColorCode = List<String>.from(result['colorCode']);
        _selectedColors = List<String>.from(_currentColorCode);
        _successMessage = 'Bol vygenerovaný náhodný farebný kód';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Nepodarilo sa vygenerovať farebný kód: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      DateTime? birthDate;
      if (_dateOfBirthController.text.isNotEmpty) {
        try {
          birthDate = _parseDateOfBirth(_dateOfBirthController.text);
        } catch (e) {
          setState(() {
            _errorMessage = "Neplatný formát dátumu. Použite formát DD/MM/RRRR";
            _isLoading = false;
          });
          return;
        }
      }

      final success = await _apiService.updateUserById(
        userId: widget.student.id,
        name: _nameController.text,
        email: _emailController.text,
        notes: _notesController.text,
        hasSpecialNeeds: _hasSpecialNeeds,
        needsDescription: _hasSpecialNeeds ? _needsDescriptionController.text : null,
        dateOfBirth: birthDate,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Údaje boli úspešne aktualizované')),
        );

        Navigator.pop(
          context,
          Student(
            id: widget.student.id,
            name: _nameController.text,
            email: _emailController.text,
            notes: _notesController.text,
            status: widget.student.status,
            hasSpecialNeeds: _hasSpecialNeeds,
            needsDescription: _hasSpecialNeeds ? _needsDescriptionController.text : '',
            lastActive: widget.student.lastActive,
            dateOfBirth: birthDate,
          ),
        );
      } else {
        setState(() {
          _errorMessage = 'Nepodarilo sa aktualizovať údaje';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  // Pomocná metóda na parsovanie dátumu
  DateTime _parseDateOfBirth(String date) {
    final separator = date.contains('/') ? '/' : '.';
    final parts = date.split(separator);

    if (parts.length == 3) {
      try {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      } catch (e) {
        throw Exception('Neplatný formát dátumu');
      }
    } else {
      throw Exception('Neplatný formát dátumu');
    }
  }

  // Získanie farby pre zobrazenie
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red': return Colors.red;
      case 'blue': return Colors.blue;
      case 'green': return Colors.green;
      case 'yellow': return Colors.yellow;
      case 'purple': return Colors.purple;
      case 'orange': return Colors.orange;
      default: return Colors.grey;
    }
  }

  // Zobrazenie farebného výberu
  void _showColorCodeDialog() {
    setState(() {
      _selectedColors = List<String>.from(_currentColorCode);
      _showColorCodePicker = true;
    });
  }

  // Widget pre výber farby
  Widget _buildColorPicker() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Vyberte farebný kód (aspoň 4 farby)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Zobrazenie vybratých farieb
          Container(
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _selectedColors.isEmpty
                  ? [const Text('Žiadne vybrané farby', style: TextStyle(color: Colors.white),)]
                  : _selectedColors.map((color) {
                return Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: _getColorFromString(color),
                    shape: BoxShape.circle,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Dostupné farby
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _availableColors.map((color) {
              final isSelected = _selectedColors.contains(color);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedColors.remove(color);
                    } else {
                      _selectedColors.add(color);
                    }
                  });
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _getColorFromString(color),
                    shape: BoxShape.circle,
                    border: isSelected
                        ? Border.all(color: Colors.black, width: 3)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Tlačidlá
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showColorCodePicker = false;
                  });
                },
                child: const Text('Zrušiť'),
              ),
              ElevatedButton(
                onPressed: _setColorCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF4A261),
                ),
                child: const Text('Potvrdiť'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: const Text('Upraviť študenta'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _saveChanges,
            icon: const Icon(Icons.save),
            label: const Text('Uložiť'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
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
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_errorMessage != null)
                        MessageDisplay(
                          message: _errorMessage!,
                          type: MessageType.error,
                        ),

                      if (_successMessage != null)
                        MessageDisplay(
                          message: _successMessage!,
                          type: MessageType.success,
                        ),

                      // Profile image placeholder
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: _hasSpecialNeeds ? Colors.orange : Colors.blue,
                              child: const Icon(Icons.person, size: 50, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      FormTextField(
                        label: 'Meno a priezvisko',
                        placeholder: 'Zadajte meno a priezvisko',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 16),

                      // Email field
                      FormTextField(
                        label: 'E-mail',
                        placeholder: 'Zadajte e-mail',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth field
                      FormDateField(
                        label: 'Dátum narodenia',
                        placeholder: 'DD/MM/RRRR',
                        controller: _dateOfBirthController,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Checkbox(
                            value: _hasSpecialNeeds,
                            onChanged: (value) {
                              setState(() {
                                _hasSpecialNeeds = value ?? false;
                              });
                            },
                          ),
                          const Text('Študent má špeciálne potreby'),
                        ],
                      ),

                      if (_hasSpecialNeeds) ...[
                        const SizedBox(height: 16),
                        FormTextField(
                          label: 'Popis špeciálnych potrieb',
                          placeholder: 'Zadajte popis špeciálnych potrieb',
                          controller: _needsDescriptionController,
                        ),
                      ],
                      const SizedBox(height: 16),

                      FormTextField(
                        label: 'Poznámky',
                        placeholder: 'Zadajte poznámky',
                        controller: _notesController,
                      ),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      const Text(
                        'Metódy prihlásenia',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'PIN kód',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Switch(
                                  value: _hasPinAuth,
                                  activeColor: Colors.orange,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasPinAuth = value;
                                      if (!value) {
                                        _pinController.clear();
                                        _currentPin = null;
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_hasPinAuth) ...[
                              const SizedBox(height: 8),

                              if (_currentPin != null && _currentPin!.isNotEmpty) ...[
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    'Aktuálny PIN: $_currentPin',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],

                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _pinController,
                                      decoration: const InputDecoration(
                                        labelText: 'Zadajte PIN (min. 4 číslice)',
                                        border: OutlineInputBorder(),
                                      ),
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(6),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _setPin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF4A261),
                                    ),
                                    child: const Text('Nastaviť', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _generateRandomPin,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Generovať náhodný PIN'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade300,
                                  foregroundColor: Colors.black,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Farebný kód',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Switch(
                                  value: _hasColorCodeAuth,
                                  activeColor: Colors.orange,
                                  onChanged: (value) {
                                    setState(() {
                                      _hasColorCodeAuth = value;
                                      if (!value) {
                                        _currentColorCode = [];
                                        _selectedColors = [];
                                      }
                                    });
                                  },
                                ),
                              ],
                            ),
                            if (_hasColorCodeAuth) ...[
                              const SizedBox(height: 8),

                              if (_currentColorCode.isNotEmpty) ...[
                                const Text(
                                  'Aktuálny farebný kód:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: _currentColorCode.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final color = entry.value;
                                    return Container(
                                      width: 30,
                                      height: 30,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      decoration: BoxDecoration(
                                        color: _getColorFromString(color),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.black, width: 1),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                offset: Offset(1, 1),
                                                blurRadius: 3.0,
                                                color: Colors.black,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                              ],

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _showColorCodeDialog,
                                    icon: const Icon(
                                      Icons.palette,
                                      color: Colors.white
                                    ),
                                    label: const Text('Vybrať farby', style: TextStyle(color: Colors.white)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF4A261),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _generateRandomColorCode,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('Náhodné farby'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade300,
                                      foregroundColor: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF4A261),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Uložiť zmeny',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Prekrytie pre výber farieb
          if (_showColorCodePicker)
            Container(
              color: Colors.black.withOpacity(0.5),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _buildColorPicker(),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _isLoading
          ? Container(
        height: 4,
        child: const LinearProgressIndicator(),
      )
          : null,
    );
  }
}