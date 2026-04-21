import 'package:flutter/material.dart';

class StreakProgressScreen extends StatelessWidget {
  const StreakProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Streak Progress')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.local_fire_department, size: 80, color: Colors.orange),
            SizedBox(height: 16),
            Text(
              '🔥 7 Day Streak!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Keep showing up every day 💪'),
          ],
        ),
      ),
    );
  }
}
