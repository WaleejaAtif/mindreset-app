import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/animated_background.dart';

const Color _primaryColorW = Color(0xFF8C52FF); // Vibrant Purple

class WeeklyViewScreen extends StatefulWidget {
  const WeeklyViewScreen({super.key});

  @override
  State<WeeklyViewScreen> createState() => _WeeklyViewScreenState();
}

class _WeeklyViewScreenState extends State<WeeklyViewScreen> {
  final DateTime _weekStart = DateTime.now().subtract(
    Duration(days: DateTime.now().weekday - 1),
  );

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  List<DateTime> get _weekDays =>
      List.generate(7, (i) => _weekStart.add(Duration(days: i)));

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .doc(id)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      isLightMode: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
          title: Text(
            'Week of ${DateFormat('dd MMM').format(_weekStart)}',
            style: const TextStyle(
                color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_userId)
                  .collection('tasks')
                  .snapshots(),
              builder: (context, snapshot) {
                final allDocs = snapshot.data?.docs ?? [];

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 7,
                  itemBuilder: (_, i) {
                    final day = _weekDays[i];
                    final dayKey =
                    DateFormat('yyyy-MM-dd').format(day);
                    final isToday = dayKey ==
                        DateFormat('yyyy-MM-dd')
                            .format(DateTime.now());

                    // Tasks for this day
                    final dayTasks = allDocs.where((doc) {
                      final data =
                      doc.data() as Map<String, dynamic>;
                      final due =
                          data['dueDate']?.toString() ?? '';
                      if (due.isEmpty) return isToday;
                      return due.startsWith(dayKey);
                    }).toList()
                      ..sort((a, b) =>
                          (a['priorityOrder'] as int? ?? 3)
                              .compareTo(
                              b['priorityOrder'] as int? ?? 3));

                    final done =
                        dayTasks.where((d) => d['done'] == true).length;
                    final total = dayTasks.length;

                    final gradients = [
                      [const Color(0xFF8C52FF), const Color(0xFF5E17EB)], // Purple
                      [const Color(0xFF38B6FF), const Color(0xFF0097B2)], // Blue
                      [const Color(0xFFFF914D), const Color(0xFFFF5757)], // Orange/Red
                      [const Color(0xFF00BF63), const Color(0xFF0097B2)], // Green/Teal
                      [const Color(0xFFb3957c), const Color(0xFF9a882a)], // Brown/Yellow
                      [const Color(0xFFCB6CE6), const Color(0xFF8C52FF)], // Pink/Purple
                      [const Color(0xFF5CE1E6), const Color(0xFF38B6FF)], // Cyan/Blue
                    ];
                    final currentGradient = gradients[i % gradients.length];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: currentGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isToday ? _primaryColorW.withValues(alpha: 0.3) : Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isToday
                              ? Colors.white
                              : Colors.transparent,
                          width: isToday ? 2.5 : 0,
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                          iconTheme: const IconThemeData(color: Colors.white),
                        ),
                        child: ExpansionTile(
                          iconColor: Colors.white,
                          collapsedIconColor: Colors.white70,
                          tilePadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          title: Row(
                            children: [
                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('EEEE').format(day),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: isToday
                                          ? FontWeight.w900
                                          : FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM').format(day),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              if (total > 0)
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$done/$total done',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                const Text('No tasks',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                            ],
                          ),
                          children: dayTasks.isEmpty
                              ? [
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'No tasks scheduled',
                                style: TextStyle(
                                    color: Colors.white70),
                              ),
                            )
                          ]
                              : dayTasks.map((doc) {
                            final data = doc.data()
                            as Map<String, dynamic>;
                            final bool done =
                                data['done'] as bool? ?? false;
                            final p = data['priority'] ?? 'Low';

                            return ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16),
                              leading: Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: done
                                    ? Colors.white54
                                    : Colors.white,
                                size: 20,
                              ),
                              title: Text(
                                data['title'] ?? '',
                                style: TextStyle(
                                  color: done
                                      ? Colors.white54
                                      : Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  decoration: done
                                      ? TextDecoration
                                      .lineThrough
                                      : null,
                                  decorationColor:
                                  Colors.white54,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      p,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                    onPressed: () => _delete(doc.id),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
    );
  }
}
