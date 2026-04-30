import 'package:flutter/material.dart';

// Import your screens (adjust paths to match your project structure)
import '../screens/planner/planner.dart';
import '../screens/home.dart';
// Add other screen imports as needed

const Color _navActive = Color(0xFF8C52FF);

/// Shared bottom navigation bar — drop this into any Scaffold's
/// [bottomNavigationBar] parameter:
///
///   bottomNavigationBar: const AppBottomNav(currentIndex: 3),
///
/// Indices:
///   0 → Home
///   1 → Study / Courses
///   2 → Wellness / Self-improvement
///   3 → Planner / Calendar
///   4 → Journal / Notes
class AppBottomNav extends StatelessWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF13131F).withOpacity(0.97),
        border: Border(
          top: BorderSide(
            color: Colors.white.withOpacity(0.08),
            width: 0.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                index: 0,
                current: currentIndex,
                onTap: () {
                  if (currentIndex != 0) {
                    Navigator.pushReplacement(context,
                        _route(const HomeScreen()));
                  }
                },
              ),
              _NavItem(
                icon: Icons.school_outlined,
                activeIcon: Icons.school_rounded,
                index: 1,
                current: currentIndex,
                onTap: () {
                  // Navigate to Study screen
                },
              ),
              _NavItem(
                icon: Icons.self_improvement_outlined,
                activeIcon: Icons.self_improvement,
                index: 2,
                current: currentIndex,
                onTap: () {
                  // Navigate to Wellness screen
                },
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                activeIcon: Icons.calendar_month_rounded,
                index: 3,
                current: currentIndex,
                onTap: () {
                  if (currentIndex != 3) {
                    Navigator.pushReplacement(context,
                        _route(const PlannerScreen()));
                  }
                },
              ),
              _NavItem(
                icon: Icons.edit_outlined,
                activeIcon: Icons.edit_rounded,
                index: 4,
                current: currentIndex,
                onTap: () {
                  // Navigate to Journal screen
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _route(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      );
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int current;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == current;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _navActive.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          selected ? activeIcon : icon,
          size: 24,
          color: selected ? _navActive : Colors.white38,
        ),
      ),
    );
  }
}