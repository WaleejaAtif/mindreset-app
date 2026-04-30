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
    final double itemWidth = MediaQuery.of(context).size.width / 5;

    final bool isMeditation = selectedIndex == 2;

    final Color tone1   = isMeditation ? Colors.black87 : const Color(0xFFB18AFF);
    final Color tone2   = isMeditation ? Colors.black   : const Color(0xFFA172FF);
    final Color bgColor = isMeditation ? Colors.white   : const Color(0xFF8C52FF);

    return Container(
      height: 65,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: isMeditation
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                )
              ]
            : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, 0, Icons.home_rounded,             '/home',     itemWidth, tone1, tone2, isMeditation),
          _buildNavItem(context, 1, Icons.school_rounded,           '/learn',    itemWidth, tone1, tone2, isMeditation),
          _buildNavItem(context, 2, Icons.self_improvement_rounded, '/meditate', itemWidth, tone1, tone2, isMeditation),
          _buildNavItem(context, 3, Icons.event_note_rounded,       '/planner',  itemWidth, tone1, tone2, isMeditation),
          _buildNavItem(context, 4, Icons.edit_rounded,             '/reflect',  itemWidth, tone1, tone2, isMeditation),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String route,
    double width,
    Color color1,
    Color color2,
    bool isMeditationTheme,
  ) {
    final bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => selectedIndex = index);
          // rootNavigator: true → always uses the top-level MaterialApp
          // navigator, so named routes are always found regardless of
          // which Scaffold or widget tree this nav bar is nested inside.
          Navigator.of(context, rootNavigator: true)
              .pushReplacementNamed(route);
        }
      },
      child: Container(
        width: width,
        height: double.infinity,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Animated highlight circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: isSelected ? 42 : 0,
              width:  isSelected ? 42 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Icon
            Icon(
              icon,
              color: isSelected
                  ? Colors.white
                  : (isMeditationTheme ? Colors.black45 : Colors.white70),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}