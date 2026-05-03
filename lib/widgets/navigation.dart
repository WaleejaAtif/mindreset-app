import 'dart:ui';
import 'package:flutter/material.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;

  const CustomBottomNav({super.key, required this.currentIndex});

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with SingleTickerProviderStateMixin {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.currentIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFF906F8F).withOpacity(0.92),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white12, width: 0.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(context, 0, Icons.home_rounded, '/home'),
                _buildNavItem(context, 1, Icons.menu_book_rounded, '/learn'),
                _buildNavItem(context, 2, Icons.self_improvement_rounded, '/meditate'),
                _buildNavItem(context, 3, Icons.calendar_today_rounded, '/planner'),
                _buildNavItem(context, 4, Icons.psychology_rounded, '/reflect'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String route,
  ) {
    bool isSelected = index == selectedIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (!isSelected) {
            setState(() {
              selectedIndex = index;
            });
            Navigator.pushReplacementNamed(context, route);
          }
        },
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: isSelected ? 16 : 12,
              vertical: isSelected ? 12 : 10,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xB3FFFFFF),
              size: isSelected ? 28 : 24,
            ),
          ),
        ),
      ),
    );
  }
}

