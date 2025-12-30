import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AuroraScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation?
  floatingActionButtonLocation; // <--- Added this
  final Widget? bottomNavigationBar;
  final Color accentColor1;
  final Color accentColor2;

  const AuroraScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation, // <--- Added to constructor
    this.bottomNavigationBar,
    this.accentColor1 = AppColors.royalBlue,
    this.accentColor2 = AppColors.electricPink,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepVoid,
      extendBodyBehindAppBar: true,
      appBar: appBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation:
          floatingActionButtonLocation, // <--- Pass to Scaffold
      bottomNavigationBar: bottomNavigationBar,
      body: Stack(
        children: [
          // --- ORB 1 (Top Left) ---
          Positioned(top: -100, left: -50, child: _buildOrb(accentColor1, 350)),

          // --- ORB 2 (Bottom Right) ---
          Positioned(
            bottom: -50,
            right: -50,
            child: _buildOrb(accentColor2, 300),
          ),

          // --- MAIN CONTENT ---
          SafeArea(
            top: false,
            child: Padding(
              // Add StatusBar Height + AppBar Height so content doesn't hide behind header
              padding: EdgeInsets.only(
                top:
                    (appBar?.preferredSize.height ?? 0) +
                    MediaQuery.of(context).padding.top,
              ),
              child: body,
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
        color: color.withOpacity(0.15),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}
