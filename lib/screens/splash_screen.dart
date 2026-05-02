import 'dart:async';
import 'package:flutter/material.dart';

import '../widgets/animated_background.dart';

// Define custom colors for the new Zenify theme
const Color primaryDark = Color(0xFF5E17EB); // Deep Purple
const Color primaryMedium = Color(0xFF8C52FF); // Vibrant Purple
const Color primaryLight = Color(0xFF38B6FF); // Light Blue
const Color accentColor = Color(0xFF5CE1E6); // Mint/Cyan

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
      'text': 'Welcome — Calm mind, clear day',
    },
    {
      'text': 'Built for ADHD-friendly focus',
    },
    {
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
        // Use primaryDark for the active dot, and a lighter/opacity color for inactive dots
        color: isActive ? primaryDark : primaryDark.withOpacity(0.3),
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  // Function to build the content for a single splash screen
  Widget _buildSplashContent(Map<String, String> data) {
    return Stack(
      children: [
        // 3. Centered Text Overlay
        Align(
          alignment: Alignment.bottomCenter, // Align to bottom
          child: Padding(
            padding: const EdgeInsets.only(bottom: 250.0, left: 40.0, right: 40.0), // Adjust bottom padding to move text lower
            child: Text(
              data['text']!,
              style: const TextStyle(
                color: primaryDark, // Dark text for light background
                fontSize: 25, // Reduced text size
                fontFamily: 'Bilderberg', // Custom font
                fontWeight: FontWeight.w900,
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
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        hasBlur: false,
        isLightMode: true,
        child: Stack(
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
                        backgroundColor: primaryDark,
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
                          color: Color(0xFF1A1333),
                        ),
                      ),
                    ),
                ],
              ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
