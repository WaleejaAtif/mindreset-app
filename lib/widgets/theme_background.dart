import 'package:flutter/material.dart';
import 'dart:ui';

class ThemeBackground extends StatelessWidget {
  final Widget child;

  const ThemeBackground({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/theme_bg.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          // Purple tinted overlay
          Container(
            color: const Color(0xFF8C52FF).withValues(alpha: 0.15),
          ),
          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
            child: Container(color: Colors.transparent),
          ),
          child,
        ],
      ),
    );
  }
}
