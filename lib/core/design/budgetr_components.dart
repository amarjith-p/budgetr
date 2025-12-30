// lib/core/design/budgetr_components.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'budgetr_colors.dart';
import 'budgetr_styles.dart';

// --- 1. Standard Glass Card ---
class BudgetrGlassCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final EdgeInsets margin;

  const BudgetrGlassCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BudgetrStyles.radiusM,
        border: BudgetrStyles.glassBorder,
        boxShadow: BudgetrStyles.glowBoxShadow(BudgetrColors.accent),
      ),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BudgetrStyles.radiusM,
        splashColor: BudgetrColors.accent.withOpacity(0.2),
        highlightColor: BudgetrColors.accent.withOpacity(0.1),
        child: content,
      );
    }

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: BudgetrStyles.radiusM,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: content,
        ),
      ),
    );
  }
}

// --- 2. Standard Input Fields ---
class BudgetrInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? prefixText;
  final String? hintText;
  final TextInputType keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final FocusNode? focusNode;

  const BudgetrInput({
    super.key,
    required this.controller,
    required this.label,
    this.prefixText,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
    this.onTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: BudgetrStyles.caption),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          readOnly: readOnly,
          keyboardType: keyboardType,
          style: BudgetrStyles.h3,
          onTap: onTap,
          cursorColor: BudgetrColors.accent,
          decoration: InputDecoration(
            prefixText: prefixText,
            prefixStyle: const TextStyle(color: BudgetrColors.textSecondary),
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.white24),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BudgetrStyles.radiusS,
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BudgetrStyles.radiusS,
              borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BudgetrStyles.radiusS,
              borderSide: const BorderSide(color: BudgetrColors.accent),
            ),
          ),
        ),
      ],
    );
  }
}

// --- 3. Primary Button ---
class BudgetrButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;

  const BudgetrButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: BudgetrColors.primaryGradient,
        borderRadius: BudgetrStyles.radiusM,
        boxShadow: BudgetrStyles.glowBoxShadow(BudgetrColors.accent),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BudgetrStyles.radiusM),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// --- 4. Scaffold Wrapper (Handles Background) ---
class BudgetrScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;

  const BudgetrScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BudgetrColors.background,
      appBar: appBar,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Global Ambient Gradient (Optional)
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BudgetrColors.accent.withOpacity(0.15),
                    Colors.transparent,
                  ],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          SafeArea(child: body),
        ],
      ),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
    );
  }
}
