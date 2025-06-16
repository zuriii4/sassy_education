import 'package:flutter/material.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/widgets/message_display.dart';

class CreateStudentScreen extends StatefulWidget {
  const CreateStudentScreen({Key? key}) : super(key: key);

  @override
  State<CreateStudentScreen> createState() => _CreateStudentScreenState();
}

class _CreateStudentScreenState extends State<CreateStudentScreen> {
  final ApiService _apiService = ApiService();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  
  bool _showPassword = false;
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _dateOfBirthController.dispose();
    super.dispose();
  }
  
  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }
  
  Future<void> _registerStudent() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Zadajte meno študenta";
      });
      return;
    }
    
    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = "Zadajte email";
      });
      return;
    }
    
    if (_passwordController.text.isEmpty) {
      setState(() {
        _errorMessage = "Zadajte heslo";
      });
      return;
    }
    
    if (_dateOfBirthController.text.isEmpty) {
      setState(() {
        _errorMessage = "Zadajte dátum narodenia";
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final parts = _dateOfBirthController.text.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      final dateOfBirth = DateTime(year, month, day);
      
      final success = await _apiService.registerStudent(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        dateOfBirth: dateOfBirth,
      );
      
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _errorMessage = "Nepodarilo sa vytvoriť študenta";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Chyba: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: const Text('Pridať nového študenta'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
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
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  MessageDisplay(
                    message: _errorMessage!,
                    type: MessageType.error,
                  ),
                
                const Text(
                  'Nový študent',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                FormTextField(
                  label: 'Meno a priezvisko',
                  placeholder: 'Zadajte meno a priezvisko',
                  controller: _nameController,
                ),
                const SizedBox(height: 15),
                
                FormTextField(
                  label: 'Email',
                  placeholder: 'email@skola.sk',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),
                
                FormPasswordField(
                  label: 'Heslo',
                  placeholder: 'Zadajte heslo',
                  controller: _passwordController,
                  showPassword: _showPassword,
                  onToggleVisibility: _togglePasswordVisibility,
                ),
                const SizedBox(height: 15),
                
                FormDateField(
                  label: 'Dátum narodenia',
                  placeholder: 'DD/MM/RRRR',
                  controller: _dateOfBirthController,
                ),
                const SizedBox(height: 30),
                
                // Tlačidlo na vytvorenie študenta
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _registerStudent,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF4A261),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Vytvoriť študenta',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}