import 'dart:async'; // ✅ fixes Timer error
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GroundingScreen extends StatefulWidget {
  const GroundingScreen({super.key});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {

  // ✅ All exercise categories
  final List<Map<String, dynamic>> _categories = [
    {
      'id': 'sensory',
      'title': '5-4-3-2-1 Sensory',
      'subtitle': 'Ground your 5 senses',
      'emoji': '👁️',
      'color': const Color(0xFF5B8DB8),
      'isQuick': false,
    },
    {
      'id': 'emergency',
      'title': '🆘 Calm Me Now',
      'subtitle': '60 second emergency calm',
      'emoji': '🆘',
      'color': const Color(0xFFFC8181),
      'isQuick': true,
    },
    {
      'id': 'body_scan',
      'title': 'Body Scan',
      'subtitle': 'Scan & relax each body part',
      'emoji': '🧘',
      'color': const Color(0xFF48BB78),
      'isQuick': false,
    },
    {
      'id': 'mental',
      'title': 'Mental Grounding',
      'subtitle': 'Engage your mind',
      'emoji': '🧠',
      'color': const Color(0xFF7B68EE),
      'isQuick': false,
    },
    {
      'id': 'breathing',
      'title': 'Breath Awareness',
      'subtitle': 'Feel grounded through breath',
      'emoji': '🌬️',
      'color': const Color(0xFFED8936),
      'isQuick': false,
    },
    {
      'id': 'tap',
      'title': 'Tap Grounding',
      'subtitle': 'Rhythmic tapping exercise',
      'emoji': '👆',
      'color': const Color(0xFFB794F4),
      'isQuick': false,
    },
  ];

  void _openExercise(Map<String, dynamic> category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroundingSessionScreen(category: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Grounding Exercises',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Stay present & centered',
              style: TextStyle(color: Colors.white60, fontSize: 14),
            ),
            const SizedBox(height: 20),

            // ✅ Emergency button at top
            GestureDetector(
              onTap: () => _openExercise(_categories[1]),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFC8181).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: const Color(0xFFFC8181).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Text('🆘',
                        style: TextStyle(fontSize: 36)),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Calm Me Now',
                            style: TextStyle(
                              color: Color(0xFFFC8181),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Feeling anxious? Quick 60-second relief',
                            style: TextStyle(
                                color: Colors.white60, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        color: Color(0xFFFC8181), size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'All Exercises',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            // ✅ Exercise grid (skip emergency since shown above)
            Expanded(
              child: GridView.builder(
                gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,
                ),
                itemCount:
                _categories.where((c) => c['id'] != 'emergency').length,
                itemBuilder: (context, i) {
                  final filtered = _categories
                      .where((c) => c['id'] != 'emergency')
                      .toList();
                  final cat = filtered[i];
                  final color = cat['color'] as Color;

                  return GestureDetector(
                    onTap: () => _openExercise(cat),
                    child: Container(
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withOpacity(0.3)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(cat['emoji'],
                              style: const TextStyle(fontSize: 28)),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                cat['title'],
                                style: TextStyle(
                                  color: color,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                cat['subtitle'],
                                style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ✅ Session screen for each exercise
class GroundingSessionScreen extends StatefulWidget {
  final Map<String, dynamic> category;
  const GroundingSessionScreen({super.key, required this.category});

  @override
  State<GroundingSessionScreen> createState() =>
      _GroundingSessionScreenState();
}

class _GroundingSessionScreenState extends State<GroundingSessionScreen> {
  int _currentStep = 0;
  bool _isCompleted = false;
  bool _isPaused = false;
  int _tapCount = 0;
  int _countDown = 60;
  Timer? _emergencyTimer;

  // ✅ Exercise steps for each category
  Map<String, List<Map<String, dynamic>>> get _allSteps => {
    'sensory': [
      {
        'number': 5,
        'sense': 'SEE',
        'icon': Icons.visibility,
        'instruction':
        'Look around and name 5 things you can see right now.',
        'examples': ['A chair', 'A window', 'Your hands', 'The sky', 'A plant'],
        'color': const Color(0xFF5B8DB8),
      },
      {
        'number': 4,
        'sense': 'TOUCH',
        'icon': Icons.back_hand,
        'instruction':
        'Notice 4 things you can physically feel right now.',
        'examples': ['Your clothes', 'The floor', 'Your breath', 'Temperature'],
        'color': const Color(0xFF7B68EE),
      },
      {
        'number': 3,
        'sense': 'HEAR',
        'icon': Icons.hearing,
        'instruction': 'Listen and name 3 things you can hear.',
        'examples': ['Birds', 'Traffic', 'Your heartbeat'],
        'color': const Color(0xFF48BB78),
      },
      {
        'number': 2,
        'sense': 'SMELL',
        'icon': Icons.air,
        'instruction': 'Notice 2 things you can smell right now.',
        'examples': ['Fresh air', 'Food nearby'],
        'color': const Color(0xFFED8936),
      },
      {
        'number': 1,
        'sense': 'TASTE',
        'icon': Icons.restaurant,
        'instruction': 'Notice 1 thing you can taste right now.',
        'examples': ['Water', 'Last meal'],
        'color': const Color(0xFFFC8181),
      },
    ],
    'body_scan': [
      {
        'title': 'Feet & Legs',
        'instruction':
        'Feel your feet on the ground. Notice any tension in your legs. Breathe and let it go.',
        'emoji': '🦶',
        'color': const Color(0xFF48BB78),
      },
      {
        'title': 'Stomach & Back',
        'instruction':
        'Notice your stomach rising and falling. Feel your back against the chair or surface.',
        'emoji': '🫁',
        'color': const Color(0xFF48BB78),
      },
      {
        'title': 'Chest & Heart',
        'instruction':
        'Feel your heartbeat. Place a hand on your chest. Notice the warmth.',
        'emoji': '❤️',
        'color': const Color(0xFF48BB78),
      },
      {
        'title': 'Shoulders & Arms',
        'instruction':
        'Drop your shoulders down. Unclench your hands. Let your arms feel heavy and relaxed.',
        'emoji': '💪',
        'color': const Color(0xFF48BB78),
      },
      {
        'title': 'Face & Head',
        'instruction':
        'Relax your jaw, forehead and eyes. Let all tension melt away from your face.',
        'emoji': '😌',
        'color': const Color(0xFF48BB78),
      },
    ],
    'mental': [
      {
        'title': 'Count Backwards',
        'instruction':
        'Count slowly from 20 to 1 in your mind. Focus only on the numbers.',
        'emoji': '🔢',
        'color': const Color(0xFF7B68EE),
      },
      {
        'title': 'Name Animals',
        'instruction':
        'Name 10 different animals in your mind. Take your time with each one.',
        'emoji': '🐘',
        'color': const Color(0xFF7B68EE),
      },
      {
        'title': 'Colors Around You',
        'instruction':
        'Look around and name every color you can see. Be specific - light blue, dark green...',
        'emoji': '🎨',
        'color': const Color(0xFF7B68EE),
      },
      {
        'title': 'Safe Place',
        'instruction':
        'Close your eyes. Imagine a place where you feel completely safe and calm. Stay there.',
        'emoji': '🏡',
        'color': const Color(0xFF7B68EE),
      },
    ],
    'breathing': [
      {
        'title': 'Feel Your Feet',
        'instruction':
        'Press your feet firmly on the floor. Feel the ground beneath you as you breathe in slowly.',
        'emoji': '🌬️',
        'color': const Color(0xFFED8936),
      },
      {
        'title': 'Breathe & Notice',
        'instruction':
        'Take a slow breath in for 4 counts. Hold for 2. Breathe out for 6. Notice how your body feels.',
        'emoji': '🫧',
        'color': const Color(0xFFED8936),
      },
      {
        'title': 'Hand on Heart',
        'instruction':
        'Place one hand on your heart. Feel each breath. Say to yourself: I am safe. I am here.',
        'emoji': '🤲',
        'color': const Color(0xFFED8936),
      },
    ],
    'tap': [
      {
        'title': 'Tap Rhythm',
        'instruction':
        'Tap the screen slowly and rhythmically. Each tap brings you more present. Try 20 taps.',
        'emoji': '👆',
        'color': const Color(0xFFB794F4),
        'isTap': true,
      },
      {
        'title': 'Butterfly Tap',
        'instruction':
        'Cross your arms over your chest. Tap your shoulders alternately — left, right, left, right. Do 20 taps.',
        'emoji': '🦋',
        'color': const Color(0xFFB794F4),
      },
    ],
    'emergency': [
      {
        'title': 'You Are Safe',
        'instruction':
        'You are safe right now. Take one slow breath. In through your nose... out through your mouth.',
        'emoji': '💙',
        'color': const Color(0xFFFC8181),
      },
      {
        'title': 'Feel the Ground',
        'instruction':
        'Press both feet on the floor. Feel the solid ground beneath you. You are supported.',
        'emoji': '🌍',
        'color': const Color(0xFFFC8181),
      },
      {
        'title': 'Name 3 Things',
        'instruction':
        'Quickly name 3 things you can see right now. Say them out loud if you can.',
        'emoji': '👁️',
        'color': const Color(0xFFFC8181),
      },
      {
        'title': 'One More Breath',
        'instruction':
        'Take one final deep breath. In for 4... Hold for 2... Out for 6... You got this. 💙',
        'emoji': '✨',
        'color': const Color(0xFFFC8181),
      },
    ],
  };

  List<Map<String, dynamic>> get _steps =>
      _allSteps[widget.category['id']] ?? [];

  Color get _color => widget.category['color'] as Color;

  @override
  void initState() {
    super.initState();
    if (widget.category['id'] == 'emergency') {
      _startEmergencyTimer();
    }
  }

  void _startEmergencyTimer() {
    _emergencyTimer =
        Timer.periodic(const Duration(seconds: 1), (t) {
          if (!mounted) return;
          setState(() => _countDown--);
          if (_countDown <= 0) {
            t.cancel();
          }
        });
  }

  @override
  void dispose() {
    _emergencyTimer?.cancel();
    super.dispose();
  }

  // ✅ Save to Firestore
  Future<void> _saveCompletion(bool completed) async {
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
      'category': 'grounding',
      'type': widget.category['id'],
      'exercise': widget.category['title'],
      'completed': completed,
      'date': dateKey,
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('daily_logs')
        .doc(dateKey)
        .set({
      'groundingCompleted': completed,
      'groundingType': widget.category['id'],
    }, SetOptions(merge: true));

    if (completed) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'totalGroundingSessions': FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
  }

  // ✅ Motivational popup
  void _showMotivationalMessage(bool completed) {
    final messages = completed
        ? [
      "Amazing! You're building inner strength. 🌟",
      "Well done! You stayed present and grounded. 💫",
      "You did it! Your calm mind is growing stronger. 🌸",
    ]
        : [
      "It's okay to pause. Even a few moments matter. 💙",
      "Every step counts. Come back when you're ready. 🌿",
      "Be kind to yourself. You're doing great. ✨",
    ];

    messages.shuffle();
    final message = messages.first;
    final color =
    completed ? const Color(0xFF48BB78) : const Color(0xFF5B8DB8);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                completed
                    ? Icons.self_improvement
                    : Icons.favorite,
                color: color,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                completed ? 'Session Complete!' : 'Good effort!',
                style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No steps available',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () async {
            _emergencyTimer?.cancel();
            await _saveCompletion(false);
            if (mounted) {
              _showMotivationalMessage(false);
            }
          },
        ),
        title: Text(
          widget.category['title'],
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (!_isCompleted)
            IconButton(
              icon: Icon(
                _isPaused ? Icons.play_arrow : Icons.pause,
                color: Colors.white,
              ),
              onPressed: () =>
                  setState(() => _isPaused = !_isPaused),
            ),
        ],
      ),
      body: _isCompleted
          ? _buildCompletedUI()
          : _buildSessionUI(),
    );
  }

  Widget _buildSessionUI() {
    final step = _steps[_currentStep];
    final color = (step['color'] as Color?) ?? _color;
    final isTapExercise = step['isTap'] == true;
    final isEmergency = widget.category['id'] == 'emergency';

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Step ${_currentStep + 1} of ${_steps.length}',
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 13),
                  ),
                  if (isEmergency)
                    Text(
                      '${_countDown}s',
                      style: TextStyle(
                          color: _color,
                          fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 4,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ),

        // Step dots
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_steps.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _currentStep ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= _currentStep
                    ? color
                    : Colors.white24,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),

        const Spacer(),

        // Main step card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Container(
              key: ValueKey(_currentStep),
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  // Emoji or number
                  if (step.containsKey('number'))
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.2),
                        border: Border.all(color: color, width: 3),
                      ),
                      child: Center(
                        child: Text(
                          '${step['number']}',
                          style: TextStyle(
                            color: color,
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      step['emoji'] ?? widget.category['emoji'],
                      style: const TextStyle(fontSize: 56),
                    ),

                  const SizedBox(height: 16),

                  // Title or sense
                  Text(
                    step['sense'] ?? step['title'] ?? '',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Instruction
                  Text(
                    step['instruction'] ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                  ),

                  // Examples if available
                  if (step.containsKey('examples')) ...[
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: (step['examples'] as List<String>)
                          .map(
                            (e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(20),
                            border: Border.all(
                                color: color.withOpacity(0.3)),
                          ),
                          child: Text(
                            'e.g. $e',
                            style: TextStyle(
                                color: color.withOpacity(0.8),
                                fontSize: 12),
                          ),
                        ),
                      )
                          .toList(),
                    ),
                  ],

                  // ✅ Tap counter for tap exercise
                  if (isTapExercise) ...[
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _tapCount++);
                      },
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withOpacity(0.3),
                          border: Border.all(color: color, width: 3),
                        ),
                        child: Center(
                          child: Text(
                            '$_tapCount',
                            style: TextStyle(
                              color: color,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap the circle',
                      style: TextStyle(
                          color: color.withOpacity(0.7),
                          fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        const Spacer(),

        // Next / Complete button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ElevatedButton(
            onPressed: _isPaused
                ? null
                : () async {
              if (_currentStep < _steps.length - 1) {
                setState(() {
                  _currentStep++;
                  _tapCount = 0;
                });
              } else {
                _emergencyTimer?.cancel();
                await _saveCompletion(true);
                setState(() => _isCompleted = true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isPaused
                  ? Colors.grey
                  : color,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              _isPaused
                  ? 'Paused'
                  : _currentStep < _steps.length - 1
                  ? 'Next →'
                  : 'Complete ✓',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildCompletedUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.self_improvement,
                color: Color(0xFF48BB78), size: 80),
            const SizedBox(height: 24),
            const Text(
              'You did it! 🌟',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Session saved! You are grounded and present.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white60, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                  _isCompleted = false;
                  _tapCount = 0;
                });
                _showMotivationalMessage(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF48BB78),
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Do It Again',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Meditation',
                  style: TextStyle(color: Colors.white60)),
            ),
          ],
        ),
      ),
    );
  }
}