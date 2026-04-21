import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home.dart';
import 'login_screen.dart';

// --- COLORS ---
const Color _primaryColor = Color(0xFF755F84);
const Color _darkBgColor = Color(0xff3a2355);

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  bool _saving = false;

  String? gender;
  String? ageGroup;
  List<String> struggles = [];
  String? distraction;
  String? breakFocus;
  String? timeOfDay;
  String? focusStyle;
  String? goal;

  Future<void> _saveProfile() async {
    setState(() => _saving = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
      return;
    }

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
    });

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
    );
  }

  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg1.jpg', fit: BoxFit.cover),
          ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.white.withOpacity(0.2)),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Profile Setup"),

                const SizedBox(height: 20),

                _saving
                    ? CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _saveProfile,
                  child: Text("Finish"),
                ),

                TextButton(
                  onPressed: logout,
                  child: Text("Logout"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}