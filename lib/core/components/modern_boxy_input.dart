import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ModernBoxyInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool autofocus;
  
  // ─── ADDED KEYBOARD PARAMETERS ───
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const ModernBoxyInput({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.suffixIcon,
    this.autofocus = false,
    // ─── ADDED TO CONSTRUCTOR ───
    this.keyboardType,
    this.textInputAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // The strict Boxy aesthetic
    final boxyRadius = BorderRadius.circular(DesignTokens.spacingXs); // 4.0 radius
    
    final boxyBorder = OutlineInputBorder(
      borderRadius: boxyRadius,
      borderSide: BorderSide(color: theme.dividerColor, width: 1.2),
    );
    
    final focusedBoxyBorder = OutlineInputBorder(
      borderRadius: boxyRadius,
      borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
    );
    
    final errorBoxyBorder = OutlineInputBorder(
      borderRadius: boxyRadius,
      borderSide: BorderSide(color: theme.colorScheme.error, width: 1.2),
    );

    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      // ─── PASSED TO TEXTFORMFIELD ───
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      style: const TextStyle(fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        alignLabelWithHint: true,
        border: boxyBorder,
        enabledBorder: boxyBorder,
        focusedBorder: focusedBoxyBorder,
        errorBorder: errorBoxyBorder,
        filled: true,
        fillColor: theme.colorScheme.surface,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }
}