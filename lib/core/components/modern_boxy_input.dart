import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ModernBoxyInput extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final bool autofocus;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;
  
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;

  const ModernBoxyInput({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.validator,
    this.suffixIcon,
    this.autofocus = false,
    this.keyboardType,
    this.textInputAction,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final boxyRadius = BorderRadius.circular(DesignTokens.spacingXs); 

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
      focusNode: focusNode, 
      autofocus: autofocus,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      readOnly: readOnly, 
      showCursor: readOnly ? true : null, // <-- Forces blinking cursor on calc fields
      onTap: onTap,       
      onFieldSubmitted: onFieldSubmitted, 
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