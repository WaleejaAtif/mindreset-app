import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ═══════════════════════════════════════════════
//  ENUMS
// ═══════════════════════════════════════════════

enum BreathingState { idle, inhale, hold, exhale, encouraging, talking }

// ═══════════════════════════════════════════════
//  EXERCISE CONFIG
// ═══════════════════════════════════════════════

const List<Map<String, dynamic>> kExercises = [
  {
    'name': 'Box Breathing',
    'description': 'Inhale 4s → Hold 4s → Exhale 4s → Hold 4s',
    'steps': ['Inhale', 'Hold', 'Exhale', 'Hold'],
    'durations': [4, 4, 4, 4],
    'color': Color(0xFF5B8DB8),
    'rounds': 4,
  },
  {
    'name': '4-7-8 Breathing',
    'description': 'Inhale 4s → Hold 7s → Exhale 8s',
    'steps': ['Inhale', 'Hold', 'Exhale'],
    'durations': [4, 7, 8],
    'color': Color(0xFF7B68EE),
    'rounds': 3,
  },
  {
    'name': 'Deep Breathing',
    'description': 'Inhale 5s → Exhale 5s',
    'steps': ['Inhale', 'Exhale'],
    'durations': [5, 5],
    'color': Color(0xFF48BB78),
    'rounds': 5,
  },
];

// ═══════════════════════════════════════════════
//  MESSAGES
// ═══════════════════════════════════════════════

const _inhaleMsg = [
  "Breathe in slowly... 🌬️",
  "Fill your lungs... ✨",
  "Take a deep breath... 💙",
];
const _exhaleMsg = [
  "Let it all out... 🍃",
  "Release the tension... 🌸",
  "Breathe out slowly... 💫",
];
const _holdMsg = [
  "Hold it gently... ⏸️",
  "Stay calm... 🕊️",
  "Almost there... 🌟",
];
const _doneMsg = [
  "Amazing! You're calmer now 🌸",
  "You did it! Feel the peace 💫",
  "Beautiful work! Stay relaxed 🌟",
];
const _stopMsg = [
  "Hey, don't stop now… you're doing great! 💪",
  "Come back and finish your session 💙",
  "Take a deep breath, you've got this 💫",
];

// ═══════════════════════════════════════════════
//  VIDEO MANAGER
// ═══════════════════════════════════════════════

class VideoManager {
  final String gender;
  VideoManager({required this.gender});

  VideoPlayerController? _idleCtrl;
  VideoPlayerController? _inhaleCtrl;
  VideoPlayerController? _holdCtrl;
  VideoPlayerController? _exhaleCtrl;
  VideoPlayerController? _talkingCtrl;
  VideoPlayerController? _encouragingCtrl;

  VideoPlayerController? _activeCtrl;
  BreathingState _currentState = BreathingState.idle;
  bool _isInitialized = false;

  String _prefix() => gender == 'girl' ? 'girl_' : '';

  Future<void> initialize() async {
    _idleCtrl = VideoPlayerController.asset(
        'assets/videos/${_prefix()}idle.mp4');
    _inhaleCtrl = VideoPlayerController.asset(
        'assets/videos/${_prefix()}inhale.mp4');
    _holdCtrl = VideoPlayerController.asset(
        'assets/videos/${_prefix()}hold.mp4');
    _exhaleCtrl = VideoPlayerController.asset(
        'assets/videos/${_prefix()}exhale.mp4');
    _talkingCtrl = VideoPlayerController.asset(
        'assets/videos/${_prefix()}talking.mp4');
    _encouragingCtrl = VideoPlayerController.asset(
        'assets/videos/${_prefix()}encouraging.mp4');

    await Future.wait([
      _idleCtrl!.initialize(),
      _inhaleCtrl!.initialize(),
      _holdCtrl!.initialize(),
      _exhaleCtrl!.initialize(),
      _talkingCtrl!.initialize(),
      _encouragingCtrl!.initialize(),
    ]);

    await _idleCtrl!.setLooping(true);
    await _talkingCtrl!.setLooping(true);
    await _switchTo(BreathingState.idle);
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;
  VideoPlayerController? get activeController => _activeCtrl;
  BreathingState get currentState => _currentState;

  Future<void> switchTo(BreathingState state) async {
    if (_currentState == state) return;
    await _switchTo(state);
  }

  Future<void> _switchTo(BreathingState state) async {
    await _activeCtrl?.pause();
    _currentState = state;

    switch (state) {
      case BreathingState.idle:
        _activeCtrl = _idleCtrl;
        await _activeCtrl?.setLooping(true);
        break;
      case BreathingState.inhale:
        _activeCtrl = _inhaleCtrl;
        await _activeCtrl?.setLooping(false);
        break;
      case BreathingState.hold:
        _activeCtrl = _holdCtrl;
        await _activeCtrl?.setLooping(true);
        break;
      case BreathingState.exhale:
        _activeCtrl = _exhaleCtrl;
        await _activeCtrl?.setLooping(false);
        break;
      case BreathingState.talking:
        _activeCtrl = _talkingCtrl;
        await _activeCtrl?.setLooping(true);
        break;
      case BreathingState.encouraging:
        _activeCtrl = _encouragingCtrl;
        await _activeCtrl?.setLooping(false);
        break;
    }

    await _activeCtrl?.seekTo(Duration.zero);
    await _activeCtrl?.play();
  }

  Future<void> pause() async => await _activeCtrl?.pause();
  Future<void> resume() async => await _activeCtrl?.play();

  Future<void> dispose() async {
    await _idleCtrl?.dispose();
    await _inhaleCtrl?.dispose();
    await _holdCtrl?.dispose();
    await _exhaleCtrl?.dispose();
    await _talkingCtrl?.dispose();
    await _encouragingCtrl?.dispose();
  }
}

// ═══════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {

  String _gender = 'boy';
  bool _genderSelected = false;

  VideoManager? _videoManager;
  bool _videoLoading = false;
  bool _videoReady = false;

  int _selectedExercise = 0;
  bool _isRunning = false;
  bool _isCompleted = false;
  bool _isPaused = false;
  int _currentStep = 0;
  int _secondsLeft = 0;
  int _currentRound = 0;
  Timer? _timer;

  String _bubbleText = '';
  bool _showBubble = false;
  Timer? _bubbleTimer;

  // ✅ Only animation controllers needed for UI effects
  // (no character animation controllers anymore)
  late AnimationController _pulseCtrl;
  late AnimationController _speechCtrl;
  late AnimationController _progressCtrl;

  late Animation<double> _pulseAnim;
  late Animation<double> _speechAnim;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadGenderFromFirestore();
  }

  void _initAnimations() {
    // ✅ Pulse ring around video
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    // ✅ Speech bubble fade in/out
    _speechCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _speechAnim =
        CurvedAnimation(parent: _speechCtrl, curve: Curves.easeOut);

    // ✅ Progress smooth update
    _progressCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1));
  }

  Future<void> _loadGenderFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final gender = doc.data()?['gender']?.toString().toLowerCase();
      if (gender != null && mounted) {
        setState(() {
          _gender = gender == 'female' ? 'girl' : 'boy';
          _genderSelected = true;
        });
        _initVideoManager();
      }
    } catch (e) {
      debugPrint('Gender error: $e');
    }
  }

  Future<void> _initVideoManager() async {
    if (!mounted) return;
    setState(() {
      _videoLoading = true;
      _videoReady = false;
    });

    await _videoManager?.dispose();
    _videoManager = VideoManager(gender: _gender);

    try {
      await _videoManager!.initialize();
      if (mounted) {
        setState(() {
          _videoLoading = false;
          _videoReady = true;
        });
      }
    } catch (e) {
      debugPrint('Video init error: $e');
      if (mounted) {
        setState(() {
          _videoLoading = false;
          _videoReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bubbleTimer?.cancel();
    _videoManager?.dispose();
    _pulseCtrl.dispose();
    _speechCtrl.dispose();
    _progressCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _current => kExercises[_selectedExercise];

  void _showBubbleText(String text) {
    _bubbleTimer?.cancel();
    setState(() {
      _bubbleText = text;
      _showBubble = true;
    });
    _speechCtrl.forward(from: 0);
    _bubbleTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      _speechCtrl.reverse().then((_) {
        if (mounted) setState(() => _showBubble = false);
      });
    });
  }

  Future<void> _animateForStep(String step, int duration) async {
    if (step == 'Inhale') {
      await _videoManager?.switchTo(BreathingState.inhale);
      final m = List.from(_inhaleMsg)..shuffle();
      _showBubbleText(m.first);
    } else if (step == 'Exhale') {
      await _videoManager?.switchTo(BreathingState.exhale);
      final m = List.from(_exhaleMsg)..shuffle();
      _showBubbleText(m.first);
    } else if (step == 'Hold') {
      await _videoManager?.switchTo(BreathingState.hold);
      final m = List.from(_holdMsg)..shuffle();
      _showBubbleText(m.first);
    }
    if (mounted) setState(() {});
  }

  // ── All breathing logic unchanged ──────────────────
  void _startExercise() {
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _isCompleted = false;
      _currentStep = 0;
      _currentRound = 1;
      _secondsLeft = (_current['durations'] as List<int>)[0];
    });
    _runStep();
  }

  void _pauseResume() async {
    if (_isPaused) {
      await _videoManager?.resume();
      setState(() => _isPaused = false);
      _runStep();
    } else {
      _timer?.cancel();
      await _videoManager?.pause();
      setState(() => _isPaused = true);
    }
  }

  void _runStep() {
    final steps = _current['steps'] as List<String>;
    final durations = _current['durations'] as List<int>;
    _animateForStep(steps[_currentStep], durations[_currentStep]);
    _timer?.cancel();
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
      nextStep = 0;
      int nextRound = _currentRound + 1;
      if (nextRound > totalRounds) {
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

  Future<void> _onComplete() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = true;
      _isPaused = false;
    });

    await _videoManager?.switchTo(BreathingState.talking);
    setState(() {});

    final m = List.from(_doneMsg)..shuffle();
    _showBubbleText(m.first);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final today = DateTime.now();
      final dateKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meditation_logs')
          .add({
        'category': 'breathing',
        'exercise': _current['name'],
        'completed': true,
        'date': dateKey,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({'totalBreathingSessions': FieldValue.increment(1)},
              SetOptions(merge: true));
    }

    if (mounted) _showCompletionDialog();
  }

  Future<void> _stopMidway() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _isPaused = false;
      _currentStep = 0;
      _currentRound = 0;
    });

    await _videoManager?.switchTo(BreathingState.encouraging);
    setState(() {});

    final m = List.from(_stopMsg)..shuffle();
    _showBubbleText(m.first);

    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        await _videoManager?.switchTo(BreathingState.idle);
        setState(() {});
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _showMidwayDialog();
    });
  }

  Future<void> _resetExercise() async {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isCompleted = false;
      _isPaused = false;
      _currentStep = 0;
      _currentRound = 0;
    });
    await _videoManager?.switchTo(BreathingState.idle);
    setState(() {});
  }

  double get _progress {
    if (!_isRunning) return 0;
    final durations = _current['durations'] as List<int>;
    return 1.0 - (_secondsLeft / durations[_currentStep]);
  }

  Color _stepColor(String step) {
    if (step == 'Inhale') return Colors.lightBlueAccent;
    if (step == 'Exhale') return Colors.greenAccent;
    if (step == 'Hold') return Colors.amberAccent;
    return _current['color'] as Color;
  }

  // ── Dialogs ────────────────────────────────────────
  void _showCompletionDialog() {
    final color = _current['color'] as Color;
    final m = List.from(_doneMsg)..shuffle();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VideoDialog(
        videoManager: _videoManager,
        message: m.first,
        color: color,
        title: 'Session Complete! 🎉',
        primaryLabel: 'Continue',
        onPrimary: () {
          Navigator.pop(context);
          _resetExercise();
        },
      ),
    );
  }

  void _showMidwayDialog() {
    final m = List.from(_stopMsg)..shuffle();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _VideoDialog(
        videoManager: _videoManager,
        message: m.first,
        color: Colors.orange,
        title: "Don't give up! 💙",
        primaryLabel: 'Try Again 🌿',
        secondaryLabel: 'Maybe Later',
        onPrimary: () {
          Navigator.pop(context);
          _startExercise();
        },
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  // ── Gender selection ───────────────────────────────
  Widget _buildGenderSelection() {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF1A1333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Breathing Exercise',
            style: TextStyle(
                color: Color(0xFF1A1333), fontWeight: FontWeight.bold)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D0D1A),
              Color(0xFF1A1A3E),
              Color(0xFF0D1A2E),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),
              const Text('Choose Your Guide',
                  style: TextStyle(
                      color: Color(0xFF1A1333),
                      fontSize: 28,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Pick a character to guide your breathing',
                style: TextStyle(color: Color(0x8AFFFFFF), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGenderCard('boy', '🧘‍♂️', 'Male',
                      const Color(0xFF5B8DB8), 'Calm & focused'),
                  _buildGenderCard('girl', '🧘‍♀️', 'Female',
                      const Color(0xFFB57BEE), 'Peaceful & mindful'),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ElevatedButton(
                  onPressed: () async {
                    setState(() => _genderSelected = true);
                    await _initVideoManager();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gender == 'girl'
                        ? const Color(0xFFB57BEE)
                        : const Color(0xFF5B8DB8),
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    'Continue with ${_gender == 'girl' ? 'Female 🧘‍♀️' : 'Male 🧘‍♂️'}',
                    style: const TextStyle(
                        color: Color(0xFF1A1333),
                        fontSize: 17,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGenderCard(String gender, String emoji, String label,
      Color color, String description) {
    final isSelected = _gender == gender;
    return GestureDetector(
      onTap: () => setState(() => _gender = gender),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 155,
        height: 220,
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.18)
              : Color(0xFF1A1333).withOpacity(0.05),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: isSelected ? color : Color(0x3DFFFFFF),
              width: isSelected ? 2.5 : 1),
          boxShadow: isSelected
              ? [BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 24,
                  spreadRadius: 4)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 70)),
            const SizedBox(height: 12),
            Text(label,
                style: TextStyle(
                    color: isSelected ? color : Color(0xB3FFFFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            Text(description,
                style: const TextStyle(
                    color: Color(0x61FFFFFF), fontSize: 11)),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(Icons.check_circle, color: color, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  MAIN BUILD
  // ═══════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (!_genderSelected) return _buildGenderSelection();

    final exercise = _current;
    final color = exercise['color'] as Color;
    final steps = exercise['steps'] as List<String>;
    final stepName = _isRunning ? steps[_currentStep] : 'Ready';
    final ctrl = _videoManager?.activeController;

    return Scaffold(
      backgroundColor: Color(0xFFFFFFFF),
      body: Stack(
        children: [

          // ✅ LAYER 1: Blurred video as full-screen background
          // This creates the immersive look — same video, blurred
          if (_videoReady && ctrl != null && ctrl.value.isInitialized)
            Positioned.fill(
              child: Stack(
                children: [
                  // Scaled-up blurred video background
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: ctrl.value.size.width,
                        height: ctrl.value.size.height,
                        child: VideoPlayer(ctrl),
                      ),
                    ),
                  ),
                  // ✅ Dark + blur overlay so text is readable
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFFFFFF).withOpacity(0.55),
                            Color(0xFFFFFFFF).withOpacity(0.35),
                            Color(0xFFFFFFFF).withOpacity(0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Fallback gradient when video not ready
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0D0D1A),
                      color.withOpacity(0.3),
                      const Color(0xFF0D1A2E),
                    ],
                  ),
                ),
              ),
            ),

          // ✅ LAYER 2: All UI on top
          SafeArea(
            child: Column(
              children: [

                // ── AppBar ─────────────────────────────
                _buildAppBar(color),

                // ── Exercise tabs ──────────────────────
                _buildExerciseTabs(),

                const SizedBox(height: 4),
                Text(exercise['description'],
                    style: const TextStyle(
                        color: Color(0x99FFFFFF), fontSize: 11),
                    textAlign: TextAlign.center),

                if (_isRunning)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Round $_currentRound of ${exercise['rounds']}',
                      style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),

                const Spacer(),

                // ── VIDEO AREA ─────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge(
                      [_pulseAnim, _speechAnim]),
                  builder: (context, _) {
                    return SizedBox(
                      height: 370,
                      child: Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [

                          // ✅ Pulse ring
                          Transform.scale(
                            scale: _pulseAnim.value,
                            child: Container(
                              width: 260,
                              height: 260,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: color.withOpacity(0.25),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),

                          // ✅ Inner glow circle
                          Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: color.withOpacity(0.15),
                                width: 1,
                              ),
                              boxShadow: _isRunning
                                  ? [
                                      BoxShadow(
                                        color: color.withOpacity(0.2),
                                        blurRadius: 40,
                                        spreadRadius: 10,
                                      )
                                    ]
                                  : [],
                            ),
                          ),

                          // ✅ Circular progress ring
                          if (_isRunning)
                            SizedBox(
                              width: 238,
                              height: 238,
                              child: CircularProgressIndicator(
                                value: _progress,
                                strokeWidth: 4,
                                backgroundColor:
                                    color.withOpacity(0.15),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        _stepColor(stepName)
                                            .withOpacity(0.9)),
                              ),
                            ),

                          // ✅ VIDEO PLAYER — centered, clipped circle
                          _buildVideoPlayer(ctrl),

                          // ✅ SPEECH BUBBLE on top
                          if (_showBubble)
                            Positioned(
                              top: 8,
                              child: FadeTransition(
                                opacity: _speechAnim,
                                child: ScaleTransition(
                                  scale: _speechAnim,
                                  alignment: Alignment.bottomCenter,
                                  child: _buildSpeechBubble(
                                      _bubbleText, color),
                                ),
                              ),
                            ),

                          // ✅ Step name + timer
                          Positioned(
                            bottom: 0,
                            child: Column(
                              children: [
                                AnimatedSwitcher(
                                  duration: const Duration(
                                      milliseconds: 300),
                                  child: Text(
                                    stepName,
                                    key: ValueKey(stepName),
                                    style: TextStyle(
                                      color: _isRunning
                                          ? _stepColor(stepName)
                                          : Color(0xB3FFFFFF),
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 4,
                                      shadows: [
                                        Shadow(
                                          color: Color(0xFFFFFFFF)
                                              .withOpacity(0.5),
                                          blurRadius: 8,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                                if (_isRunning)
                                  AnimatedSwitcher(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    child: Text(
                                      '$_secondsLeft s',
                                      key: ValueKey(_secondsLeft),
                                      style: TextStyle(
                                        color: Color(0xFF1A1333),
                                        fontSize: 42,
                                        fontWeight: FontWeight.w900,
                                        shadows: [
                                          Shadow(
                                            color: Color(0xFFFFFFFF)
                                                .withOpacity(0.5),
                                            blurRadius: 8,
                                          )
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
                  },
                ),

                const Spacer(),

                // ── Step indicators ────────────────────
                if (_isRunning) _buildStepIndicators(steps),

                const SizedBox(height: 20),

                // ── Buttons ────────────────────────────
                _buildButtons(color),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Immersive AppBar — transparent, no background
  Widget _buildAppBar(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Back button with frosted glass effect
          _glassButton(
            child: const Icon(Icons.arrow_back_ios,
                color: Color(0xFF1A1333), size: 18),
            onTap: () {
              _timer?.cancel();
              Navigator.pop(context);
            },
          ),
          const Expanded(
            child: Text(
              'Breathing Exercise',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF1A1333),
                fontWeight: FontWeight.bold,
                fontSize: 17,
                shadows: [
                  Shadow(color: Color(0xFFAFA8BA), blurRadius: 6),
                ],
              ),
            ),
          ),
          // Gender switch — frosted glass
          _glassButton(
            child: Text(
              _gender == 'girl' ? '🧘‍♀️' : '🧘‍♂️',
              style: const TextStyle(fontSize: 20),
            ),
            onTap: () async {
              setState(() => _genderSelected = false);
              await _resetExercise();
            },
          ),
        ],
      ),
    );
  }

  // ✅ Frosted glass button helper
  Widget _glassButton(
      {required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Color(0xFF1A1333).withOpacity(0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Color(0xFF1A1333).withOpacity(0.2)),
        ),
        child: child,
      ),
    );
  }

  // ✅ Exercise tabs with glass style
  Widget _buildExerciseTabs() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: kExercises.length,
        itemBuilder: (context, i) {
          final selected = i == _selectedExercise;
          final tabColor = kExercises[i]['color'] as Color;
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
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected
                    ? tabColor.withOpacity(0.8)
                    : Color(0xFF1A1333).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? tabColor
                      : Color(0xFF1A1333).withOpacity(0.2),
                ),
              ),
              child: Text(
                kExercises[i]['name'],
                style: TextStyle(
                  color: selected ? Color(0xFF1A1333) : Color(0xB3FFFFFF),
                  fontWeight: selected
                      ? FontWeight.bold
                      : FontWeight.normal,
                  fontSize: 12,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ Video player — circular clipped
  Widget _buildVideoPlayer(VideoPlayerController? ctrl) {
    if (_videoLoading) {
      return Container(
        width: 210,
        height: 210,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1A1333).withOpacity(0.08),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0x8AFFFFFF)),
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (!_videoReady || ctrl == null || !ctrl.value.isInitialized) {
      // Clean fallback
      return Container(
        width: 210,
        height: 210,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF1A1333).withOpacity(0.08),
          border: Border.all(color: Color(0x3DFFFFFF)),
        ),
        child: Center(
          child: Text(
            _gender == 'girl' ? '🧘‍♀️' : '🧘‍♂️',
            style: const TextStyle(fontSize: 80),
          ),
        ),
      );
    }

    // ✅ Circular clipped video
    return ClipOval(
      child: SizedBox(
        width: 210,
        height: 210,
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: ctrl.value.size.width,
            height: ctrl.value.size.height,
            child: VideoPlayer(ctrl),
          ),
        ),
      ),
    );
  }

  // ✅ Speech bubble
  Widget _buildSpeechBubble(String text, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFFFFFFFF).withOpacity(0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 14,
              spreadRadius: 2),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_gender == 'girl' ? '🧘‍♀️' : '🧘‍♂️',
              style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Step indicators
  Widget _buildStepIndicators(List<String> steps) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(steps.length, (i) {
          final isActive = i == _currentStep;
          final sc = _stepColor(steps[i]);
          return Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 46 : 32,
                height: isActive ? 46 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive
                      ? sc.withOpacity(0.3)
                      : Color(0xFF1A1333).withOpacity(0.1),
                  border: Border.all(
                      color: isActive ? sc : Color(0x61FFFFFF),
                      width: 2),
                ),
                child: Center(
                  child: Text('${i + 1}',
                      style: TextStyle(
                          color: isActive ? sc : Color(0x8AFFFFFF),
                          fontWeight: FontWeight.bold,
                          fontSize: isActive ? 15 : 11)),
                ),
              ),
              const SizedBox(height: 4),
              Text(steps[i],
                  style: TextStyle(
                      color: isActive ? sc : Color(0x8AFFFFFF),
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.normal,
                      shadows: const [
                        Shadow(color: Color(0xFFAFA8BA), blurRadius: 4)
                      ])),
            ],
          );
        }),
      ),
    );
  }

  // ✅ Buttons
  Widget _buildButtons(Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: _isCompleted
          ? Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withOpacity(0.5)),
                ),
                child: Row(children: [
                  Icon(Icons.check_circle, color: color),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Session saved! Great job! 🎉',
                        style: TextStyle(
                            color: Color(0xFF1A1333),
                            fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _resetExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  minimumSize: const Size(double.infinity, 54),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Try Again',
                    style: TextStyle(
                        color: Color(0xFF1A1333),
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ])
          : Row(children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  onPressed:
                      _isRunning ? _pauseResume : _startExercise,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPaused
                        ? Colors.amber.withOpacity(0.9)
                        : _isRunning
                            ? Colors.orange.withOpacity(0.9)
                            : color,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isRunning
                            ? (_isPaused
                                ? Icons.play_arrow
                                : Icons.pause)
                            : Icons.play_arrow,
                        color: Color(0xFF1A1333),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isRunning
                            ? (_isPaused ? 'Resume' : 'Pause')
                            : 'Start',
                        style: const TextStyle(
                            color: Color(0xFF1A1333),
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              if (_isRunning) ...[
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _stopMidway,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.red.shade900.withOpacity(0.9),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child:
                        const Icon(Icons.stop, color: Color(0xFF1A1333)),
                  ),
                ),
              ],
            ]),
    );
  }
}

// ═══════════════════════════════════════════════
//  VIDEO DIALOG
// ═══════════════════════════════════════════════

class _VideoDialog extends StatelessWidget {
  final VideoManager? videoManager;
  final String message;
  final Color color;
  final String title;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _VideoDialog({
    required this.videoManager,
    required this.message,
    required this.color,
    required this.title,
    required this.primaryLabel,
    this.secondaryLabel,
    required this.onPrimary,
    this.onSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final ctrl = videoManager?.activeController;

    return Dialog(
      backgroundColor: Color(0xFFFFFFFF).withOpacity(0.85),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ Circular video in dialog
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 20,
                          spreadRadius: 5),
                    ],
                  ),
                ),
                ClipOval(
                  child: SizedBox(
                    width: 150,
                    height: 150,
                    child: ctrl != null && ctrl.value.isInitialized
                        ? FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: ctrl.value.size.width,
                              height: ctrl.value.size.height,
                              child: VideoPlayer(ctrl),
                            ),
                          )
                        : Container(
                            color: Color(0x1AFFFFFF),
                            child: const Center(
                              child: Text('😊',
                                  style: TextStyle(fontSize: 60)),
                            ),
                          ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5),
              ),
            ),

            const SizedBox(height: 14),

            Text(title,
                style: TextStyle(
                    color: Color(0xFF1A1333),
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(primaryLabel,
                  style: const TextStyle(
                      color: Color(0xFF1A1333),
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
            ),

            if (secondaryLabel != null) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onSecondary,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Color(0x3DFFFFFF)),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(secondaryLabel!,
                    style: const TextStyle(
                        color: Color(0x99FFFFFF), fontSize: 14)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

