import 'package:flutter/material.dart';
import 'modern_loader.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color? color;
  final double opacity;

  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.color = Colors.black,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: (color ?? Colors.black).withOpacity(opacity),
              child: const Center(child: ModernLoader(size: 60)),
            ),
          ),
      ],
    );
  }
}
