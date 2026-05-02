import 'dart:async';
import 'package:flutter/material.dart';

class TimerActivityScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final int durationMinutes;
  final List<String>? suggestions;

  const TimerActivityScreen({
    super.key,
    required this.item,
    required this.durationMinutes,
    this.suggestions,
  });

  @override
  State<TimerActivityScreen> createState() => _TimerActivityScreenState();
}

class _TimerActivityScreenState extends State<TimerActivityScreen> {
  late int _remainingSeconds;
  Timer? _timer;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.durationMinutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            _timer?.cancel();
            _isRunning = false;
            _onComplete();
          }
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  void _onComplete() {
    // Show a small success dialog if it finishes naturally
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Great Job!"),
        content: const Text("You've completed this session."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context, true); // Return true to award points
            },
            child: const Text("Claim Points"),
          ),
        ],
      ),
    );
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.item['colorHex'] ?? 0xFF6f7f61);
    final totalSeconds = widget.durationMinutes * 60;
    final progress = 1 - (_remainingSeconds / totalSeconds);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        title: Text(widget.item['title'] ?? 'Timer', style: const TextStyle(color: Color(0xFFFFFFFF))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.item['desc'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFFAFA8BA)),
              ),
              if (widget.suggestions != null && widget.suggestions!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Tips for this session:", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      const SizedBox(height: 8),
                      ...widget.suggestions!.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.check_circle_outline, size: 16, color: color),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s, style: const TextStyle(fontSize: 14, color: Color(0xFFFFFFFF)))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    height: 280,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 12,
                      backgroundColor: color.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                  Text(
                    _formattedTime,
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w300,
                      color: Color(0xFFFFFFFF),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton.large(
                    heroTag: 'play_pause',
                    backgroundColor: color,
                    onPressed: _toggleTimer,
                    child: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Color(0xFF1A1333), size: 36),
                  ),
                ],
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Finish early
                  Navigator.pop(context, true);
                },
                child: const Text("Finish Early", style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

