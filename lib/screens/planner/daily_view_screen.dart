import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_task_screen.dart';
import '../../services/activity_service.dart';
import '../../widgets/animated_background.dart';

const Color _primaryColor = Color(0xFF8C52FF); // Vibrant Purple
const Color _highColor = Color(0xFF5E17EB); // Deep Purple
const Color _medColor = Color(0xFF38B6FF); // Light Blue
const Color _lowColor = Color(0xFF5CE1E6); // Mint/Cyan

class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends State<DailyViewScreen> {
  DateTime _selectedDay = DateTime.now();
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Color _colorFor(String p) {
    if (p == 'High') return _highColor;
    if (p == 'Medium') return _medColor;
    return _lowColor;
  }

  // Build 7-day horizontal strip centred on today
  List<DateTime> get _weekDays {
    final today = DateTime.now();
    return List.generate(7, (i) => today.subtract(Duration(days: 3 - i)));
  }

  Future<void> _toggleDone(String id, bool current) async {
    final taskRef = FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .doc(id);
    final taskDoc = await taskRef.get();
    final data = taskDoc.data() as Map<String, dynamic>? ?? {};
    await taskRef.update({'done': !current});
    if (!current) {
      final title = data['title']?.toString() ?? 'Task';
      final priority = data['priority']?.toString() ?? '';
      await ActivityService.recordDaily(
        values: {
          'tasksCompleted': FieldValue.increment(1),
          'lastCompletedTask': title,
          if (priority == 'High') 'highPriorityTaskCompleted': title,
        },
        points: priority == 'High' ? 8 : 5,
      );
    }
  }

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
    final selectedKey =
    DateFormat('yyyy-MM-dd').format(_selectedDay);

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
            DateFormat('MMMM yyyy').format(_selectedDay),
            style: const TextStyle(
                color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
            child: Column(
              children: [
                // 7-day strip
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _weekDays.length,
                    itemBuilder: (_, i) {
                      final day = _weekDays[i];
                      final isSelected = DateFormat('yyyy-MM-dd')
                          .format(day) ==
                          DateFormat('yyyy-MM-dd')
                              .format(_selectedDay);
                      final isToday = DateFormat('yyyy-MM-dd')
                          .format(day) ==
                          DateFormat('yyyy-MM-dd')
                              .format(DateTime.now());

                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedDay = day),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          margin: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _primaryColor
                                : Color(0xFF1A1333),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: isSelected ? [
                              BoxShadow(
                                color: _primaryColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ] : [
                              BoxShadow(
                                color: Color(0xFFFFFFFF).withValues(alpha: 0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: isToday && !isSelected
                                ? Border.all(
                                color: _primaryColor.withValues(alpha: 0.5), width: 2)
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Text(
                                DateFormat('EEE').format(day),
                                style: TextStyle(
                                  color: isSelected
                                      ? Color(0xB3FFFFFF)
                                      : const Color(0xFF6B7280),
                                  fontSize: 11,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${day.day}',
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFFFFFFFF),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Tasks for selected day
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(_userId)
                        .collection('tasks')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                                Color(0xFF1A1333)),
                          ),
                        );
                      }

                      final all = snapshot.data?.docs ?? [];

                      // Filter: tasks with no dueDate show on today,
                      // tasks with dueDate show on their day
                      final filtered = all.where((doc) {
                        final data =
                        doc.data() as Map<String, dynamic>;
                        final due =
                            data['dueDate']?.toString() ?? '';
                        if (due.isEmpty) {
                          // No due date → show on today only
                          return selectedKey ==
                              DateFormat('yyyy-MM-dd')
                                  .format(DateTime.now());
                        }
                        return due.startsWith(selectedKey);
                      }).toList()
                        ..sort((a, b) =>
                            (a['priorityOrder'] as int? ?? 3)
                                .compareTo(
                                b['priorityOrder'] as int? ?? 3));

                      if (filtered.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.event_available,
                                  color: Color(0xFF9CA3AF), size: 56),
                              const SizedBox(height: 12),
                              Text(
                                'No tasks for ${DateFormat('EEE, dd MMM').format(_selectedDay)}',
                                style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final doc = filtered[i];
                          final data = doc.data()
                          as Map<String, dynamic>;
                          final bool done =
                              data['done'] as bool? ?? false;
                          final color =
                          _colorFor(data['priority'] ?? 'Low');

                          return Dismissible(
                            key: Key(doc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin:
                              const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius:
                                BorderRadius.circular(14),
                              ),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(
                                  right: 20),
                              child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white),
                            ),
                            onDismissed: (_) => _delete(doc.id),
                            child: Container(
                              margin:
                              const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD7CCC8),
                                borderRadius:
                                BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFD7CCC8).withOpacity(0.6)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  GestureDetector(
                                    onTap: () =>
                                        _toggleDone(doc.id, done),
                                    child: AnimatedContainer(
                                      duration: const Duration(
                                          milliseconds: 200),
                                      width: 26,
                                      height: 26,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: done
                                            ? Colors.green
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: done
                                              ? Colors.green
                                              : Color(0x99FFFFFF),
                                          width: 2,
                                        ),
                                      ),
                                      child: done
                                          ? const Icon(Icons.check,
                                          size: 14,
                                          color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      data['title'] ?? '',
                                      style: TextStyle(
                                        color: done
                                            ? const Color(0xFF9CA3AF)
                                            : const Color(0xFFFFFFFF),
                                        fontWeight: FontWeight.bold,
                                        decoration: done
                                            ? TextDecoration
                                            .lineThrough
                                            : null,
                                        decorationColor:
                                        const Color(0xFF9CA3AF),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3),
                                    decoration: BoxDecoration(
                                      color:
                                      color.withOpacity(0.25),
                                      borderRadius:
                                      BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      data['priority'] ?? '',
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTaskScreen()),
          ),
          backgroundColor: _primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}


