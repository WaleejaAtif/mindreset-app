import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_task_screen.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/app_bottom_nav.dart';

const Color _primaryColor = Color(0xFF8C52FF);
const Color _brandOlive   = Color(0xFF6D774C);
const Color _highColor    = Color(0xFF5E17EB);
const Color _medColor     = Color(0xFF38B6FF);
const Color _lowColor     = Color(0xFF5CE1E6);

class DailyViewScreen extends StatefulWidget {
  const DailyViewScreen({super.key});

  @override
  State<DailyViewScreen> createState() => _DailyViewScreenState();
}

class _DailyViewScreenState extends State<DailyViewScreen> {
  // ── Existing state (UNCHANGED) ──────────────────────────────────────────────
  DateTime _selectedDay = DateTime.now();
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── New strip state ─────────────────────────────────────────────────────────
  late int _stripMonth;
  final ScrollController _dateScrollCtrl  = ScrollController();
  final ScrollController _monthScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _stripMonth = DateTime.now().month;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
      _scrollToCurrentMonth();
    });
  }

  @override
  void dispose() {
    _dateScrollCtrl.dispose();
    _monthScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToToday() {
    const double itemW = 76.0;
    final double screenW = MediaQuery.of(context).size.width;
    final double offset =
        (_selectedDay.day - 1) * itemW - (screenW / 2) + (itemW / 2);
    if (_dateScrollCtrl.hasClients) {
      _dateScrollCtrl.animateTo(
        offset.clamp(0.0, _dateScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToCurrentMonth() {
    const double itemW = 110.0;
    final double offset = (_stripMonth - 1) * itemW - 20;
    if (_monthScrollCtrl.hasClients) {
      _monthScrollCtrl.animateTo(
        offset.clamp(0.0, _monthScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Existing helpers (UNCHANGED) ────────────────────────────────────────────
  Color _colorFor(String p) {
    if (p == 'High') return _highColor;
    if (p == 'Medium') return _medColor;
    return _lowColor;
  }

  Future<void> _toggleDone(String id, bool current) async {
    await FirebaseFirestore.instance
        .collection('users').doc(_userId).collection('tasks')
        .doc(id).update({'done': !current});
  }

  Future<void> _delete(String id) async {
    await FirebaseFirestore.instance
        .collection('users').doc(_userId).collection('tasks')
        .doc(id).delete();
  }

  // ── Strip helpers ───────────────────────────────────────────────────────────
  int _daysInMonth(int m) {
    if ([1,3,5,7,8,10,12].contains(m)) return 31;
    if ([4,6,9,11].contains(m)) return 30;
    return (DateTime.now().year % 4 == 0) ? 29 : 28;
  }

  String _monthName(int m) => [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ][m - 1];

  String _weekdayShort(int wd) =>
      ['MON','TUE','WED','THU','FRI','SAT','SUN'][wd - 1];

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final selectedKey = DateFormat('yyyy-MM-dd').format(_selectedDay);

    return AnimatedBackground(
      isLightMode: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text(
            DateFormat('MMMM yyyy').format(_selectedDay),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),

        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Month chips ────────────────────────────────────────────────
              SizedBox(
                height: 44,
                child: ListView.builder(
                  controller: _monthScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final m = i + 1;
                    final sel = m == _stripMonth;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _stripMonth = m;
                        _selectedDay = DateTime(DateTime.now().year, m, 1);
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? _brandOlive
                              : Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: sel
                                ? _brandOlive
                                : Colors.white.withOpacity(0.20),
                          ),
                        ),
                        child: Text(
                          _monthName(m),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight:
                                sel ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // ── Date cards (replaces the original 7-day strip) ─────────────
              SizedBox(
                height: 96,
                child: ListView.builder(
                  controller: _dateScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: _daysInMonth(_stripMonth),
                  itemBuilder: (_, i) {
                    final day  = i + 1;
                    final date = DateTime(DateTime.now().year, _stripMonth, day);
                    final isSelected =
                        DateFormat('yyyy-MM-dd').format(date) == selectedKey;
                    final isToday = DateFormat('yyyy-MM-dd').format(date) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now());

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: 64,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _brandOlive
                              : Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isToday && !isSelected
                                ? _brandOlive.withOpacity(0.7)
                                : Colors.white.withOpacity(
                                    isSelected ? 0.4 : 0.10),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _brandOlive.withOpacity(0.45),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  )
                                ]
                              : [],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _weekdayShort(date.weekday),
                              style: TextStyle(
                                fontSize: 9,
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white60,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '$day',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _dot(Colors.blue.shade300),
                                const SizedBox(width: 2),
                                _dot(Colors.orange.shade300),
                                const SizedBox(width: 2),
                                _dot(Colors.purple.shade300),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 4),

              // ── Task list (EXISTING LOGIC — UNCHANGED) ─────────────────────
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users').doc(_userId).collection('tasks')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white)),
                      );
                    }

                    final all = snapshot.data?.docs ?? [];
                    final filtered = all.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final due = data['dueDate']?.toString() ?? '';
                      if (due.isEmpty) {
                        return selectedKey ==
                            DateFormat('yyyy-MM-dd').format(DateTime.now());
                      }
                      return due.startsWith(selectedKey);
                    }).toList()
                      ..sort((a, b) =>
                          (a['priorityOrder'] as int? ?? 3)
                              .compareTo(b['priorityOrder'] as int? ?? 3));

                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.event_available,
                                color: Colors.white24, size: 56),
                            const SizedBox(height: 12),
                            Text(
                              'No tasks for ${DateFormat('EEE, dd MMM').format(_selectedDay)}',
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final doc  = filtered[i];
                        final data = doc.data() as Map<String, dynamic>;
                        final bool done = data['done'] as bool? ?? false;
                        final color = _colorFor(data['priority'] ?? 'Low');

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
                            child: const Icon(Icons.delete_outline,
                                color: Colors.white),
                          ),
                          onDismissed: (_) => _delete(doc.id),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.09),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.10)),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.12),
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
                                    duration:
                                        const Duration(milliseconds: 200),
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
                                            : Colors.white38,
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
                                  child: Text(
                                    data['title'] ?? '',
                                    style: TextStyle(
                                      color: done
                                          ? Colors.white30
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                      decorationColor: Colors.white30,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.22),
                                    borderRadius: BorderRadius.circular(8),
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
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddTaskScreen())),
          backgroundColor: _primaryColor,
          child: const Icon(Icons.add, color: Colors.white),
        ),

        bottomNavigationBar: const AppBottomNav(currentIndex: 3),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}