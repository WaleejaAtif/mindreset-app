import 'package:flutter/material.dart';
import 'dart:math';

class ActiveRecallScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ActiveRecallScreen({super.key, required this.item});

  @override
  State<ActiveRecallScreen> createState() => _ActiveRecallScreenState();
}

class _ActiveRecallScreenState extends State<ActiveRecallScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();
  bool _isFlipped = false;
  bool _completed = false;

  void _flip() {
    if (_questionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Enter a question to test yourself on first!")));
      return;
    }
    setState(() {
      _isFlipped = true;
    });
  }

  void _submitAnswer() {
    if (_answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Try to answer it from memory!")));
      return;
    }
    setState(() {
      _completed = true;
    });
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
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
        title: Text(widget.item['title'] ?? 'Active Recall', style: const TextStyle(color: Color(0xFFFFFFFF))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [
              Text(
                widget.item['desc'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFFAFA8BA)),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final rotate = Tween(begin: pi, end: 0.0).animate(animation);
                    return AnimatedBuilder(
                      animation: rotate,
                      child: child,
                      builder: (context, child) {
                        final isUnder = (ValueKey(_isFlipped) != child!.key);
                        var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
                        tilt *= isUnder ? -1.0 : 1.0;
                        final value = isUnder ? min(rotate.value, pi / 2) : rotate.value;
                        return Transform(
                          transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                          alignment: Alignment.center,
                          child: child,
                        );
                      },
                    );
                  },
                  child: !_isFlipped
                      ? _buildFrontCard(color)
                      : _completed
                          ? _buildSuccessCard(color)
                          : _buildBackCard(color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(Color color) {
    return Container(
      key: const ValueKey(false),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Color(0xFF1A1333), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Color(0xFFFFFFFF).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Front of Card", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          const Text("What do you want to memorize?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _questionController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Enter your question or prompt...", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: _flip,
            child: const Text("Flip Card"),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(Color color) {
    return Container(
      key: const ValueKey(true),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Back of Card", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(_questionController.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),
          const Text("Answer from memory:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _answerController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: "Type your answer...", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: _submitAnswer,
            child: const Text("Check Answer"),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessCard(Color color) {
    return Container(
      key: const ValueKey('success'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text("Great Job!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text("Active recall strengthens your memory.", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xB3FFFFFF))),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A1333), foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Claim Points"),
          ),
        ],
      ),
    );
  }
}

