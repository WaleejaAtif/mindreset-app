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

const Color _primaryColor = Color(0xFF8C52FF); // Vibrant Purple

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C1A4D), Color(0xFF0D0B1A)], // Light purple to light blue gradient
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        bottomNavigationBar: const CustomBottomNav(currentIndex: 3),

        // 🔥 BACK BUTTON ADDED
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
                      icon: const Icon(Icons.add, color: Color(0xFF1A1333)),
                      label: const Text(
                        'Add New Task',
                        style: TextStyle(color: Color(0xFF1A1333), fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
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
          gradient: const LinearGradient(
            colors: [Color(0xFF2C1A4D), Color(0xFF0D0B1A)], // Light purple to light blue gradient
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Color(0xFF1A1333), width: 1.5), // Frosted border
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFFFFFF).withValues(alpha: 0.05),
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
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


