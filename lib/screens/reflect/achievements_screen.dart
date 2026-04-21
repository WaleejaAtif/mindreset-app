import 'package:flutter/material.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _AchievementTile(
            title: 'First Login',
            subtitle: 'Started your journey 🚀',
            icon: Icons.star,
          ),
          _AchievementTile(
            title: '7 Day Streak',
            subtitle: 'Consistency champion 🔥',
            icon: Icons.local_fire_department,
          ),
          _AchievementTile(
            title: 'Mood Tracker',
            subtitle: 'Tracked mood 5 times 😊',
            icon: Icons.emoji_emotions,
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _AchievementTile({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: Colors.indigo),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
