import 'package:flutter/material.dart';

class PostureActivityScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const PostureActivityScreen({super.key, required this.item});

  @override
  State<PostureActivityScreen> createState() => _PostureActivityScreenState();
}

class _PostureActivityScreenState extends State<PostureActivityScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _moveAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _moveAnimation = Tween<double>(begin: -50.0, end: 50.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.item['colorHex'] ?? 0xFFc2a7c3);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(widget.item['title'] ?? 'Posture', style: const TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              child: Text(
                widget.item['desc'] ?? 'Stand up and stretch.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _moveAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _moveAnimation.value),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.accessibility_new, size: 120, color: color),
                          const SizedBox(height: 20),
                          Text(_moveAnimation.value < 0 ? "Stretch Up..." : "Relax Down...", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("I Feel Better", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
