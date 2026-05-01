import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Brand colors (matching PlannerScreen) ──────────────────────────────────
const Color _primaryColor = Color(0xFF8C52FF);
const Color _brandOlive   = Color(0xFF6D774C);
const Color _darkBg       = Color(0xFF0F0F1A);
const Color _cardBg       = Color(0xFF1A1A2E);

// ── Mood data model ─────────────────────────────────────────────────────────
class DailyData {
  final String mood;
  final String emoji;
  final String sleep;
  final String exercise;
  final int pomodoro;
  final List<String> tasks;

  const DailyData({
    required this.mood,
    required this.emoji,
    required this.sleep,
    required this.exercise,
    required this.pomodoro,
    required this.tasks,
  });

  factory DailyData.fromMap(Map<String, dynamic> map) {
    return DailyData(
      mood:      map['mood']     as String? ?? '',
      emoji:     map['emoji']    as String? ?? '😐',
      sleep:     map['sleep']    as String? ?? '--',
      exercise:  map['exercise'] as String? ?? '--',
      pomodoro:  (map['pomodoro'] as num?)?.toInt() ?? 0,
      tasks:     List<String>.from(map['tasks'] as List? ?? []),
    );
  }
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

  // ── Animation controllers ──────────────────────────────────────────────
  late AnimationController _cardAnimCtrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  // ── Emoji selection state (preserved) ──────────────────────────────────
  String? _selectedEmoji;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _stripMonth   = DateTime.now().month;

    _cardAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _cardFade  = CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end:   Offset.zero,
    ).animate(CurvedAnimation(parent: _cardAnimCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
      _scrollToCurrentMonth();
      _fetchDailyData(_selectedDate);
    });
  }

  @override
  void dispose() {
    _dateScrollCtrl.dispose();
    _monthScrollCtrl.dispose();
    _cardAnimCtrl.dispose();
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
    _cardAnimCtrl.reset();

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
          _cardAnimCtrl.forward();
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
        _cardAnimCtrl.forward();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingData = false);
        _cardAnimCtrl.forward();
      }
    }
  }

  /// Returns lightweight mock data for preview / unauthenticated use.
  DailyData? _mockData(DateTime date) {
    final today = DateTime.now();
    if (date.day == today.day && date.month == today.month) {
      return const DailyData(
        mood: 'Happy', emoji: '😄',
        sleep: '7h', exercise: 'Yes',
        pomodoro: 4,
        tasks: ['Study AI', 'Workout', 'Read book'],
      );
    }
    if (date.day == today.day - 1) {
      return const DailyData(
        mood: 'Okay', emoji: '🙂',
        sleep: '6h', exercise: 'No',
        pomodoro: 2,
        tasks: ['Morning run', 'Team meeting'],
      );
    }
    return null;
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
      backgroundColor: _darkBg,
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
                      },
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
                              : Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isTdy && !isSel
                                ? _brandOlive.withOpacity(0.7)
                                : Colors.white.withOpacity(
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
                                    : Colors.white60,
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
                            if (isTdy)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? Colors.white
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

              // ── "How are you feeling" section (PRESERVED) ────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isToday ? 'How are you feeling today?' : 'Mood for ${_monthName(_selectedDate.month)} ${_selectedDate.day}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: ['😄','🙂','😐','😔','😢'].map((emoji) =>
                        _MoodEmoji(
                          emoji: emoji,
                          isSelected: _selectedEmoji == emoji,
                          onTap: () => setState(() => _selectedEmoji = emoji),
                        ),
                      ).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Daily history card ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
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
                              ? "Today's Summary"
                              : 'Day Summary — ${_selectedDate.day} ${_monthName(_selectedDate.month)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _buildHistoryCard(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── History card widget ─────────────────────────────────────────────────
  Widget _buildHistoryCard() {
    if (_loadingData) {
      return _glassCard(
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: CircularProgressIndicator(
              color: _brandOlive,
              strokeWidth: 2.5,
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _cardFade,
      child: SlideTransition(
        position: _cardSlide,
        child: _dailyData == null
            ? _buildEmptyCard()
            : _buildDataCard(_dailyData!),
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
          _historyRow(
            icon: '😊',
            label: 'Mood',
            value: '${data.emoji}  ${data.mood}',
            accent: const Color(0xFFFFB347),
          ),

          _divider(),

          // Sleep row
          _historyRow(
            icon: '🛌',
            label: 'Sleep',
            value: data.sleep,
            accent: const Color(0xFF7EC8E3),
          ),

          _divider(),

          // Exercise row
          _historyRow(
            icon: '🏃',
            label: 'Exercise',
            value: data.exercise,
            accent: const Color(0xFF90EE90),
          ),

          _divider(),

          // Pomodoro row
          _historyRow(
            icon: '⏱️',
            label: 'Pomodoro',
            value: data.pomodoro > 0
                ? '${data.pomodoro} session${data.pomodoro == 1 ? '' : 's'} ✓'
                : 'Not achieved',
            accent: const Color(0xFFFF7F7F),
          ),

          if (data.tasks.isNotEmpty) ...[
            _divider(),

            // Tasks section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _iconBadge('📋', const Color(0xFFD4AAFF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tasks',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...data.tasks.map((task) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _brandOlive,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                task,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.check_circle_outline,
                              color: _brandOlive,
                              size: 14,
                            ),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
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
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
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
        color: Colors.white.withOpacity(0.08),
        height: 1,
        thickness: 1,
      );
}

// ── Mood emoji widget (PRESERVED + enhanced) ─────────────────────────────────
class _MoodEmoji extends StatelessWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodEmoji({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width:  isSelected ? 58 : 50,
        height: isSelected ? 58 : 50,
        decoration: BoxDecoration(
          color: isSelected
              ? _brandOlive.withOpacity(0.25)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(isSelected ? 16 : 14),
          border: Border.all(
            color: isSelected
                ? _brandOlive
                : Colors.white.withOpacity(0.12),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _brandOlive.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        alignment: Alignment.center,
        child: Text(
          emoji,
          style: TextStyle(fontSize: isSelected ? 30 : 26),
        ),
      ),
    );
  }
}