import 'dart:async';
import 'package:flutter/material.dart';

// Define custom colors for the theme
const Color primaryDark = Color(0xFF755F84); // #4d3536
const Color primaryMedium = Color(0xFF755251); // #755251
const Color primaryLight = Color(0xFF9e7473); // #9e7473
const Color accentColor = Color(0xFF8d5e5e); // #8d5e5e

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Use PageController to manage the current page and handle animation/swiping
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // The list of image paths and corresponding text lines
  final _splashData = [
    {
      'image': 'assets/images/splash1.jpg',
      'text': 'Welcome — Calm mind, clear day',
    },
    {
      'image': 'assets/images/splash2.jpg',
      'text': 'Built for ADHD-friendly focus',
    },
    {
      'image': 'assets/images/splash3.jpg',
      'text': 'Personalize your experience',
    },
  ];

  @override
  void initState() {
    super.initState();
    // Listen to page changes to update the indicator dots
    _pageController.addListener(() {
      int next = _pageController.page!.round();
      if (_currentPage != next) {
        // Use setState to rebuild the widget and update the dots
        setState(() {
          _currentPage = next;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // Widget to build a single dot indicator
  Widget _buildPageIndicator(int index) {
    bool isActive = index == _currentPage;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      height: 8.0,
      width: 8.0,
      decoration: BoxDecoration(
        // Use accentColor for the active dot, and a lighter/opacity color for inactive dots
        color: isActive ? accentColor : primaryLight.withOpacity(0.6),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: isActive ? Colors.white : Colors.transparent, width: 1.0),
      ),
    );
  }

  // Function to build the content for a single splash screen
  Widget _buildSplashContent(Map<String, String> data) {
    return Stack(
      children: [
        // 1. Full Screen Background Image
        Positioned.fill(
          child: Image.asset(
            data['image']!,
            fit: BoxFit.cover,
            // Fallback for image loading errors
            errorBuilder: (context, error, stackTrace) {
              return Container(color: primaryDark);
            },
          ),
        ),

        // 2. Subtle Dark Gradient Overlay for text contrast
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.5),
                ],
              ),
              color: primaryDark.withOpacity(0.2),
            ),
          ),
        ),

        // 3. Centered Text Overlay
        Align(
          alignment: Alignment.bottomCenter, // Align to bottom
          child: Padding(
            padding: const EdgeInsets.only(bottom: 250.0, left: 40.0, right: 40.0), // Adjust bottom padding to move text lower
            child: Text(
              data['text']!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25, // Reduced text size
                fontFamily: 'Bilderberg', // Custom font
                fontWeight: FontWeight.w900,
                shadows: [
                  Shadow(
                    blurRadius: 4.0,
                    color: Colors.black,
                    offset: Offset(1.0, 1.0),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryDark,
      body: Stack(
        children: <Widget>[
          // PageView for swiping between screens
          PageView.builder(
            controller: _pageController,
            itemCount: _splashData.length,
            itemBuilder: (context, index) {
              return _buildSplashContent(_splashData[index]);
            },
          ),

          // Bottom Indicator Dots and Navigation Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row of Indicator Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_splashData.length, (index) => _buildPageIndicator(index)),
                  ),

                  const SizedBox(height: 30),

                  // Optional: Next/Start Button (only visible on the last page)
                  if (_currentPage == _splashData.length - 1)
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to the login screen
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}