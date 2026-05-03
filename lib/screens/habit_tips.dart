import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/activity_service.dart';
import 'activities/activity_router.dart';

class HabitTipsScreen extends StatefulWidget {
  const HabitTipsScreen({super.key});

  @override
  State<HabitTipsScreen> createState() => _HabitTipsScreenState();
}

class _HabitTipsScreenState extends State<HabitTipsScreen> {
  static const Color _bgColor = Color(0xFF0F0C20);

  // Default tips to seed if DB is empty
  final List<Map<String, dynamic>> _defaultTips = [
    {
      "title": "Start Small",
      "desc": "Make it so easy you can't say no (e.g. 1 pushup).",
      "iconCode": Icons.rocket_launch.codePoint,
      "colorHex": 0xFFb3957c
    },
    {
      "title": "Habit Stacking",
      "desc": "Tie a new habit to an existing one (e.g. after I brush teeth).",
      "iconCode": Icons.layers.codePoint,
      "colorHex": 0xFFc2a7c3
    },
    {
      "title": "2-Minute Rule",
      "desc": "When you start a new habit, it should take less than 2 mins.",
      "iconCode": Icons.timer_outlined.codePoint,
      "colorHex": 0xFF6f7f61
    },
    {
      "title": "Track It",
      "desc": "Don't break the chain. Visual progress is motivating.",
      "iconCode": Icons.check_circle_outline.codePoint,
      "colorHex": 0xFF9a882a
    },
    {
      "title": "Forgive Yourself",
      "desc": "Missing one day doesn't ruin your progress.",
      "iconCode": Icons.favorite_border.codePoint,
      "colorHex": 0xFFb3957c
    },
    {
      "title": "Environment",
      "desc": "Make bad habits hard and good habits easy by altering your room.",
      "iconCode": Icons.home_repair_service.codePoint,
      "colorHex": 0xFFc2a7c3
    },
  ];

  Future<List<Map<String, dynamic>>> _fetchTips() async {
    final snapshot = await FirebaseFirestore.instance.collection('content_habit_tips').get();
    
    if (snapshot.docs.isEmpty) {
      // Seed data if empty
      for (var tip in _defaultTips) {
        await FirebaseFirestore.instance.collection('content_habit_tips').add(tip);
      }
      return _defaultTips;
    }

    final List<Map<String, dynamic>> uniqueTips = [];
    final Set<String> titles = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final title = data['title']?.toString() ?? '';
      if (!titles.contains(title)) {
        titles.add(title);
        uniqueTips.add(data);
      }
    }

    return uniqueTips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 90.0,
            floating: false,
            pinned: true,
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFFFFFFFF).withOpacity(0.8),
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Habit Tips',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Build Routines",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6f7f61),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Psychology tricks to make good habits stick.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchTips(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(color: Color(0xFF6f7f61)),
                    ),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const SliverToBoxAdapter(child: Center(child: Text("Error loading tips.")));
              }

              final tips = snapshot.data!;

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
                    (context, index) => _buildTipCard(tips[index]),
                    childCount: tips.length,
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

  Widget _buildTipCard(Map<String, dynamic> item) {
    final icon = IconData(item['iconCode'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons');
    final color = Color(item['colorHex'] ?? 0xFF6f7f61);

    return GestureDetector(
      onTap: () => _showDetailSheet(item, icon, color),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF1A1333),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFFFFFF).withOpacity(0.04),
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
                color: Color(0xFFFFFFFF),
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

  void _showDetailSheet(Map<String, dynamic> item, IconData icon, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF1A1333),
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
              style: const TextStyle(fontSize: 16, color: Color(0xFFAFA8BA)),
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
                onPressed: () => _tryTip(context, item),
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

  Future<void> _tryTip(BuildContext sheetContext, Map<String, dynamic> item) async {
    Navigator.pop(sheetContext);

    final completed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ActivityRouter.getRoute(item, 'habit')),
    );

    if (completed != true) return;

    await ActivityService.logActivity(
      collection: 'habit_tip_logs',
      data: {
        'title': item['title'] ?? '',
        'description': item['desc'] ?? '',
      },
      dailyValues: {
        'habitTipsTaken': FieldValue.increment(1),
        'lastHabitTip': item['title'] ?? '',
      },
      points: 5,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Habit tip saved: ${item['title'] ?? 'Tip'}")),
    );
  }
}

