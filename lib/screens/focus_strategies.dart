import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FocusStrategiesScreen extends StatefulWidget {
  const FocusStrategiesScreen({super.key});

  @override
  State<FocusStrategiesScreen> createState() => _FocusStrategiesScreenState();
}

class _FocusStrategiesScreenState extends State<FocusStrategiesScreen> {
  static const Color _bgColor = Color(0xFFF9F8FD);

  // Strategy list with all your new additions and assigned design properties
  final List<Map<String, dynamic>> _defaultStrategies = [
    {
      "title": "Pause & Breathe",
      "desc": "Slow breathing calms the mind and resets attention.",
      "iconCode": Icons.air.codePoint,
      "colorHex": 0xFFb3957c
    },
    {
      "title": "Change Posture",
      "desc": "Physical movement reactivates the brain and energy.",
      "iconCode": Icons.accessibility_new.codePoint,
      "colorHex": 0xFFc2a7c3
    },
    {
      "title": "Clear Workspace",
      "desc": "Remove visual clutter to reduce mental noise.",
      "iconCode": Icons.cleaning_services.codePoint,
      "colorHex": 0xFF6f7f61
    },
    {
      "title": "Write Thoughts",
      "desc": "Park them on paper so your mind can return to the task.",
      "iconCode": Icons.edit_note.codePoint,
      "colorHex": 0xFF9a882a
    },
    {
      "title": "Break Tasks",
      "desc": "Smaller actions feel manageable and re-engage focus.",
      "iconCode": Icons.account_tree.codePoint,
      "colorHex": 0xFFb3957c
    },
    {
      "title": "Timed Session",
      "desc": "10–25 minute sessions create urgency and structure.",
      "iconCode": Icons.timer.codePoint,
      "colorHex": 0xFFc2a7c3
    },
    {
      "title": "Digital Peace",
      "desc": "Silence notifications and close unused tabs.",
      "iconCode": Icons.do_not_disturb_on.codePoint,
      "colorHex": 0xFF6f7f61
    },
    {
      "title": "Switch Tasks",
      "desc": "Keeps momentum without losing direction.",
      "iconCode": Icons.swap_horiz.codePoint,
      "colorHex": 0xFF9a882a
    },
    {
      "title": "Hydrate & Snack",
      "desc": "Low energy reduces concentration. Fuel up.",
      "iconCode": Icons.local_cafe.codePoint,
      "colorHex": 0xFFb3957c
    },
    {
      "title": "Rest Your Eyes",
      "desc": "Look away from screens for 30–60 seconds.",
      "iconCode": Icons.visibility_off.codePoint,
      "colorHex": 0xFFc2a7c3
    },
    {
      "title": "Re-read Goal",
      "desc": "Reminds you why the task matters.",
      "iconCode": Icons.flag.codePoint,
      "colorHex": 0xFF6f7f61
    },
    {
      "title": "Self-Talk",
      "desc": "Say: “Just start. Progress over perfection.”",
      "iconCode": Icons.record_voice_over.codePoint,
      "colorHex": 0xFF9a882a
    },
    {
      "title": "New Setting",
      "desc": "Different lighting or location refreshes attention.",
      "iconCode": Icons.landscape.codePoint,
      "colorHex": 0xFFb3957c
    },
    {
      "title": "No Multitasking",
      "desc": "Focus on one task only to regain depth.",
      "iconCode": Icons.filter_1.codePoint,
      "colorHex": 0xFFc2a7c3
    },
    {
      "title": "Short Walk",
      "desc": "Even 2–5 minutes can reset concentration.",
      "iconCode": Icons.directions_walk.codePoint,
      "colorHex": 0xFF6f7f61
    },
  ];

  Future<List<Map<String, dynamic>>> _fetchStrategies() async {
    final snapshot = await FirebaseFirestore.instance.collection('content_focus_strategies').get();
    
    if (snapshot.docs.isEmpty) {
      // Seed data if empty
      for (var strat in _defaultStrategies) {
        await FirebaseFirestore.instance.collection('content_focus_strategies').add(strat);
      }
      return _defaultStrategies;
    }

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

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
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchStrategies(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Color(0xff608ba5)),
                    ),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const SliverToBoxAdapter(child: Center(child: Text("Error loading strategies.")));
              }

              final strats = snapshot.data!;

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.88,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildStrategyCard(strats[index]),
                    childCount: strats.length,
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(Map<String, dynamic> item) {
    final icon = IconData(item['iconCode'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons');
    final color = Color(item['colorHex'] ?? 0xFFb3957c);

    return GestureDetector(
      onTap: () => _showDetailSheet(item, icon, color),
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
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const Spacer(),
            Text(
              item['title'] ?? '',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item['desc'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tryStrategy(BuildContext context, Map<String, dynamic> item) async {
    Navigator.pop(context); // close sheet
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'points': FieldValue.increment(10),
        }, SetOptions(merge: true));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Awesome! You earned 10 Loot points for trying '${item['title']}'!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint("Error adding points: $e");
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Guest Mode: Great job trying '${item['title']}'!"),
            backgroundColor: Colors.blueGrey,
          ),
        );
      }
    }
  }

  void _showDetailSheet(Map<String, dynamic> item, IconData icon, Color color) {
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
            Icon(icon, size: 60, color: color),
            const SizedBox(height: 20),
            Text(
              item['title'] ?? '',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              item['desc'] ?? '',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => _tryStrategy(context, item),
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