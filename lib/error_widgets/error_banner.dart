import 'package:flutter/material.dart';

enum MessageType { error, success }

class ErrorBanner extends StatelessWidget {
  final String message;
  final MessageType messageType;
  final VoidCallback? onDismiss;

  const ErrorBanner({
    super.key,
    required this.message,
    this.messageType = MessageType.error, // Default is error
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Set color scheme based on message type
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (messageType == MessageType.success) {
      backgroundColor = colorScheme.secondaryContainer;
      textColor = colorScheme.onSecondaryContainer;
      icon = Icons.check_circle_outline; // Success icon
    } else {
      backgroundColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      icon = Icons.error_outline; // Error icon
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: textColor))),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 20, color: textColor),
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
