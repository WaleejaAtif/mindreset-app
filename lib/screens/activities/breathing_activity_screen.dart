import 'package:flutter/material.dart';

class BreathingActivityScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const BreathingActivityScreen({super.key, required this.item});

  @override
  State<BreathingActivityScreen> createState() => _BreathingActivityScreenState();
}

class _BreathingActivityScreenState extends State<BreathingActivityScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  String _instruction = "Breathe In";

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..addStatusListener((status) async {
        if (status == AnimationStatus.completed) {
          setState(() => _instruction = "Hold");
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() => _instruction = "Breathe Out");
            _controller.reverse();
          }
        } else if (status == AnimationStatus.dismissed) {
          setState(() => _instruction = "Hold");
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) {
            setState(() => _instruction = "Breathe In");
            _controller.forward();
          }
        }
      });

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Start cycle
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.item['colorHex'] ?? 0xFFb3957c);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        title: Text(widget.item['title'] ?? 'Breathe', style: const TextStyle(color: Color(0xFFFFFFFF))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Text(
                widget.item['desc'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFFAFA8BA)),
              ),
            ),
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 250 * _scaleAnimation.value + 50,
                          height: 250 * _scaleAnimation.value + 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.2),
                          ),
                        ),
                        Container(
                          width: 220 * _scaleAnimation.value + 30,
                          height: 220 * _scaleAnimation.value + 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color.withOpacity(0.4),
                          ),
                        ),
                        Container(
                          width: 200 * _scaleAnimation.value,
                          height: 200 * _scaleAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                          ),
                        ),
                        Text(
                          _instruction,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text("Finish Session", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

