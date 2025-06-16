import 'package:flutter/material.dart';

enum MessageType {
  error,
  success,
  info,
  warning
}

class MessageDisplay extends StatelessWidget {
  final String message;
  final MessageType type;

  const MessageDisplay({
    Key? key,
    required this.message,
    required this.type,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData iconData;

    switch (type) {
      case MessageType.error:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red;
        iconData = Icons.error;
        break;
      case MessageType.success:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green;
        iconData = Icons.check_circle;
        break;
      case MessageType.info:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue;
        iconData = Icons.info;
        break;
      case MessageType.warning:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange;
        iconData = Icons.warning;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(iconData, color: textColor),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: textColor))),
        ],
      ),
    );
  }
}