import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/activity_service.dart';

class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> {
  // Theme Color from reference image
  static const Color _primaryColor = Color(0xFF755F84);
  static const Color _backgroundColor = Color(0xFF0F0C20);

  // Timer Durations in seconds
  static const int _pomodoroSeconds = 25 * 60;
  static const int _shortBreakSeconds = 10 * 60;
  static const int _longBreakSeconds = 30 * 60;

  int _currentMaxSeconds = _pomodoroSeconds;
  int _seconds = _pomodoroSeconds;
  Timer? _timer;
  bool _isRunning = false;
  String _activeTab = 'Pomodoro';
  DateTime? _sessionStart;

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _sessionStart ??= DateTime.now();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_seconds > 0) {
          setState(() => _seconds--);
        } else {
          timer.cancel();
          _saveSession(completed: true);
          setState(() => _isRunning = false);
        }
      });
    }
    setState(() => _isRunning = !_isRunning);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _seconds = _currentMaxSeconds;
      _isRunning = false;
      _sessionStart = null;
    });
  }

  void _setTimerMode(String mode, int duration) {
    _timer?.cancel();
    setState(() {
      _activeTab = mode;
      _currentMaxSeconds = duration;
      _seconds = duration;
      _isRunning = false;
      _sessionStart = null;
    });
  }

  Future<void> _stopAndSaveIncomplete() async {
    if (_sessionStart == null && _seconds == _currentMaxSeconds) {
      _resetTimer();
      return;
    }
    _timer?.cancel();
    await _saveSession(completed: false);
    _resetTimer();
  }

  Future<void> _saveSession({required bool completed}) async {
    final start = _sessionStart ?? DateTime.now();
    final end = DateTime.now();
    final durationMinutes =
        ((_currentMaxSeconds - _seconds) / 60).clamp(0, _currentMaxSeconds / 60).round();
    if (_userId.isEmpty) return;
    await ActivityService.logActivity(
      collection: 'pomodoro_sessions',
      data: {
        'mode': _activeTab,
        'completed': completed,
        'startTime': start.toIso8601String(),
        'endTime': end.toIso8601String(),
        'durationMinutes': durationMinutes,
      },
      dailyValues: {
        'pomodoroSessions': FieldValue.increment(1),
        if (completed) 'pomodoroCompletedToday': true,
        'lastPomodoroStatus': completed ? 'completed' : 'incomplete',
      },
      points: completed ? 10 : 2,
    );
    _sessionStart = null;
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_seconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_seconds % 60).toString().padLeft(2, '0');
    double progress = _seconds / _currentMaxSeconds;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFFFFFFFF), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pomodoro Timer',
          style: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFFFFFFF)),
            onPressed: () {},
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text('Planner/Task', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Text(
              'Prepare the brief',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
            ),
            const SizedBox(height: 30),

            // Mode Toggle Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTab('Pomodoro', _pomodoroSeconds),
                _buildTab('Short break', _shortBreakSeconds),
                _buildTab('Long break', _longBreakSeconds),
              ],
            ),

            const Spacer(),

            // Circular Timer
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CustomPaint(
                      painter: TimerPainter(
                        progress: progress,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Focus', style: TextStyle(color: Colors.grey, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        '$minutes : $seconds',
                        style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: 2),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRunning ? 'Running...' : 'Paused',
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Center(
              child: Text(
                '1 of 4 intervals',
                style: TextStyle(color: Color(0xFFAFA8BA), fontWeight: FontWeight.w500),
              ),
            ),

            const Spacer(),

            // Bottom Controls
            Row(
              children: [
                _buildCircleActionBtn(Icons.refresh, _resetTimer),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _toggleTimer,
                      child: Text(
                        _isRunning ? 'Pause' : 'Continue',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                _buildCircleActionBtn(Icons.stop, _stopAndSaveIncomplete),
              ],
            ),
            const SizedBox(height: 20),
            _buildSessionHistory(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int duration) {
    bool isActive = _activeTab == label;
    return GestureDetector(
      onTap: () => _setTimerMode(label, duration),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? _primaryColor : _primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : _primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildCircleActionBtn(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(icon, color: _primaryColor),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildSessionHistory() {
    if (_userId.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 120,
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_userId)
            .collection('pomodoro_sessions')
            .orderBy('timestamp', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('No Pomodoro records yet.',
                  style: TextStyle(color: Color(0xFFAFA8BA))),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final data = docs[index].data();
              final start =
                  DateTime.tryParse(data['startTime']?.toString() ?? '') ??
                      DateTime.now();
              final end = DateTime.tryParse(data['endTime']?.toString() ?? '') ??
                  start;
              final completed = data['completed'] == true;
              return Container(
                width: 210,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Color(0xFF1A1333),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primaryColor.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_weekday(start),
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      '${ActivityService.readableTime(start)} - ${ActivityService.readableTime(end)}',
                      style: const TextStyle(color: Color(0xFFAFA8BA)),
                    ),
                    const Spacer(),
                    Text(
                      completed ? 'Session completed' : 'Session incomplete',
                      style: TextStyle(
                        color: completed ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _weekday(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }
}

class TimerPainter extends CustomPainter {
  final double progress;
  final Color color;

  TimerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    Paint backgroundPaint = Paint()
      ..color = color.withOpacity(0.1)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    Paint progressPaint = Paint()
      ..color = color
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    Offset center = Offset(size.width / 2, size.height / 2);
    double radius = math.min(size.width / 2, size.height / 2);

    canvas.drawCircle(center, radius, backgroundPaint);

    double arcAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      arcAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(TimerPainter oldDelegate) => oldDelegate.progress != progress;
}

