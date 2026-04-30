import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _dotAnimation;
  late Animation<double> _anim1;
  late Animation<double> _anim2;
  late Animation<double> _anim3;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    // Dot animation: drops from way above (-50) to 0 and bounces into place
    _dotAnimation = Tween<double>(begin: -50.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.3, curve: Curves.bounceOut),
      ),
    );

    _anim1 = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.5, curve: Curves.easeOutCubic),
    );

    _anim2 = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 0.7, curve: Curves.easeOutCubic),
    );

    _anim3 = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.6, 0.9, curve: Curves.easeOutCubic),
    );

    // Start after a tiny delay
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTitle() {
    const textStyle = TextStyle(
      fontSize: 46,
      fontWeight: FontWeight.w300, // explicitly light
      color: Colors.black, // requested black
      letterSpacing: 1.5,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const Text('Zenf', style: textStyle),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _dotAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, _dotAnimation.value), // animates from -50 to 0
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const Text('ı', style: TextStyle(
              fontSize: 46,
              fontWeight: FontWeight.w300,
              color: Colors.black,
              letterSpacing: 1.5,
              height: 0.8, // Reduced height so it sits snug under the dot
            )),
          ],
        ),
        const Text('y', style: textStyle),
      ],
    );
  }

  Widget _buildFeatureRow(String imagePath, String title, String subtitle, bool imageOnLeft, Animation<double> animation) {
    final imageWidget = Image.asset(imagePath, width: 120, height: 120, fit: BoxFit.contain);
    
    final textWidget = Column(
      crossAxisAlignment: imageOnLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2D3142),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            height: 1.2,
          ),
          textAlign: imageOnLeft ? TextAlign.left : TextAlign.right,
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF608BA5),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: imageOnLeft ? TextAlign.left : TextAlign.right,
        ),
      ],
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(begin: Offset(imageOnLeft ? -0.2 : 0.2, 0.0), end: Offset.zero).animate(animation),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: imageOnLeft 
                ? [imageWidget, const SizedBox(width: 16), Expanded(child: textWidget)]
                : [Expanded(child: textWidget), const SizedBox(width: 16), imageWidget],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 50), // Added top spacing so the falling dot doesn't clip the screen edge
            _buildAnimatedTitle(),
            const Spacer(), // Pushes content to center
            
            _buildFeatureRow(
              'assets/images/getstarted1.png',
              '1. Clarify Your Mind.',
              'Reduce overwhelm.',
              true, // Image on Left
              _anim1,
            ),
            _buildFeatureRow(
              'assets/images/getstarted2.png',
              '2. Build Better Habits.',
              'Small steps count.',
              false, // Image on Right
              _anim2,
            ),
            _buildFeatureRow(
              'assets/images/getstarted3.png',
              '3. Connect & Succeed.',
              'A supportive community.',
              true, // Image on Left
              _anim3,
            ),
            
            const Spacer(),
            
            // Get Started Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 30.0),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF3E5F5), Color(0xFFE3F2FD)], // Light purple to light blue
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: const Color(0xFF2D3142), // Dark text for contrast
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Get Started',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
