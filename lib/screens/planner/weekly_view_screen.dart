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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF6f7f61), const Color(0xFFC8E6C9)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isToday ? _primaryColorW.withValues(alpha: 0.15) : Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isToday
                              ? _primaryColorW.withValues(alpha: 0.6)
                              : const Color(0xFF6f7f61).withOpacity(0.6),
                        ),
                      ),
                      child: Theme(
                        data: Theme.of(context).copyWith(
                          dividerColor: Colors.transparent,
                        ),
                        child: ExpansionTile(
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
                                      color: isToday
                                          ? const Color(0xFFFFFFFF)
                                          : const Color(0xFF6B7280),
                                      fontWeight: isToday
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('dd MMM').format(day),
                                    style: const TextStyle(
                                      color: const Color(0xFF9CA3AF),
                                      fontSize: 12,
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
                                    color: done == total
                                        ? Colors.green
                                        .withOpacity(0.3)
                                        : _primaryColorW
                                        .withOpacity(0.3),
                                    borderRadius:
                                    BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$done/$total done',
                                    style: TextStyle(
                                      color: done == total
                                          ? Colors.green
                                          : _primaryColorW,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              else
                                const Text('No tasks',
                                    style: TextStyle(
                                        color: Color(0xFF9CA3AF),
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
                                    color: Color(0xFF9CA3AF)),
                              ),
                            )
                          ]
                              : dayTasks.map((doc) {
                            final data = doc.data()
                            as Map<String, dynamic>;
                            final bool done =
                                data['done'] as bool? ?? false;
                            final p = data['priority'] ?? 'Low';
                            final color = p == 'High'
                                ? const Color(0xFF5E17EB)
                                : p == 'Medium'
                                ? const Color(0xFF38B6FF)
                                : const Color(0xFF5CE1E6);

                            return ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16),
                              leading: Icon(
                                done
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: done
                                    ? Colors.green
                                    : color,
                                size: 20,
                              ),
                              title: Text(
                                data['title'] ?? '',
                                style: TextStyle(
                                  color: done
                                      ? const Color(0xFF9CA3AF)
                                      : const Color(0xFFFFFFFF),
                                  fontSize: 14,
                                  decoration: done
                                      ? TextDecoration
                                      .lineThrough
                                      : null,
                                  decorationColor:
                                  const Color(0xFF9CA3AF),
                                ),
                              ),
                              trailing: Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                                decoration: BoxDecoration(
                                  color:
                                  color.withOpacity(0.2),
                                  borderRadius:
                                  BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p,
                                  style: TextStyle(
                                      color: color,
                                      fontSize: 11,
                                      fontWeight:
                                      FontWeight.bold),
                                ),
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
