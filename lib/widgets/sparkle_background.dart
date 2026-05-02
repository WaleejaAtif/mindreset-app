import 'dart:math';
import 'package:flutter/material.dart';

class SparkleBackground extends StatefulWidget {
  final Widget child;

  const SparkleBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<SparkleBackground> createState() => _SparkleBackgroundState();
}

class _SparkleBackgroundState extends State<SparkleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    final List<Color> appPalette = [
      const Color(0xFF884288), // Primary purple
      const Color(0xFF608BA5), // Secondary blue
      const Color(0xFF8C52FF), // Vibrant purple
      const Color(0xFFFF9800), // Flame orange
      const Color(0xFFF1B111), // Loot gold
      const Color(0xFF0CAF5B), // Green
      const Color(0xFFAB7DAC), // Light purple
    ];

    // Create 400 random stars
    _stars = List.generate(400, (index) {
      return _Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        dx: (_random.nextDouble() - 0.5) * 0.05, // Slight horizontal drift
        dy: (_random.nextDouble() - 0.5) * 0.05, // Slight vertical drift
        maxSize: _random.nextDouble() * 3 + 1, // 1 to 4 px
        blinkSpeed: _random.nextDouble() * 2 + 0.5,
        timeOffset: _random.nextDouble() * 2 * pi,
        color: appPalette[_random.nextInt(appPalette.length)],
      );
    });

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10), // Continuous loop
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: _SparklePainter(_stars, _controller.value * 2 * pi),
                );
              },
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Star {
  final double x;
  final double y;
  final double dx; // Velocity X
  final double dy; // Velocity Y
  final double maxSize;
  final double blinkSpeed;
  final double timeOffset;
  final Color color;

  _Star({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.maxSize,
    required this.blinkSpeed,
    required this.timeOffset,
    required this.color,
  });
}

class _SparklePainter extends CustomPainter {
  final List<_Star> stars;
  final double time;

  _SparklePainter(this.stars, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (var star in stars) {
      // Calculate opacity using sine wave for smooth twinkling
      final double phase = time * star.blinkSpeed + star.timeOffset;
      final double opacity = (sin(phase) + 1) / 2; // Range 0.0 to 1.0

      paint.color = star.color.withOpacity(opacity * 0.5); // Softer colorful stars
      final double currentSize = star.maxSize * (0.5 + 0.5 * opacity);

      // Continuous drift (decreased speed multiplier from 15 to 8)
      double currentX = (star.x + star.dx * (time / pi * 8)) % 1.0;
      double currentY = (star.y + star.dy * (time / pi * 8)) % 1.0;
      if (currentX < 0) currentX += 1.0;
      if (currentY < 0) currentY += 1.0;

      canvas.drawCircle(
        Offset(currentX * size.width, currentY * size.height),
        currentSize,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}

