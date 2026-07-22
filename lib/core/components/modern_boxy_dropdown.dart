import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class ModernBoxyDropdown<T> extends StatelessWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String labelText;
  final String? Function(T?)? validator;

  const ModernBoxyDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelText,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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

    return DropdownButtonFormField<T>(
      value: value,
      items: items,
      onChanged: onChanged,
      validator: validator,
      isExpanded: true, // Prevents overflow if bank names are long
      icon: const Icon(Icons.arrow_drop_down_rounded),
      decoration: InputDecoration(
        labelText: labelText,
        border: boxyBorder,
        enabledBorder: boxyBorder,
        focusedBorder: focusedBoxyBorder,
        errorBorder: errorBoxyBorder,
        filled: true,
        fillColor: theme.colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      dropdownColor: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(DesignTokens.spacingSm),
    );
  }
}