import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../widgets/navigation.dart';
import 'mood_graph_screen.dart';
import 'daily_mood_screen.dart';
import 'streak_progress_screen.dart';
import 'achievements_screen.dart';
import '../../widgets/sparkle_background.dart';

class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends State<ReflectScreen> {
  String _userName = '';
  int _streakDays = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // ✅ Get user data from Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final data = doc.data();

      setState(() {
        // ✅ Get name from Firestore profile or Firebase Auth displayName
        _userName = data?['displayName'] ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'User';
        _streakDays = data?['streakDays'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Error loading user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SparkleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        bottomNavigationBar: const CustomBottomNav(currentIndex: 4), // Should be 4
        body: SafeArea(
            child: _loading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFF884288)),
              ),
            )
                : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  // ✅ Real user name
                  _buildProfileHeader(),

                  const SizedBox(height: 30),

                  Row(
                    children: [
                      Expanded(
                        child: _smallCard(
                          title: 'Streak',
                          // ✅ Real streak days
                          value: '$_streakDays Days',
                          icon: Icons.local_fire_department_rounded,
                          color: Colors.orangeAccent,
                          gradientColors: const [Color(0xFF9a882a), Color(0xFFFFE0B2)], // Focus Games
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const StreakProgressScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _smallCard(
                          title: 'Badges',
                          value: '8 Won',
                          icon: Icons.emoji_events_rounded,
                          color: Colors.amber,
                          gradientColors: const [Color(0xFF4d7ea8), Color(0xFF9ad1d4)], // Learning Assistant
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                const AchievementsScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Analytics",
                      style: TextStyle(
                        color: Color(0xFF2D3142),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  _listCard(
                    title: 'Mood Graph',
                    subtitle: 'Weekly mood & sleep trends',
                    icon: Icons.show_chart_rounded,
                    color: Colors.lightBlueAccent,
                    gradientColors: const [Color(0xFFc2a7c3), Color(0xFFE1BEE7)], // Study Hacks
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MoodGraphScreen(),
                        ),
                      );
                    },
                  ),

                  _listCard(
                    title: 'Daily Mood Tracker',
                    subtitle: 'History of your reflections',
                    icon: Icons.history_rounded,
                    color: Colors.purpleAccent,
                    gradientColors: const [Color(0xFF6f7f61), Color(0xFFC8E6C9)], // Habit Tips
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DailyMoodScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
        ),
      ),
    );
  }

  // ✅ Shows real logged-in user name
  Widget _buildProfileHeader() {
    return Stack(
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                Border.all(color: const Color(0xFF6D774C), width: 2),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundColor: const Color(0xFF755F84),
                child: Text(
                  _userName.isNotEmpty
                      ? _userName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _userName,
              style: const TextStyle(
                color: Color(0xFF2D3142),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              "Focus Level: Advanced",
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFF2D3142)),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
          ),
        ),
      ],
    );
  }

  Widget _smallCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF2D3142),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _listCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.black26,
          size: 14,
        ),
      ),
    );
  }
}