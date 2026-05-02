import 'package:flutter/material.dart';

class HabitStackingScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const HabitStackingScreen({super.key, required this.item});

  @override
  State<HabitStackingScreen> createState() => _HabitStackingScreenState();
}

class _HabitStackingScreenState extends State<HabitStackingScreen> {
  final TextEditingController _existingHabitController = TextEditingController();
  final TextEditingController _newHabitController = TextEditingController();

  void _submit() {
    if (_existingHabitController.text.isEmpty || _newHabitController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill out both fields.")));
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  void dispose() {
    _existingHabitController.dispose();
    _newHabitController.dispose();
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
        title: Text(widget.item['title'] ?? 'Habit Stacking', style: const TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item['desc'] ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("After I...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _existingHabitController,
                      decoration: const InputDecoration(hintText: "e.g. Brush my teeth", border: UnderlineInputBorder()),
                    ),
                    const SizedBox(height: 30),
                    const Text("I will...", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newHabitController,
                      decoration: const InputDecoration(hintText: "e.g. Do 5 pushups", border: UnderlineInputBorder()),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _submit,
                  child: const Text("Lock in my Stack!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
