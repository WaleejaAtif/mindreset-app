import 'package:flutter/material.dart';

class HabitTipsScreen extends StatelessWidget {
  const HabitTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habit Tips')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '• Start tiny habits\n'
          '• Attach habits to routines\n'
          '• Track consistency\n'
          '• Reward progress',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
