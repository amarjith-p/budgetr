// APP LOGO PROGRESSBAR

// import 'dart:ui';
// import 'package:flutter/material.dart';

// class ModernLoader extends StatefulWidget {
//   final double size;
//   const ModernLoader({super.key, this.size = 80});

//   @override
//   State<ModernLoader> createState() => _ModernLoaderState();
// }

// class _ModernLoaderState extends State<ModernLoader>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;

//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: const Duration(seconds: 2),
//       vsync: this,
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Center(
//       child: Stack(
//         alignment: Alignment.center,
//         children: [
//           // 1. Ambient Glow
//           Container(
//             width: widget.size,
//             height: widget.size,
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               boxShadow: [
//                 BoxShadow(
//                   color: colorScheme.primary.withOpacity(0.2),
//                   blurRadius: 24,
//                   spreadRadius: 0,
//                 ),
//               ],
//             ),
//           ),
//           // 2. Glass Disc Background
//           ClipOval(
//             child: BackdropFilter(
//               filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//               child: Container(
//                 width: widget.size * 0.9,
//                 height: widget.size * 0.9,
//                 decoration: BoxDecoration(
//                   color: Colors.white.withOpacity(0.05),
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color: Colors.white.withOpacity(0.1),
//                     width: 1,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           // 3. Static Track Ring
//           SizedBox(
//             width: widget.size * 0.6,
//             height: widget.size * 0.6,
//             child: CircularProgressIndicator(
//               strokeWidth: 3,
//               value: 1,
//               valueColor: AlwaysStoppedAnimation<Color>(
//                 colorScheme.primary.withOpacity(0.15),
//               ),
//             ),
//           ),
//           // 4. Animated Indicator Ring
//           RotationTransition(
//             turns: _controller,
//             child: SizedBox(
//               width: widget.size * 0.6,
//               height: widget.size * 0.6,
//               child: CircularProgressIndicator(
//                 strokeWidth: 3,
//                 valueColor: AlwaysStoppedAnimation<Color>(
//                   colorScheme.secondary,
//                 ),
//                 backgroundColor: Colors.transparent,
//                 strokeCap: StrokeCap.round,
//               ),
//             ),
//           ),
//           // 5. Center App Logo (Clipped to Circle)
//           SizedBox(
//             width: widget.size * 0.35,
//             height: widget.size * 0.35,
//             // ClipOval forces the square image into a circle
//             child: ClipOval(
//               child: Image.asset(
//                 'assets/icon/budgetr.png',
//                 fit: BoxFit.cover,
//                 // Using cover ensures the image fills the circle.
//                 // If the logo gets cut off, change this to BoxFit.contain
//                 errorBuilder: (context, error, stackTrace) {
//                   return Icon(
//                     Icons.savings_outlined,
//                     size: widget.size * 0.3,
//                     color: colorScheme.primary.withOpacity(0.8),
//                   );
//                 },
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:ui';
import 'package:flutter/material.dart';

class ModernLoader extends StatefulWidget {
  final double size;
  const ModernLoader({super.key, this.size = 80});

  @override
  State<ModernLoader> createState() => _ModernLoaderState();
}

class _ModernLoaderState extends State<ModernLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient Glow
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.2),
                  blurRadius: 24,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
          // 2. Glass Disc Background
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: widget.size * 0.9,
                height: widget.size * 0.9,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
          // 3. Static Track Ring
          SizedBox(
            width: widget.size * 0.6,
            height: widget.size * 0.6,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              value: 1,
              valueColor: AlwaysStoppedAnimation<Color>(
                colorScheme.primary.withOpacity(0.15),
              ),
            ),
          ),
          // 4. Animated Indicator Ring
          RotationTransition(
            turns: _controller,
            child: SizedBox(
              width: widget.size * 0.6,
              height: widget.size * 0.6,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  colorScheme.secondary,
                ),
                backgroundColor: Colors.transparent,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          // 5. Center Rupee Symbol
          Text(
            '₹',
            style: TextStyle(
              fontSize: widget.size * 0.35,
              fontWeight: FontWeight.w300, // Thinner weight looks more elegant
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
