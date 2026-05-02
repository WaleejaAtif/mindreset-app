import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

enum BreathingState { idle, inhale, hold, exhale, encouraging, talking }

const List<Map<String, dynamic>> kExercises = [
  {
    'name': 'Box',
    'fullName': 'Box Breathing',
    'description': 'Inhale 4s, hold 4s, exhale 4s, hold 4s',
    'steps': ['Inhale', 'Hold', 'Exhale', 'Hold'],
    'durations': [4, 4, 4, 4],
    'color': Color(0xFF65C7F7),
    'rounds': 4,
    'icon': Icons.crop_square_rounded,
  },
  {
    'name': '4-7-8',
    'fullName': '4-7-8 Breathing',
    'description': 'Inhale 4s, hold 7s, exhale 8s',
    'steps': ['Inhale', 'Hold', 'Exhale'],
    'durations': [4, 7, 8],
    'color': Color(0xFF8A7CFF),
    'rounds': 3,
    'icon': Icons.timelapse_rounded,
  },
  {
    'name': 'Deep',
    'fullName': 'Deep Breathing',
    'description': 'Inhale 5s, exhale 5s',
    'steps': ['Inhale', 'Exhale'],
    'durations': [5, 5],
    'color': Color(0xFF59D99D),
    'rounds': 5,
    'icon': Icons.air_rounded,
  },
];

const _inhaleMsg = [
  'Breathe in slowly.',
  'Fill your lungs gently.',
  'Let the breath arrive.',
];
const _exhaleMsg = [
  'Release the tension.',
  'Let the breath leave slowly.',
  'Soften your shoulders.',
];
const _holdMsg = [
  'Hold it gently.',
  'Stay steady.',
  'You are doing well.',
];
const _doneMsg = [
  'Session complete. Notice the calm.',
  'Beautiful work. Keep this pace with you.',
  'You finished the reset.',
];
const _stopMsg = [
  'Pause is okay. Come back when you are ready.',
  'Take one easy breath before you leave.',
  'You can restart with a softer pace.',
];

class VideoManager {
  final Map<BreathingState, VideoPlayerController> _controllers = {};
  final Map<BreathingState, Future<VideoPlayerController>> _loading = {};

  VideoPlayerController? _activeCtrl;
  BreathingState _currentState = BreathingState.idle;
  bool _isInitialized = false;

  String _assetFor(BreathingState state) {
    switch (state) {
      case BreathingState.idle:
        return 'assets/videos/idle.mp4';
      case BreathingState.inhale:
        return 'assets/videos/inhale.mp4';
      case BreathingState.hold:
        return 'assets/videos/hold.mp4';
      case BreathingState.exhale:
        return 'assets/videos/exhale.mp4';
      case BreathingState.talking:
        return 'assets/videos/talking.mp4';
      case BreathingState.encouraging:
        return 'assets/videos/encouraging.mp4';
    }
  }

  bool _shouldLoop(BreathingState state) {
    return state == BreathingState.idle ||
        state == BreathingState.hold ||
        state == BreathingState.talking;
  }

  Future<VideoPlayerController> _controllerFor(BreathingState state) async {
    final existing = _controllers[state];
    if (existing != null && existing.value.isInitialized) return existing;

    final pending = _loading[state];
    if (pending != null) return pending;

    final future = () async {
      final controller = VideoPlayerController.asset(_assetFor(state));
      _controllers[state] = controller;
      await controller.initialize();
      await controller.setLooping(_shouldLoop(state));
      return controller;
    }();

    _loading[state] = future;
    try {
      return await future;
    } finally {
      _loading.remove(state);
    }
  }

  Future<void> initialize() async {
    await _switchTo(BreathingState.idle);
    _isInitialized = true;
  }

  Future<void> preloadBreathingClips() async {
    await Future.wait([
      _controllerFor(BreathingState.inhale),
      _controllerFor(BreathingState.hold),
      _controllerFor(BreathingState.exhale),
    ]);
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
    _activeCtrl = await _controllerFor(state);
    await _activeCtrl?.seekTo(Duration.zero);
    await _activeCtrl?.play();
  }

  Future<void> pause() async => _activeCtrl?.pause();
  Future<void> resume() async => _activeCtrl?.play();

  Future<void> dispose() async {
    for (final controller in _controllers.values) {
      await controller.dispose();
    }
    _controllers.clear();
  }
}

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with TickerProviderStateMixin {
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

  late AnimationController _pulseCtrl;
  late AnimationController _speechCtrl;
  late Animation<double> _pulseAnim;
  late Animation<double> _speechAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _speechCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _pulseAnim = Tween<double>(begin: 0.96, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _speechAnim = CurvedAnimation(parent: _speechCtrl, curve: Curves.easeOut);
    _initVideoManager();
  }

  Future<void> _initVideoManager() async {
    if (!mounted) return;
    setState(() {
      _videoLoading = true;
      _videoReady = false;
    });

    await _videoManager?.dispose();
    _videoManager = VideoManager();

    try {
      await _videoManager!.initialize();
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoReady = true;
      });
      unawaited(_videoManager!.preloadBreathingClips());
    } catch (e) {
      debugPrint('Video init error: $e');
      if (!mounted) return;
      setState(() {
        _videoLoading = false;
        _videoReady = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bubbleTimer?.cancel();
    _videoManager?.dispose();
    _pulseCtrl.dispose();
    _speechCtrl.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _current => kExercises[_selectedExercise];

  double get _overallProgress {
    if (!_isRunning) return _isCompleted ? 1 : 0;
    final durations = _current['durations'] as List<int>;
    final rounds = _current['rounds'] as int;
    final totalSeconds =
        durations.fold<int>(0, (total, value) => total + value) * rounds;
    final completedRounds = (_currentRound - 1).clamp(0, rounds);
    final completedInRound = durations
        .take(_currentStep)
        .fold<int>(0, (total, value) => total + value);
    final currentDuration = durations[_currentStep];
    final elapsedInStep =
        (currentDuration - _secondsLeft).clamp(0, currentDuration);
    final elapsed = completedRounds *
            durations.fold<int>(0, (total, value) => total + value) +
        completedInRound +
        elapsedInStep;
    return (elapsed / totalSeconds).clamp(0, 1);
  }

  double get _stepProgress {
    if (!_isRunning) return 0;
    final durations = _current['durations'] as List<int>;
    return 1 - (_secondsLeft / durations[_currentStep]);
  }

  Color _stepColor(String step) {
    if (step == 'Inhale') return const Color(0xFF65C7F7);
    if (step == 'Exhale') return const Color(0xFF59D99D);
    if (step == 'Hold') return const Color(0xFFFFD166);
    return _current['color'] as Color;
  }

  void _showBubbleText(String text) {
    _bubbleTimer?.cancel();
    setState(() {
      _bubbleText = text;
      _showBubble = true;
    });
    _speechCtrl.forward(from: 0);
    _bubbleTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      _speechCtrl.reverse().then((_) {
        if (mounted) setState(() => _showBubble = false);
      });
    });
  }

  Future<void> _animateForStep(String step) async {
    if (step == 'Inhale') {
      await _videoManager?.switchTo(BreathingState.inhale);
      final messages = List<String>.from(_inhaleMsg)..shuffle();
      _showBubbleText(messages.first);
    } else if (step == 'Exhale') {
      await _videoManager?.switchTo(BreathingState.exhale);
      final messages = List<String>.from(_exhaleMsg)..shuffle();
      _showBubbleText(messages.first);
    } else {
      await _videoManager?.switchTo(BreathingState.hold);
      final messages = List<String>.from(_holdMsg)..shuffle();
      _showBubbleText(messages.first);
    }
    if (mounted) setState(() {});
  }

  void _startExercise() {
    final durations = _current['durations'] as List<int>;
    setState(() {
      _isRunning = true;
      _isPaused = false;
      _isCompleted = false;
      _currentStep = 0;
      _currentRound = 1;
      _secondsLeft = durations.first;
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
    _animateForStep(steps[_currentStep]);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        timer.cancel();
        _nextStep();
      }
    });
  }

  void _nextStep() {
    final durations = _current['durations'] as List<int>;
    final steps = _current['steps'] as List<String>;
    final totalRounds = _current['rounds'] as int;
    var nextStep = _currentStep + 1;

    if (nextStep >= steps.length) {
      nextStep = 0;
      final nextRound = _currentRound + 1;
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
    final messages = List<String>.from(_doneMsg)..shuffle();
    _showBubbleText(messages.first);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meditation_logs')
          .add({
        'category': 'breathing',
        'exercise': _current['fullName'] ?? _current['name'],
        'completed': true,
        'date': dateKey,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'totalBreathingSessions': FieldValue.increment(1),
      }, SetOptions(merge: true));
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
    final messages = List<String>.from(_stopMsg)..shuffle();
    _showBubbleText(messages.first);

    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;
      await _videoManager?.switchTo(BreathingState.idle);
      setState(() {});
    });

    Future.delayed(const Duration(milliseconds: 500), () {
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
    if (mounted) setState(() {});
  }

  void _showCompletionDialog() {
    final color = _current['color'] as Color;
    final messages = List<String>.from(_doneMsg)..shuffle();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BreathingDialog(
        message: messages.first,
        color: color,
        title: 'Session complete',
        primaryLabel: 'Continue',
        onPrimary: () {
          Navigator.pop(context);
          _resetExercise();
        },
      ),
    );
  }

  void _showMidwayDialog() {
    final messages = List<String>.from(_stopMsg)..shuffle();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BreathingDialog(
        message: messages.first,
        color: const Color(0xFFFFB86B),
        title: 'Keep it gentle',
        primaryLabel: 'Try again',
        secondaryLabel: 'Maybe later',
        onPrimary: () {
          Navigator.pop(context);
          _startExercise();
        },
        onSecondary: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercise = _current;
    final color = exercise['color'] as Color;
    final steps = exercise['steps'] as List<String>;
    final stepName = _isRunning ? steps[_currentStep] : 'Ready';
    final ctrl = _videoManager?.activeController;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildBackground(color),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    18,
                    10,
                    18,
                    18 + MediaQuery.of(context).padding.bottom,
                  ),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight - 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAppBar(),
                        const SizedBox(height: 18),
                        _buildHeader(exercise, color),
                        const SizedBox(height: 16),
                        _buildExerciseTabs(),
                        const SizedBox(height: 16),
                        _buildStage(ctrl, color, stepName),
                        const SizedBox(height: 16),
                        _buildProgressPanel(exercise, color, steps, stepName),
                        const SizedBox(height: 16),
                        _buildButtons(color),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color color) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2C1A4D),
              Color(0xFF150E28),
              Color(0xFF0D0B1A),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/images/theme_bg.png',
                fit: BoxFit.cover,
                opacity: const AlwaysStoppedAnimation<double>(0.12),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.18, -0.34),
                    radius: 0.86,
                    colors: [
                      color.withValues(alpha: 0.28),
                      const Color(0xFF5ED8C6).withValues(alpha: 0.14),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.42, 1],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF07131F).withValues(alpha: 0.06),
                      const Color(0xFF07131F).withValues(alpha: 0.42),
                      const Color(0xFF040B12).withValues(alpha: 0.86),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        _glassIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
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
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ),
        _glassIconButton(
          icon: Icons.refresh_rounded,
          onTap: _resetExercise,
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> exercise, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.35)),
                ),
                child: Icon(exercise['icon'] as IconData, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise['fullName'] as String,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      exercise['description'] as String,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.76),
                        fontSize: 13,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTabs() {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: kExercises.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final exercise = kExercises[index];
          final selected = index == _selectedExercise;
          final tabColor = exercise['color'] as Color;

          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: _isRunning
                ? null
                : () => setState(() {
                      _selectedExercise = index;
                      _isCompleted = false;
                    }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 116,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected
                    ? tabColor.withValues(alpha: 0.86)
                    : Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.42)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    exercise['icon'] as IconData,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      exercise['name'] as String,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStage(
      VideoPlayerController? ctrl, Color color, String stepName) {
    final ringColor = _isRunning ? _stepColor(stepName) : color;

    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnim, _speechAnim]),
      builder: (context, _) {
        return Container(
          height: 376,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.18),
                const Color(0xFF5ED8C6).withValues(alpha: 0.12),
                const Color(0xFF06101B).withValues(alpha: 0.34),
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 252,
                  height: 252,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: ringColor.withValues(alpha: 0.34), width: 2),
                  ),
                ),
              ),
              Container(
                width: 214,
                height: 214,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.16)),
                ),
              ),
              if (_isRunning)
                SizedBox(
                  width: 236,
                  height: 236,
                  child: CircularProgressIndicator(
                    value: _stepProgress,
                    strokeWidth: 6,
                    strokeCap: StrokeCap.round,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(ringColor),
                  ),
                ),
              Positioned(
                top: 18,
                child: AnimatedOpacity(
                  opacity: _showBubble ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: ScaleTransition(
                    scale: _speechAnim,
                    child: _buildSpeechBubble(_bubbleText, ringColor),
                  ),
                ),
              ),
              Positioned(
                top: 84,
                child: _buildVideoPlayer(ctrl, color),
              ),
              Positioned(
                bottom: 26,
                child: Column(
                  children: [
                    Text(
                      stepName,
                      style: TextStyle(
                        color: _isRunning
                            ? ringColor
                            : Colors.white.withValues(alpha: 0.9),
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isRunning
                          ? '$_secondsLeft seconds'
                          : 'Choose a pace and begin',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildVideoPlayer(VideoPlayerController? ctrl, Color color) {
    Widget child;
    if (_videoLoading) {
      child = const Center(
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else if (!_videoReady || ctrl == null || !ctrl.value.isInitialized) {
      child = const Center(
        child:
            Icon(Icons.self_improvement_rounded, color: Colors.white, size: 76),
      );
    } else {
      child = ClipOval(
        child: ColoredBox(
          color: const Color(0xFF7FCFC4),
          child: FittedBox(
            fit: BoxFit.cover,
            alignment: Alignment.center,
            child: SizedBox(
              width: ctrl.value.size.width,
              height: ctrl.value.size.height,
              child: VideoPlayer(ctrl),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 192,
      height: 192,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          colors: [
            color.withValues(alpha: 0.95),
            const Color(0xFF8CE4DA),
            const Color(0xFFB7D8FF),
            color.withValues(alpha: 0.95),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5ED8C6).withValues(alpha: 0.26),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: color.withValues(alpha: 0.18),
            blurRadius: 40,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0A1724),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: ClipOval(child: child),
      ),
    );
  }

  Widget _buildSpeechBubble(String text, Color color) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF17213B).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.42)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.spa_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.25,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPanel(
    Map<String, dynamic> exercise,
    Color color,
    List<String> steps,
    String stepName,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isRunning
                      ? 'Round $_currentRound of ${exercise['rounds']}'
                      : '${exercise['rounds']} guided rounds',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                '${(_overallProgress * 100).round()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: _overallProgress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(steps.length, (index) {
              final active = _isRunning && index == _currentStep;
              final stepColor = _stepColor(steps[index]);
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 44,
                  margin:
                      EdgeInsets.only(right: index == steps.length - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: active
                        ? stepColor.withValues(alpha: 0.24)
                        : Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: active
                          ? stepColor.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      steps[index],
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: active
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.72),
                        fontSize: 12,
                        fontWeight: active ? FontWeight.w900 : FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(Color color) {
    if (_isCompleted) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.42)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: color),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Session saved. Nice reset.',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _primaryButton(
            color: color,
            icon: Icons.replay_rounded,
            label: 'Try Again',
            onPressed: _resetExercise,
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _primaryButton(
            color: _isPaused
                ? const Color(0xFFFFC857)
                : _isRunning
                    ? const Color(0xFFFF9F6E)
                    : color,
            icon: _isRunning
                ? (_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded)
                : Icons.play_arrow_rounded,
            label: _isRunning ? (_isPaused ? 'Resume' : 'Pause') : 'Start',
            onPressed: _isRunning ? _pauseResume : _startExercise,
          ),
        ),
        if (_isRunning) ...[
          const SizedBox(width: 12),
          SizedBox(
            width: 64,
            height: 58,
            child: FilledButton(
              onPressed: _stopMidway,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE85D75),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Icon(Icons.stop_rounded, color: Colors.white),
            ),
          ),
        ],
      ],
    );
  }

  Widget _primaryButton({
    required Color color,
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

class _BreathingDialog extends StatelessWidget {
  final String message;
  final Color color;
  final String title;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback? onSecondary;

  const _BreathingDialog({
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
    return Dialog(
      backgroundColor: const Color(0xFF14152C),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
                border: Border.all(color: color.withValues(alpha: 0.45)),
              ),
              child:
                  Icon(Icons.self_improvement_rounded, color: color, size: 38),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.74),
                fontSize: 14,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: onPrimary,
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18)),
                ),
                child: Text(
                  primaryLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (secondaryLabel != null) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: onSecondary,
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text(
                    secondaryLabel!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.74),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}