import 'dart:math';
import 'package:flutter/material.dart';

class AnimatedBorderCard extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final BorderRadius borderRadius;

  final Color baseColor;
  final Color glowColor;

  const AnimatedBorderCard({
    Key? key,
    required this.child,
    this.borderWidth = 3.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.baseColor = const Color(0xFF1A1333),
    this.glowColor = const Color(0xFF2C1A4D),
  }) : super(key: key);

  @override
  State<AnimatedBorderCard> createState() => _AnimatedBorderCardState();
}

class _AnimatedBorderCardState extends State<AnimatedBorderCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    _glowAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GlowingBorderPainter(
            glowValue: _glowAnimation.value,
            borderWidth: widget.borderWidth,
            borderRadius: widget.borderRadius,
            baseColor: widget.baseColor,
            glowColor: widget.glowColor,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: widget.child,
          ),
        );
      },
      child: widget.child, // The child is wrapped in Padding inside the builder
    );
  }
}

class _GlowingBorderPainter extends CustomPainter {
  final double glowValue;
  final double borderWidth;
  final BorderRadius borderRadius;
  final Color baseColor;
  final Color glowColor;

  _GlowingBorderPainter({
    required this.glowValue,
    required this.borderWidth,
    required this.borderRadius,
    required this.baseColor,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Inset the rect by half the border width so the stroke fits entirely inside the widget bounds
    final rect = Offset(borderWidth / 2, borderWidth / 2) & 
                 Size(size.width - borderWidth, size.height - borderWidth);
    
    // Create the RRect with the correct inset
    // If the original radius is R, the inner radius for the stroke center is R - borderWidth/2
    final insetRadius = Radius.circular(
        max(0.0, borderRadius.topLeft.x - borderWidth / 2));
    final rrect = RRect.fromRectAndRadius(rect, insetRadius);
    
    final darkenedGlow = Color.lerp(glowColor, Colors.black, 0.75)!;
    
    final color = Color.lerp(
      baseColor,
      darkenedGlow,
      glowValue,
    )!;
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;
      
    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _GlowingBorderPainter oldDelegate) {
    return oldDelegate.glowValue != glowValue || 
           oldDelegate.borderWidth != borderWidth ||
           oldDelegate.borderRadius != borderRadius ||
           oldDelegate.baseColor != baseColor ||
           oldDelegate.glowColor != glowColor;
  }
}
