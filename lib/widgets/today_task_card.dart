import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TodayTaskCard extends StatelessWidget {
  const TodayTaskCard({Key? key}) : super(key: key);

  // ✅ Correct path: users/{uid}/tasks
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ✅ Today's date matching planner format exactly
  String get _todayKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Color _colorForPriority(String priority) {
    if (priority == 'High') return const Color(0xFF976565);
    if (priority == 'Medium') return const Color(0xFF7D509F);
    return const Color(0xFF957C2E);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      // REPLACE this stream:
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('tasks')
          .where('done', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFF755F84)),
              ),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Error loading tasks: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [Color(0xFF884288), Color(0xFF608BA5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                  child: const Text(
                    "Today's Top Tasks",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'LeagueSpartan',
                    ),
                  ),
                ),
                if (docs.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withValues(alpha: 0.15), // Blue accent
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${docs.length} task${docs.length > 1 ? 's' : ''}',
                      style: const TextStyle(
                        color: Color(0xFF1565C0), // Blue text
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // ✅ Empty state
            if (docs.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFFFFF), Color(0xFFEAF4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20), // Softer corners
                  border: Border.all(color: Colors.white, width: 1.5), // White frosted border
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05), // Soft shadow
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle_outline,
                        color: Color(0xFF1565C0), size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No tasks for today!\nAdd tasks in your Planner.',
                        style:
                        TextStyle(color: Color(0xFF2D3142), height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            // ✅ Task list
            if (docs.isNotEmpty)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data =
                  docs[index].data() as Map<String, dynamic>;
                  final color =
                  _colorForPriority(data['priority'] ?? 'Low');
                  final isLast = index == docs.length - 1;

                  return _TimelineTaskRow(
                    title: data['title'] ?? 'Untitled',
                    time: data['time'] ?? '',
                    category: data['category'] ?? '',
                    priority: data['priority'] ?? 'Low',
                    color: color,
                    isLast: isLast,
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _TimelineTaskRow extends StatelessWidget {
  final String title;
  final String time;
  final String category;
  final String priority;
  final Color color;
  final bool isLast;

  const _TimelineTaskRow({
    required this.title,
    required this.time,
    required this.category,
    required this.priority,
    required this.color,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Category pill
          Column(
            children: [
              Container(
                width: 60,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Center(
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: CustomPaint(
                    size: const Size(1, double.infinity),
                    painter: _DashedLinePainter(color: color),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Right: Task card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFF90CAF9)], // Bluish gradient
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            priority,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (time.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.access_time, size: 13, color: color),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              time,
                              style: TextStyle(
                                color: const Color(0xFF1F2937),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.circle,
                            size: 7, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    double dashHeight = 5, dashSpace = 3, startY = 10;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    while (startY < size.height) {
      canvas.drawLine(
          Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
