import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/navigation.dart';
import 'breathing_exercises.dart';
import 'sound_therapy.dart';
import 'grounding_exercises.dart';

final ValueNotifier<Color> appBarColor =
ValueNotifier<Color>(Colors.transparent);

class MeditateScreen extends StatefulWidget {
  const MeditateScreen({super.key});

  @override
  State<MeditateScreen> createState() => _MeditateScreenState();
}

class _MeditateScreenState extends State<MeditateScreen> {
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    setState(() {
      _userName = doc.data()?['displayName'] ??
          user.displayName ??
          user.email?.split('@')[0] ??
          'User';
    });
  }

  // ✅ Log session to Firestore
  Future<void> _logSession(String category) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meditation_logs')
        .add({
      'category': category,
      'date': dateKey,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ✅ Update total sessions count
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'totalMeditationSessions': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              ValueListenableBuilder<Color>(
                valueListenable: appBarColor,
                builder: (context, color, child) {
                  return SliverAppBar(
                    expandedHeight: 140.0,
                    floating: false,
                    pinned: true,
                    centerTitle: true,
                    elevation: 0,
                    backgroundColor: color,
                    surfaceTintColor: Colors.transparent,
                    leading: const Icon(Icons.wifi_tethering,
                        color: Color(0xFF1A1333)),
                    actions: const [
                      Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: Icon(Icons.notifications_none,
                            color: Color(0xFF1A1333)),
                      ),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      centerTitle: true,
                      titlePadding: const EdgeInsets.only(bottom: 16),
                      background: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Color(0x3DFFFFFF),
                            child: Text(
                              _userName.isNotEmpty
                                  ? _userName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: Color(0xFF1A1333),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                      title: const Text(
                        'Meditation',
                        style: TextStyle(
                          color: Color(0xFF1A1333),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Sections
              SliverList(
                delegate: SliverChildListDelegate([
                  _InteractiveSection(
                    title: 'Breathing Exercises',
                    subtitle: 'Calm your mind & body',
                    imagePath: 'assets/images/breathing.jpg',
                    onTap: () async {
                      await _logSession('breathing');
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const BreathingScreen()),
                        );
                      }
                    },
                  ),
                  _InteractiveSection(
                    title: 'Sound Therapy',
                    subtitle: 'Relax with healing sounds',
                    imagePath: 'assets/images/sound.jpg',
                    onTap: () async {
                      await _logSession('sound_therapy');
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SoundTherapyScreen()),
                        );
                      }
                    },
                  ),
                  _InteractiveSection(
                    title: 'Grounding Exercises',
                    subtitle: 'Stay present & centered',
                    imagePath: 'assets/images/grounding.jpg',
                    onTap: () async {
                      await _logSession('grounding');
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GroundingScreen()),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 100),
                ]),
              ),
            ],
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNav(currentIndex: 2),
          ),
        ],
      ),
    );
  }
}

class _InteractiveSection extends StatefulWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;

  const _InteractiveSection({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  @override
  State<_InteractiveSection> createState() => _InteractiveSectionState();
}

class _InteractiveSectionState extends State<_InteractiveSection> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        height: 240,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              widget.imagePath,
              fit: BoxFit.cover,
              color: _isPressed
                  ? Color(0xFFFFFFFF).withOpacity(0.3)
                  : null,
              colorBlendMode: BlendMode.darken,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFFFFFF).withOpacity(0.4),
                    Colors.transparent,
                    Color(0xFFFFFFFF).withOpacity(0.6),
                  ],
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1A1333),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Color(0xFFFFFFFF).withOpacity(0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
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
}
