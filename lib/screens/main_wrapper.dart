/*import 'package:flutter/material.dart';
import '../widgets/navigation.dart'; // Adjust path if needed

class MainWrapper extends StatefulWidget {
  const MainWrapper({Key? key}) : super(key: key);

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // Replace these with your actual screen widgets
  final List<Widget> _pages = [
    const Center(child: Text("Home", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Learn", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Meditate", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Planner", style: TextStyle(color: Colors.white))),
    const Center(child: Text("Reflect", style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // This is the fix: it allows the body to be drawn behind the navigation bar
      extendBody: true, 
      backgroundColor: const Color(0xFF1A1A2E), // Your app's dark background
      body: _pages[_currentIndex],
      bottomNavigationBar: AppNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}*/

