import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../widgets/animated_background.dart';

class MonthlyMoodScreen extends StatefulWidget {
  const MonthlyMoodScreen({super.key});

  @override
  State<MonthlyMoodScreen> createState() => _MonthlyMoodScreenState();
}

class _MonthlyMoodScreenState extends State<MonthlyMoodScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _selectedDateKey = DateFormat('yyyy-MM-dd').format(DateTime.now());

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  // Mood → color mapping
  Color _moodColor(String? mood) {
    switch (mood) {
      case 'Great': return Colors.green;
      case 'Good': return Colors.lightGreen;
      case 'Okay': return Colors.amber;
      case 'Low': return Colors.orange;
      case 'Very Low': return Colors.red;
      default: return Color(0xFFFFFFFF).withValues(alpha: 0.05);
    }
  }

  String _moodEmoji(String? mood) {
    switch (mood) {
      case 'Great': return '😄';
      case 'Good': return '🙂';
      case 'Okay': return '😐';
      case 'Low': return '😕';
      case 'Very Low': return '😞';
      default: return '';
    }
  }

  int get _daysInMonth =>
      DateTime(_month.year, _month.month + 1, 0).day;

  void _prevMonth() => setState(() =>
  _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() {
    final next = DateTime(_month.year, _month.month + 1);
    if (!next.isAfter(DateTime.now())) {
      setState(() => _month = next);
    }
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
          title: const Text(
            'Monthly Mood',
            style: TextStyle(
                color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
            child: FutureBuilder<QuerySnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_userId)
                  .collection('daily_logs')
                  .get(),
              builder: (context, snapshot) {
                // Build mood map: "yyyy-MM-dd" → mood string
                final Map<String, Map<String, dynamic>> logMap = {};
                final Map<String, String> moodMap = {};
                if (snapshot.hasData) {
                  for (final doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    logMap[doc.id] = data;
                    moodMap[doc.id] = data['mood'] ?? '';
                  }
                }

                return Column(
                  children: [
                    // Month navigation
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(
                                Icons.chevron_left,
                                color: Color(0xFFFFFFFF)),
                            onPressed: _prevMonth,
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(_month),
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                                Icons.chevron_right,
                                color: Color(0xFFFFFFFF)),
                            onPressed: _nextMonth,
                          ),
                        ],
                      ),
                    ),

                    // Day-of-week headers
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12),
                      child: Row(
                        children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                            .map(
                              (d) => Expanded(
                            child: Center(
                              child: Text(
                                d,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
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

                    // Calendar grid
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12),
                        child: GridView.builder(
                          gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          itemCount: _daysInMonth +
                              (DateTime(_month.year, _month.month, 1)
                                  .weekday -
                                  1),
                          itemBuilder: (_, i) {
                            // Empty cells for offset
                            final offset =
                                DateTime(_month.year, _month.month, 1)
                                    .weekday -
                                    1;
                            if (i < offset) {
                              return const SizedBox.shrink();
                            }

                            final day = i - offset + 1;
                            final dateKey = DateFormat('yyyy-MM-dd')
                                .format(DateTime(
                                _month.year, _month.month, day));
                            final mood = moodMap[dateKey];
                            final isToday = dateKey ==
                                DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now());

                            final isSelected = dateKey == _selectedDateKey;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedDateKey = dateKey),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _moodColor(mood),
                                  borderRadius:
                                  BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF8C52FF)
                                        : isToday
                                            ? const Color(0xFFFFFFFF)
                                            : Colors.transparent,
                                    width: isSelected ? 3 : 2,
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
                                            ? Color(0xFF1A1333)
                                            : const Color(0xFF9CA3AF),
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (mood != null && mood.isNotEmpty)
                                      Text(
                                        _moodEmoji(mood),
                                        style: const TextStyle(
                                            fontSize: 10),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    _selectedDayRecord(logMap[_selectedDateKey]),

                    // Legend
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          'Very Low', 'Low', 'Okay', 'Good', 'Great'
                        ].map((m) => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: _moodColor(m),
                                borderRadius:
                                BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              m,
                              style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12),
                            ),
                          ],
                        )).toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
    );
  }

  Widget _selectedDayRecord(Map<String, dynamic>? data) {
    final mood = data?['mood']?.toString();
    final sleep = data?['sleep']?.toString();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFF1A1333).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEE, dd MMM yyyy').format(DateTime.parse(_selectedDateKey)),
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (data == null)
            const Text('No mood record for this day.',
                style: TextStyle(color: Color(0xFF6B7280)))
          else ...[
            Text('Mood: ${mood?.isNotEmpty == true ? mood : 'Not set'}',
                style: const TextStyle(color: Color(0xFF374151))),
            Text('Sleep: ${sleep?.isNotEmpty == true ? sleep : 'Not set'}',
                style: const TextStyle(color: Color(0xFF374151))),
          ],
        ],
      ),
    );
  }
}

