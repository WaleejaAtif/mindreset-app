import 'dart:ui';
import 'package:flutter/material.dart';

import '../home.dart';
import 'add_task_screen.dart';
import 'today_tasks_screen.dart';
import 'daily_view_screen.dart';
import 'weekly_view_screen.dart';
import 'monthly_mood_screen.dart';
import 'home.dart';

const Color _primaryColor = Color(0xFF755F84);

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,

      // 🔥 BACK BUTTON ADDED
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          },
        ),
        title: const Text(
          'My Planner',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset('assets/images/bg17.jpg', fit: BoxFit.cover),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.black.withOpacity(0.15)),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Plan your day',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Stay focused, stay organized',
                    style: TextStyle(color: Colors.white60, fontSize: 14),
                  ),

                  const SizedBox(height: 30),

                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 1.1,
                      children: [
                        _PlannerCard(
                          icon: Icons.today,
                          label: "Today's Tasks",
                          subtitle: 'View & manage today',
                          color: const Color(0xFF976565),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TodayTasksScreen()),
                          ),
                        ),
                        _PlannerCard(
                          icon: Icons.calendar_view_day,
                          label: 'Daily View',
                          subtitle: 'Browse by date',
                          color: const Color(0xFF7D509F),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const DailyViewScreen()),
                          ),
                        ),
                        _PlannerCard(
                          icon: Icons.view_week,
                          label: 'Weekly View',
                          subtitle: 'This week at a glance',
                          color: const Color(0xFF957C2E),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const WeeklyViewScreen()),
                          ),
                        ),
                        _PlannerCard(
                          icon: Icons.mood,
                          label: 'Monthly Mood',
                          subtitle: 'Mood calendar',
                          color: const Color(0xFF4A7C8E),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MonthlyMoodScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                      ),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text(
                        'Add New Task',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// CARD (UNCHANGED UI)
class _PlannerCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PlannerCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.25),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}