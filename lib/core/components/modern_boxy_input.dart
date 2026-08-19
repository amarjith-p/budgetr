import 'package:flutter/material.dart';

class ModernBoxyInput extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
  final bool enabled;
  final bool obscureText;
  final int maxLines; // --- NEW PARAMETER ---
  final VoidCallback? onTap;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;

  const ModernBoxyInput({
    Key? key,
    required this.controller,
    required this.labelText,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.suffixIcon,
    this.prefixIcon,
    this.readOnly = false,
    this.enabled = true,
    this.obscureText = false,
    this.maxLines = 1, // --- DEFAULT TO 1 ---
    this.onTap,
    this.validator,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  }) : super(key: key);

  @override
  State<ModernBoxyInput> createState() => _ModernBoxyInputState();
}

class _ModernBoxyInputState extends State<ModernBoxyInput> {
  late FocusNode _internalFocusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return TextFormField(
      controller: widget.controller,
      focusNode: _internalFocusNode,
      keyboardType: widget.keyboardType,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      obscureText: widget.obscureText,
      maxLines: widget.maxLines, // --- PASS MAXLINES ---
      onTap: widget.onTap,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: !widget.enabled
            ? theme.colorScheme.onSurface.withOpacity(0.5)
            : theme.colorScheme.onSurface,
        letterSpacing: 0.3,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: _isFocused ? FontWeight.w800 : FontWeight.w600,
          color: _isFocused
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
        floatingLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
          letterSpacing: 1.0,
        ),
        filled: true,
        fillColor: !widget.enabled
            ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.2)
            : _isFocused
            ? theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(
                isDark ? 0.3 : 0.5,
              ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.2),
            width: 1.0,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.error.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
        ),
        errorStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 9,
          color: theme.colorScheme.error,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
