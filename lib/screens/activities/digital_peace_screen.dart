import 'dart:async';
import 'package:flutter/material.dart';

class DigitalPeaceScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const DigitalPeaceScreen({super.key, required this.item});

  @override
  State<DigitalPeaceScreen> createState() => _DigitalPeaceScreenState();
}

class _DigitalPeaceScreenState extends State<DigitalPeaceScreen> {
  bool _inZenMode = false;
  int _seconds = 0;
  Timer? _timer;

  void _startZenMode() {
    setState(() {
      _inZenMode = true;
      _seconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _endZenMode() {
    _timer?.cancel();
    Navigator.pop(context, true); // Complete and award points
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    int minutes = _seconds ~/ 60;
    int remainingSeconds = _seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_inZenMode) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.do_not_disturb_on, color: Colors.white24, size: 100),
              const SizedBox(height: 30),
              Text(
                _formattedTime,
                style: const TextStyle(fontSize: 64, fontWeight: FontWeight.w200, color: Colors.white, fontFeatures: [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: 20),
              const Text("Zen Mode Active.\nFocus on your task.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 18)),
              const SizedBox(height: 60),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                onPressed: _endZenMode,
                child: const Text("End Zen Mode"),
              )
            ],
          ),
        ),
      );
    }

    final color = Color(widget.item['colorHex'] ?? 0xFF6f7f61);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(widget.item['title'] ?? 'Digital Peace', style: const TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.phonelink_erase, size: 80, color: color),
              ),
              const SizedBox(height: 40),
              const Text(
                "Step 1: Mute Your Phone",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              const Text(
                "Please manually flip your phone's physical mute switch or turn on Do Not Disturb.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _startZenMode,
                  child: const Text("Enter Zen Mode", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
