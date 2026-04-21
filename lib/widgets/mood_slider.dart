import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- COLORS ---
const Color _primaryColor = Color(0xFF755F84);
const Color _darkBgColor = Color(0xff608ba5);

/// ===================== TODAY'S MOOD SLIDER =====================
class MoodSwipeAnalyzer extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int> onMoodChanged;

  const MoodSwipeAnalyzer({
    super.key,
    this.initialIndex = 2,
    required this.onMoodChanged,
  });

  @override
  State<MoodSwipeAnalyzer> createState() => _MoodSwipeAnalyzerState();
}

class _MoodSwipeAnalyzerState extends State<MoodSwipeAnalyzer> {
  final List<String> _moodImages = [
    "assets/images/verylow.jpg",
    "assets/images/low.png",
    "assets/images/okay.jpg",
    "assets/images/good.png",
    "assets/images/great.jpg",
  ];

  final List<String> _labels = [
    "Very Low",
    "Low",
    "Okay",
    "Good",
    "Great",
  ];

  late final PageController _controller;
  double _page = 0;
  bool _isMoodSet = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: 0.28,
      initialPage: widget.initialIndex,
    );
    _page = widget.initialIndex.toDouble();
    _controller.addListener(() {
      setState(() => _page = _controller.page ?? _page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _jumpTo(int i) {
    if (_isMoodSet) return;
    HapticFeedback.selectionClick();
    _controller.animateToPage(
      i,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
    );
    widget.onMoodChanged(i);
  }

  // ✅ SAVE MOOD TO FIRESTORE
  Future<void> _saveMoodToFirestore(int moodIndex) async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final dateKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_logs')  // subcollection
          .doc(dateKey)              // one doc per day
          .set({
        'mood': _labels[moodIndex],
        'moodIndex': moodIndex,
        'moodSavedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge so sleep data isn't overwritten

      setState(() {
        _isMoodSet = true;
        _isSaving = false;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isSaving = false);
      debugPrint('Error saving mood: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _page.round().clamp(0, _moodImages.length - 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "How are you feeling today?",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: _darkBgColor,
          ),
        ),
        const SizedBox(height: 2),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: Text(
            _labels[currentIndex],
            key: ValueKey(_labels[currentIndex]),
            style: const TextStyle(
              color: _primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _controller,
            itemCount: _moodImages.length,
            physics: _isMoodSet
                ? const NeverScrollableScrollPhysics()
                : const BouncingScrollPhysics(),
            onPageChanged: widget.onMoodChanged,
            itemBuilder: (_, i) {
              final diff = (i - _page);
              final absDiff = diff.abs();
              final isSelected = i == currentIndex;

              if (_isMoodSet && !isSelected) return const SizedBox.shrink();

              final yOffset = _isMoodSet ? 0.0 : (absDiff * absDiff) * 12;
              final rotation = _isMoodSet ? 0.0 : diff * 0.12;
              final scale = isSelected
                  ? 1.0
                  : (1.0 - (absDiff * 0.22).clamp(0.0, 0.45));

              return GestureDetector(
                onTap: () => _jumpTo(i),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: (_isMoodSet && !isSelected) ? 0.0 : 1.0,
                  child: Transform.translate(
                    offset: Offset(0, yOffset),
                    child: Transform.rotate(
                      angle: rotation,
                      child: Transform.scale(
                        scale: scale,
                        child: Center(
                          child: _ImageCard(
                            imagePath: _moodImages[i],
                            isSelected: isSelected,
                            isGlowActive: isSelected,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),

        // ✅ Set Mood Button
        if (!_isMoodSet)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: _isSaving
                ? const CircularProgressIndicator(
              valueColor:
              AlwaysStoppedAnimation<Color>(_primaryColor),
            )
                : ElevatedButton(
              onPressed: () => _saveMoodToFirestore(currentIndex),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                elevation: 3,
                shadowColor: _primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 8),
              ),
              child: const Text(
                "Set Mood",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

        // ✅ Show confirmation after mood is set
        if (_isMoodSet)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle,
                    color: Colors.green, size: 20),
                const SizedBox(width: 6),
                Text(
                  "Mood set: ${_labels[currentIndex]}",
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// ===================== SLEEP SLIDER =====================
class SleepSwipeAnalyzer extends StatefulWidget {
  final int initialIndex;
  final ValueChanged<int> onSleepChanged;

  const SleepSwipeAnalyzer({
    super.key,
    this.initialIndex = 2,
    required this.onSleepChanged,
  });

  @override
  State<SleepSwipeAnalyzer> createState() => _SleepSwipeAnalyzerState();
}

class _SleepSwipeAnalyzerState extends State<SleepSwipeAnalyzer> {
  final List<String> sleepLabels = [
    "Terrible", "Poor", "Fair", "Good", "Amazing"
  ];

  final List<String> sleepHours = [
    "<3 HRS", "3-4 HRS", "5 HRS", "6-7 HRS", "7-9 HRS"
  ];

  final List<Color> _moodColors = [
    const Color(0xFFBF84D1),
    const Color(0xFFE67613),
    const Color(0xFFCA2D03),
    const Color(0xFFF1B111),
    const Color(0xFF0CAF5B),
  ];

  final List<IconData> _icons = [
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_dissatisfied,
    Icons.sentiment_neutral,
    Icons.sentiment_satisfied,
    Icons.sentiment_very_satisfied,
  ];

  late double _currentValue;
  bool _isSleepSet = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialIndex.toDouble();
  }

  // ✅ SAVE SLEEP TO FIRESTORE
  Future<void> _saveSleepToFirestore(int sleepIndex) async {
    setState(() => _isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final dateKey =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('daily_logs')
          .doc(dateKey)
          .set({
        'sleep': sleepLabels[sleepIndex],
        'sleepHours': sleepHours[sleepIndex],
        'sleepIndex': sleepIndex,
        'sleepSavedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge so mood data isn't overwritten

      setState(() {
        _isSleepSet = true;
        _isSaving = false;
      });

      HapticFeedback.mediumImpact();
    } catch (e) {
      setState(() => _isSaving = false);
      debugPrint('Error saving sleep: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int index = _currentValue.round();
    const Color sliderGreen = Color(0xffdca889);
    const Color headerBlue = Color(0xff608ba5);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "Rate your sleep?",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: headerBlue,
          ),
        ),
        const SizedBox(height: 20),

        // Emoticon Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_icons.length, (i) {
              bool isSelected = i == index;
              Color activeColor = _moodColors[i];
              return Column(
                children: [
                  AnimatedScale(
                    duration: const Duration(milliseconds: 200),
                    scale: isSelected ? 1.2 : 1.0,
                    child: Icon(
                      _icons[i],
                      size: 32,
                      color: isSelected
                          ? activeColor
                          : Colors.grey.withOpacity(0.4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sleepLabels[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? activeColor : Colors.grey,
                    ),
                  ),
                  Text(
                    sleepHours[i],
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.normal,
                      color: isSelected
                          ? activeColor.withOpacity(0.9)
                          : Colors.grey.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            }),
          ),
        ),

        const SizedBox(height: 10),

        // Slider
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 10,
            activeTrackColor: sliderGreen,
            inactiveTrackColor: sliderGreen.withOpacity(0.15),
            thumbColor: _isSleepSet ? Colors.grey : sliderGreen,
            overlayColor: sliderGreen.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 12,
              elevation: 3,
            ),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Slider(
              value: _currentValue,
              min: 0,
              max: 4,
              divisions: 4,
              onChanged: _isSleepSet
                  ? null  // disabled after set
                  : (value) {
                setState(() => _currentValue = value);
                widget.onSleepChanged(value.round());
              },
            ),
          ),
        ),

        const SizedBox(height: 10),

        // ✅ Save Sleep Button
        if (!_isSleepSet)
          _isSaving
              ? const CircularProgressIndicator(
            valueColor:
            AlwaysStoppedAnimation<Color>(_primaryColor),
          )
              : ElevatedButton(
            onPressed: () => _saveSleepToFirestore(index),
            style: ElevatedButton.styleFrom(
              backgroundColor: sliderGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: 8),
            ),
            child: const Text(
              "Save Sleep",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),

        // ✅ Confirmation after sleep is saved
        if (_isSleepSet)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 20),
              const SizedBox(width: 6),
              Text(
                "Sleep saved: ${sleepLabels[index]}",
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// ===================== IMAGE CARD =====================
class _ImageCard extends StatelessWidget {
  final String imagePath;
  final bool isSelected;
  final bool isGlowActive;

  const _ImageCard({
    required this.imagePath,
    required this.isSelected,
    this.isGlowActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 100,
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: isGlowActive
                ? _primaryColor.withOpacity(0.7)
                : Colors.black.withOpacity(0.08),
            blurRadius: isGlowActive ? 25 : 6,
            spreadRadius: isGlowActive ? 6 : 0,
            offset:
            isGlowActive ? const Offset(0, 8) : const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: isSelected ? _primaryColor : Colors.transparent,
          width: 3.0,
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          imagePath,
          fit: BoxFit.cover,
          // ✅ Shows icon if image is missing instead of crashing
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.face,
            size: 50,
            color: _primaryColor,
          ),
        ),
      ),
    );
  }
}