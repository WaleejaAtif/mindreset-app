import 'package:flutter/material.dart';

class DailyMoodScreen extends StatelessWidget {
  const DailyMoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Mood Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'How are you feeling today?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                _MoodEmoji(emoji: '😄'),
                _MoodEmoji(emoji: '🙂'),
                _MoodEmoji(emoji: '😐'),
                _MoodEmoji(emoji: '😔'),
                _MoodEmoji(emoji: '😢'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoodEmoji extends StatelessWidget {
  final String emoji;
  const _MoodEmoji({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 36),
      ),
    );
  }
}
