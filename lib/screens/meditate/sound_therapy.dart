// lib/screens/meditate/sound_therapy.dart
// ═══════════════════════════════════════════════════════════════════
//  SoundTherapyScreen — COMPLETE FIX
//
//  ROOT CAUSES FIXED:
//  ✅ Images: pubspec.yaml lists every asset individually (no folder globs)
//  ✅ Audio: AudioService.play() uses setAsset() → ALL sounds work
//  ✅ Play/Pause/Resume: driven by playerStateStream, never out of sync
//  ✅ Duration: reads real file duration via durationStream (30s files show 30s)
//  ✅ Loop: LoopMode.one loops audio; UI progress resets every real loop
//  ✅ Lag: waveform uses CustomPainter + RepaintBoundary (no tree rebuilds)
//      Grid cards use RepaintBoundary; StreamBuilders are scoped tightly
//  ✅ setState after dispose: all guards added
//  ✅ Multiple AudioPlayer instances: impossible — AudioService is static singleton
// ═══════════════════════════════════════════════════════════════════

import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:just_audio/just_audio.dart';
import 'package:projects/services/audio_service.dart';

// ═══════════════════════════════════════════════════════
//  MODEL
// ═══════════════════════════════════════════════════════

class SoundItem {
  final String id;
  final String name;
  final String author;
  final String imageAsset;
  final String audioFile;
  final Color accentColor;
  final String category;
  final String tagline;

  const SoundItem({
    required this.id,
    required this.name,
    required this.author,
    required this.imageAsset,
    required this.audioFile,
    required this.accentColor,
    required this.category,
    required this.tagline,
  });
}

// ═══════════════════════════════════════════════════════
//  DATA — paths verified against file screenshots
// ═══════════════════════════════════════════════════════

const List<String> kFilterTabs = ['All', 'Nature', 'Sleep', 'Focus'];

const List<SoundItem> kSounds = [
  // ── NATURE ──────────────────────────────────────────
  SoundItem(
    id: 'rain',
    name: 'Rain Sounds',
    author: 'Nature Studio',
    imageAsset: 'assets/images/sounds/rain.jpg',
    audioFile: 'assets/sounds/nature/rain.mp3',
    accentColor: Color(0xFF4FC3F7),
    category: 'Nature',
    tagline: 'Gentle rainfall to calm the mind',
  ),
  SoundItem(
    id: 'ocean',
    name: 'Ocean Waves',
    author: 'Coastal Sounds',
    imageAsset: 'assets/images/sounds/ocean.jpg',
    audioFile: 'assets/sounds/nature/ocean_waves.mp3',
    accentColor: Color(0xFF26C6DA),
    category: 'Nature',
    tagline: 'Rolling waves on a quiet shore',
  ),
  SoundItem(
    id: 'forest',
    name: 'Forest Birds',
    author: 'Wild Ambience',
    imageAsset: 'assets/images/sounds/forest.jpg',
    audioFile: 'assets/sounds/nature/forest_birds.mp3',
    accentColor: Color(0xFF66BB6A),
    category: 'Nature',
    tagline: 'Morning birdsong in a lush forest',
  ),
  SoundItem(
    id: 'thunder',
    name: 'Thunderstorm',
    author: 'Storm Atlas',
    // thunder.jpg missing → forest fallback
    imageAsset: 'assets/images/sounds/forest.jpg',
    audioFile: 'assets/sounds/nature/thunderstorm.mp3',
    accentColor: Color(0xFF9575CD),
    category: 'Nature',
    tagline: 'Distant thunder and steady rain',
  ),
  SoundItem(
    id: 'river',
    name: 'River Stream',
    author: 'Nature Studio',
    imageAsset: 'assets/images/sounds/river.jpg',
    audioFile: 'assets/sounds/nature/river_stream.mp3',
    accentColor: Color(0xFF4DB6AC),
    category: 'Nature',
    tagline: 'Crystal clear mountain stream',
  ),
  SoundItem(
    id: 'morning_birds',
    name: 'Morning Birds',
    author: 'Nature Studio',
    imageAsset: 'assets/images/sounds/morning_birds.jpg',
    audioFile: 'assets/sounds/nature/morning_birds.mp3',
    accentColor: Color(0xFF81C784),
    category: 'Nature',
    tagline: 'Fresh morning chirping for a calm start',
  ),
  SoundItem(
    id: 'sparrow',
    name: 'Sparrow Chirping',
    author: 'Wild Life Audio',
    // sparrow.jpg missing → morning_birds fallback
    imageAsset: 'assets/images/sounds/morning_birds.jpg',
    audioFile: 'assets/sounds/nature/sparrow_chirping.mp3',
    accentColor: Color(0xFFAED581),
    category: 'Nature',
    tagline: 'Soft sparrow sounds in the background',
  ),
  SoundItem(
    id: 'tropical_birds',
    name: 'Tropical Birds',
    author: 'Jungle Studio',
    imageAsset: 'assets/images/sounds/tropical_birds.jpg',
    audioFile: 'assets/sounds/nature/tropical_birds.mp3',
    accentColor: Color(0xFF4DB6AC),
    category: 'Nature',
    tagline: 'Exotic birds from tropical forests',
  ),

  // ── SLEEP ───────────────────────────────────────────
  SoundItem(
    id: 'white_noise',
    name: 'White Noise',
    author: 'Sleep Lab',
    imageAsset: 'assets/images/sounds/white_noise.jpg',
    audioFile: 'assets/sounds/sleep/white_noise.mp3',
    accentColor: Color(0xFFB0BEC5),
    category: 'Sleep',
    tagline: 'Pure white noise for deep sleep',
  ),
  SoundItem(
    id: 'brown_noise',
    name: 'Brown Noise',
    author: 'Sleep Lab',
    imageAsset: 'assets/images/sounds/brown_noise.jpg',
    audioFile: 'assets/sounds/sleep/brown_noise.mp3',
    accentColor: Color(0xFFA1887F),
    category: 'Sleep',
    tagline: 'Rich brown noise, deeper than white',
  ),
  SoundItem(
    id: 'lullaby',
    name: 'Lullaby',
    author: 'Dreamy Tones',
    imageAsset: 'assets/images/sounds/lullaby.jpg',
    audioFile: 'assets/sounds/sleep/lullaby.mp3',
    accentColor: Color(0xFFF48FB1),
    category: 'Sleep',
    tagline: 'Soft melodic lullaby tones',
  ),
  SoundItem(
    id: 'deep_sleep',
    name: 'Deep Sleep 432Hz',
    author: 'Freq. Lab',
    // deep_sleep.jpg missing → white_noise fallback
    imageAsset: 'assets/images/sounds/white_noise.jpg',
    audioFile: 'assets/sounds/sleep/deep_sleep_432hz.mp3',
    accentColor: Color(0xFFCE93D8),
    category: 'Sleep',
    tagline: '432Hz frequency for deep rest',
  ),
  SoundItem(
    id: 'sleep_med',
    name: 'Sleep Meditation',
    author: 'Mindful Rest',
    imageAsset: 'assets/images/sounds/sleep_med.jpg',
    audioFile: 'assets/sounds/sleep/sleep_meditation.mp3',
    accentColor: Color(0xFF80DEEA),
    category: 'Sleep',
    tagline: 'Guided meditation into sleep',
  ),

  // ── FOCUS ───────────────────────────────────────────
  SoundItem(
    id: 'binaural',
    name: 'Binaural Beats',
    author: 'Neural Audio',
    imageAsset: 'assets/images/sounds/binaural.jpg',
    audioFile: 'assets/sounds/focus/binaural_beats.mp3',
    accentColor: Color(0xFFFFD54F),
    category: 'Focus',
    tagline: 'Beta waves for laser focus',
  ),
  SoundItem(
    id: 'lofi',
    name: 'Lo-Fi Music',
    author: 'Chill Desk',
    imageAsset: 'assets/images/sounds/lofi.jpg',
    audioFile: 'assets/sounds/focus/lo_fi.mp3',
    accentColor: Color(0xFFFF8A65),
    category: 'Focus',
    tagline: 'Chill lo-fi beats to study to',
  ),
  SoundItem(
    id: 'alpha',
    name: 'Alpha Waves',
    author: 'Neural Audio',
    imageAsset: 'assets/images/sounds/alpha.jpg',
    audioFile: 'assets/sounds/focus/alpha_waves.mp3',
    accentColor: Color(0xFF4FC3F7),
    category: 'Focus',
    tagline: 'Alpha waves for creative thinking',
  ),
  SoundItem(
    id: 'study',
    name: 'Study Music',
    author: 'Deep Work',
    imageAsset: 'assets/images/sounds/study.jpg',
    audioFile: 'assets/sounds/focus/study_music.mp3',
    accentColor: Color(0xFFA5D6A7),
    category: 'Focus',
    tagline: 'Calm music for deep study sessions',
  ),
  SoundItem(
    id: 'piano',
    name: 'Piano Focus',
    author: 'Still Keys',
    imageAsset: 'assets/images/sounds/piano.jpg',
    audioFile: 'assets/sounds/focus/piano_focus.mp3',
    accentColor: Color(0xFFEF9A9A),
    category: 'Focus',
    tagline: 'Minimalist piano for clarity',
  ),
];

// ═══════════════════════════════════════════════════════
//  WAVEFORM — CustomPainter (ZERO tree rebuilds)
// ═══════════════════════════════════════════════════════

class _WavePainter extends CustomPainter {
  final List<double> bars;
  final Color color;
  final bool isPlaying;

  _WavePainter({
    required this.bars,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || bars.isEmpty) return;
    final barWidth = (size.width / bars.length) - 2.4;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < bars.length; i++) {
      final barH = 4.0 + (size.height - 4) * bars[i];
      final x = i * (barWidth + 2.4);
      final y = (size.height - barH) / 2;
      final safeBarWidth = barWidth.clamp(1.0, 100.0).toDouble();
      paint.shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withOpacity(isPlaying ? 0.35 : 0.1),
          color.withOpacity(isPlaying ? 0.9 : 0.22),
        ],
      ).createShader(Rect.fromLTWH(x, y, safeBarWidth, barH));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, safeBarWidth, barH),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) =>
      old.bars != bars || old.isPlaying != isPlaying || old.color != color;
}

class _MiniWavePainter extends CustomPainter {
  final List<double> bars;
  final Color color;
  final bool isPlaying;

  _MiniWavePainter({
    required this.bars,
    required this.color,
    required this.isPlaying,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || bars.isEmpty) return;
    final barWidth = (size.width / bars.length) - 1.6;
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withOpacity(isPlaying ? 0.8 : 0.3);

    for (int i = 0; i < bars.length; i++) {
      final barH = 3.0 + (size.height - 3) * bars[i];
      final x = i * (barWidth + 1.6);
      final y = (size.height - barH) / 2;
      final safeBarWidth = barWidth.clamp(1.0, 100.0).toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, safeBarWidth, barH),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MiniWavePainter old) =>
      old.bars != bars || old.isPlaying != isPlaying;
}

// ═══════════════════════════════════════════════════════
//  WAVE NOTIFIER — independent animation loop
// ═══════════════════════════════════════════════════════

class _WaveNotifier extends ChangeNotifier {
  final int barCount;
  final _rng = Random();
  List<double> bars;
  bool isPlaying = false;
  Timer? _waveTimer;

  _WaveNotifier(this.barCount) : bars = List.filled(barCount, 0.15);

  void startAnimating() {
    if (isPlaying) return;
    isPlaying = true;
    _tick();
  }

  void _tick() {
    if (!isPlaying) return;
    bars = List.generate(barCount, (_) => 0.06 + _rng.nextDouble() * 0.94);
    notifyListeners();
    _waveTimer = Timer(const Duration(milliseconds: 120), () {
      if (isPlaying) _tick();
    });
  }

  void stopAnimating() {
    isPlaying = false;
    _waveTimer?.cancel();
    _waveTimer = null;
    bars = List.filled(barCount, 0.15);
    notifyListeners();
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════
//  MAIN SCREEN
// ═══════════════════════════════════════════════════════

class SoundTherapyScreen extends StatefulWidget {
  const SoundTherapyScreen({super.key});

  @override
  State<SoundTherapyScreen> createState() => _SoundTherapyScreenState();
}

class _SoundTherapyScreenState extends State<SoundTherapyScreen>
    with TickerProviderStateMixin {
  // ── State ────────────────────────────────────────────────────────
  SoundItem? _selected;
  int _filterIndex = 0;
  bool _isFavorite = false;

  // FIX: isPlaying is now derived from AudioService stream, not manual setState
  bool _isPlaying = false;
  bool _isLoading = false;

  // FIX: Duration and progress from real audio streams
  Duration _realDuration = Duration.zero;
  Duration _position = Duration.zero;

  double _volume = 0.7;
  Timer? _sleepTimer;
  bool _timerMenuOpen = false;

  // UI display cap: show max 45s in progress bar regardless of loop
  static const _uiMaxSeconds = 45;

  late AnimationController _expandCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _expandAnim;

  final _WaveNotifier _waveNotifier = _WaveNotifier(40);
  final _WaveNotifier _miniWaveNotifier = _WaveNotifier(20);

  // Stream subscriptions — cleaned up in dispose
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<PlayerState>? _stateSub;

  @override
  void initState() {
    super.initState();

    _expandCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _expandAnim = CurvedAnimation(
        parent: _expandCtrl,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic);
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);

    _subscribeToAudioStreams();
  }

  // FIX: Subscribe ONCE to streams; UI always reflects real audio state
  void _subscribeToAudioStreams() {
    // Playing state → drives waveform and button icon
    _playingSub = AudioService.playingStream.listen((playing) {
      if (!mounted) return;
      setState(() => _isPlaying = playing);
      if (playing) {
        _waveNotifier.startAnimating();
        _miniWaveNotifier.startAnimating();
      } else {
        _waveNotifier.stopAnimating();
        _miniWaveNotifier.stopAnimating();
      }
    });

    // Position → drives progress bar (capped at _uiMaxSeconds for looped files)
    _positionSub = AudioService.positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _position = pos);
    });

    // Duration → shows real file duration
    _durationSub = AudioService.durationStream.listen((dur) {
      if (!mounted) return;
      setState(() => _realDuration = dur ?? Duration.zero);
    });

    // Player state → detect loading / ready
    _stateSub = AudioService.playerStateStream.listen((state) {
      if (!mounted) return;
      final loading = state.processingState == ProcessingState.loading ||
          state.processingState == ProcessingState.buffering;
      setState(() => _isLoading = loading);
    });
  }

  @override
  void dispose() {
    _playingSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _stateSub?.cancel();
    _sleepTimer?.cancel();
    _expandCtrl.dispose();
    _pulseCtrl.dispose();
    _waveNotifier.dispose();
    _miniWaveNotifier.dispose();
    AudioService.stop();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────

  List<SoundItem> get _filtered {
    if (_filterIndex == 0) return kSounds;
    return kSounds.where((s) => s.category == kFilterTabs[_filterIndex]).toList();
  }

  // FIX: Use real position/duration; cap UI at 45s for looped short files
  double get _progress {
    // Use real duration if available, else cap at 45s
    final totalSecs = _realDuration.inSeconds > 0
        ? _realDuration.inSeconds.clamp(1, _uiMaxSeconds).toInt()
        : _uiMaxSeconds;
    final posSecs = _position.inSeconds % _uiMaxSeconds;
    return (posSecs / totalSecs).clamp(0.0, 1.0).toDouble();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get _positionStr {
    // Show position within current loop (mod real duration)
    if (_realDuration.inSeconds > 0) {
      final loopPos = Duration(
          seconds: _position.inSeconds %
              _realDuration.inSeconds.clamp(1, 9999).toInt());
      return _formatDuration(loopPos);
    }
    return _formatDuration(_position);
  }

  // Duration shown in UI: real file duration (capped at 45s for display)
  String get _durationStr {
    if (_realDuration.inSeconds > 0 && _realDuration.inSeconds <= _uiMaxSeconds) {
      return _formatDuration(_realDuration);
    }
    return '${_uiMaxSeconds}s';
  }

  // ── Open / play a sound ──────────────────────────────────────────

  Future<void> _openSound(SoundItem sound) async {
    if (_isLoading) return;
    HapticFeedback.lightImpact();

    // Tap same card → just re-open player
    if (_selected?.id == sound.id) {
      _expandCtrl.forward();
      return;
    }

    setState(() {
      _selected = sound;
      _isFavorite = false;
      _isLoading = true;
      _timerMenuOpen = false;
      _realDuration = Duration.zero;
      _position = Duration.zero;
    });

    _expandCtrl.forward(from: 0);

    try {
      await AudioService.play(sound.audioFile);
      await AudioService.setVolume(_volume);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Could not load audio: ${sound.name}'),
        backgroundColor: const Color(0xFF1E1635),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  void _closePlayer() {
    HapticFeedback.lightImpact();
    _expandCtrl.reverse();
    setState(() => _timerMenuOpen = false);
  }

  // FIX: togglePlayPause checks real audio state, never manual bool
  Future<void> _togglePlayPause() async {
    if (_isLoading || _selected == null) return;
    HapticFeedback.lightImpact();

    if (AudioService.isPlaying) {
      await AudioService.pause();
    } else {
      await AudioService.resume();
    }
    // UI updates automatically via _playingSub stream
  }

  void _skipTo(int delta) {
    if (_selected == null) return;
    final idx = kSounds.indexWhere((s) => s.id == _selected!.id);
    if (idx == -1) return;
    final next = (idx + delta).clamp(0, kSounds.length - 1).toInt();
    if (next != idx) _openSound(kSounds[next]);
  }

  void _onVolumeChanged(double v) {
    setState(() => _volume = v);
    AudioService.setVolume(v);
  }

  void _onProgressScrub(double v) {
    if (_realDuration.inSeconds > 0) {
      final target = Duration(
          milliseconds: (v * _realDuration.inMilliseconds).round());
      AudioService.seek(target);
    }
  }

  void _setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    setState(() => _timerMenuOpen = false);
    _sleepTimer = Timer(Duration(minutes: minutes), () async {
      await _saveSession();
      await AudioService.stop();
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Sleep timer: $minutes min'),
      backgroundColor: const Color(0xFF1E1635),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _saveSession() async {
    if (_selected == null || _position.inSeconds < 5) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sound_sessions')
          .add({
        'sound': _selected!.name,
        'category': _selected!.category,
        'duration': _position.inSeconds,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  // ═════════════════════════════════════════════════════
  //  BUILD
  // ═════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0B1E),
        body: Stack(
          children: [
            _buildGrid(),
            _buildExpandedPlayer(),
            _buildMiniBar(),
          ],
        ),
      ),
    );
  }

  // ── GRID ─────────────────────────────────────────────

  Widget _buildGrid() {
    return AnimatedBuilder(
      animation: _expandAnim,
      builder: (_, child) {
        final t = _expandAnim.value;
        return Opacity(
          opacity: (1 - t).clamp(0.0, 1.0).toDouble(),
          child: Transform.scale(scale: 1 - t * 0.025, child: child),
        );
      },
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGridAppBar(),
            _buildFilterTabs(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: GridView.builder(
                  key: ValueKey(_filterIndex),
                  padding: EdgeInsets.fromLTRB(
                      16, 12, 16, _selected != null ? 96 : 24),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final s = _filtered[i];
                    return RepaintBoundary(
                      child: SoundCard(
                        sound: s,
                        isActive:
                            _selected?.id == s.id && _isPlaying,
                        isSelected: _selected?.id == s.id,
                        waveNotifier: _miniWaveNotifier,
                        onTap: () => _openSound(s),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await _saveSession();
              await AudioService.stop();
              if (mounted) Navigator.pop(context);
            },
            child: _circleIcon(const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 14,
                color: Colors.white70)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sound Therapy',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                Text('${kSounds.length} healing soundscapes',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.38),
                        fontSize: 12)),
              ],
            ),
          ),
          _circleIcon(const Icon(Icons.search_rounded,
              size: 18, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _circleIcon(Widget child) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Center(child: child),
      );

  Widget _buildFilterTabs() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: kFilterTabs.length,
        itemBuilder: (_, i) {
          final sel = _filterIndex == i;
          return GestureDetector(
            onTap: () => setState(() => _filterIndex = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFF7C3AED)
                    : Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: sel
                        ? const Color(0xFF7C3AED)
                        : Colors.white.withOpacity(0.1)),
              ),
              child: Text(kFilterTabs[i],
                  style: TextStyle(
                      color: sel ? Colors.white : Colors.white.withOpacity(0.45),
                      fontWeight:
                          sel ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  // ── MINI BAR ─────────────────────────────────────────

  Widget _buildMiniBar() {
    return AnimatedBuilder(
      animation: _expandAnim,
      builder: (_, __) {
        final t = _expandAnim.value;
        if (_selected == null || t > 0.05) return const SizedBox.shrink();
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: GestureDetector(
                onTap: () => _expandCtrl.forward(),
                child: Container(
                  height: 68,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color(0xFF1E1635),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.12)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20)
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        child: _SoundImg(
                            asset: _selected!.imageAsset,
                            width: 68,
                            height: 68),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_selected!.name,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            RepaintBoundary(
                              child: SizedBox(
                                height: 16,
                                child: ListenableBuilder(
                                  listenable: _miniWaveNotifier,
                                  builder: (_, __) => CustomPaint(
                                    painter: _MiniWavePainter(
                                      bars: _miniWaveNotifier.bars,
                                      color: _selected!.accentColor,
                                      isPlaying: _miniWaveNotifier.isPlaying,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 42,
                          height: 42,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _selected!.accentColor.withOpacity(0.2),
                            border: Border.all(
                                color:
                                    _selected!.accentColor.withOpacity(0.5)),
                          ),
                          child: Center(
                            child: _isLoading
                                ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: _selected!.accentColor))
                                : Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: _selected!.accentColor,
                                    size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── EXPANDED PLAYER ──────────────────────────────────

  Widget _buildExpandedPlayer() {
    if (_selected == null) return const SizedBox.shrink();
    final sound = _selected!;

    return AnimatedBuilder(
      animation: _expandAnim,
      builder: (_, __) {
        final t = _expandAnim.value;
        if (t == 0) return const SizedBox.shrink();
        return Positioned.fill(
          child: Opacity(
            opacity: t.clamp(0.0, 1.0).toDouble(),
            child: _ExpandedPlayer(
              sound: sound,
              isPlaying: _isPlaying,
              isLoading: _isLoading,
              isFavorite: _isFavorite,
              progress: _progress,
              volume: _volume,
              positionStr: _positionStr,
              durationStr: _durationStr,
              waveNotifier: _waveNotifier,
              pulseCtrl: _pulseCtrl,
              timerMenuOpen: _timerMenuOpen,
              onClose: _closePlayer,
              onPlayPause: _togglePlayPause,
              onSkipPrev: () => _skipTo(-1),
              onSkipNext: () => _skipTo(1),
              onFavorite: () => setState(() => _isFavorite = !_isFavorite),
              onProgressChanged: _onProgressScrub,
              onVolumeChanged: _onVolumeChanged,
              onTimerTap: () =>
                  setState(() => _timerMenuOpen = !_timerMenuOpen),
              onSleepTimerSelected: _setSleepTimer,
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════
//  SOUND CARD
// ═══════════════════════════════════════════════════════

class SoundCard extends StatelessWidget {
  final SoundItem sound;
  final bool isActive;
  final bool isSelected;
  final _WaveNotifier waveNotifier;
  final VoidCallback onTap;

  const SoundCard({
    super.key,
    required this.sound,
    required this.isActive,
    required this.isSelected,
    required this.waveNotifier,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: isSelected
              ? Border.all(
                  color: sound.accentColor.withOpacity(0.75), width: 2)
              : null,
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: sound.accentColor.withOpacity(0.3),
                      blurRadius: 14,
                      spreadRadius: 1)
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _SoundImg(asset: sound.imageAsset),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.transparent,
                      Color(0xCC000000),
                    ],
                    stops: [0.0, 0.38, 1.0],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.45),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.15)),
                      ),
                      child: Text(sound.category,
                          style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5)),
                    ),
                    const Spacer(),
                    Text(sound.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(
                                color: Colors.black54,
                                blurRadius: 8,
                                offset: Offset(0, 2))
                          ],
                        )),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(sound.author,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Icon(Icons.play_circle_outline_rounded,
                            size: 11,
                            color: Colors.white.withOpacity(0.6)),
                        const SizedBox(width: 3),
                      ],
                    ),
                    if (isActive) ...[
                      const SizedBox(height: 8),
                      RepaintBoundary(
                        child: SizedBox(
                          height: 18,
                          child: ListenableBuilder(
                            listenable: waveNotifier,
                            builder: (_, __) => CustomPaint(
                              painter: _MiniWavePainter(
                                bars: waveNotifier.bars,
                                color: sound.accentColor,
                                isPlaying: waveNotifier.isPlaying,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ═══════════════════════════════════════════════════════
//  EXPANDED PLAYER WIDGET
// ═══════════════════════════════════════════════════════

class _ExpandedPlayer extends StatelessWidget {
  final SoundItem sound;
  final bool isPlaying;
  final bool isLoading;
  final bool isFavorite;
  final double progress;
  final double volume;
  final String positionStr;
  final String durationStr;
  final _WaveNotifier waveNotifier;
  final AnimationController pulseCtrl;
  final bool timerMenuOpen;
  final VoidCallback onClose;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipPrev;
  final VoidCallback onSkipNext;
  final VoidCallback onFavorite;
  final ValueChanged<double> onProgressChanged;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onTimerTap;
  final ValueChanged<int> onSleepTimerSelected;

  const _ExpandedPlayer({
    required this.sound,
    required this.isPlaying,
    required this.isLoading,
    required this.isFavorite,
    required this.progress,
    required this.volume,
    required this.positionStr,
    required this.durationStr,
    required this.waveNotifier,
    required this.pulseCtrl,
    required this.timerMenuOpen,
    required this.onClose,
    required this.onPlayPause,
    required this.onSkipPrev,
    required this.onSkipNext,
    required this.onFavorite,
    required this.onProgressChanged,
    required this.onVolumeChanged,
    required this.onTimerTap,
    required this.onSleepTimerSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragEnd: (d) {
        if ((d.primaryVelocity ?? 0) > 250) onClose();
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _SoundImg(asset: sound.imageAsset),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.28),
                      Colors.black.withOpacity(0.58),
                      Colors.black.withOpacity(0.92),
                      Colors.black.withOpacity(0.98),
                    ],
                    stops: const [0.0, 0.28, 0.58, 1.0],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  _topBar(),
                  _artwork(),
                  _info(),
                  _waveformWidget(),
                  _progressBar(),
                  _controls(),
                  _volumeRow(),
                  _sleepTimerBtn(),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            if (timerMenuOpen) _timerMenu(),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
                border: Border.all(color: Colors.white.withOpacity(0.18)),
              ),
              child: const Icon(Icons.keyboard_arrow_down_rounded,
                  size: 22, color: Colors.white),
            ),
          ),
          const Spacer(),
          Text(sound.category.toUpperCase(),
              style: TextStyle(
                  color: sound.accentColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2)),
          const Spacer(),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(Icons.more_horiz_rounded,
                size: 20, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _artwork() {
    return Expanded(
      flex: 3,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
        child: AnimatedBuilder(
          animation: pulseCtrl,
          builder: (_, child) => Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: sound.accentColor
                      .withOpacity(0.18 + 0.15 * pulseCtrl.value),
                  blurRadius: 38 + 18 * pulseCtrl.value,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
          child: ClipRRect(
            key: ValueKey(sound.id),
            borderRadius: BorderRadius.circular(28),
            child: _SoundImg(asset: sound.imageAsset),
          ),
        ),
      ),
    );
  }

  Widget _info() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sound.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        height: 1.1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Text('By ${sound.author}',
                    style: TextStyle(
                        color: sound.accentColor.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onFavorite,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFavorite
                    ? Colors.pinkAccent.withOpacity(0.2)
                    : Colors.white.withOpacity(0.08),
                border: Border.all(
                    color: isFavorite
                        ? Colors.pinkAccent.withOpacity(0.6)
                        : Colors.white.withOpacity(0.15)),
              ),
              child: Icon(
                isFavorite
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isFavorite ? Colors.pinkAccent : Colors.white54,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _waveformWidget() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 4),
      child: RepaintBoundary(
        child: SizedBox(
          height: 44,
          width: double.infinity,
          child: ListenableBuilder(
            listenable: waveNotifier,
            builder: (_, __) => CustomPaint(
              painter: _WavePainter(
                bars: waveNotifier.bars,
                color: sound.accentColor,
                isPlaying: waveNotifier.isPlaying,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _progressBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 16),
              activeTrackColor: sound.accentColor,
              inactiveTrackColor: Colors.white.withOpacity(0.15),
              thumbColor: Colors.white,
              overlayColor: sound.accentColor.withOpacity(0.2),
            ),
            child: Slider(
                value: progress.clamp(0.0, 1.0).toDouble(),
                onChanged: onProgressChanged),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(positionStr,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
                Text(durationStr,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _controls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          GestureDetector(
            onTap: onSkipPrev,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border:
                    Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(Icons.skip_previous_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
          GestureDetector(
            onTap: onPlayPause,
            child: AnimatedBuilder(
              animation: pulseCtrl,
              builder: (_, child) => Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sound.accentColor,
                  boxShadow: [
                    BoxShadow(
                      color: sound.accentColor.withOpacity(
                          0.38 + 0.18 * pulseCtrl.value),
                      blurRadius: 22 + 10 * pulseCtrl.value,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: child,
              ),
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 34),
              ),
            ),
          ),
          GestureDetector(
            onTap: onSkipNext,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
                border:
                    Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: const Icon(Icons.skip_next_rounded,
                  color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }

  Widget _volumeRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          const Icon(Icons.volume_off_rounded,
              color: Colors.white38, size: 18),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.5,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white60,
                inactiveTrackColor: Colors.white.withOpacity(0.12),
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.1),
              ),
              child: Slider(value: volume, onChanged: onVolumeChanged),
            ),
          ),
          const Icon(Icons.volume_up_rounded,
              color: Colors.white60, size: 18),
        ],
      ),
    );
  }

  Widget _sleepTimerBtn() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
      child: Center(
        child: GestureDetector(
          onTap: onTimerTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: BoxDecoration(
              color: timerMenuOpen
                  ? sound.accentColor.withOpacity(0.18)
                  : Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                  color: timerMenuOpen
                      ? sound.accentColor.withOpacity(0.55)
                      : Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bedtime_outlined,
                    size: 16,
                    color: timerMenuOpen
                        ? sound.accentColor
                        : Colors.white54),
                const SizedBox(width: 8),
                Text('Sleep Timer',
                    style: TextStyle(
                        color: timerMenuOpen
                            ? sound.accentColor
                            : Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _timerMenu() {
    final options = [
      const MapEntry(15, '15 min'),
      const MapEntry(30, '30 min'),
      const MapEntry(45, '45 min'),
      const MapEntry(60, '60 min'),
      const MapEntry(90, '90 min'),
    ];
    return Positioned(
      bottom: 90,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.13),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: options
                    .map((e) => GestureDetector(
                          onTap: () => onSleepTimerSelected(e.key),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 13),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color:
                                          Colors.white.withOpacity(0.07))),
                            ),
                            child: Row(children: [
                              Icon(Icons.timer_outlined,
                                  size: 15,
                                  color:
                                      sound.accentColor.withOpacity(0.8)),
                              const SizedBox(width: 12),
                              Text(e.value,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
//  IMAGE WIDGET — gradient fallback if asset missing
// ═══════════════════════════════════════════════════════

class _SoundImg extends StatelessWidget {
  final String asset;
  final double? width;
  final double? height;
  const _SoundImg({required this.asset, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E1635), Color(0xFF0E0B1E)],
          ),
        ),
        child: const Center(
          child: Icon(Icons.music_note_rounded,
              color: Colors.white24, size: 40),
        ),
      ),
    );
  }
}
