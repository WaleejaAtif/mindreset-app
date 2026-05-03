import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../widgets/navigation.dart';
import '../../widgets/sparkle_background.dart';
import 'achievements_screen.dart';
import 'daily_mood_screen.dart';
import 'mood_graph_screen.dart';
import 'streak_progress_screen.dart';
import '../settings_screen.dart';

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
                                Color(0xFF957C2E), // Gold/Orange dark
                                Color(0xFF4A3E17),
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
                                Color(0xFF005B9F), // Deep blue
                                Color(0xFF002B4E),
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
                      _buildSuggestionBlock(),
                      const SizedBox(height: 24),
                      _sectionTitle('Analytics'),
                      const SizedBox(height: 12),
                      _listCard(
                        title: 'Mood Graph',
                        subtitle: 'Weekly mood & sleep trends',
                        icon: Icons.show_chart_rounded,
                        gradientColors: const [
                          Color(0xFF2C1A4D),
                          Color(0xFF1A1333),
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
                          Color(0xFF2C1A4D),
                          Color(0xFF1A1333),
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
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ).then((_) => _loadUserData());
              },
              icon: const Icon(Icons.settings, color: Color(0xFFFFFFFF)),
              label: const Text('Settings', style: TextStyle(color: Color(0xFFFFFFFF))),
            ),
            TextButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
              },
              icon: const Icon(Icons.logout, color: Color(0xFFFFFFFF)),
              label: const Text('Logout', style: TextStyle(color: Color(0xFFFFFFFF))),
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
            color: Color(0xFFFFFFFF),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text(
          'Focus Level: Advanced',
          style: TextStyle(color: Color(0xFFAFA8BA), fontSize: 14),
        ),
      ],
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
    final records = _recordLines();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1333),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF381E72), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.assignment_rounded, color: Color(0xFFB39DDB), size: 22),
              SizedBox(width: 8),
              Text(
                'Today\'s Record',
                style: TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (records.isEmpty)
            const Text('No activity recorded today yet.',
                style: TextStyle(color: Color(0xFFAFA8BA), fontSize: 14))
          else
            ...records.map(
              (rec) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: rec['color'].withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(rec['icon'], size: 16, color: rec['color']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          rec['text'],
                          style: const TextStyle(
                              color: Color(0xFFE2DCE9),
                              fontSize: 14,
                              height: 1.3),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _recordLines() {
    final lines = <Map<String, dynamic>>[];
    final mood = _todayLog['mood']?.toString();
    final sleep = _todayLog['sleep']?.toString();
    if (mood != null && mood.isNotEmpty) {
      lines.add({'text': 'Mood is set to $mood', 'icon': Icons.mood, 'color': const Color(0xFFCB6CE6)});
    }
    if (sleep != null && sleep.isNotEmpty) {
      lines.add({'text': 'Sleep recorded: $sleep', 'icon': Icons.nights_stay, 'color': const Color(0xFF38B6FF)});
    }
    final focus = (_todayLog['focusStrategiesTaken'] as num?)?.toInt() ?? 0;
    if (focus > 0) {
      lines.add({'text': '$focus focus strategy taken', 'icon': Icons.psychology, 'color': const Color(0xFFFFDE59)});
    }
    final study = (_todayLog['studyTipsTaken'] as num?)?.toInt() ?? 0;
    if (study > 0) {
      lines.add({'text': '$study study tip taken', 'icon': Icons.lightbulb, 'color': const Color(0xFFFF914D)});
    }
    if (_todayLog['chattedWithAi'] == true) {
      lines.add({'text': 'Chatted with AI assistant', 'icon': Icons.chat_bubble_outline, 'color': const Color(0xFF5CE1E6)});
    }
    final games = (_todayLog['gamesPlayed'] as num?)?.toInt() ?? 0;
    if (games > 0) {
      lines.add({'text': 'Played $games game${games == 1 ? '' : 's'}', 'icon': Icons.videogame_asset, 'color': const Color(0xFFFF5757)});
    }
    final created = (_todayLog['tasksCreated'] as num?)?.toInt() ?? 0;
    if (created > 0) {
      lines.add({'text': '$created task${created == 1 ? '' : 's'} created', 'icon': Icons.add_task, 'color': const Color(0xFF00BF63)});
    }
    final highTask = _todayLog['highPriorityTaskCompleted']?.toString();
    if (highTask != null && highTask.isNotEmpty) {
      lines.add({'text': 'High priority "$highTask" completed', 'icon': Icons.priority_high, 'color': const Color(0xFFFF5757)});
    }
    if (_todayLog['groundingCompleted'] == true ||
        ((_todayLog['groundingExercisesTaken'] as num?)?.toInt() ?? 0) > 0) {
      lines.add({'text': 'Completed grounding exercise', 'icon': Icons.self_improvement, 'color': const Color(0xFFCB6CE6)});
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
          color: Color(0xFFFFFFFF),
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
        color: Color(0xFF1A1333).withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Color(0xFF1A1333)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF755F84)),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  color: Color(0xFFFFFFFF), fontWeight: FontWeight.w700)),
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
          border: Border.all(color: Color(0xFF1A1333), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFFFFFFFF), size: 30),
            const SizedBox(height: 12),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Color(0xFFAFA8BA), fontSize: 12)),
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
        border: Border.all(color: Color(0xFF1A1333), width: 1.5),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF8C52FF), // Vibrant Purple
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title,
            style: const TextStyle(
                color: Color(0xFFFFFFFF), fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: const TextStyle(color: Color(0xFFB39DDB), fontSize: 12)), // Light purple subtext
        trailing:
            const Icon(Icons.arrow_forward_ios, color: Color(0x8AFFFFFF), size: 14),
      ),
    );
  }

  Widget _buildSuggestionBlock() {
    final mood = _todayLog['mood']?.toString() ?? '';
    final sleep = _todayLog['sleep']?.toString() ?? '';
    final suggestions = _getSuggestionsForMood(mood, sleep);
    final moodLevel = _getMoodLevel(mood);
    final goal = _getGoalForMood(moodLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A1D), Color(0xFF2D2D34)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1A1333), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFFFFF).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personalized Suggestions',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Mood: ',
                style: const TextStyle(
                  color: Color(0xFFAFA8BA),
                  fontSize: 13,
                ),
              ),
              Text(
                mood.isNotEmpty ? mood : 'Not set',
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                'Goal: ',
                style: const TextStyle(
                  color: Color(0xFFAFA8BA),
                  fontSize: 13,
                ),
              ),
              Text(
                goal,
                style: const TextStyle(
                  color: Color(0xFF8C52FF), // Vibrant Purple
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions
                .map((suggestion) => _suggestionChip(suggestion['label'], suggestion['icon'], suggestion['color']))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _suggestionChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _getMoodLevel(String mood) {
    final lowerMood = mood.toLowerCase();
    if (lowerMood.contains('very good') || lowerMood.contains('great') || lowerMood.contains('amazing')) {
      return 'very_good';
    } else if (lowerMood.contains('good')) {
      return 'good';
    } else if (lowerMood.contains('neutral') || lowerMood.contains('okay') || lowerMood.contains('fair')) {
      return 'neutral';
    } else if (lowerMood.contains('bad') || lowerMood.contains('low') || lowerMood.contains('poor')) {
      return 'bad';
    } else if (lowerMood.contains('very bad') || lowerMood.contains('very low') || lowerMood.contains('terrible')) {
      return 'very_bad';
    }
    return 'neutral';
  }

  String _getGoalForMood(String moodLevel) {
    switch (moodLevel) {
      case 'very_bad':
        return 'Calm the user and stabilize emotions';
      case 'bad':
        return 'Reduce overwhelm and encourage small action';
      case 'neutral':
        return 'Build momentum and engagement';
      case 'good':
        return 'Maintain productivity and consistency';
      case 'very_good':
        return 'Maximize productivity and reinforce habits';
      default:
        return 'Gentle engagement';
    }
  }

  List<Map<String, dynamic>> _getSuggestionsForMood(String mood, String sleep) {
    final moodLevel = _getMoodLevel(mood);
    final lowerSleep = sleep.toLowerCase();
    final isSleepLow = lowerSleep.contains('low') || lowerSleep.contains('poor') || lowerSleep.contains('<3') || lowerSleep.contains('3-4');
    
    List<Map<String, dynamic>> suggestions = [];

    if (isSleepLow) {
      suggestions = [
        {'label': 'Breathing Exercises', 'icon': Icons.air_rounded, 'color': const Color(0xFF59D99D)},
        {'label': 'Grounding', 'icon': Icons.spa_rounded, 'color': const Color(0xFFAB7DAC)},
        {'label': 'Sound Therapy', 'icon': Icons.music_note_rounded, 'color': const Color(0xFF8A7CFF)},
        {'label': 'AI Chatbot', 'icon': Icons.chat_rounded, 'color': const Color(0xFF65C7F7)},
      ];
    } else {
      switch (moodLevel) {
        case 'very_bad':
          suggestions = [
            {'label': 'Breathing Exercises', 'icon': Icons.air_rounded, 'color': const Color(0xFF59D99D)},
            {'label': 'Grounding', 'icon': Icons.spa_rounded, 'color': const Color(0xFFAB7DAC)},
            {'label': 'Sound Therapy', 'icon': Icons.music_note_rounded, 'color': const Color(0xFF8A7CFF)},
            {'label': 'AI Chatbot', 'icon': Icons.chat_rounded, 'color': const Color(0xFF65C7F7)},
          ];
          break;
        case 'bad':
          suggestions = [
            {'label': 'Short Breathing', 'icon': Icons.air_rounded, 'color': const Color(0xFF59D99D)},
            {'label': 'Mini Pomodoro', 'icon': Icons.timer_rounded, 'color': const Color(0xFFFFD166)},
            {'label': 'Small Task', 'icon': Icons.task_alt_rounded, 'color': const Color(0xFF65C7F7)},
            {'label': 'Light Sound', 'icon': Icons.music_note_rounded, 'color': const Color(0xFF8A7CFF)},
          ];
          break;
        case 'neutral':
          suggestions = [
            {'label': 'Standard Pomodoro', 'icon': Icons.timer_rounded, 'color': const Color(0xFFFFD166)},
            {'label': 'Top Tasks', 'icon': Icons.checklist_rounded, 'color': const Color(0xFF65C7F7)},
            {'label': 'Focus Games', 'icon': Icons.videogame_asset_rounded, 'color': const Color(0xFF8A7CFF)},
            {'label': 'Mood Tracking', 'icon': Icons.show_chart_rounded, 'color': const Color(0xFF59D99D)},
          ];
          break;
        case 'good':
          suggestions = [
            {'label': 'Full Pomodoro', 'icon': Icons.timer_rounded, 'color': const Color(0xFFFFD166)},
            {'label': 'Priority Tasks', 'icon': Icons.checklist_rounded, 'color': const Color(0xFF65C7F7)},
            {'label': 'Streak Tracking', 'icon': Icons.local_fire_department_rounded, 'color': const Color(0xFFFF9F6E)},
            {'label': 'Focus Sounds', 'icon': Icons.music_note_rounded, 'color': const Color(0xFF8A7CFF)},
          ];
          break;
        case 'very_good':
          suggestions = [
            {'label': 'Multiple Pomodoro', 'icon': Icons.timer_rounded, 'color': const Color(0xFFFFD166)},
            {'label': 'High Priority Tasks', 'icon': Icons.checklist_rounded, 'color': const Color(0xFF65C7F7)},
            {'label': 'Rewards & Achievements', 'icon': Icons.emoji_events_rounded, 'color': const Color(0xFFFF9F6E)},
            {'label': 'Reflection Entry', 'icon': Icons.edit_rounded, 'color': const Color(0xFF8A7CFF)},
          ];
          break;
        default:
          suggestions = [
            {'label': 'Tasks', 'icon': Icons.checklist_rounded, 'color': const Color(0xFF65C7F7)},
            {'label': 'Focus', 'icon': Icons.lightbulb_rounded, 'color': const Color(0xFFFFD166)},
            {'label': 'Sounds', 'icon': Icons.music_note_rounded, 'color': const Color(0xFF8A7CFF)},
            {'label': 'Learning', 'icon': Icons.school_rounded, 'color': const Color(0xFF59D99D)},
          ];
          break;
      }
    }

    return suggestions;
  }
}



