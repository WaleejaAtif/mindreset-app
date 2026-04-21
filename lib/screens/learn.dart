import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/navigation.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ValueNotifier to track color changes based on scroll offset
    final ValueNotifier<Color> appBarColor = ValueNotifier<Color>(Colors.transparent);

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true, // 🟢 Ensures content flows behind the Nav Bar
      bottomNavigationBar: const CustomBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          // 1️⃣ Global Background Image
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg17.jpg", // Using your bg17
              fit: BoxFit.cover,
            ),
          ),

          // 2️⃣ Global Glassmorphism Blur Effect
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: Colors.black.withOpacity(0.2), // Dark tint for white text contrast
              ),
            ),
          ),

          // 3️⃣ Main Content Layer
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollUpdateNotification) {
                if (notification.metrics.pixels > 50) {
                  appBarColor.value = Colors.black.withOpacity(0.5);
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
                      flexibleSpace: const FlexibleSpaceBar(
                        centerTitle: true,
                        titlePadding: EdgeInsets.only(bottom: 16),
                        title: Text(
                          'Learning Today',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('👋 Hey!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(
                  0xFFBACCD8))),
              const SizedBox(height: 4),
              Text('Ready to learn something small today?', style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.7))),
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: textColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: iconColor),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.white70), overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_forward, size: 18, color: Colors.white70),
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
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}