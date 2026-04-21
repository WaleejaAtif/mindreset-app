import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  // Added a callback to handle navigation in the parent without rebuilding the bar
  final Function(int) onTap; 

  const CustomBottomNav({
    super.key, 
    required this.currentIndex, 
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final double itemWidth = MediaQuery.of(context).size.width / 5;

    // Gradient Hex Colors
    const Color purpleTone = Color(0xFF755F84);
    const Color blueTone = Color(0xFF608BA5);

    return Container(
      height: 65,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem(0, Icons.home_rounded, itemWidth, purpleTone, blueTone),
          _buildNavItem(1, Icons.school_rounded, itemWidth, purpleTone, blueTone),
          _buildNavItem(2, Icons.self_improvement_rounded, itemWidth, purpleTone, blueTone),
          _buildNavItem(3, Icons.event_note_rounded, itemWidth, purpleTone, blueTone),
          _buildNavItem(4, Icons.edit_rounded, itemWidth, purpleTone, blueTone),
        ],
      ),
    );
  }

  Widget _buildNavItem(
      int index,
      IconData icon,
      double width,
      Color color1,
      Color color2,
      ) {
    bool isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index), // Pass the index back to the parent
      child: Container(
        width: width,
        height: double.infinity,
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // --- GRADIENT CIRCLE HIGHLIGHT ---
            // This will now glide smoothly because the Bar is static
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
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