import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StreakWidget extends StatefulWidget {
  const StreakWidget({Key? key}) : super(key: key);

  @override
  State<StreakWidget> createState() => _StreakWidgetState();
}

class _StreakWidgetState extends State<StreakWidget> {
  int _streakDays = 0;
  List<bool> _weekCompleted = List.filled(7, false);
  List<String> _weekDates = List.filled(7, '');
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStreakData();
  }

  // ✅ Get Monday of current week
  DateTime _getMonday() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  String _dateKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

 Future<void> _loadStreakData() async {
  try {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _loading = false);
      return;
    }

    final uid = user.uid;
    final monday = _getMonday();

    final weekKeys = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return _dateKey(day);
    });

    final weekDateNumbers = List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      return day.day.toString();
    });

    final List<bool> completed = [];

    for (final key in weekKeys) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .doc(key)
          .get();

      if (!mounted) return; // 🔥 SAFE CHECK

      final data = doc.data();
      final hasLog = doc.exists &&
          (data?.containsKey('mood') == true ||
              data?.containsKey('sleep') == true);

      completed.add(hasLog);
    }

    final today = DateTime.now();
    int streak = 0;

    for (int i = 0; i >= -365; i--) {
      final day = today.add(Duration(days: i));
      final key = _dateKey(day);

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .doc(key)
          .get();

      if (!mounted) return; // 🔥 SAFE CHECK

      final data = doc.data();
      final hasLog = doc.exists &&
          (data?.containsKey('mood') == true ||
              data?.containsKey('sleep') == true);

      if (hasLog) {
        streak++;
      } else {
        break;
      }
    }

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'streakDays': streak}, SetOptions(merge: true));

    if (!mounted) return; // 🔥 FINAL SAFETY CHECK

    setState(() {
      _streakDays = streak;
      _weekCompleted = completed;
      _weekDates = weekDateNumbers;
      _loading = false;
    });

  } catch (e) {
    debugPrint('Streak error: $e');

    if (!mounted) return;
    setState(() => _loading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF884288)),
        ),
      );
    }

    return BigStreakCard(
      days: _streakDays,
      weekCompleted: _weekCompleted,
      weekDates: _weekDates,
    );
  }
}

/// ------------------- THEMED STREAK CARD -------------------
class BigStreakCard extends StatelessWidget {
  final int days;
  final List<bool> weekCompleted;
  final List<String> weekDates;

  const BigStreakCard({
    super.key,
    required this.days,
    required this.weekCompleted,
    required this.weekDates,
  });

  @override
  Widget build(BuildContext context) {
    final week = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Today's index (Monday=0, Sunday=6)
    final todayIndex = DateTime.now().weekday - 1;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1D), Color(0xFF2D2D34)], // Blackish gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5), // Frosted white border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), // Soft elegant shadow
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // --- GLOWING FLAME ICON ---
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9800).withValues(alpha: 0.3), // Vibrant orange shadow
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.local_fire_department,
                color: Color(0xFFFF9800), // Vibrant orange flame
                size: 80,
              ),
            ],
          ),

          const SizedBox(height: 12),

          // --- STREAK NUMBER ---
          Text(
            "$days",
            style: const TextStyle(
              fontSize: 68,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFF9800), // Vibrant orange number
              fontFamily: 'LeagueSpartan',
            ),
          ),

          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFFFFB74D), Color(0xFFFF9800)], // Flame orange
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
            child: const Text(
              "days streak",
              style: TextStyle(
                fontSize: 22,
                color: Colors.white, // Overridden by ShaderMask
                fontWeight: FontWeight.w800,
                fontFamily: 'LeagueSpartan',
              ),
            ),
          ),

          // ✅ Show message based on streak
          const SizedBox(height: 8),
          Text(
            days == 0
                ? "Start your streak today! 💪"
                : days < 3
                ? "Great start! Keep going! 🔥"
                : days < 7
                ? "You're on fire! 🔥🔥"
                : "Unstoppable! 🔥🔥🔥",
            style: const TextStyle(
              color: Colors.white70, // Light text for dark background
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 30),

          // --- WEEKLY CALENDAR ROW ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1), // Dark mode calendar background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isToday = i == todayIndex;
                final isDone = weekCompleted[i];
                final dateNum = weekDates.isNotEmpty ? weekDates[i] : '';

                return Column(
                  children: [
                    Text(
                      week[i],
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday
                            ? const Color(0xFFFF9800)
                            : Colors.transparent,
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(
                          Icons.check,
                          size: 18,
                          color: Colors.white,
                        )
                            : Text(
                                dateNum,
                                style: TextStyle(
                                  color: isToday ? Colors.white : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}