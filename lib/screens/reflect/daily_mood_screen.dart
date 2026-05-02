import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Brand colors (matching PlannerScreen) ──────────────────────────────────
const Color _brandOlive   = Color(0xFF6D774C);

// ── Mood data model ─────────────────────────────────────────────────────────
class DailyData {
  final String? mood;
  final String? emoji;
  final String? sleep;
  final int pomodoroCompleted;
  final int gamesPlayed;
  final bool exerciseCompleted;
  final bool chattedWithAi;
  final int focusStrategiesTaken;
  final int studyTipsTaken;
  final int tasksCreated;
  final bool? highPriorityTaskCompleted;

  DailyData({
    this.mood,
    this.emoji,
    this.sleep,
    this.pomodoroCompleted = 0,
    this.gamesPlayed = 0,
    this.exerciseCompleted = false,
    this.chattedWithAi = false,
    this.focusStrategiesTaken = 0,
    this.studyTipsTaken = 0,
    this.tasksCreated = 0,
    this.highPriorityTaskCompleted,
  });

  factory DailyData.fromMap(Map<String, dynamic> map) {
    return DailyData(
      mood: map['mood'] as String?,
      emoji: map['emoji'] as String?,
      sleep: map['sleep'] as String?,
      pomodoroCompleted: map['pomodoroCompleted'] as int? ?? 0,
      gamesPlayed: map['gamesPlayed'] as int? ?? 0,
      exerciseCompleted: map['exerciseCompleted'] as bool? ?? false,
      chattedWithAi: map['chattedWithAi'] as bool? ?? false,
      focusStrategiesTaken: map['focusStrategiesTaken'] as int? ?? 0,
      studyTipsTaken: map['studyTipsTaken'] as int? ?? 0,
      tasksCreated: map['tasksCreated'] as int? ?? 0,
      highPriorityTaskCompleted: map['highPriorityTaskCompleted'] as bool?,
    );
  }

  bool get hasData => mood != null || sleep != null || pomodoroCompleted > 0 || gamesPlayed > 0 || exerciseCompleted || chattedWithAi || focusStrategiesTaken > 0 || studyTipsTaken > 0 || tasksCreated > 0 || highPriorityTaskCompleted != null;
}

// ── Main screen ──────────────────────────────────────────────────────────────
class DailyMoodScreen extends StatefulWidget {
  const DailyMoodScreen({super.key});

  @override
  State<DailyMoodScreen> createState() => _DailyMoodScreenState();
}

class _DailyMoodScreenState extends State<DailyMoodScreen>
    with TickerProviderStateMixin {

  // ── Calendar state ──────────────────────────────────────────────────────
  late DateTime _selectedDate;
  late int _stripMonth;
  final ScrollController _dateScrollCtrl  = ScrollController();
  final ScrollController _monthScrollCtrl = ScrollController();

  // ── History card state ─────────────────────────────────────────────────
  DailyData? _dailyData;
  bool _loadingData = false;

  // ── Monthly data state ─────────────────────────────────────────────────
  Map<int, DailyData?> _monthlyData = {};
  bool _loadingMonthly = false;

  // ── Animation controllers ──────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _stripMonth   = DateTime.now().month;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
      _scrollToCurrentMonth();
      _fetchDailyData(_selectedDate);
      _fetchMonthlyData(_selectedDate.year, _stripMonth);
    });
  }

  @override
  void dispose() {
    _dateScrollCtrl.dispose();
    _monthScrollCtrl.dispose();
    super.dispose();
  }

  // ── Scroll helpers ──────────────────────────────────────────────────────
  void _scrollToSelectedDate() {
    const double itemW = 72.0;
    final double screenW = MediaQuery.of(context).size.width;
    final double offset =
        (_selectedDate.day - 1) * itemW - (screenW / 2) + (itemW / 2);
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

  // ── Firebase fetch ──────────────────────────────────────────────────────
  Future<void> _fetchDailyData(DateTime date) async {
    setState(() {
      _loadingData = true;
      _dailyData   = null;
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        // Use mock data when not authenticated (dev/preview mode)
        await Future.delayed(const Duration(milliseconds: 300));
        final mock = _mockData(date);
        if (mounted) {
          setState(() {
            _dailyData   = mock;
            _loadingData = false;
          });
        }
        return;
      }

      final dateKey = '${date.year}-${date.month.toString().padLeft(2,'0')}-${date.day.toString().padLeft(2,'0')}';
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_data')
          .doc(dateKey)
          .get();

      if (mounted) {
        setState(() {
          _dailyData   = doc.exists ? DailyData.fromMap(doc.data()!) : null;
          _loadingData = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingData = false);
      }
    }
  }

  /// Returns lightweight mock data for preview / unauthenticated use.
  DailyData? _mockData(DateTime date) {
    final today = DateTime.now();
    if (date.day == today.day && date.month == today.month) {
      return DailyData(
        mood: 'Happy',
        emoji: '😄',
        sleep: '7h',
        pomodoroCompleted: 4,
        gamesPlayed: 1,
        exerciseCompleted: true,
        chattedWithAi: true,
        focusStrategiesTaken: 2,
        studyTipsTaken: 1,
        tasksCreated: 3,
        highPriorityTaskCompleted: true,
      );
    }
    if (date.day == today.day - 1) {
      return DailyData(
        mood: 'Okay',
        emoji: '🙂',
        sleep: '6h',
        pomodoroCompleted: 2,
        gamesPlayed: 0,
        exerciseCompleted: false,
        chattedWithAi: false,
        focusStrategiesTaken: 1,
        studyTipsTaken: 0,
        tasksCreated: 2,
        highPriorityTaskCompleted: false,
      );
    }
    return null;
  }

  // ── Fetch monthly data ──────────────────────────────────────────────────
  Future<void> _fetchMonthlyData(int year, int month) async {
    setState(() {
      _loadingMonthly = true;
      _monthlyData = {};
    });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        // Mock data for unauthenticated
        final daysInMonth = _daysInMonth(month);
        for (int day = 1; day <= daysInMonth; day++) {
          final date = DateTime(year, month, day);
          _monthlyData[day] = _mockData(date);
        }
        if (mounted) {
          setState(() => _loadingMonthly = false);
        }
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final daysInMonth = _daysInMonth(month);
      for (int day = 1; day <= daysInMonth; day++) {
        final dateKey = '$year-${month.toString().padLeft(2,'0')}-${day.toString().padLeft(2,'0')}';
        final doc = await userRef.collection('daily_logs').doc(dateKey).get();
        if (doc.exists) {
          _monthlyData[day] = DailyData.fromMap(doc.data()!);
        } else {
          _monthlyData[day] = null;
        }
      }

      if (mounted) {
        setState(() => _loadingMonthly = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingMonthly = false);
      }
    }
  }

  // ── Date tap ────────────────────────────────────────────────────────────
  void _onDateTap(int day) {
    final newDate = DateTime(_selectedDate.year, _stripMonth, day);
    setState(() => _selectedDate = newDate);
    _fetchDailyData(newDate);
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  int _daysInMonth(int month) {
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

  bool get _isToday =>
      _selectedDate.day   == DateTime.now().day &&
      _selectedDate.month == DateTime.now().month &&
      _selectedDate.year  == DateTime.now().year;

  // ── Build ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Daily Mood',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0F1A),
              Color(0xFF1A1228),
              Color(0xFF0D1A14),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            children: [

              const SizedBox(height: 8),

              // ── Month chips ──────────────────────────────────────────
              SizedBox(
                height: 44,
                child: ListView.builder(
                  controller: _monthScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: 12,
                  itemBuilder: (_, i) {
                    final m   = i + 1;
                    final sel = m == _stripMonth;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _stripMonth   = m;
                          _selectedDate = DateTime(
                            _selectedDate.year, m,
                            1.clamp(1, _daysInMonth(m)),
                          );
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToSelectedDate();
                        });
                        _fetchDailyData(_selectedDate);
                        _fetchMonthlyData(_selectedDate.year, m);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel
                              ? _brandOlive
                              : Color(0xFF1A1333).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: sel
                                ? _brandOlive
                                : Color(0xFF1A1333).withOpacity(0.20),
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

              // ── Date strip ───────────────────────────────────────────
              SizedBox(
                height: 96,
                child: ListView.builder(
                  controller: _dateScrollCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: _daysInMonth(_stripMonth),
                  itemBuilder: (_, i) {
                    final day    = i + 1;
                    final date   = DateTime(_selectedDate.year, _stripMonth, day);
                    final isSel  = day == _selectedDate.day &&
                                   _stripMonth == _selectedDate.month;
                    final isTdy  = day == DateTime.now().day &&
                                   _stripMonth == DateTime.now().month;

                    return GestureDetector(
                      onTap: () => _onDateTap(day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                        width: 60,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSel
                              ? _brandOlive
                              : Color(0xFF1A1333).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isTdy && !isSel
                                ? _brandOlive.withOpacity(0.7)
                                : Color(0xFF1A1333).withOpacity(
                                    isSel ? 0.4 : 0.10),
                            width: 1.5,
                          ),
                          boxShadow: isSel
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
                                color: isSel
                                    ? Colors.white
                                    : Color(0x99FFFFFF),
                              ),
                            ),
                            const SizedBox(height: 4),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: isSel ? 24 : 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              child: Text('$day'),
                            ),
                            const SizedBox(height: 4),
                            if (_monthlyData[day]?.hasData ?? false)
                              Text(
                                _monthlyData[day]!.emoji ?? '😐',
                                style: TextStyle(
                                  fontSize: isSel ? 18 : 14,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              )
                            else if (isTdy)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? Color(0xFF1A1333)
                                      : _brandOlive,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ── Selected Day Details ─────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSelectedDayDetails(),
              ),

              const SizedBox(height: 24),

              // ── Monthly Summary ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildMonthlySummary(),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ── Selected Day Details ──────────────────────────────────────────────
  Widget _buildSelectedDayDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: _brandOlive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _isToday
                  ? "Today's Details"
                  : 'Day Details — ${_selectedDate.day} ${_monthName(_selectedDate.month)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_loadingData)
          _glassCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  color: _brandOlive,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          )
        else if (_dailyData == null)
          _buildEmptyCard()
        else
          _buildDataCard(_dailyData!),
      ],
    );
  }

  // ── Monthly Summary ────────────────────────────────────────────────────
  Widget _buildMonthlySummary() {
    if (_loadingMonthly) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: _brandOlive,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Monthly Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _glassCard(
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(
                  color: _brandOlive,
                  strokeWidth: 2.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    int goodMood = 0, neutralMood = 0, badMood = 0;
    int goodSleep = 0, poorSleep = 0;
    int games = 0, aiChats = 0, exercises = 0;

    _monthlyData.forEach((day, data) {
      if (data != null) {
        // Mood
        if (data.mood != null) {
          final lower = data.mood!.toLowerCase();
          if (lower.contains('very good') || lower.contains('amazing')) {
            goodMood++;
          } else if (lower.contains('neutral') || lower.contains('okay') || lower.contains('fair')) {
            neutralMood++;
          } else if (lower.contains('bad') || lower.contains('low') || lower.contains('poor') || lower.contains('terrible')) {
            badMood++;
          }
        }

        // Sleep
        if (data.sleep != null) {
          final lower = data.sleep!.toLowerCase();
          if (lower.contains('good') || lower.contains('7-8') || lower.contains('8+') || lower.contains('excellent')) {
            goodSleep++;
          } else {
            poorSleep++;
          }
        }

        // Activities
        games += data.gamesPlayed;
        if (data.chattedWithAi) aiChats++;
        if (data.exerciseCompleted) exercises++;
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: _brandOlive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Monthly Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _glassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mood Summary
              _summaryRow('Mood', [
                _SummaryItem('Good', goodMood, const Color(0xFF59D99D)),
                _SummaryItem('Neutral', neutralMood, const Color(0xFFFFD166)),
                _SummaryItem('Bad', badMood, const Color(0xFFFF7F7F)),
              ]),
              _divider(),
              // Sleep Summary
              _summaryRow('Sleep', [
                _SummaryItem('Good sleep', goodSleep, const Color(0xFF7EC8E3)),
                _SummaryItem('Poor sleep', poorSleep, const Color(0xFFFFB347)),
              ]),
              _divider(),
              // Activities Summary
              _summaryRow('Activities', [
                _SummaryItem('Games', games, const Color(0xFF8A7CFF)),
                _SummaryItem('AI Chatbot', aiChats, const Color(0xFF65C7F7)),
                _SummaryItem('Exercises', exercises, const Color(0xFFAB7DAC)),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String title, List<_SummaryItem> items) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: items.map((item) => _summaryChip(item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(_SummaryItem item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: item.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        '${item.label}: ${item.count}',
        style: TextStyle(
          color: item.color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return _glassCard(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Icon(
            Icons.calendar_today_outlined,
            color: Colors.white.withOpacity(0.25),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No data for this day',
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Log your mood, sleep, and tasks to see history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.25),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildDataCard(DailyData data) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Mood row
          if (data.mood != null) ...[
            _historyRow(
              icon: data.emoji ?? '😐',
              label: 'Mood',
              value: data.mood!,
              accent: const Color(0xFFFFB347),
            ),
            _divider(),
          ],

          // Sleep row
          if (data.sleep != null) ...[
            _historyRow(
              icon: '🛌',
              label: 'Sleep',
              value: data.sleep!,
              accent: const Color(0xFF7EC8E3),
            ),
            _divider(),
          ],

          // Exercise row
          if (data.exerciseCompleted) ...[
            _historyRow(
              icon: '🏃',
              label: 'Exercise',
              value: 'Completed',
              accent: const Color(0xFF90EE90),
            ),
            _divider(),
          ],

          // Pomodoro row
          if (data.pomodoroCompleted > 0) ...[
            _historyRow(
              icon: '⏱️',
              label: 'Pomodoro',
              value: '${data.pomodoroCompleted} session${data.pomodoroCompleted == 1 ? '' : 's'}',
              accent: const Color(0xFFFF7F7F),
            ),
            _divider(),
          ],

          // Tasks row
          if (data.tasksCreated > 0) ...[
            _historyRow(
              icon: '📝',
              label: 'Tasks',
              value: '${data.tasksCreated} created',
              accent: const Color(0xFF9370DB),
            ),
            _divider(),
          ],

          // Games row
          if (data.gamesPlayed > 0) ...[
            _historyRow(
              icon: '🎮',
              label: 'Games',
              value: '${data.gamesPlayed} played',
              accent: const Color(0xFFFF69B4),
            ),
            _divider(),
          ],

          // AI Chat row
          if (data.chattedWithAi) ...[
            _historyRow(
              icon: '🤖',
              label: 'AI Chat',
              value: 'Yes',
              accent: const Color(0xFF00CED1),
            ),
            _divider(),
          ],

          // Focus Strategies row
          if (data.focusStrategiesTaken > 0) ...[
            _historyRow(
              icon: '🎯',
              label: 'Focus',
              value: '${data.focusStrategiesTaken} strategies',
              accent: const Color(0xFFFFD700),
            ),
            _divider(),
          ],

          // Study Tips row
          if (data.studyTipsTaken > 0) ...[
            _historyRow(
              icon: '📚',
              label: 'Study Tips',
              value: '${data.studyTipsTaken} tips',
              accent: const Color(0xFF32CD32),
            ),
            _divider(),
          ],

          // High Priority Task
          if (data.highPriorityTaskCompleted != null) ...[
            _historyRow(
              icon: '⭐',
              label: 'Priority Task',
              value: data.highPriorityTaskCompleted! ? 'Completed' : 'Not Completed',
              accent: const Color(0xFFFF4500),
            ),
          ],
        ],
      ),
    );
  }

  // ── Card helpers ────────────────────────────────────────────────────────
  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1A1333).withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Color(0xFF1A1333).withOpacity(0.12),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _brandOlive.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _historyRow({
    required String icon,
    required String label,
    required String value,
    required Color accent,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          _iconBadge(icon, accent),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconBadge(String emoji, Color color) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _divider() => Divider(
        color: Color(0xFF1A1333).withOpacity(0.08),
        height: 1,
        thickness: 1,
      );
}

// ── Summary Item helper ───────────────────────────────────────────────────
class _SummaryItem {
  final String label;
  final int count;
  final Color color;

  const _SummaryItem(this.label, this.count, this.color);
}

