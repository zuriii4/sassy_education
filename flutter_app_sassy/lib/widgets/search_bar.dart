import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final Function()? onClear;
  final bool autofocus;
  
  const CustomSearchBar({
    Key? key,
    required this.controller,
    this.hintText = "Hľadať",
    this.onChanged,
    this.onClear,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF4F4F4),
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  controller.clear();
                  if (onClear != null) {
                    onClear!();
                  }
                  if (onChanged != null) {
                    onChanged!('');
                  }
                },
              )
            : null,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: onChanged,
    );
  }
}