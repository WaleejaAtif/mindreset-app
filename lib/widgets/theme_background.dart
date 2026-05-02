import 'package:flutter/material.dart';
import 'dart:ui';

class ThemeBackground extends StatelessWidget {
  final Widget child;

  const ThemeBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C1A4D), // Soft glowing purple at top
            Color(0xFF150E28), // Deep purple middle
            Color(0xFF0D0B1A), // Near black at bottom
          ],
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Optional subtle glow effect
          Container(
            color: const Color(0xFF8C52FF).withValues(alpha: 0.05),
          ),
          child,
        ],
      ),
    );
  }
}

