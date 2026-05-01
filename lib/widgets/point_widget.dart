import 'package:flutter/material.dart';

class PointWidget extends StatelessWidget {
  final int points;

  const PointWidget({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    const Color goldColor = Color(0xFFF5A623); // Vibrant modern gold
    const Color textDark = Color(0xFF2D3142);
    const int rewardGoal = 100;
    final progress = ((points % rewardGoal) / rewardGoal).clamp(0.0, 1.0);
    final pointsToNext = rewardGoal - (points % rewardGoal == 0 && points > 0
        ? rewardGoal
        : points % rewardGoal);
    final progressText = '${(progress * 100).round()}%';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9a882a), Color(0xFFFFE0B2)], // Focus games gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- HEADER ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MY LOOT",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5A4D1A), // Dark brown
                  letterSpacing: 1.5,
                  fontFamily: 'LeagueSpartan',
                ),
              ),
              // Small gift icon in the corner
              Icon(Icons.card_giftcard, color: const Color(0xFF5A4D1A).withValues(alpha: 0.5)),
            ],
          ),
          const SizedBox(height: 20),

          // --- BALANCE DISPLAY ---
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6), // Frosted glass effect
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current Balance",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$points",
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        color: textDark,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.stars_rounded,
                    color: goldColor,
                    size: 40,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- PROGRESS BAR ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                "Reward Progress",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                ),
              ),
              Text(
                progressText,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF5A4D1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 12,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF5A4D1A), Color(0xFF9A882A)], // Dark brown to olive gradient
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            points >= rewardGoal && points % rewardGoal == 0
                ? 'Reward unlocked. Keep earning for the next one.'
                : '$pointsToNext more loot to unlock the next reward.',
            style: const TextStyle(
              color: Color(0xFF5A4D1A),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 18),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.52),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white, width: 1.3),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How loot works',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 8),
                _LootRule(label: 'Complete Pomodoro', points: '+10'),
                _LootRule(label: 'Breathing or grounding exercise', points: '+10'),
                _LootRule(label: 'Try a focus strategy', points: '+10'),
                _LootRule(label: 'Complete task', points: '+5'),
                _LootRule(label: 'Complete high priority task', points: '+8'),
                _LootRule(label: 'Play focus game or use tip', points: '+5'),
                _LootRule(label: 'Create a task', points: '+2'),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // --- ACTION BUTTONS ---
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/learn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF5A4D1A),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFF5A4D1A), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text(
                    "Earn",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Redeem unlocks at 100 loot. Keep completing focus activities.',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A4D1A),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    shadowColor: const Color(0xFF5A4D1A).withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.card_giftcard, size: 20),
                  label: const Text(
                    "Redeem",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LootRule extends StatelessWidget {
  final String label;
  final String points;

  const _LootRule({
    required this.label,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            points,
            style: const TextStyle(
              color: Color(0xFF5A4D1A),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
