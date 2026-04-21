import 'package:flutter/material.dart';

class PointWidget extends StatelessWidget {
  final int points;

  const PointWidget({Key? key, required this.points}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFB19F16);
    const Color accentPurple = Color(0xFFAB7DAC);
    const Color darkBg = Color(0xF50B021C);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: darkBg,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "MY LOOT",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF608BA5),
              letterSpacing: 2.0,
              fontFamily: 'LeagueSpartan',
            ),
          ),
          const SizedBox(height: 30),

          // --- CENTRAL SECTION: Add Button | Glowing Ring | Claim Gift ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSideButton(Icons.add, accentPurple),

              const SizedBox(width: 25),

              // Glowing Point Ring
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle ,
                  color: const Color(0xFF1A0B2E), // Subtle dark inner fill
                  border: Border.all(color: goldColor, width: 7),
                  boxShadow: [
                    // Outer glow
                    BoxShadow(
                      color: goldColor.withOpacity(0.5),
                      blurRadius: 25,
                      spreadRadius: 2,
                    ),
                    // Inner glow
                    BoxShadow(
                      color: goldColor.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: -2,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
                child: Center(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: "\$",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: goldColor.withOpacity(0.9),
                          ),
                        ),
                        TextSpan(
                          text: "$points",
                          style: const TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w900,
                            color: goldColor,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 25),

              _buildClaimSection(goldColor),
            ],
          ),

          const SizedBox(height: 40),

          // --- GIFT ROW ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildGiftItem('assets/images/gift-box.png', Colors.blue, true),
              _buildGiftItem('assets/images/gift-box.png', Colors.red, true),
              _buildGiftItem('assets/images/gift-box.png', Colors.green, true),
              _buildGiftItem('assets/images/gift-box.png', Colors.amber, false),
            ],
          ),

          const SizedBox(height: 35),

          // --- PROGRESS BAR ---
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 34,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.85,
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF9A825), Color(0xFFFFD54F)],
                      ),
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                ),
              ),
              const Text(
                "15% to next level",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          // --- COLLECT BUTTON ---
          Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.orange, Color(0xFFFFD700)]),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Center(
              child: Text(
                "COLLECT MORE COINS",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BUILDER HELPERS ---

  Widget _buildSideButton(IconData icon, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }

  Widget _buildClaimSection(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.card_giftcard, color: color, size: 34),
        const SizedBox(height: 4),
        const Text(
          "CLAIM GIFT",
          style: TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGiftItem(String assetPath, Color tint, bool isLocked) {
    return Column(
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
          child: Image.asset(
            assetPath,
            width: 45,
            height: 45,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 6),
        if (isLocked)
          const Icon(Icons.lock, color: Colors.white54, size: 16)
        else
          const SizedBox(height: 16),
      ],
    );
  }
}