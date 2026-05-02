import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

// ── Brand colors ─────────────────────────────────────────────────────────────
const Color _brandOlive   = Color(0xFF6D774C);
const Color _darkBg       = Color(0xFF0F0F1A);
const double _badThreshold = 2.0;

// ── Emoji maps (index 0‥4) ────────────────────────────────────────────────────
const List<String> _moodEmojis  = ['😢', '😔', '😐', '🙂', '😄'];
const List<String> _sleepEmojis = ['😫', '🥱', '😑', '😌', '😴'];

String _emojiForIndex(double index, List<String> map) =>
    map[index.round().clamp(0, map.length - 1)];

// ═════════════════════════════════════════════════════════════════════════════

class MoodGraphScreen extends StatefulWidget {
  const MoodGraphScreen({super.key});

  @override
  State<MoodGraphScreen> createState() => _MoodGraphScreenState();
}

class _MoodGraphScreenState extends State<MoodGraphScreen>
    with TickerProviderStateMixin {

  late AnimationController _pulseCtrl;
  late Animation<double>   _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Data ────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return _mockData();
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .orderBy('moodSavedAt', descending: true)
          .limit(7)
          .get();
      if (snap.docs.isEmpty) return _mockData();
      return snap.docs.reversed.map((d) {
        final raw = d.data();
        return {
          "mood":  _parseNum(raw['moodIndex']),
          "sleep": _parseNum(raw['sleepIndex']),
          "date":  raw['date'] ?? d.id,
        };
      }).toList();
    } catch (_) {
      return _mockData();
    }
  }

  double _parseNum(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v?.toString() ?? '0') ?? 0.0;
  }

  List<Map<String, dynamic>> _mockData() => [
    {"mood": 3.0, "sleep": 3.0, "date": "2025-07-14"},
    {"mood": 2.0, "sleep": 1.0, "date": "2025-07-15"},
    {"mood": 1.0, "sleep": 0.5, "date": "2025-07-16"},
    {"mood": 2.0, "sleep": 2.0, "date": "2025-07-17"},
    {"mood": 0.5, "sleep": 1.0, "date": "2025-07-18"},
    {"mood": 3.0, "sleep": 3.5, "date": "2025-07-19"},
    {"mood": 4.0, "sleep": 4.0, "date": "2025-07-20"},
  ];

  double _avg(List<Map<String, dynamic>> data, String key) {
    if (data.isEmpty) return 0;
    return data.map((e) => (e[key] as double)).reduce((a, b) => a + b) /
        data.length;
  }

  // ── Build ───────────────────────────────────────────────────────────────────
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
          'Weekly Insights',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
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
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: getData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: _brandOlive, strokeWidth: 2.5),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}',
                    style: const TextStyle(color: Colors.redAccent)),
              );
            }

            final data      = snapshot.data ?? [];
            if (data.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.bar_chart_rounded,
                      size: 56, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No mood data yet!',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.6))),
                  const SizedBox(height: 6),
                  Text('Set your mood on the home screen.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.35))),
                ]),
              );
            }

            final avgMood  = _avg(data, 'mood');
            final avgSleep = _avg(data, 'sleep');
            final moodBad  = avgMood  < _badThreshold;
            final sleepBad = avgSleep < _badThreshold;

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Summary chips ──────────────────────────────────
                    Row(children: [
                      _SummaryChip(
                        label: 'Avg Mood',
                        value: avgMood.toStringAsFixed(1),
                        icon:  _emojiForIndex(avgMood, _moodEmojis),
                        isBad: moodBad,
                        accentGood: const Color(0xFF6FCF97),
                        accentBad:  const Color(0xFFEB5757),
                      ),
                      const SizedBox(width: 12),
                      _SummaryChip(
                        label: 'Avg Sleep',
                        value: avgSleep.toStringAsFixed(1),
                        icon:  _emojiForIndex(avgSleep, _sleepEmojis),
                        isBad: sleepBad,
                        accentGood: const Color(0xFF9B8DFF),
                        accentBad:  const Color(0xFFEB5757),
                      ),
                    ]),

                    const SizedBox(height: 24),

                    // ── Mood section ───────────────────────────────────
                    if (moodBad) ...[
                      _AlertBanner(
                        pulseAnim: _pulseAnim,
                        message:
                            'Your mood has been low this week. Consider taking a break or talking to someone you trust. 💙',
                        color: const Color(0xFFEB5757),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _SectionLabel(
                        emoji: _emojiForIndex(avgMood, _moodEmojis),
                        title: 'Mood This Week',
                        isBad: moodBad),
                    const SizedBox(height: 10),
                    _EmojiGraphCard(
                      data: data,
                      dataKey: 'mood',
                      emojiMap: _moodEmojis,
                      isBad: moodBad,
                      accentGood: const Color(0xFF6FCF97),
                      accentBad:  const Color(0xFFEB5757),
                      yLabels: const ['VLow', 'Low', 'Okay', 'Good', 'Great'],
                      pulseAnim: _pulseAnim,
                    ),

                    const SizedBox(height: 28),

                    // ── Sleep section ──────────────────────────────────
                    if (sleepBad) ...[
                      _AlertBanner(
                        pulseAnim: _pulseAnim,
                        message:
                            'Your sleep quality has been poor. Try a consistent bedtime routine and limit screen time. 🌙',
                        color: const Color(0xFFEB5757),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _SectionLabel(
                        emoji: _emojiForIndex(avgSleep, _sleepEmojis),
                        title: 'Sleep This Week',
                        isBad: sleepBad),
                    const SizedBox(height: 10),
                    _EmojiGraphCard(
                      data: data,
                      dataKey: 'sleep',
                      emojiMap: _sleepEmojis,
                      isBad: sleepBad,
                      accentGood: const Color(0xFF9B8DFF),
                      accentBad:  const Color(0xFFEB5757),
                      yLabels: const [
                        'Terrible', 'Poor', 'Fair', 'Good', 'Amazing'
                      ],
                      pulseAnim: _pulseAnim,
                    ),

                    const SizedBox(height: 28),
                    _AnalysisCard(avgMood: avgMood, avgSleep: avgSleep),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ★  EMOJI GRAPH CARD
//
// Strategy: fl_chart dots are hidden. We overlay Flutter Text emoji widgets
// in a Stack, positioned using the same coordinate math fl_chart uses
// internally (minY=0, maxY=4, leftReserved, bottomReserved).
// ═══════════════════════════════════════════════════════════════════════════════
class _EmojiGraphCard extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String dataKey;
  final List<String> emojiMap;
  final bool isBad;
  final Color accentGood;
  final Color accentBad;
  final List<String> yLabels;
  final Animation<double> pulseAnim;

  // These must mirror the reserved sizes passed to fl_chart titles
  static const double _leftReserved   = 54.0;
  static const double _bottomReserved = 22.0;
  static const double _topPad         = 20.0;  // fl_chart internal top margin
  static const double _rightPad       = 16.0;
  static const double _cardH          = 270.0; // taller so emojis above dots fit

  const _EmojiGraphCard({
    required this.data,
    required this.dataKey,
    required this.emojiMap,
    required this.isBad,
    required this.accentGood,
    required this.accentBad,
    required this.yLabels,
    required this.pulseAnim,
  });

  Color get _lineColor => isBad ? accentBad : accentGood;

  /// Convert chart data coordinates → pixel offset within the card widget.
  Offset _dataToPixel(double xIndex, double yValue, double cardW) {
    final plotW = cardW - _leftReserved - _rightPad;
    final plotH = _cardH - _topPad - _bottomReserved;
    final n     = data.length;
    final px    = _leftReserved + (n <= 1 ? plotW / 2 : xIndex / (n - 1) * plotW);
    final py    = _topPad + (1.0 - yValue / 4.0) * plotH;
    return Offset(px, py);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final cardW = constraints.maxWidth;

      return AnimatedBuilder(
        animation: pulseAnim,
        builder: (_, child) => ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: _cardH,
              decoration: BoxDecoration(
                color: Color(0xFF1A1333).withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isBad
                      ? accentBad.withOpacity(0.3 + 0.2 * pulseAnim.value)
                      : Color(0xFF1A1333).withOpacity(0.10),
                  width: isBad ? 1.5 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _lineColor.withOpacity(0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: child,
            ),
          ),
        ),
        child: Stack(
          children: [

            // ── fl_chart (dots hidden) ─────────────────────────────────
            Positioned.fill(
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 4,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) => FlLine(
                      color: _lineColor.withOpacity(0.10),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _leftReserved,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i >= 0 && i < yLabels.length) {
                            return Text(yLabels[i],
                                style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white.withOpacity(0.4),
                                ));
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: _bottomReserved,
                        getTitlesWidget: (value, _) {
                          final i = value.toInt();
                          if (i >= 0 && i < data.length) {
                            final raw   = data[i]['date']?.toString() ?? '';
                            final parts = raw.split('-');
                            final label = parts.length >= 3
                                ? '${parts[2]}/${parts[1]}'
                                : 'D${i + 1}';
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(label,
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: Colors.white.withOpacity(0.4),
                                  )),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  extraLinesData: isBad
                      ? ExtraLinesData(horizontalLines: [
                          HorizontalLine(
                            y: _badThreshold,
                            color: accentBad.withOpacity(0.55),
                            strokeWidth: 1.5,
                            dashArray: [6, 4],
                            label: HorizontalLineLabel(
                              show: true,
                              alignment: Alignment.topRight,
                              padding:
                                  const EdgeInsets.only(right: 6, bottom: 2),
                              style: TextStyle(
                                  color: accentBad,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600),
                              labelResolver: (_) => '⚠ Low threshold',
                            ),
                          ),
                        ])
                      : null,
                  // ── Touch tooltip shows emoji ──────────────────────
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Color(0xFFFFFFFF).withOpacity(0.75),
                      tooltipRoundedRadius: 10,
                      getTooltipItems: (spots) => spots.map((s) {
                        final e = _emojiForIndex(s.y, emojiMap);
                        return LineTooltipItem(
                          '$e  ${s.y.toStringAsFixed(1)}',
                          const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        data.length,
                        (i) => FlSpot(
                          i.toDouble(),
                          (data[i][dataKey] as double).clamp(0.0, 4.0),
                        ),
                      ),
                      isCurved: true,
                      barWidth: 3,
                      color: _lineColor,
                      // Native dots OFF — emoji widgets replace them
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _lineColor.withOpacity(isBad ? 0.18 : 0.12),
                            _lineColor.withOpacity(0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Emoji overlay ─────────────────────────────────────────
            // Each emoji bubble is centred on the chart data point.
            // We position the bubble ABOVE the line (top: dot.dy - 32)
            // so it doesn't obscure the curve itself.
            ...List.generate(data.length, (i) {
              final yVal  = (data[i][dataKey] as double).clamp(0.0, 4.0);
              final emoji = _emojiForIndex(yVal, emojiMap);
              final isLow = yVal < _badThreshold;
              final pos   = _dataToPixel(i.toDouble(), yVal, cardW);
              const bubbleSize = 30.0;

              return Positioned(
                left: pos.dx - bubbleSize / 2,
                top:  pos.dy - bubbleSize - 4, // float above the line
                child: _EmojiBubble(
                  emoji: emoji,
                  isLow: isLow,
                  accentBad:  accentBad,
                  accentGood: accentGood,
                  size: bubbleSize,
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

// ── Emoji bubble widget ───────────────────────────────────────────────────────
class _EmojiBubble extends StatelessWidget {
  final String emoji;
  final bool   isLow;
  final Color  accentBad;
  final Color  accentGood;
  final double size;

  const _EmojiBubble({
    required this.emoji,
    required this.isLow,
    required this.accentBad,
    required this.accentGood,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLow ? accentBad : accentGood;
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        color:  color.withOpacity(0.20),
        shape:  BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.60), width: 1.5),
        boxShadow: [
          BoxShadow(
            color:      color.withOpacity(0.35),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(emoji,
          style: TextStyle(fontSize: size * 0.50, height: 1)),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String emoji;
  final String title;
  final bool   isBad;

  const _SectionLabel(
      {required this.emoji, required this.title, required this.isBad});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 4, height: 20,
        decoration: BoxDecoration(
          color: isBad ? const Color(0xFFEB5757) : _brandOlive,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 8),
      Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      if (isBad) ...[
        const SizedBox(width: 8),
        const Icon(Icons.warning_amber_rounded,
            color: Color(0xFFEB5757), size: 18),
      ],
    ]);
  }
}

// ── Alert banner ──────────────────────────────────────────────────────────────
class _AlertBanner extends StatelessWidget {
  final Animation<double> pulseAnim;
  final String message;
  final Color  color;

  const _AlertBanner(
      {required this.pulseAnim,
      required this.message,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (_, __) => Opacity(
        opacity: pulseAnim.value,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: color.withOpacity(0.5), width: 1.2),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: color, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(message,
                        style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.45)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Summary chip ──────────────────────────────────────────────────────────────
class _SummaryChip extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final bool   isBad;
  final Color  accentGood;
  final Color  accentBad;

  const _SummaryChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.isBad,
    required this.accentGood,
    required this.accentBad,
  });

  Color get _accent => isBad ? accentBad : accentGood;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.10),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: _accent.withOpacity(0.3), width: 1.2),
            ),
            child: Row(children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 11,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Text(value,
                        style: TextStyle(
                            color: _accent,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(width: 4),
                    Icon(
                      isBad
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: _accent,
                      size: 14,
                    ),
                  ]),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Analysis card ─────────────────────────────────────────────────────────────
class _AnalysisCard extends StatelessWidget {
  final double avgMood;
  final double avgSleep;

  const _AnalysisCard({required this.avgMood, required this.avgSleep});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _card(_info(avgMood,  isMood: true)),
      const SizedBox(height: 12),
      _card(_info(avgSleep, isMood: false)),
    ]);
  }

  ({String text, Color color, IconData icon}) _info(
      double avg, {required bool isMood}) {
    if (avg >= 3) {
      return (
        text:  isMood ? '🔥 Great Mood Week!' : '😴 Great Sleep Week!',
        color: isMood
            ? const Color(0xFF6FCF97)
            : const Color(0xFF9B8DFF),
        icon: Icons.sentiment_very_satisfied_rounded,
      );
    } else if (avg >= 2) {
      return (
        text:  isMood ? '🙂 Stable Mood Week' : '😐 Average Sleep Week',
        color: const Color(0xFFF2994A),
        icon: Icons.sentiment_neutral_rounded,
      );
    } else {
      return (
        text: isMood
            ? '⚠️ Low Mood Week — take care of yourself'
            : '⚠️ Poor Sleep Week — rest is critical',
        color: const Color(0xFFEB5757),
        icon: Icons.warning_amber_rounded,
      );
    }
  }

  Widget _card(({String text, Color color, IconData icon}) info) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: info.color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: info.color.withOpacity(0.35), width: 1.2),
          ),
          child: Row(children: [
            Icon(info.icon, color: info.color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(info.text,
                  style: TextStyle(
                      color: info.color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ]),
        ),
      ),
    );
  }
}
