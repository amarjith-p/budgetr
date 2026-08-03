import 'package:flutter/material.dart';

class ModernBoxyInput extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final TextInputType keyboardType;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final bool readOnly;
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
    // Use the provided FocusNode, or create one if none was passed
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    // Only dispose the FocusNode if we created it internally
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
      onTap: widget.onTap,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      // 1. MODERN INPUT TEXT: Bold and crisp for premium readability
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: theme.colorScheme.onSurface,
        letterSpacing: 0.3,
      ),
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        
        // 2. IDLE LABEL: Clean and semi-transparent
        labelStyle: TextStyle(
          fontSize: 14,
          fontWeight: _isFocused ? FontWeight.w800 : FontWeight.w600,
          color: _isFocused 
              ? theme.colorScheme.primary 
              : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          letterSpacing: 0.5,
        ),
        
        // 3. ACTIVE FLOATING LABEL: Snaps to an ultra-bold, tracked-out metadata style
        floatingLabelStyle: TextStyle(
          fontSize: 12, 
          fontWeight: FontWeight.w900,
          color: theme.colorScheme.primary,
          letterSpacing: 1.0,
        ),
        
        // 4. ANIMATED BACKGROUND: Subtly tints to the primary color when focused
        filled: true,
        fillColor: _isFocused 
            ? theme.colorScheme.primary.withOpacity(isDark ? 0.1 : 0.05)
            : theme.colorScheme.surfaceContainerHighest.withOpacity(isDark ? 0.3 : 0.5),
            
        // 5. SPACING: Generous internal padding prevents the cramped "traditional" feel
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.suffixIcon,
        
        // 6. IDLE BORDER: Extremely subtle, matching the filled background
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.dividerColor.withOpacity(0.5),
            width: 1.0,
          ),
        ),
        
        // 7. ACTIVE BORDER: Crisp, distinct 2px primary line
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2.0,
          ),
        ),
        
        // 8. ERROR STATES: Maintains the modern radius but applies semantic colors
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error.withOpacity(0.5),
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: theme.colorScheme.error,
            width: 2.0,
          ),
        ),
        errorStyle: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11,
          color: theme.colorScheme.error,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}