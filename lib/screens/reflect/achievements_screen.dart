import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/activity_service.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: user == null
          ? const Center(child: Text('Login to see achievements.'))
          : FutureBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
              future: Future.wait([
                FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('daily_logs')
                    .doc(ActivityService.dateKey())
                    .get(),
              ]),
              builder: (context, snapshot) {
                final userData = snapshot.data?[0].data() ?? {};
                final today = snapshot.data?[1].data() ?? {};
                final streak = (userData['streakDays'] as num?)?.toInt() ?? 0;
                final games = (today['gamesPlayed'] as num?)?.toInt() ?? 0;
                final points = (userData['points'] as num?)?.toInt() ?? 0;
                final exercise = today['exerciseCompleted'] == true ||
                    today['groundingCompleted'] == true ||
                    today['breathingCompleted'] == true;

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _AchievementTile(
                      title: 'Streak Score',
                      subtitle: '$streak day${streak == 1 ? '' : 's'} active',
                      icon: Icons.local_fire_department,
                      achieved: streak > 0,
                    ),
                    _AchievementTile(
                      title: 'Pomodoro Timer',
                      subtitle: today['pomodoroCompletedToday'] == true
                          ? 'Completed today'
                          : 'Not completed today',
                      icon: Icons.timer,
                      achieved: today['pomodoroCompletedToday'] == true,
                    ),
                    _AchievementTile(
                      title: 'Good Game Score',
                      subtitle: games > 0 ? 'Played $games game(s) today' : 'No games today',
                      icon: Icons.games,
                      achieved: games > 0,
                    ),
                    _AchievementTile(
                      title: 'Exercise Completed',
                      subtitle: exercise ? 'Exercise completed today' : 'No exercise yet',
                      icon: Icons.self_improvement,
                      achieved: exercise,
                    ),
                    _AchievementTile(
                      title: 'Loot Progress',
                      subtitle: '$points points earned',
                      icon: Icons.stars,
                      achieved: points > 0,
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool achieved;

  const _AchievementTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.achieved,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: achieved ? Colors.indigo : Colors.grey),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Icon(
          achieved ? Icons.check_circle : Icons.radio_button_unchecked,
          color: achieved ? Colors.green : Colors.grey,
        ),
      ),
    );
  }
}
