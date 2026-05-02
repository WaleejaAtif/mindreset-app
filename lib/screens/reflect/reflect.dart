import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/navigation.dart';
import '../../widgets/sparkle_background.dart';
import 'achievements_screen.dart';
import 'daily_mood_screen.dart';
import 'mood_graph_screen.dart';
import 'streak_progress_screen.dart';

class ReflectScreen extends StatefulWidget {
  const ReflectScreen({super.key});

  @override
  State<ReflectScreen> createState() => _ReflectScreenState();
}

class _ReflectScreenState extends State<ReflectScreen> {
  String _userName = '';
  int _streakDays = 0;
  bool _loading = true;
  Map<String, dynamic> _todayLog = {};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDoc = await userRef.get();
      final data = userDoc.data() ?? <String, dynamic>{};
      final firstName = data['firstName']?.toString() ?? '';
      final lastName = data['lastName']?.toString() ?? '';
      final fullName = [firstName, lastName]
          .where((part) => part.trim().isNotEmpty)
          .join(' ')
          .trim();
      final now = DateTime.now();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayDoc = await userRef.collection('daily_logs').doc(dateKey).get();

      if (!mounted) return;
      setState(() {
        _userName = data['displayName'] ??
            (fullName.isNotEmpty ? fullName : null) ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'User';
        _streakDays = (data['streakDays'] as num?)?.toInt() ?? 0;
        _todayLog = todayDoc.data() ?? {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      debugPrint('Error loading user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SparkleBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true,
        bottomNavigationBar: const CustomBottomNav(currentIndex: 4),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF884288)),
                  ),
                )
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildProfileHeader(),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          Expanded(
                            child: _smallCard(
                              title: 'Streak',
                              value: '$_streakDays Days',
                              icon: Icons.local_fire_department_rounded,
                              gradientColors: const [
                                Color(0xFF9A882A),
                                Color(0xFFFFE0B2),
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const StreakProgressScreen(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _smallCard(
                              title: 'Badges',
                              value: '${_badgeCount()} Won',
                              icon: Icons.emoji_events_rounded,
                              gradientColors: const [
                                Color(0xFF4D7EA8),
                                Color(0xFF9AD1D4),
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AchievementsScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildAchievementSummary(),
                      const SizedBox(height: 24),
                      _sectionTitle('Analytics'),
                      const SizedBox(height: 12),
                      _listCard(
                        title: 'Mood Graph',
                        subtitle: 'Weekly mood & sleep trends',
                        icon: Icons.show_chart_rounded,
                        gradientColors: const [
                          Color(0xFFC2A7C3),
                          Color(0xFFE1BEE7),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MoodGraphScreen(),
                          ),
                        ),
                      ),
                      _listCard(
                        title: 'Daily Mood Tracker',
                        subtitle: 'History of your reflections',
                        icon: Icons.history_rounded,
                        gradientColors: const [
                          Color(0xFF6F7F61),
                          Color(0xFFC8E6C9),
                        ],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const DailyMoodScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildDailyRecord(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: _showEditProfileDialog,
              icon: const Icon(Icons.settings, color: Color(0xFF2D3142)),
              label: const Text('Settings', style: TextStyle(color: Color(0xFF2D3142))),
            ),
            TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              },
              icon: const Icon(Icons.logout, color: Color(0xFF2D3142)),
              label: const Text('Logout', style: TextStyle(color: Color(0xFF2D3142))),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CircleAvatar(
          radius: 52,
          backgroundColor: const Color(0xFF755F84),
          child: Text(
            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _userName,
          style: const TextStyle(
            color: Color(0xFF2D3142),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Focus Level: Advanced',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
      ],
    );
  }

  void _showEditProfileDialog() {
    final _nameController = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile Name'),
          content: TextField(
            controller: _nameController,
            decoration: const InputDecoration(hintText: "Enter your name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = _nameController.text.trim();
                if (newName.isNotEmpty) {
                  setState(() {
                    _userName = newName;
                  });
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await user.updateDisplayName(newName);
                    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
                      'displayName': newName,
                    });
                  }
                }
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF884288),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAchievementSummary() {
    final completedPomodoro = _todayLog['pomodoroCompletedToday'] == true;
    final games = (_todayLog['gamesPlayed'] as num?)?.toInt() ?? 0;
    final exerciseCompleted = _todayLog['exerciseCompleted'] == true ||
        _todayLog['groundingCompleted'] == true ||
        _todayLog['breathingCompleted'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle('Today Achievements'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _achievementChip('Streak $_streakDays', Icons.local_fire_department),
            _achievementChip(
              completedPomodoro ? 'Pomodoro done' : 'Pomodoro pending',
              Icons.timer,
            ),
            _achievementChip('$games game${games == 1 ? '' : 's'}', Icons.games),
            _achievementChip(
              exerciseCompleted ? 'Exercise done' : 'Exercise pending',
              Icons.self_improvement,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyRecord() {
    final lines = _recordLines();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Today Record',
            style: TextStyle(
              color: Color(0xFF2D3142),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (lines.isEmpty)
            const Text('No activity recorded today yet.',
                style: TextStyle(color: Colors.black54))
          else
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('* ',
                        style: TextStyle(
                            color: Color(0xFF755F84),
                            fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(line,
                          style: const TextStyle(color: Color(0xFF374151))),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<String> _recordLines() {
    final lines = <String>[];
    final mood = _todayLog['mood']?.toString();
    final sleep = _todayLog['sleep']?.toString();
    if (mood != null && mood.isNotEmpty) lines.add('Mood is set on $mood');
    if (sleep != null && sleep.isNotEmpty) lines.add('Sleep is $sleep');
    final focus = (_todayLog['focusStrategiesTaken'] as num?)?.toInt() ?? 0;
    if (focus > 0) lines.add('$focus focus strategy taken');
    final study = (_todayLog['studyTipsTaken'] as num?)?.toInt() ?? 0;
    if (study > 0) lines.add('$study study tip taken');
    if (_todayLog['chattedWithAi'] == true) lines.add('Chatted with AI assistant');
    final games = (_todayLog['gamesPlayed'] as num?)?.toInt() ?? 0;
    if (games > 0) lines.add('Played $games game${games == 1 ? '' : 's'}');
    final created = (_todayLog['tasksCreated'] as num?)?.toInt() ?? 0;
    if (created > 0) lines.add('$created task${created == 1 ? '' : 's'} created');
    final highTask = _todayLog['highPriorityTaskCompleted']?.toString();
    if (highTask != null && highTask.isNotEmpty) {
      lines.add('High priority "$highTask" task has been completed');
    }
    if (_todayLog['groundingCompleted'] == true ||
        ((_todayLog['groundingExercisesTaken'] as num?)?.toInt() ?? 0) > 0) {
      lines.add('Took grounding exercise');
    }
    return lines;
  }

  int _badgeCount() {
    var count = 0;
    if (_streakDays > 0) count++;
    if (_todayLog['pomodoroCompletedToday'] == true) count++;
    if (((_todayLog['gamesPlayed'] as num?)?.toInt() ?? 0) > 0) count++;
    if (_todayLog['exerciseCompleted'] == true) count++;
    return count;
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF2D3142),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _achievementChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF755F84)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF2D3142), fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _smallCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF2D3142), size: 30),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFF2D3142),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _listCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.5),
          child: Icon(icon, color: const Color(0xFF755F84)),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Color(0xFF2D3142), fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Colors.black26, size: 14),
      ),
    );
  }
}
