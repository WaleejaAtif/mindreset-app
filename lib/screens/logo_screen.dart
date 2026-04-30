import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class LogoScreen extends StatefulWidget {
  @override
  _LogoScreenState createState() => _LogoScreenState();
}

class _LogoScreenState extends State<LogoScreen> with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _typewriterAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo Stomp Animation
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _scaleAnimation = Tween<double>(begin: 4.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _popController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _popController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeIn),
    );

    _typewriterAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _popController,
        curve: const Interval(0.5, 0.9, curve: Curves.easeInOut),
      ),
    );

    // Navigate to welcome screen when animation completes
    _popController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 800),
                pageBuilder: (context, animation, secondaryAnimation) => WelcomeScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;
                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          }
        });
      }
    });

    // Start the animation immediately
    _popController.forward();
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: Colors.black54,
      fontSize: 18,
      fontWeight: FontWeight.bold,
      letterSpacing: 1.0,
      fontFamily: 'LeagueSpartan',
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Logo
            ScaleTransition(
              scale: _scaleAnimation,
              child: Image.asset('assets/images/logo.png', width: 220),
            ),
            const SizedBox(height: 24),
            // Typewriter reveal text
            AnimatedBuilder(
              animation: _typewriterAnimation,
              builder: (context, child) {
                const String fullText = 'Focus, Calm and Clarity.';
                int charCount = (_typewriterAnimation.value * fullText.length).round();
                String visibleText = fullText.substring(0, charCount);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Invisible text to reserve exact layout space
                    Opacity(
                      opacity: 0.0,
                      child: Text(fullText, style: textStyle),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Text(visibleText, style: textStyle),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
