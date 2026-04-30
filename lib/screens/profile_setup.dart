import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home.dart';
import 'login_screen.dart';

import '../widgets/animated_background.dart';

// --- COLORS ---
const Color _primaryColor = Color(0xFF8C52FF); // Vibrant Purple
const Color _accentColor = Color(0xFF5E17EB); // Deep Purple

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 8;
  bool _saving = false;

  // Answers
  String? gender;
  String? ageGroup;
  List<String> struggles = [];
  String? distraction;
  String? breakFocus;
  String? timeOfDay;
  String? focusStyle;
  String? goal;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prevPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'gender': gender,
        'ageGroup': ageGroup,
        'struggles': struggles,
        'distraction': distraction,
        'breakFocus': breakFocus,
        'timeOfDay': timeOfDay,
        'focusStyle': focusStyle,
        'goal': goal,
        'profileCompleted': true,
      }, SetOptions(merge: true)); // ✅ Use merge so registration fields aren't lost

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      isLightMode: false,
      hasBlur: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: _currentPage > 0
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: _prevPage,
                )
              : null,
          actions: [
            TextButton(
              onPressed: _logout,
              child: const Text("Logout", style: TextStyle(color: Colors.white70)),
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                child: Row(
                  children: List.generate(_totalPages, (index) {
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2.0),
                        height: 6.0,
                        decoration: BoxDecoration(
                          color: index <= _currentPage ? _primaryColor : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(3.0),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 20),
              
              // Quiz Pages
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Disable swipe
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildSingleSelectPage(
                      title: "How do you identify?",
                      subtitle: "Help us personalize your experience.",
                      options: ["Male", "Female", "Non-binary", "Prefer not to say"],
                      currentValue: gender,
                      onSelect: (val) {
                        setState(() => gender = val);
                        _nextPage();
                      },
                    ),
                    _buildSingleSelectPage(
                      title: "What's your age group?",
                      subtitle: "This helps us tailor content.",
                      options: ["Under 18", "18-24", "25-34", "35-44", "45+"],
                      currentValue: ageGroup,
                      onSelect: (val) {
                        setState(() => ageGroup = val);
                        _nextPage();
                      },
                    ),
                    _buildMultiSelectPage(
                      title: "What are your biggest struggles?",
                      subtitle: "Select all that apply.",
                      options: ["Procrastination", "Anxiety", "Lack of Focus", "Burnout", "Sleep Issues", "Overthinking"],
                      selectedValues: struggles,
                      onToggle: (val) {
                        setState(() {
                          if (struggles.contains(val)) {
                            struggles.remove(val);
                          } else {
                            struggles.add(val);
                          }
                        });
                      },
                      onContinue: _nextPage,
                    ),
                    _buildSingleSelectPage(
                      title: "What distracts you most?",
                      subtitle: "Pick the biggest culprit.",
                      options: ["Social Media", "Environment/Noise", "Fatigue/Tiredness", "Internal Thoughts"],
                      currentValue: distraction,
                      onSelect: (val) {
                        setState(() => distraction = val);
                        _nextPage();
                      },
                    ),
                    _buildSingleSelectPage(
                      title: "How do you take breaks?",
                      subtitle: "When you lose focus, what do you do?",
                      options: ["Scroll Phone", "Take a Walk", "Get a Snack", "Chat with someone"],
                      currentValue: breakFocus,
                      onSelect: (val) {
                        setState(() => breakFocus = val);
                        _nextPage();
                      },
                    ),
                    _buildSingleSelectPage(
                      title: "When are you most productive?",
                      subtitle: "Your peak focus time.",
                      options: ["Early Morning", "Late Morning", "Afternoon", "Night Owl"],
                      currentValue: timeOfDay,
                      onSelect: (val) {
                        setState(() => timeOfDay = val);
                        _nextPage();
                      },
                    ),
                    _buildSingleSelectPage(
                      title: "What's your focus style?",
                      subtitle: "How you naturally work.",
                      options: ["Deep Work (Hours)", "Short Bursts (Pomodoro)", "Multitasking (Chaotic)"],
                      currentValue: focusStyle,
                      onSelect: (val) {
                        setState(() => focusStyle = val);
                        _nextPage();
                      },
                    ),
                    _buildSingleSelectPage(
                      title: "What is your main goal?",
                      subtitle: "What do you want to achieve with Zenify?",
                      options: ["Better Grades/Work", "Mental Peace", "Build Consistency", "Reduce Screen Time"],
                      currentValue: goal,
                      onSelect: (val) {
                        setState(() => goal = val);
                      },
                      isLastPage: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSingleSelectPage({
    required String title,
    required String subtitle,
    required List<String> options,
    required String? currentValue,
    required Function(String) onSelect,
    bool isLastPage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = currentValue == option;
                return GestureDetector(
                  onTap: () => onSelect(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_circle, color: Colors.white),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (isLastPage)
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 55,
                child: _saving
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : ElevatedButton(
                        onPressed: currentValue != null ? _saveProfile : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          disabledBackgroundColor: Colors.white.withOpacity(0.2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: const Text("Finish Setup", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildMultiSelectPage({
    required String title,
    required String subtitle,
    required List<String> options,
    required List<String> selectedValues,
    required Function(String) onToggle,
    required VoidCallback onContinue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 40),
          Expanded(
            child: ListView.separated(
              itemCount: options.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final option = options[index];
                final isSelected = selectedValues.contains(option);
                return GestureDetector(
                  onTap: () => onToggle(option),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isSelected ? _primaryColor : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        if (isSelected) const Icon(Icons.check_box, color: Colors.white)
                        else const Icon(Icons.check_box_outline_blank, color: Colors.white70),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: selectedValues.isNotEmpty ? onContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  disabledBackgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Continue", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
    );
  }
}