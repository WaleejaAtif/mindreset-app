import 'package:flutter/material.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Focus Games')),
      body: const Center(
        child: Text(
          'Mini focus & memory games coming soon!',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
