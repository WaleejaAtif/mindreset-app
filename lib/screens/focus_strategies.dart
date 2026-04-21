import 'dart:ui';
import 'package:flutter/material.dart';

class FocusStrategiesScreen extends StatefulWidget {
  const FocusStrategiesScreen({super.key});

  @override
  State<FocusStrategiesScreen> createState() => _FocusStrategiesScreenState();
}

class _FocusStrategiesScreenState extends State<FocusStrategiesScreen> {
  static const Color _bgColor = Color(0xFFF9F8FD);

  // Strategy list with all your new additions and assigned design properties
  final List<Map<String, dynamic>> strategies = [
    {
      "title": "Pause & Breathe",
      "desc": "Slow breathing calms the mind and resets attention.",
      "icon": Icons.air,
      "color": const Color(0xFFb3957c)
    },
    {
      "title": "Change Posture",
      "desc": "Physical movement reactivates the brain and energy.",
      "icon": Icons.accessibility_new,
      "color": const Color(0xFFc2a7c3)
    },
    {
      "title": "Clear Workspace",
      "desc": "Remove visual clutter to reduce mental noise.",
      "icon": Icons.cleaning_services,
      "color": const Color(0xFF6f7f61)
    },
    {
      "title": "Write Thoughts",
      "desc": "Park them on paper so your mind can return to the task.",
      "icon": Icons.edit_note,
      "color": const Color(0xFF9a882a)
    },
    {
      "title": "Break Tasks",
      "desc": "Smaller actions feel manageable and re-engage focus.",
      "icon": Icons.account_tree,
      "color": const Color(0xFFb3957c)
    },
    {
      "title": "Timed Session",
      "desc": "10–25 minute sessions create urgency and structure.",
      "icon": Icons.timer,
      "color": const Color(0xFFc2a7c3)
    },
    {
      "title": "Digital Peace",
      "desc": "Silence notifications and close unused tabs.",
      "icon": Icons.do_not_disturb_on,
      "color": const Color(0xFF6f7f61)
    },
    {
      "title": "Switch Tasks",
      "desc": "Keeps momentum without losing direction.",
      "icon": Icons.swap_horiz,
      "color": const Color(0xFF9a882a)
    },
    {
      "title": "Hydrate & Snack",
      "desc": "Low energy reduces concentration. Fuel up.",
      "icon": Icons.local_cafe,
      "color": const Color(0xFFb3957c)
    },
    {
      "title": "Rest Your Eyes",
      "desc": "Look away from screens for 30–60 seconds.",
      "icon": Icons.visibility_off,
      "color": const Color(0xFFc2a7c3)
    },
    {
      "title": "Re-read Goal",
      "desc": "Reminds you why the task matters.",
      "icon": Icons.flag,
      "color": const Color(0xFF6f7f61)
    },
    {
      "title": "Self-Talk",
      "desc": "Say: “Just start. Progress over perfection.”",
      "icon": Icons.record_voice_over,
      "color": const Color(0xFF9a882a)
    },
    {
      "title": "New Setting",
      "desc": "Different lighting or location refreshes attention.",
      "icon": Icons.landscape,
      "color": const Color(0xFFb3957c)
    },
    {
      "title": "No Multitasking",
      "desc": "Focus on one task only to regain depth.",
      "icon": Icons.filter_1,
      "color": const Color(0xFFc2a7c3)
    },
    {
      "title": "Short Walk",
      "desc": "Even 2–5 minutes can reset concentration.",
      "icon": Icons.directions_walk,
      "color": const Color(0xFF6f7f61)
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Transparent to Dark Black AppBar (matching your Learn screen)
          SliverAppBar(
            expandedHeight: 90.0,
            floating: false,
            pinned: true,
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.black.withOpacity(0.8),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Regain Focus',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),

          // 2. Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Quick Strategies",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff608ba5),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Pick a technique to reset your brain.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ],
              ),
            ),
          ),

          // 3. The Grid
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.88,
              ),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStrategyCard(strategies[index]),
                childCount: strategies.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => _showDetailSheet(item),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item['color'].withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'], color: item['color'], size: 26),
            ),
            const Spacer(),
            Text(
              item['title'],
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item['desc'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item['icon'], size: 60, color: item['color']),
            const SizedBox(height: 20),
            Text(
              item['title'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              item['desc'],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: item['color'],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Try This Now",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}