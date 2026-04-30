import 'package:flutter/material.dart';

import 'add_task_screen.dart';
import 'today_tasks_screen.dart';
import 'daily_view_screen.dart';
import 'weekly_view_screen.dart';
import 'monthly_mood_screen.dart';
import '../../widgets/navigation.dart';
import '../../widgets/animated_background.dart';

const Color _primaryColor = Color(0xFF8C52FF);
const Color _brandOlive   = Color(0xFF6D774C);

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {

  late int _stripMonth;
  late int _stripDay;
  final ScrollController _dateScrollCtrl  = ScrollController();
  final ScrollController _monthScrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _stripMonth = DateTime.now().month;
    _stripDay   = DateTime.now().day;
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
        (_stripDay - 1) * itemW - (screenW / 2) + (itemW / 2);
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

  int _daysInMonth(int m) {
    if ([1, 3, 5, 7, 8, 10, 12].contains(m)) return 31;
    if ([4, 6, 9, 11].contains(m)) return 30;
    return (DateTime.now().year % 4 == 0) ? 29 : 28;
  }

  String _monthName(int m) => [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ][m - 1];

  String _weekdayShort(int wd) =>
      ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'][wd - 1];

  @override
  Widget build(BuildContext context) {
    // ── Capture the navigator context HERE, at the Scaffold level ─────────
    // This ensures CustomBottomNav always gets a context that has
    // the named routes registered in main.dart.
    final navigatorContext = context;

    return AnimatedBackground(
      isLightMode: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,

        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
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

        // ── Pass the outer context explicitly so routes resolve correctly ──
        bottomNavigationBar: Builder(
          builder: (ctx) => CustomBottomNav(currentIndex: 3),
        ),

        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Month chips ──────────────────────────────────────────────
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
                      onTap: () => setState(() {
                        _stripMonth = m;
                        _stripDay   = 1;
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

              // ── Date cards ───────────────────────────────────────────────
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
                    final date =
                        DateTime(DateTime.now().year, _stripMonth, day);
                    final isSelected = day == _stripDay;
                    final isToday    = day == DateTime.now().day &&
                        _stripMonth == DateTime.now().month;

                    return GestureDetector(
                      onTap: () => setState(() => _stripDay = day),
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

              const SizedBox(height: 20),

              // ── Heading ──────────────────────────────────────────────────
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Plan Your Day',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(left: 20, top: 4),
                child: Text(
                  'Stay focused, stay organized',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ),

              const SizedBox(height: 22),

              // ── Grid ─────────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _PlannerCard(
                        icon: Icons.today,
                        label: "Today's Tasks",
                        subtitle: 'View & manage today',
                        color: const Color(0xFF976565),
                        onTap: () => Navigator.push(
                          navigatorContext,
                          MaterialPageRoute(
                              builder: (_) => const TodayTasksScreen()),
                        ),
                      ),
                      _PlannerCard(
                        icon: Icons.calendar_view_day,
                        label: 'Daily View',
                        subtitle: 'Browse by date',
                        color: const Color(0xFF7D509F),
                        onTap: () => Navigator.push(
                          navigatorContext,
                          MaterialPageRoute(
                              builder: (_) => const DailyViewScreen()),
                        ),
                      ),
                      _PlannerCard(
                        icon: Icons.view_week,
                        label: 'Weekly View',
                        subtitle: 'This week at a glance',
                        color: const Color(0xFF957C2E),
                        onTap: () => Navigator.push(
                          navigatorContext,
                          MaterialPageRoute(
                              builder: (_) => const WeeklyViewScreen()),
                        ),
                      ),
                      _PlannerCard(
                        icon: Icons.mood,
                        label: 'Monthly Mood',
                        subtitle: 'Mood calendar',
                        color: const Color(0xFF4A7C8E),
                        onTap: () => Navigator.push(
                          navigatorContext,
                          MaterialPageRoute(
                              builder: (_) => const MonthlyMoodScreen()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Add Task button ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      navigatorContext,
                      MaterialPageRoute(
                          builder: (_) => const AddTaskScreen()),
                    ),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Add New Task',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(color: c, shape: BoxShape.circle),
      );
}

// ── Planner card ──────────────────────────────────────────────────────────────
class _PlannerCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _PlannerCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: Colors.white.withOpacity(0.12), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.18),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: Colors.white38, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}