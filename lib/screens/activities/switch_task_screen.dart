import 'package:flutter/material.dart';

class SwitchTaskScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const SwitchTaskScreen({super.key, required this.item});

  @override
  State<SwitchTaskScreen> createState() => _SwitchTaskScreenState();
}

class _SwitchTaskScreenState extends State<SwitchTaskScreen> {
  final TextEditingController _oldTaskController = TextEditingController();
  final TextEditingController _newTaskController = TextEditingController();
  bool _switched = false;

  void _switchTasks() {
    if (_oldTaskController.text.isEmpty || _newTaskController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter both tasks.")));
      return;
    }
    setState(() {
      _switched = true;
    });
    // Wait a moment for the animation then pop
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.pop(context, true);
    });
  }

  @override
  void dispose() {
    _oldTaskController.dispose();
    _newTaskController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.item['colorHex'] ?? 0xFF9a882a);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        title: Text(widget.item['title'] ?? 'Switch Task', style: const TextStyle(color: Color(0xFFFFFFFF))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: _switched
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.swap_calls, size: 100, color: color),
                      const SizedBox(height: 20),
                      const Text("Momentum Switched!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF))),
                      const SizedBox(height: 10),
                      Text("Now focusing on:\n${_newTaskController.text}", textAlign: TextAlign.center, style: TextStyle(fontSize: 18, color: color)),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item['desc'] ?? '',
                      style: const TextStyle(fontSize: 16, color: Color(0xFFAFA8BA)),
                    ),
                    const SizedBox(height: 40),
                    const Text("What task are you leaving?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _oldTaskController,
                      decoration: InputDecoration(hintText: "e.g. Checking emails", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 30),
                    Center(child: Icon(Icons.arrow_downward, size: 40, color: color.withOpacity(0.5))),
                    const SizedBox(height: 30),
                    const Text("What is your new focus?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newTaskController,
                      decoration: InputDecoration(hintText: "e.g. Writing report", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                        onPressed: _switchTasks,
                        child: const Text("Switch Momentum", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1333))),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

