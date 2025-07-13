import 'package:flutter/material.dart';

// model pentru banner de eroare
// widget-ul este folosit pentru a afisa mesaje de eroare sau succes
// tipuri de mesaje pentru banner
enum MessageType { error, success }

class ErrorBanner extends StatelessWidget {
  final String message; // mesajul de afisat
  final MessageType messageType; // tipul mesajului (eroare sau succes)
  final VoidCallback? onDismiss; // callback pentru butonul de inchidere
  const ErrorBanner({
    super.key,
    required this.message,
    this.messageType = MessageType.error,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // culori in functie de tipul mesajului
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor;
    Color textColor;
    IconData icon;

    if (messageType == MessageType.success) {
      backgroundColor = colorScheme.secondaryContainer;
      textColor = colorScheme.onSecondaryContainer;
      icon = Icons.check_circle_outline;
    } else {
      backgroundColor = colorScheme.errorContainer;
      textColor = colorScheme.onErrorContainer;
      icon = Icons.error_outline;
    }

    return Container(
      width: double.infinity, // ocupa toata latimea
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor), // iconita in stanga
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: TextStyle(color: textColor))),
          if (onDismiss != null)
            IconButton(
              icon: Icon(Icons.close, size: 20, color: textColor),
              onPressed: onDismiss, // buton de inchidere
            ),
        ],
      ),
    );
  }
}
