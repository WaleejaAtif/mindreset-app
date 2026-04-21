import 'package:flutter/material.dart';

class GroundingScreen extends StatelessWidget {
  const GroundingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Grounding Exercises')),
      body: const Center(
        child: Text(
          'Sensory & mindfulness grounding techniques\n(Coming soon)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}