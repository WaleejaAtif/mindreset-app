import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/animated_background.dart';

// ── Bottom-nav destination imports (adjust paths as needed) ──────────────────
import '../home.dart';
import 'planner.dart'; // this screen lives here

// ── Brand colours (kept in sync with rest of app) ────────────────────────────
const Color _brand    = Color(0xFF6D774C); // olive-green highlight (matches TimeTable)
const Color _navActive = Color(0xFF8C52FF); // vibrant purple (matches PlannerScreen FAB)

class MonthlyMoodScreen extends StatefulWidget {
  const MonthlyMoodScreen({super.key});

  @override
  State<MonthlyMoodScreen> createState() => _MonthlyMoodScreenState();
}

class _MonthlyMoodScreenState extends State<MonthlyMoodScreen> {
  // ── Existing state ──────────────────────────────────────────────────────────
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  // ── New state for horizontal date strip ────────────────────────────────────
  late int _selectedDateStripMonth;
  late int _selectedDateStripDay;
  final ScrollController _dateScrollCtrl  = ScrollController();
  final ScrollController _monthScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedDateStripMonth = DateTime.now().month;
    _selectedDateStripDay   = DateTime.now().day;

    // Auto-scroll to today after first frame
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

  // ── Scroll helpers ──────────────────────────────────────────────────────────
  void _scrollToToday() {
    const double itemW = 76.0; // card-width (64) + margin (12)
    final double screenW = MediaQuery.of(context).size.width;
    final double offset =
        (_selectedDateStripDay - 1) * itemW - (screenW / 2) + (itemW / 2);
    if (_dateScrollCtrl.hasClients) {
      _dateScrollCtrl.animateTo(
        offset.clamp(0.0, _dateScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _scrollToCurrentMonth() {
    const double itemW = 110.0; // chip-width approx
    final double offset = (_selectedDateStripMonth - 1) * itemW - 20;
    if (_monthScrollCtrl.hasClients) {
      _monthScrollCtrl.animateTo(
        offset.clamp(0.0, _monthScrollCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    }
  }

  // ── Existing helpers (UNCHANGED) ────────────────────────────────────────────
  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Color _moodColor(String? mood) {
    switch (mood) {
      case 'Great':    return Colors.green;
      case 'Good':     return Colors.lightGreen;
      case 'Okay':     return Colors.amber;
      case 'Low':      return Colors.orange;
      case 'Very Low': return Colors.red;
      default:         return Colors.black.withValues(alpha: 0.05);
    }
  }

  String _moodEmoji(String? mood) {
    switch (mood) {
      case 'Great':    return '😄';
      case 'Good':     return '🙂';
      case 'Okay':     return '😐';
      case 'Low':      return '😕';
      case 'Very Low': return '😞';
      default:         return '';
    }
  }

  int get _daysInMonth =>
      DateTime(_month.year, _month.month + 1, 0).day;

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime.now())) {
      setState(() => _month = next);
    }
  }

  // ── Date-strip helpers ──────────────────────────────────────────────────────
  int _daysInStripMonth(int month) {
    if ([1,3,5,7,8,10,12].contains(month)) return 31;
    if ([4,6,9,11].contains(month)) return 30;
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
    return AnimatedBackground(
      isLightMode: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,

        // ── AppBar ────────────────────────────────────────────────────────────
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: const Text(
            'Planning',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),

        // ── Body ──────────────────────────────────────────────────────────────
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
                    final selected = m == _selectedDateStripMonth;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDateStripMonth = m;
                          // reset day to 1 when changing month
                          _selectedDateStripDay = 1;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToToday();
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected
                              ? _brand
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: selected
                                ? _brand
                                : Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          _monthName(m),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 14),

              // ── Date cards ─────────────────────────────────────────────────
              SizedBox(
                height: 96,
                child: ListView.builder(
                  controller: _dateScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: _daysInStripMonth(_selectedDateStripMonth),
                  itemBuilder: (_, i) {
                    final day  = i + 1;
                    final date = DateTime(
                        DateTime.now().year, _selectedDateStripMonth, day);
                    final isSelected = day == _selectedDateStripDay &&
                        _selectedDateStripMonth == DateTime.now().month;
                    final isToday = day == DateTime.now().day &&
                        _selectedDateStripMonth == DateTime.now().month;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDateStripDay = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: 64,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _brand
                              : Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isToday && !isSelected
                                ? _brand.withOpacity(0.7)
                                : Colors.white.withOpacity(
                                    isSelected ? 0.4 : 0.10),
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _brand.withOpacity(0.45),
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
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 5),
                            // Mood indicator dots
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

              const SizedBox(height: 10),

              // ── "Plan Your Day" heading ─────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Plan Your Day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Month navigation for mood calendar ─────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: Colors.white70),
                      onPressed: _prevMonth,
                    ),
                    Text(
                      DateFormat('MMMM yyyy').format(_month),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: Colors.white70),
                      onPressed: _nextMonth,
                    ),
                  ],
                ),
              ),

              // ── Day-of-week headers ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map(
                        (d) => Expanded(
                          child: Center(
                            child: Text(
                              d,
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),

              const SizedBox(height: 8),

              // ── Mood calendar grid ──────────────────────────────────────────
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_userId)
                      .collection('daily_logs')
                      .get(),
                  builder: (context, snapshot) {
                    final Map<String, String> moodMap = {};
                    if (snapshot.hasData) {
                      for (final doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        moodMap[doc.id] = data['mood'] ?? '';
                      }
                    }

                    return Column(
                      children: [
                        Expanded(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: GridView.builder(
                              physics: const BouncingScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 7,
                                crossAxisSpacing: 5,
                                mainAxisSpacing: 5,
                              ),
                              itemCount: _daysInMonth +
                                  (DateTime(
                                              _month.year, _month.month, 1)
                                          .weekday -
                                      1),
                              itemBuilder: (_, i) {
                                final offset =
                                    DateTime(_month.year, _month.month, 1)
                                            .weekday -
                                        1;
                                if (i < offset) {
                                  return const SizedBox.shrink();
                                }

                                final day = i - offset + 1;
                                final dateKey =
                                    DateFormat('yyyy-MM-dd').format(DateTime(
                                        _month.year, _month.month, day));
                                final mood = moodMap[dateKey];
                                final isToday = dateKey ==
                                    DateFormat('yyyy-MM-dd')
                                        .format(DateTime.now());

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: mood != null && mood.isNotEmpty
                                        ? _moodColor(mood)
                                        : Colors.white.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isToday
                                          ? Colors.white
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '$day',
                                        style: TextStyle(
                                          color: mood != null &&
                                                  mood.isNotEmpty
                                              ? Colors.white
                                              : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (mood != null && mood.isNotEmpty)
                                        Text(
                                          _moodEmoji(mood),
                                          style: const TextStyle(fontSize: 9),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        // ── Legend ──────────────────────────────────────────
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 6,
                            alignment: WrapAlignment.center,
                            children: [
                              'Very Low', 'Low', 'Okay', 'Good', 'Great'
                            ]
                                .map((m) => Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: _moodColor(m),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          m,
                                          style: const TextStyle(
                                              color: Colors.white54,
                                              fontSize: 11),
                                        ),
                                      ],
                                    ))
                                .toList(),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Bottom Navigation Bar ─────────────────────────────────────────────
        bottomNavigationBar: _BottomNavBar(currentIndex: 3),
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

// ── Reusable bottom nav bar (matches app-wide design) ─────────────────────────
class _BottomNavBar extends StatelessWidget {
  final int currentIndex;
  const _BottomNavBar({required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withOpacity(0.95),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.08), width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                index: 0,
                currentIndex: currentIndex,
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                ),
              ),
              _NavItem(
                icon: Icons.school_outlined,
                index: 1,
                currentIndex: currentIndex,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.self_improvement_outlined,
                index: 2,
                currentIndex: currentIndex,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.calendar_month_outlined,
                index: 3,
                currentIndex: currentIndex,
                isActive: true,
                onTap: () {},
              ),
              _NavItem(
                icon: Icons.edit_outlined,
                index: 4,
                currentIndex: currentIndex,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;
  final bool isActive;

  const _NavItem({
    required this.icon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool selected = index == currentIndex;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? _navActive.withOpacity(0.20)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          size: 24,
          color: selected ? _navActive : Colors.white54,
        ),
      ),
    );
  }
}