import 'package:flutter/material.dart';
import 'package:sassy/widgets/message_display.dart';
import 'package:sassy/widgets/form_fields.dart';
import 'package:sassy/services/api_service.dart';

class SpecializationTab extends StatefulWidget {
  final TextEditingController specializationController;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Function() onSave;

  const SpecializationTab({
    Key? key,
    required this.specializationController,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.onSave,
  }) : super(key: key);

  @override
  State<SpecializationTab> createState() => _SpecializationTabState();
}

class _SpecializationTabState extends State<SpecializationTab> {
  final ApiService _apiService = ApiService();
  bool _isInitializing = true;
  String? _initErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadSpecialization();
  }

  Future<void> _loadSpecialization() async {
    setState(() {
      _isInitializing = true;
    });

    try {
      final userData = await _apiService.getCurrentUser();
      if (userData != null && mounted) {
        setState(() {
          widget.specializationController.text = userData['user']['specialization'] ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initErrorMessage = "Nepodarilo sa načítať špecializáciu: ${e.toString()}";
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
        // Init error message
        if (_initErrorMessage != null)
          MessageDisplay(
            message: _initErrorMessage!,
            type: MessageType.error,
          ),
          
        // Status messages from parent
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
          
        const Text(
          "Vaša špecializácia",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        
        FormTextField(
          label: "Špecializácia",
          placeholder: "Zadajte vašu špecializáciu",
          controller: widget.specializationController
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
            widget.isLoading ? "Aktualizácia..." : "Uložiť špecializáciu",
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