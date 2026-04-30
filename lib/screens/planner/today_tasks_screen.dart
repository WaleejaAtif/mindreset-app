import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_task_screen.dart';
import '../../widgets/animated_background.dart';

const Color _primaryColor = Color(0xFF8C52FF); // Vibrant Purple
const Color _highColor = Color(0xFF5E17EB); // Deep Purple
const Color _medColor = Color(0xFF38B6FF); // Light Blue
const Color _lowColor = Color(0xFF5CE1E6); // Mint/Cyan

class TodayTasksScreen extends StatelessWidget {
  const TodayTasksScreen({super.key});

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Color _colorFor(String p) {
    if (p == 'High') return _highColor;
    if (p == 'Medium') return _medColor;
    return _lowColor;
  }

  Future<void> _toggleDone(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_userId)
        .collection('tasks')
        .doc(id)
        .update({'done': !current});
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
    return AnimatedBackground(
      isLightMode: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Today\'s Tasks',
              style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF2D3142)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFF2D3142)),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddTaskScreen()),
              ),
            ),
          ],
        ),
        body: SafeArea(
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
                      valueColor:
                      AlwaysStoppedAnimation(Colors.white),
                    ),
                  );
                }

                final all = snapshot.data?.docs ?? [];
                final pending = all
                    .where((d) => !(d['done'] as bool? ?? false))
                    .toList()
                  ..sort((a, b) =>
                      (a['priorityOrder'] as int? ?? 3)
                          .compareTo(b['priorityOrder'] as int? ?? 3));

                final done = all
                    .where((d) => d['done'] as bool? ?? false)
                    .toList();

                if (all.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.checklist_rounded,
                            color: Colors.white54, size: 64),
                        const SizedBox(height: 12),
                        const Text('No tasks yet!',
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18)),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                const AddTaskScreen()),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Task'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (pending.isNotEmpty) ...[
                      _sectionHeader('Pending', Colors.white70),
                      ...pending.map((doc) => _taskTile(
                          doc, _colorFor(doc['priority'] ?? 'Low'))),
                    ],
                    if (done.isNotEmpty) ...[
                      _sectionHeader(
                          'Completed', Colors.greenAccent),
                      ...done.map((doc) => _taskTile(
                          doc, _colorFor(doc['priority'] ?? 'Low'))),
                    ],
                  ],
                );
              },
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

  Widget _sectionHeader(String label, Color color) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 8),
    child: Text(
      label,
      style: TextStyle(
          color: color == Colors.white70 ? const Color(0xFF2D3142) : color,
          fontWeight: FontWeight.bold,
          fontSize: 15),
    ),
  );

  Widget _taskTile(QueryDocumentSnapshot doc, Color color) {
    final data = doc.data() as Map<String, dynamic>;
    final bool done = data['done'] as bool? ?? false;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _delete(doc.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => _toggleDone(doc.id, done),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? Colors.green : Colors.transparent,
                  border: Border.all(
                    color: done ? Colors.green : Colors.white60,
                    width: 2,
                  ),
                ),
                child: done
                    ? const Icon(Icons.check,
                    size: 14, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['title'] ?? '',
                    style: TextStyle(
                      color: done ? const Color(0xFF9CA3AF) : const Color(0xFF2D3142),
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: const Color(0xFF9CA3AF),
                    ),
                  ),
                  if ((data['description'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        data['description'],
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if ((data['dueDate'] ?? '').toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 11, color: color),
                          const SizedBox(width: 4),
                          Text(
                            data['dueDate'].toString().substring(0, 10),
                            style: TextStyle(
                                color: color, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['priority'] ?? '',
                    style: TextStyle(
                      color: done ? Colors.white38 : color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['category'] ?? '',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}