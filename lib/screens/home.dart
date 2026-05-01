import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/mood_slider.dart';
import '../widgets/today_task_card.dart';
import '../widgets/streak_widget.dart';
import '../widgets/point_widget.dart';
import '../widgets/navigation.dart';
import '../widgets/sparkle_background.dart';

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

  // Removed saveMood() from here because MoodSwipeAnalyzer and SleepSwipeAnalyzer handle their own saving correctly to daily_logs on button press.

  @override
  Widget build(BuildContext context) {
    return SparkleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true, // Let background show behind app bar
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleSpacing: 12,
          title: Image.asset(
            'assets/images/logo.png',
            height: 52,
            fit: BoxFit.contain,
          ),
          iconTheme: const IconThemeData(color: Colors.black87), // Dark icons for white bg
        ),
        bottomNavigationBar: const CustomBottomNav(currentIndex: 0),
        body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [

                // 🎭 MOOD
                MoodSwipeAnalyzer(
                  initialIndex: moodIndex,
                  onMoodChanged: (val) {
                    setState(() => moodIndex = val);
                  },
                ),

                const SizedBox(height: 20),

                // 😴 SLEEP
                SleepSwipeAnalyzer(
                  initialIndex: sleepIndex,
                  onSleepChanged: (val) {
                    setState(() => sleepIndex = val);
                  },
                ),

                const SizedBox(height: 20),

                const SizedBox(height: 16),
                const TodayTaskCard(),
                const SizedBox(height: 16),
                const StreakWidget(),
                const SizedBox(height: 16),
                _buildLoot(),
                const SizedBox(height: 40), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildLoot() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const PointWidget(points: 0);
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        final points = (snapshot.data?.data()?['points'] as num?)?.toInt() ?? 0;
        return PointWidget(points: points);
      },
    );
  }
}
