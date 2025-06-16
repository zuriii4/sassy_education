import 'package:flutter/material.dart';
import 'package:sassy/widgets/message_display.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/services/api_service.dart';

class AccountTab extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController surnameController;
  final TextEditingController birthdateController;
  final TextEditingController emailController;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Function() onSave;

  const AccountTab({
    Key? key,
    required this.nameController,
    required this.surnameController,
    required this.birthdateController,
    required this.emailController,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.onSave,
  }) : super(key: key);

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final ApiService _apiService = ApiService();
  bool _isInitializing = true;
  String? _initErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final userData = await _apiService.getCurrentUser();
      if (userData != null && mounted) {
        // Rozdelenie celého mena na meno a priezvisko
        final nameParts = userData['user']['name']?.split(' ') ?? [];
        if (nameParts.isNotEmpty) {
          widget.nameController.text = nameParts.first;
          if (nameParts.length > 1) {
            widget.surnameController.text = nameParts.skip(1).join(' ');
          }
        }
        
        widget.emailController.text = userData['user']['email'] ?? '';
        
        // Správne formátovanie dátumu narodenia
        if (userData['user']['dateOfBirth'] != null) {
          try {
            final DateTime date = DateTime.parse(userData['user']['dateOfBirth']);
            widget.birthdateController.text = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
          } catch (e) {
            widget.birthdateController.text = '';
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initErrorMessage = "Nepodarilo sa načítať používateľské údaje: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF4A261)),
        ),
      );
    }

    return ListView(
      children: [
        Center(
          child: Stack(
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Color(0xFFF4A261),
                child: Icon(Icons.person, size: 60, color: Colors.white),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        if (_initErrorMessage != null)
          MessageDisplay(
            message: _initErrorMessage!,
            type: MessageType.error,
          ),
          
        if (widget.errorMessage != null)
          MessageDisplay(
            message: widget.errorMessage!,
            type: MessageType.error,
          ),
        if (widget.successMessage != null)
          MessageDisplay(
            message: widget.successMessage!,
            type: MessageType.success,
          ),
        
        FormTextField(
          label: "Meno",
          placeholder: "Zadajte vaše meno",
          controller: widget.nameController
        ),
        const SizedBox(height: 10),
        
        FormTextField(
          label: "Priezvisko",
          placeholder: "Zadajte vaše priezvisko",
          controller: widget.surnameController
        ),
        const SizedBox(height: 10),
        
        FormDateField(
          label: "Dátum narodenia",
          placeholder: "DD.MM.RRRR",
          controller: widget.birthdateController
        ),
        const SizedBox(height: 10),
        
        FormTextField(
          label: "Email",
          placeholder: "Zadajte váš email",
          controller: widget.emailController
        ),
        const SizedBox(height: 20),
        
        const Row(
          children: [
            Icon(Icons.info, color: Colors.blue),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Vaše osobné údaje sú chránené a používané len na účely zlepšenia vašej skúsenosti s aplikáciou.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        ElevatedButton.icon(
          onPressed: widget.isLoading ? null : widget.onSave,
          icon: widget.isLoading
            ? Container(
                width: 24,
                height: 24,
                padding: const EdgeInsets.all(2.0),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              )
            : const Icon(Icons.save),
          label: Text(
            widget.isLoading ? "Aktualizácia..." : "Uložiť zmeny",
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            iconColor: Colors.white,
            backgroundColor: const Color(0xFFF4A261),
            disabledBackgroundColor: const Color(0xFFF4A261).withOpacity(0.7),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}