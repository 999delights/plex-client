// custom_button.dart
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final bool isPressed;
  final bool isEnabled;
  final VoidCallback? onPressed;

  const CustomButton({
    required this.text,
    required this.isPressed,
    required this.isEnabled,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: isPressed ? Colors.blue : Colors.white.withOpacity(0.3), shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24),
      ),
      child: Text(text),
    );
  }
}
