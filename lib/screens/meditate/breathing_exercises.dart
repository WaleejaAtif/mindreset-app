import 'dart:async'; // ✅ fixes Timer error
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {

  // Breathing exercises list
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': 'Box Breathing',
      'description': 'Inhale 4s → Hold 4s → Exhale 4s → Hold 4s',
      'steps': ['Inhale', 'Hold', 'Exhale', 'Hold'],
      'durations': [4, 4, 4, 4],
      'color': const Color(0xFF5B8DB8),
      'rounds': 4,
    },
    {
      'name': '4-7-8 Breathing',
      'description': 'Inhale 4s → Hold 7s → Exhale 8s',
      'steps': ['Inhale', 'Hold', 'Exhale'],
      'durations': [4, 7, 8],
      'color': const Color(0xFF7B68EE),
      'rounds': 3,
    },
    {
      'name': 'Deep Breathing',
      'description': 'Slow inhale 5s → Exhale 5s',
      'steps': ['Inhale', 'Exhale'],
      'durations': [5, 5],
      'color': const Color(0xFF48BB78),
      'rounds': 5,
    },
  ];

  int _selectedExercise = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  int _currentStep = 0;
  int _secondsLeft = 0;
  int _currentRound = 0;
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _scaleAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _current => _exercises[_selectedExercise];

  void _startExercise() {
    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _currentStep = 0;
      _currentRound = 1;
      _secondsLeft = (_current['durations'] as List<int>)[0];
    });
    _runStep();
  }

  void _runStep() {
    final durations = _current['durations'] as List<int>;
    final steps = _current['steps'] as List<String>;

    // Animate based on step
    if (steps[_currentStep] == 'Inhale') {
      _animController.forward();
    } else if (steps[_currentStep] == 'Exhale') {
      _animController.reverse();
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);

      if (_secondsLeft <= 0) {
        t.cancel();
        _nextStep();
      }
    });
  }

  void _nextStep() {
    final durations = _current['durations'] as List<int>;
    final steps = _current['steps'] as List<String>;
    final totalRounds = _current['rounds'] as int;

    int nextStep = _currentStep + 1;

    if (nextStep >= steps.length) {
      // Round complete
      nextStep = 0;
      int nextRound = _currentRound + 1;

      if (nextRound > totalRounds) {
        // All rounds done
        _onComplete();
        return;
      }

      setState(() => _currentRound = nextRound);
    }

    setState(() {
      _currentStep = nextStep;
      _secondsLeft = durations[nextStep];
    });

    _runStep();
  }

  // ✅ Save completion to Firestore
  Future<void> _onComplete() async {
    setState(() {
      _isRunning = false;
      _isCompleted = true;
    });
    _animController.reset();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final today = DateTime.now();
    final dateKey =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    // ✅ Save completed session
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('meditation_logs')
        .add({
      'category': 'breathing',
      'exercise': _current['name'],
      'rounds': _current['rounds'],
      'completed': true,
      'date': dateKey,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // ✅ Update daily log
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('daily_logs')
        .doc(dateKey)
        .set({
      'breathingCompleted': true,
      'breathingExercise': _current['name'],
    }, SetOptions(merge: true));

    // ✅ Increment total sessions
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'totalBreathingSessions': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  void _stopExercise() {
    _timer?.cancel();
    _animController.reset();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _currentStep = 0;
      _currentRound = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _current;
    final color = exercise['color'] as Color;
    final steps = exercise['steps'] as List<String>;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            _timer?.cancel();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Breathing Exercises',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [

          // ✅ Exercise selector tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _exercises.length,
              itemBuilder: (context, i) {
                final selected = i == _selectedExercise;
                return GestureDetector(
                  onTap: _isRunning
                      ? null
                      : () => setState(() {
                    _selectedExercise = i;
                    _isCompleted = false;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? (_exercises[i]['color'] as Color)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _exercises[i]['name'],
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.white60,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              exercise['description'],
              style: const TextStyle(color: Colors.white60, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 10),

          // Round indicator
          if (_isRunning)
            Text(
              'Round $_currentRound of ${exercise['rounds']}',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),

          const Spacer(),

          // ✅ Breathing circle animation
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) {
              return Container(
                width: 200 * _scaleAnim.value + 60,
                height: 200 * _scaleAnim.value + 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.15),
                  border: Border.all(
                      color: color.withOpacity(0.5), width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: _isCompleted
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: color, size: 50),
                      const SizedBox(height: 8),
                      Text(
                        'Complete!',
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                      : _isRunning
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        steps[_currentStep],
                        style: TextStyle(
                          color: color,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_secondsLeft',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  )
                      : Text(
                    'Tap Start',
                    style: TextStyle(
                      color: color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),

          const Spacer(),

          // ✅ Step indicators
          if (_isRunning)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(steps.length, (i) {
                  return Column(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: i == _currentStep ? 40 : 30,
                        height: i == _currentStep ? 40 : 30,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _currentStep
                              ? color
                              : color.withOpacity(0.2),
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        steps[i],
                        style: TextStyle(
                          color: i == _currentStep
                              ? color
                              : Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),

          const SizedBox(height: 30),

          // ✅ Start / Stop button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: _isCompleted
                ? Column(
              children: [
                // Completion message
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Session saved! Great job! 🎉',
                          style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _isCompleted = false;
                    _currentStep = 0;
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            )
                : ElevatedButton(
              onPressed:
              _isRunning ? _stopExercise : _startExercise,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                _isRunning ? Colors.red.shade800 : color,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                _isRunning ? 'Stop' : 'Start',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}