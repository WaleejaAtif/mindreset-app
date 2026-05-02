import 'package:flutter/material.dart';

class GuidedActivityScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final List<String>? suggestions;

  const GuidedActivityScreen({super.key, required this.item, this.suggestions});

  @override
  Widget build(BuildContext context) {
    final color = Color(item['colorHex'] ?? 0xFF6f7f61);
    final icon = IconData(item['iconCode'] ?? Icons.star.codePoint, fontFamily: 'MaterialIcons');

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        title: const Text('Activity', style: TextStyle(color: Color(0xFFFFFFFF))),
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
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 80, color: color),
              ),
              const SizedBox(height: 40),
              Text(
                item['title'] ?? 'Strategy',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
              ),
              const SizedBox(height: 20),
              Text(
                item['desc'] ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, color: Color(0xFFAFA8BA), height: 1.5),
              ),
              if (suggestions != null && suggestions!.isNotEmpty) ...[
                const SizedBox(height: 30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Try these tips:", style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                      const SizedBox(height: 12),
                      ...suggestions!.map((s) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.lightbulb_outline, size: 20, color: color),
                            const SizedBox(width: 12),
                            Expanded(child: Text(s, style: const TextStyle(fontSize: 15, color: Color(0xFFFFFFFF)))),
                          ],
                        ),
                      )),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              const Text(
                "Take a moment to apply this strategy. Click 'I did it!' when you're ready to continue.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // Return true to indicate completion and award points
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    "I did it!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

