import 'package:flutter/material.dart';


class TimeTable extends StatefulWidget {
  const TimeTable({super.key});

  @override
  State<TimeTable> createState() => _TimeTableState();
}

class _TimeTableState extends State<TimeTable> {
  final DateTime today = DateTime.now();
  late int selectedMonth;
  late int selectedDay;

  // Controllers to handle auto-scrolling
  final ScrollController _dateScrollController = ScrollController();
  final Color brandColor = const Color(0xFF6D774C); // Your requested color

  @override
  void initState() {
    super.initState();
    selectedMonth = today.month;
    selectedDay = today.day;

    // Scroll to the current date after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentDay());
  }

  void _scrollToCurrentDay() {
    // Card width (70) + Margin (12) = 82
    const double itemWidth = 82.0;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Calculate offset to bring selected index to center
    double offset = (selectedDay - 1) * itemWidth - (screenWidth / 2) + (itemWidth / 2);

    if (_dateScrollController.hasClients) {
      _dateScrollController.animateTo(
        offset.clamp(0, _dateScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutBack,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = _getDaysInMonth(selectedMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🌙 MONTHS (Glassmorphic Strip)
        SizedBox(
          height: 45,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 12,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, index) {
              final month = index + 1;
              bool isSelected = month == selectedMonth;
              return GestureDetector(
                onTap: () {
                  setState(() => selectedMonth = month);
                },
                child: _monthChip(_monthName(month), isSelected),
              );
            },
          ),
        ),

        const SizedBox(height: 20),

        /// 📆 DATES (Centered Auto-Scroll)
        SizedBox(
          height: 100,
          child: ListView.builder(
            controller: _dateScrollController,
            scrollDirection: Axis.horizontal,
            itemCount: daysInMonth,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (_, index) {
              final day = index + 1;
              final date = DateTime(today.year, selectedMonth, day);
              final isSelected = day == selectedDay && selectedMonth == today.month;

              return GestureDetector(
                onTap: () => setState(() => selectedDay = day),
                child: _dateCard(date, isSelected),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _monthChip(String month, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? brandColor : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: selected ? brandColor : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Center(
        child: Text(
          month,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _dateCard(DateTime date, bool selected) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 70,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: selected ? brandColor : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? Colors.white.withOpacity(0.5) : Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: selected ? [
          BoxShadow(
            color: brandColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            _weekdayName(date.weekday).toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date.day.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MoodDot(color: Colors.blue.shade300),
              const SizedBox(width: 2),
              MoodDot(color: Colors.orange.shade300),
              const SizedBox(width: 2),
              MoodDot(color: Colors.purple.shade300),
            ],
          )
        ],
      ),
    );
  }

  // Helper methods... (kept from original for logic)
  int _getDaysInMonth(int month) {
    if ([1, 3, 5, 7, 8, 10, 12].contains(month)) return 31;
    if ([4, 6, 9, 11].contains(month)) return 30;
    return (DateTime.now().year % 4 == 0) ? 29 : 28;
  }

  String _monthName(int month) {
    return ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][month - 1];
  }

  String _weekdayName(int weekday) {
    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];
  }
}
class MoodDot extends StatelessWidget {
  final Color color;

  const MoodDot({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}