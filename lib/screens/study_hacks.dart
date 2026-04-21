import 'package:flutter/material.dart';

class StudyHacksScreen extends StatelessWidget {
  const StudyHacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Study Hacks')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          '• Active recall\n'
          '• Feynman technique\n'
          '• Spaced repetition\n'
          '• Study in short sessions',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
