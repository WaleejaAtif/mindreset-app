import 'dart:ui';
import 'package:flutter/material.dart';

import '../home.dart';
import 'add_task_screen.dart';
import 'today_tasks_screen.dart';
import 'daily_view_screen.dart';
import 'weekly_view_screen.dart';
import 'monthly_mood_screen.dart';
import 'home.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/navigation.dart';

const Color _primaryColor = Color(0xFF8C52FF);

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C1A4D), Color(0xFF0D0B1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        bottomNavigationBar: const CustomBottomNav(currentIndex: 3),

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFFFFFF)),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              );
            },
          ),
          title: const Text(
            'My Planner',
            style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
          ),
        ),

        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Plan your day',
                  style: TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                const Text(
                  'Stay focused, stay organized',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
                ),

                const SizedBox(height: 30),

                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: [
                      // ── Today's Tasks ──────────────────────────────
                      _PlannerCard(
                        icon: Icons.today,
                        label: "Today's Tasks",
                        subtitle: 'View & manage today',
                        gradientColors: const [Color(0xFF976565), Color(0xFF976565)],
                        iconColor: const Color(0xFF4A1F1F),
                        labelColor: const Color(0xFF2D0A0A),
                        subtitleColor: const Color(0xFF5C2E2E),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TodayTasksScreen()),
                        ),
                      ),

                      // ── Daily View ─────────────────────────────────
                      _PlannerCard(
                        icon: Icons.calendar_view_day,
                        label: 'Daily View',
                        subtitle: 'Browse by date',
                        gradientColors: const [Color(0xFFc2a7c3), Color(0xFFE1BEE7)],
                        iconColor: const Color(0xFF7B4F7E),
                        labelColor: const Color(0xFF4A1F5C),
                        subtitleColor: const Color(0xFF6B3D7A),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const DailyViewScreen()),
                        ),
                      ),

                      // ── Weekly View ────────────────────────────────
                      _PlannerCard(
                        icon: Icons.view_week,
                        label: 'Weekly View',
                        subtitle: 'This week at a glance',
                        gradientColors: const [Color(0xFF6f7f61), Color(0xFFC8E6C9)],
                        iconColor: const Color(0xFF3B4F2E),
                        labelColor: const Color(0xFF1A2E10),
                        subtitleColor: const Color(0xFF3A5028),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WeeklyViewScreen()),
                        ),
                      ),

                      // ── Monthly Mood ───────────────────────────────
                      _PlannerCard(
                        icon: Icons.mood,
                        label: 'Monthly Mood',
                        subtitle: 'Mood calendar',
                        gradientColors: const [Color(0xFFb3957c), Color(0xFFD7CCC8)],
                        iconColor: const Color(0xFF6B4226),
                        labelColor: const Color(0xFF3E1F0A),
                        subtitleColor: const Color(0xFF5C3520),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MonthlyMoodScreen()),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Add New Task Button ────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF976565), // rose — Today's Tasks
                          Color(0xFF7B4F7E), // purple — Daily View
                          Color(0xFF6f7f61), // green — Weekly View
                          Color(0xFFb3957c), // beige — Monthly Mood
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                      ),
                      icon: const Icon(Icons.add, color: Color(0xFFFFF8F0)),
                      label: const Text(
                        'Add New Task',
                        style: TextStyle(
                          color: Color(0xFFFFF8F0),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 84),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── CARD WIDGET ────────────────────────────────────────────────────────────────
class _PlannerCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradientColors;
  final Color iconColor;
  final Color labelColor;
  final Color subtitleColor;
  final VoidCallback onTap;

  const _PlannerCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradientColors,
    required this.iconColor,
    required this.labelColor,
    required this.subtitleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: gradientColors[0].withOpacity(0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: gradientColors[0].withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: labelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}