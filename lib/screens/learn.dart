import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/navigation.dart';
import '../widgets/animated_background.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueNotifier to track color changes based on scroll offset
    final ValueNotifier<Color> appBarColor = ValueNotifier<Color>(Colors.transparent);

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C1A4D), Color(0xFF0D0B1A)], // Light purple to light blue gradient
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        extendBody: true, // 🟢 Ensures content flows behind the Nav Bar
        bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
        body: Stack(
          children: [
            // Main Content Layer
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.metrics.pixels > 50) {
                  appBarColor.value = Color(0xFF1A1333).withValues(alpha: 0.9);
                } else {
                  appBarColor.value = Colors.transparent;
                }
              }
              return true;
            },
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(), // Better feel with blur
              slivers: [
                // Dynamic AppBar
                ValueListenableBuilder<Color>(
                  valueListenable: appBarColor,
                  builder: (context, color, child) {
                    return SliverAppBar(
                      expandedHeight: 80.0,
                      floating: false,
                      pinned: true,
                      centerTitle: true,
                      elevation: 0,
                      backgroundColor: color,
                      surfaceTintColor: Colors.transparent,
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        titlePadding: const EdgeInsets.only(bottom: 16),
                        title: ShaderMask(
                          blendMode: BlendMode.srcIn,
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFF884288), Color(0xFF608BA5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                          child: const Text(
                            'Learning Today',
                            style: TextStyle(
                              color: Color(0xFF1A1333), // Overridden by ShaderMask
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 100), // Added bottom padding for Nav Bar
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header (Already has internal glass effect)
                        _buildIntroHeader(),

                        const SizedBox(height: 15),

                        // Pomodoro Card
                        _buildFeatureCard(
                          context,
                          title: '🎯 Today’s Focus Tip',
                          description: 'Try the 25–5 Pomodoro to beat task paralysis.',
                          buttonText: 'Start Pomodoro',
                          color: const Color(0x9EA7CDCD),
                          textColor: const Color(0xFF5D4037),
                          route: '/pomodoro',
                        ),

                        const SizedBox(height: 20),

                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            "Explore at Your Pace",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff608ba5),
                            ),
                          ),
                        ),

                        // Learning Cards Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          padding: const EdgeInsets.only(top: 8),
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 0.82,
                          children: [
                            _buildLearnCard(
                              context,
                              icon: Icons.smart_toy,
                              title: 'Smart Bot',
                              subtitle: 'Chat + suggestions',
                              gradientColors: [const Color(0xFF4d7ea8), const Color(0xFF9ad1d4)],
                              iconColor: const Color(0xFF2f5d7c),
                              route: '/learningAssistant',
                            ),
                            _buildLearnCard(
                              context,
                              icon: Icons.psychology,
                              title: 'Focus Strategies',
                              subtitle: 'Small steps',
                              gradientColors: [const Color(0xFFb3957c), const Color(0xFFD7CCC8)],
                              iconColor: const Color(0xFFb3957c),
                              route: '/focusStrategies',
                            ),
                            _buildLearnCard(
                              context,
                              icon: Icons.menu_book,
                              title: 'Study Hacks',
                              subtitle: 'Smart ways',
                              gradientColors: [const Color(0xFFc2a7c3), const Color(0xFFE1BEE7)],
                              iconColor: const Color(0xffb9a7c8),
                              route: '/studyHacks',
                            ),
                            _buildLearnCard(
                              context,
                              icon: Icons.spa,
                              title: 'Habit Tips',
                              subtitle: 'Build routines',
                              gradientColors: [const Color(0xFF6f7f61), const Color(0xFFC8E6C9)],
                              iconColor: const Color(0xFF6f7f61),
                              route: '/habitTips',
                            ),
                            _buildLearnCard(
                              context,
                              icon: Icons.games,
                              title: 'Focus Games',
                              subtitle: 'Train attention',
                              gradientColors: [const Color(0xFF9a882a), const Color(0xFFFFE0B2)],
                              iconColor: const Color(0xFF9a882a),
                              route: '/games',
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        _buildAssistantShowcase(context),

                        const SizedBox(height: 20),

                        // Bottom List Tiles (Already has internal glass effect)
                        _buildModernListTile(
                          icon: Icons.local_fire_department,
                          iconColor: Colors.orangeAccent,
                          title: 'Learning Streak: 3 days',
                          subtitle: '⭐ You unlocked “Curious Mind”',
                        ),
                        const SizedBox(height: 12),
                        _buildModernListTile(
                          icon: Icons.lightbulb_outline,
                          iconColor: Colors.yellowAccent,
                          title: 'Did you know?',
                          subtitle: 'Short focus sessions work better for ADHD brains.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

// Helper Methods (Keep as they are in your code)
// ... _buildIntroHeader, _buildFeatureCard, _buildLearnCard, _buildModernListTile ...


  // Helper Methods
  Widget _buildIntroHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0xFF1A1333),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFFFFFF).withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👋 Hey!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5E17EB))),
              const SizedBox(height: 4),
              Text('Ready to learn something small today?', style: TextStyle(fontSize: 15, color: Color(0xFF6B7280))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, {required String title, required String description, required String buttonText, required Color color, required Color textColor, required String route}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(28)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
          const SizedBox(height: 8),
          Text(description, style: TextStyle(fontSize: 15, color: textColor.withOpacity(0.8))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, route),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF1A1333), foregroundColor: textColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
            child: Text(buttonText, style: const TextStyle(fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildLearnCard(BuildContext context, {required IconData icon, required String title, required String subtitle, required List<Color> gradientColors, required Color iconColor, required String route}) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [gradientColors[0], gradientColors[1].withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Color(0xFFFFFFFF).withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFF1A1333).withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF1A1333))),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xB3FFFFFF)), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_forward, size: 18, color: Color(0xB3FFFFFF)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernListTile({required IconData icon, required Color iconColor, required String title, required String subtitle}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFF1A1333),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFFFFFFF).withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssistantShowcase(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8C52FF), Color(0xFF38B6FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8C52FF).withOpacity(0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF1A1333).withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'NEW SMART ASSISTANT',
              style: TextStyle(
                color: Color(0xFF1A1333),
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Talk to a smart bot made for Learning Today.',
            style: TextStyle(
              color: Color(0xFF1A1333),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ask about focus, procrastination, exams, or burnout. It chats back with calm support and picks the best next tool for you, like Pomodoro, Focus Games, or Explore Your Peace.',
            style: TextStyle(
              color: Color(0xFF1A1333).withOpacity(0.82),
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _AssistantTag(label: 'Responsive chat'),
              _AssistantTag(label: 'Smart recommendations'),
              _AssistantTag(label: 'Multi-model ready'),
            ],
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/learningAssistant'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF1A1333),
              foregroundColor: const Color(0xFF5E17EB),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            icon: const Icon(Icons.auto_awesome),
            label: const Text(
              'Open Chat Assistant',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantTag extends StatelessWidget {
  final String label;

  const _AssistantTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1A1333).withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1A1333),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}


