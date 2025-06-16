import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String count;
  final String label;
  final Color? countColor;
  
  const StatCard({
    Key? key,
    required this.count,
    required this.label,
    this.countColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: countColor,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}