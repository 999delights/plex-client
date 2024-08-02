import 'package:flutter/material.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String)? onChanged;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final FocusNode? focusNode;
  final bool obscureText;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
    this.suffixIcon,
    this.prefixIcon,
    this.focusNode,
    this.obscureText = false,
  });

  @override
  CustomTextFieldState createState() => CustomTextFieldState();
}

class CustomTextFieldState extends State<CustomTextField> {
  late bool _isFieldNotEmpty;

  @override
  void initState() {
    super.initState();
    _isFieldNotEmpty = widget.controller.text.isNotEmpty;
    widget.controller.addListener(_updateSuffixIconVisibility);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSuffixIconVisibility);
    super.dispose();
  }

  void _updateSuffixIconVisibility() {
    final isNotEmpty = widget.controller.text.isNotEmpty;
    if (_isFieldNotEmpty != isNotEmpty) {
      setState(() {
        _isFieldNotEmpty = isNotEmpty;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: (text) {
        widget.onChanged?.call(text);
        _updateSuffixIconVisibility();
      },
      obscureText: widget.obscureText,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.transparent, width: 0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        filled: true,
        fillColor: const Color(0xff333333), // Darker fill color for better contrast
        hintText: widget.hintText,
        hintStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        suffixIcon: _isFieldNotEmpty ? widget.suffixIcon : null,
        prefixIcon: widget.prefixIcon,
      ),
    );
  }
}
