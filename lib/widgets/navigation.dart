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

    // Gradient Hex Colors for selected bubble
    const Color tone1 = Color(0xFFB18AFF);
    const Color tone2 = Color(0xFFA172FF);
    const Color bgColor = Color(0xFF8C52FF);

    return Container(
      height: 65, // Standard height for a straight bottom bar
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(context, 0, Icons.home_rounded, '/home', itemWidth, tone1, tone2),
          _buildNavItem(context, 1, Icons.school_rounded, '/learn', itemWidth, tone1, tone2),
          _buildNavItem(context, 2, Icons.self_improvement_rounded, '/meditate', itemWidth, tone1, tone2),
          _buildNavItem(context, 3, Icons.event_note_rounded, '/planner', itemWidth, tone1, tone2),
          _buildNavItem(context, 4, Icons.edit_rounded, '/reflect', itemWidth, tone1, tone2),
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
      ) {
    bool isSelected = index == selectedIndex;

    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() {
            selectedIndex = index;
          });
          // Direct navigation to your separate dart files
          Navigator.pushReplacementNamed(context, route);
        }
      },
      child: Container(
        width: width,
        height: double.infinity,
        color: Colors.transparent, // Ensures the entire section is clickable
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- GRADIENT CIRCLE HIGHLIGHT ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              height: isSelected ? 42 : 0,
              width: isSelected ? 42 : 0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [color1, color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

            // --- ICON ---
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white70,
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}
