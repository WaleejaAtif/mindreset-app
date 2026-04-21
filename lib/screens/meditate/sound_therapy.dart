import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projects/services/audio_service.dart';

class SoundTherapyScreen extends StatefulWidget {
  const SoundTherapyScreen({super.key});

  @override
  State<SoundTherapyScreen> createState() => _SoundTherapyScreenState();
}

class _SoundTherapyScreenState extends State<SoundTherapyScreen> {
  int? _selectedSound;
  bool _isPlaying = false;
  bool _voiceGuidanceOn = false;
  int _secondsElapsed = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _sounds = [
    {
      'name': 'Rain Sounds',
      'emoji': '🌧️',
      'color': Colors.blue,
    },
    {
      'name': 'Ocean Waves',
      'emoji': '🌊',
      'color': Colors.cyan,
    },
    {
      'name': 'Forest Birds',
      'emoji': '🌲',
      'color': Colors.green,
    },
    {
      'name': 'White Noise',
      'emoji': '〰️',
      'color': Colors.grey,
    },
  ];

  String get _time {
    final m = (_secondsElapsed ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsElapsed % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Future<void> _togglePlay(int index) async {
    if (_isPlaying && _selectedSound == index) {
      _timer?.cancel();
      await AudioService.stop();
      setState(() => _isPlaying = false);
    } else {
      await AudioService.stop();

      setState(() {
        _selectedSound = index;
        _isPlaying = true;
        _secondsElapsed = 0;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() => _secondsElapsed++);
      });

      // 🔊 ALWAYS plays calm.mp3 (for now)
      await AudioService.play("calm.mp3");
    }
  }

  Future<void> _saveSession() async {
    if (_selectedSound == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('sound_sessions')
        .add({
      'sound': _sounds[_selectedSound!]['name'],
      'duration': _secondsElapsed,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    AudioService.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Sound Therapy"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () async {
            _timer?.cancel();
            await AudioService.stop();
            if (mounted) Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          if (_isPlaying)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                "Playing... $_time",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sounds.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final sound = _sounds[index];
                final isSelected =
                    _selectedSound == index && _isPlaying;

                return GestureDetector(
                  onTap: () => _togglePlay(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? sound['color'].withOpacity(0.4)
                          : Colors.white10,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? sound['color']
                            : Colors.white24,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(sound['emoji'],
                            style: const TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Text(
                          sound['name'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        Icon(
                          isSelected
                              ? Icons.stop
                              : Icons.play_arrow,
                          color: Colors.white,
                        )
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
}