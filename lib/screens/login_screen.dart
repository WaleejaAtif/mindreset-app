import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import 'profile_setup.dart';
import 'home.dart';

// --- COLORS ---
const Color _primaryColor = Color(0xFF755F84);
const Color _darkBgColor = Color(0xFF4d3536);
const Color _textColor = Colors.white;

const String _splashImage = 'assets/images/login3.jpg';
const String _loginImage = 'assets/images/login2.jpg';

enum ScreenType { splash, login, register }

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  ScreenType _currentScreen = ScreenType.splash;

  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  final _regEmailCtrl = TextEditingController();
  final _regPassCtrl = TextEditingController();

  bool _remember = false;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadRemember();
    // ❌ IMPORTANT: NO AUTO LOGIN HERE (as you requested)
  }

  void _loadRemember() async {
    final email = await AuthService.getRememberEmail();
    if (email != null) {
      setState(() {
        _loginEmailCtrl.text = email;
        _remember = true;
      });
    }
  }

  // ================= LOGIN =================
  void _login() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final email = _loginEmailCtrl.text.trim();
    final password = _loginPassCtrl.text.trim();

    try {
      // Firebase login
      UserCredential cred =
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await AuthService.saveRemember(email, _remember);

      final uid = cred.user!.uid;

      // check profile status
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (doc.exists && doc.data() != null && doc['profileCompleted'] == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProfileSetupScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? "Login failed";
        _loading = false;
      });
    }
  }

  // ================= REGISTER =================
  void _register() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final email = _regEmailCtrl.text.trim();
    final password = _regPassCtrl.text.trim();

    try {
      UserCredential cred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // create default profile state
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': email,
        'profileCompleted': false,
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProfileSetupScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.message ?? "Registration failed";
        _loading = false;
      });
    }
  }

  void _guest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ProfileSetupScreen()),
    );
  }

  // ================= UI =================
  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      hintText: label,
      prefixIcon: Icon(icon, color: _primaryColor),
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide.none,
      ),
    );
  }

  // SPLASH
  Widget _buildSplashUI() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(_splashImage),
          fit: BoxFit.cover,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            "The best app for your FOCUS",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 100),

          ElevatedButton(
            onPressed: () =>
                setState(() => _currentScreen = ScreenType.login),
            child: Text("Sign In"),
          ),

          TextButton(
            onPressed: () =>
                setState(() => _currentScreen = ScreenType.register),
            child: Text("Create Account"),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // LOGIN UI
  Widget _buildLoginUI() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Login",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),

            const SizedBox(height: 30),

            TextField(
              controller: _loginEmailCtrl,
              decoration: _inputDecoration("Email", Icons.email),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _loginPassCtrl,
              obscureText: true,
              decoration: _inputDecoration("Password", Icons.lock),
            ),

            const SizedBox(height: 10),

            if (_error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red)),

            const SizedBox(height: 20),

            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _login,
              child: Text("Login"),
            ),

            TextButton(
              onPressed: _guest,
              child: Text("Continue as Guest"),
            ),
          ],
        ),
      ),
    );
  }

  // REGISTER UI
  Widget _buildRegisterUI() {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Register",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),

            const SizedBox(height: 30),

            TextField(
              controller: _regEmailCtrl,
              decoration: _inputDecoration("Email", Icons.email),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: _regPassCtrl,
              obscureText: true,
              decoration: _inputDecoration("Password", Icons.lock),
            ),

            const SizedBox(height: 20),

            if (_error.isNotEmpty)
              Text(_error, style: TextStyle(color: Colors.red)),

            const SizedBox(height: 20),

            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _register,
              child: Text("Register"),
            ),

            TextButton(
              onPressed: () =>
                  setState(() => _currentScreen = ScreenType.login),
              child: Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: Duration(milliseconds: 300),
      child: _currentScreen == ScreenType.splash
          ? _buildSplashUI()
          : _currentScreen == ScreenType.login
          ? _buildLoginUI()
          : _buildRegisterUI(),
    );
  }
}