import 'package:flutter/material.dart';

class HydrateActivityScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const HydrateActivityScreen({super.key, required this.item});

  @override
  State<HydrateActivityScreen> createState() => _HydrateActivityScreenState();
}

class _HydrateActivityScreenState extends State<HydrateActivityScreen> {
  bool _drank = false;
  bool _snacked = false;

  void _claim() {
    if (!_drank && !_snacked) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please drink some water or grab a snack first!")));
      return;
    }
    Navigator.pop(context, true);
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
        title: Text(widget.item['title'] ?? 'Fuel Up', style: const TextStyle(color: Color(0xFFFFFFFF))),
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
                style: const TextStyle(fontSize: 18, color: Color(0xFFAFA8BA)),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _drank = !_drank),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: _drank ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: _drank ? Colors.blue : Colors.transparent, width: 3),
                          ),
                          child: Icon(Icons.water_drop, size: 60, color: _drank ? Colors.blue : Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Text("Drank Water", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _drank ? Colors.blue : Colors.grey)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _snacked = !_snacked),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: _snacked ? Colors.orange.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(color: _snacked ? Colors.orange : Colors.transparent, width: 3),
                          ),
                          child: Icon(Icons.cookie, size: 60, color: _snacked ? Colors.orange : Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Text("Had a Snack", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _snacked ? Colors.orange : Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _claim,
                  child: const Text("I Fueled Up!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

