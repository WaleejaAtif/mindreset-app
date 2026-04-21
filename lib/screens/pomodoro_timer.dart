import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

class PomodoroTimerScreen extends StatefulWidget {
  const PomodoroTimerScreen({super.key});

  @override
  State<PomodoroTimerScreen> createState() => _PomodoroTimerScreenState();
}

class _PomodoroTimerScreenState extends State<PomodoroTimerScreen> {
  // Theme Color from reference image
  static const Color _primaryColor = Color(0xFF755F84);
  static const Color _backgroundColor = Color(0xFFF9F8FD);

  // Timer Durations in seconds
  static const int _pomodoroSeconds = 25 * 60;
  static const int _shortBreakSeconds = 10 * 60;
  static const int _longBreakSeconds = 30 * 60;

  int _currentMaxSeconds = _pomodoroSeconds;
  int _seconds = _pomodoroSeconds;
  Timer? _timer;
  bool _isRunning = false;
  String _activeTab = 'Pomodoro';

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_seconds > 0) {
          setState(() => _seconds--);
        } else {
          timer.cancel();
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
    });
  }

  void _setTimerMode(String mode, int duration) {
    _timer?.cancel();
    setState(() {
      _activeTab = mode;
      _currentMaxSeconds = duration;
      _seconds = duration;
      _isRunning = false;
    });
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pomodoro Timer',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
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
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
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
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w500),
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
                _buildCircleActionBtn(Icons.stop, () {}),
              ],
            ),
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