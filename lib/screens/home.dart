import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/mood_slider.dart';
import '../widgets/today_task_card.dart';
import '../widgets/streak_widget.dart';
import '../widgets/point_widget.dart';
import '../widgets/navigation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int moodIndex = 2;
  int sleepIndex = 2;

  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> saveMood() async {
    if (_uid.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('mood_data')
        .doc(_todayKey)
        .set({
      "mood": moodIndex,
      "sleep": sleepIndex,
      "date": _todayKey,
      "timestamp": FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Focus App"),
      ),
      bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/bg17.jpg", fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.1)),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // 🎭 MOOD
                MoodSwipeAnalyzer(
                  initialIndex: moodIndex,
                  onMoodChanged: (val) {
                    setState(() => moodIndex = val);
                    saveMood();
                  },
                ),

                const SizedBox(height: 20),

                // 😴 SLEEP
                SleepSwipeAnalyzer(
                  initialIndex: sleepIndex,
                  onSleepChanged: (val) {
                    setState(() => sleepIndex = val);
                    saveMood();
                  },
                ),

                const SizedBox(height: 20),

                const TodayTaskCard(),
                const StreakWidget(),
                const PointWidget(points: 120),
              ],
            ),
          ),
        ],
      ),
    );
  }
}