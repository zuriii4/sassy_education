import 'package:flutter/material.dart';
import 'package:sassy/models/teacher.dart';
import 'package:sassy/services/api_service.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/widgets/message_display.dart';

class EditTeacherScreen extends StatefulWidget {
  final Teacher teacher;

  const EditTeacherScreen({
    Key? key,
    required this.teacher,
  }) : super(key: key);

  @override
  State<EditTeacherScreen> createState() => _EditTeacherScreenState();
}

class _EditTeacherScreenState extends State<EditTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  String? _errorMessage;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _specializationController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.teacher.name);
    _emailController = TextEditingController(text: widget.teacher.email);
    _specializationController = TextEditingController(text: widget.teacher.specialization);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _specializationController.dispose();
    super.dispose();
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

      final teacherData = {
        'id': widget.teacher.id,
        'name': _nameController.text,
        'email': _emailController.text,
        'specialization': _specializationController.text,
      };
      
      await _apiService.updateUserById(
        userId: widget.teacher.id,
        name: _nameController.text,
        email: _emailController.text,
        specialization: _specializationController.text,
      );
      
      final updatedTeacher = Teacher(
        id: widget.teacher.id,
        name: _nameController.text,
        email: _emailController.text,
        specialization: _specializationController.text,
      );

      Navigator.pop(context, updatedTeacher);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 230, 217),
      appBar: AppBar(
        title: const Text('Upraviť učiteľa'),
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
      body: _isLoading
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

                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.person, size: 50, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 24),

                      FormTextField(
                        label: 'Meno a priezvisko',
                        placeholder: 'Zadajte meno a priezvisko',
                        controller: _nameController,
                      ),
                      const SizedBox(height: 16),

                      FormTextField(
                        label: 'E-mail',
                        placeholder: 'Zadajte e-mail',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Specialization field
                      FormTextField(
                        label: 'Špecializácia',
                        placeholder: 'Zadajte špecializáciu',
                        controller: _specializationController,
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
      bottomNavigationBar: _isLoading
        ? Container(
            height: 4,
            child: const LinearProgressIndicator(),
          )
        : null,
    );
  }
}