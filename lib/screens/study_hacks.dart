import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudyHacksScreen extends StatefulWidget {
  const StudyHacksScreen({super.key});

  @override
  State<StudyHacksScreen> createState() => _StudyHacksScreenState();
}

class _StudyHacksScreenState extends State<StudyHacksScreen> {
  static const Color _bgColor = Color(0xFFF9F8FD);

  // Default hacks to seed if DB is empty
  final List<Map<String, dynamic>> _defaultHacks = [
    {
      "title": "Active Recall",
      "desc": "Test yourself instead of just re-reading.",
      "iconCode": Icons.psychology.codePoint,
      "colorHex": 0xFFb3957c
    },
    {
      "title": "Feynman Technique",
      "desc": "Explain it simply as if teaching a child.",
      "iconCode": Icons.record_voice_over.codePoint,
      "colorHex": 0xFFc2a7c3
    },
    {
      "title": "Spaced Repetition",
      "desc": "Review material at increasing intervals.",
      "iconCode": Icons.calendar_month.codePoint,
      "colorHex": 0xFF6f7f61
    },
    {
      "title": "Pomodoro Focus",
      "desc": "Study 25 mins, rest 5 mins.",
      "iconCode": Icons.timer.codePoint,
      "colorHex": 0xFF9a882a
    },
    {
      "title": "Sleep on It",
      "desc": "Sleep consolidates memory. Don't pull all-nighters.",
      "iconCode": Icons.bedtime.codePoint,
      "colorHex": 0xFFb3957c
    },
    {
      "title": "Mind Mapping",
      "desc": "Visually organize information to see connections.",
      "iconCode": Icons.hub.codePoint,
      "colorHex": 0xFFc2a7c3
    },
  ];

  Future<List<Map<String, dynamic>>> _fetchHacks() async {
    final snapshot = await FirebaseFirestore.instance.collection('content_study_hacks').get();
    
    if (snapshot.docs.isEmpty) {
      // Seed data if empty
      for (var hack in _defaultHacks) {
        await FirebaseFirestore.instance.collection('content_study_hacks').add(hack);
      }
      return _defaultHacks;
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
                'Study Hacks',
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
                    "Learn Smarter",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff608ba5),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Science-backed techniques to improve retention.",
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                ],
              ),
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchHacks(),
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
                return const SliverToBoxAdapter(child: Center(child: Text("Error loading hacks.")));
              }

              final hacks = snapshot.data!;

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
                    (context, index) => _buildHackCard(hacks[index]),
                    childCount: hacks.length,
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

  Widget _buildHackCard(Map<String, dynamic> item) {
    final icon = IconData(item['iconCode'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons');
    final color = Color(item['colorHex'] ?? 0xFF6f7f61);

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
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Got It",
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
