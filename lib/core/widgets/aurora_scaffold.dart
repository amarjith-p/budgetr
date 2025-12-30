import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuroraScaffold extends StatefulWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final Color accentColor1;
  final Color accentColor2;

  const AuroraScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.accentColor1 = AppColors.royalBlue,
    this.accentColor2 = AppColors.deepPurple,
  });

  @override
  State<AuroraScaffold> createState() => _AuroraScaffoldState();
}

class _AuroraScaffoldState extends State<AuroraScaffold>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Ultra-slow, barely perceptible breathing (15 seconds)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepVoid, // Pure dark foundation
      extendBodyBehindAppBar: true,
      appBar: widget.appBar,
      floatingActionButton: widget.floatingActionButton,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      bottomNavigationBar: widget.bottomNavigationBar,
      body: Stack(
        children: [
          // --- AMBIENT LIGHTING LAYER ---
          // Reduced opacity significantly for a "Dark Mode First" look
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  // Light Source 1: Top Left (Subtle glow for header)
                  Positioned(
                    top: -150,
                    left: -100,
                    child: _buildOrb(widget.accentColor1, 400),
                  ),

                  // Light Source 2: Bottom Right (Subtle glow for balance)
                  Positioned(
                    bottom: -150,
                    right: -100,
                    child: _buildOrb(widget.accentColor2, 350),
                  ),
                ],
              );
            },
          ),

          // --- MATTE FINISH LAYER ---
          // High-sigma blur meshes the colors into a seamless gradient
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),

          // --- MAIN CONTENT ---
          SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.only(
                top:
                    (widget.appBar?.preferredSize.height ?? 0) +
                    MediaQuery.of(context).padding.top,
              ),
              child: widget.body,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Drastically reduced opacity (0.07) for professional minimalism.
        // It provides "Ambience" rather than "Color".
        color: color.withOpacity(0.07),
      ),
    );
  }
}
