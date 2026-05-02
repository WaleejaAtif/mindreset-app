import 'package:flutter/material.dart';

class SingleTaskScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const SingleTaskScreen({super.key, required this.item});

  @override
  State<SingleTaskScreen> createState() => _SingleTaskScreenState();
}

class _SingleTaskScreenState extends State<SingleTaskScreen> {
  final TextEditingController _controller = TextEditingController();
  String? _activeTask;

  void _addTask() {
    if (_controller.text.trim().isEmpty) return;
    if (_activeTask != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Finish your current task first! No multitasking allowed.", style: TextStyle(color: Color(0xFF1A1333))), backgroundColor: Colors.redAccent),
      );
      return;
    }
    setState(() {
      _activeTask = _controller.text.trim();
      _controller.clear();
    });
  }

  void _completeTask() {
    // Return true to award points since they successfully focused on one thing.
    Navigator.pop(context, true); 
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
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        title: Text(widget.item['title'] ?? 'One Thing', style: const TextStyle(color: Color(0xFFFFFFFF))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item['desc'] ?? 'Focus on one task only.',
                style: const TextStyle(fontSize: 16, color: Color(0xFFAFA8BA)),
              ),
              const SizedBox(height: 30),
              if (_activeTask == null) ...[
                const Text("What is the ONE thing you need to do right now?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(color: Color(0xFF1A1333), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Color(0xFFFFFFFF).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Enter your single task...",
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      suffixIcon: IconButton(icon: Icon(Icons.arrow_forward, color: color), onPressed: _addTask),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
              ] else ...[
                const Text("Your Current Focus:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]),
                  child: Column(
                    children: [
                      Text(_activeTask!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A1333))),
                      const SizedBox(height: 30),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A1333), foregroundColor: color, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        onPressed: _completeTask,
                        icon: const Icon(Icons.check_circle),
                        label: const Text("I Finished It!"),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Center(
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No multitasking! Either finish it or cancel the session.")));
                    },
                    child: const Text("I want to do something else", style: TextStyle(color: Colors.grey)),
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}

