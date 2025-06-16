import 'package:flutter/material.dart';
import 'package:sassy/widgets/message_display.dart';
import 'package:sassy/widgets/form_fields.dart';

class PrivacyTab extends StatelessWidget {
  final TextEditingController currentPasswordController;
  final TextEditingController newPasswordController;
  final TextEditingController confirmPasswordController;
  final bool showCurrentPassword;
  final bool showNewPassword;
  final bool showConfirmPassword;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final Function() onToggleCurrentPassword;
  final Function() onToggleNewPassword;
  final Function() onToggleConfirmPassword;
  final Function() onSave;

  const PrivacyTab({
    Key? key,
    required this.currentPasswordController,
    required this.newPasswordController,
    required this.confirmPasswordController,
    required this.showCurrentPassword,
    required this.showNewPassword,
    required this.showConfirmPassword,
    required this.isLoading,
    required this.errorMessage,
    required this.successMessage,
    required this.onToggleCurrentPassword,
    required this.onToggleNewPassword,
    required this.onToggleConfirmPassword,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        if (errorMessage != null)
          MessageDisplay(
            message: errorMessage!,
            type: MessageType.error,
          ),
          
        if (successMessage != null)
          MessageDisplay(
            message: successMessage!,
            type: MessageType.success,
          ),
          
        const Text(
          "Zmena hesla",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 15),
        FormPasswordField(
          label: "Aktuálne heslo", 
          placeholder: "Zadajte vaše aktuálne heslo", 
          controller: currentPasswordController,
          showPassword: showCurrentPassword,
          onToggleVisibility: onToggleCurrentPassword,
        ),
        const SizedBox(height: 10),
        FormPasswordField(
          label: "Nové heslo", 
          placeholder: "Zadajte nové heslo (min. 8 znakov)", 
          controller: newPasswordController,
          showPassword: showNewPassword,
          onToggleVisibility: onToggleNewPassword,
        ),
        const SizedBox(height: 10),
        FormPasswordField(
          label: "Potvrďte nové heslo", 
          placeholder: "Znovu zadajte nové heslo", 
          controller: confirmPasswordController,
          showPassword: showConfirmPassword,
          onToggleVisibility: onToggleConfirmPassword,
        ),
        const SizedBox(height: 15),
        const Row(
          children: [
            Icon(Icons.security, color: Colors.red),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Pre zvýšenie bezpečnosti používajte silné heslo obsahujúce kombináciu veľkých a malých písmen, číslic a špeciálnych znakov.",
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: isLoading ? null : onSave,
          icon: isLoading 
              ? Container(
                  width: 24,
                  height: 24,
                  padding: const EdgeInsets.all(2.0),
                  child: const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : const Icon(Icons.lock),
          label: Text(
            isLoading ? "Aktualizácia..." : "Zmeniť heslo",
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
        const SizedBox(height: 30),
      ],
    );
  }
}