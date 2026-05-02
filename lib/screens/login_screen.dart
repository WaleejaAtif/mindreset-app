import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import 'profile_setup.dart';
import 'home.dart';
import '../widgets/animated_background.dart';

// --- NEW ZENIFY COLORS ---
const Color _primaryColor = Color(0xFF8C52FF); // Vibrant Purple
const Color _darkBgColor = Color(0xFF5E17EB); // Deep Purple
const Color _textColor = Colors.white;

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
  final _regFirstNameCtrl = TextEditingController();
  final _regLastNameCtrl = TextEditingController();
  final _regContactCtrl = TextEditingController();

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
    final firstName = _regFirstNameCtrl.text.trim();
    final lastName = _regLastNameCtrl.text.trim();
    final contact = _regContactCtrl.text.trim();
    final displayName = [firstName, lastName]
        .where((part) => part.isNotEmpty)
        .join(' ')
        .trim();

    try {
      UserCredential cred =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (displayName.isNotEmpty) {
        await cred.user?.updateDisplayName(displayName);
      }

      // create default profile state
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'displayName': displayName,
        'contact': contact,
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

  void _forgotPassword() async {
    final email = _loginEmailCtrl.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email first to reset password.')),
      );
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent! Check your inbox.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  void _guest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
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
    return Scaffold(
      backgroundColor: Color(0xFF1A1333),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // We'll use the newly provided Illustration
              Image.asset(
                'assets/images/Illustration.png',
                height: 260,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              const Text(
                "Welcome to Zenify!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFFFFF),
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "Your AI companion for a balanced mind.",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFAFA8BA),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 2),
              
              // SIGN UP BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      setState(() => _currentScreen = ScreenType.register),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8C52FF), // App's vibrant purple
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Sign up",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // SIGN IN BUTTON
              TextButton(
                onPressed: () =>
                    setState(() => _currentScreen = ScreenType.login),
                child: const Text(
                  "Sign in",
                  style: TextStyle(
                    color: Color(0xFF8C52FF), // App's vibrant purple
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  // LOGIN UI
  Widget _buildLoginUI() {
    return AnimatedBackground(
      isLightMode: true,
      hasBlur: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _currentScreen = ScreenType.splash),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF1A1333),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFFFFFF).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Welcome Back",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryColor)),
                  const SizedBox(height: 8),
                  const Text("Log in to continue", style: TextStyle(color: Color(0xFFAFA8BA))),
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      child: const Text("Forgot Password?", style: TextStyle(color: _primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (_error.isNotEmpty)
                    Text(_error, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 20),

                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("Login", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                  
                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: _guest,
                    child: const Text("Continue as Guest", style: TextStyle(color: Color(0xFFAFA8BA))),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // REGISTER UI
  Widget _buildRegisterUI() {
    return AnimatedBackground(
      isLightMode: true,
      hasBlur: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => setState(() => _currentScreen = ScreenType.splash),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Color(0xFF1A1333),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFFFFFF).withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Create Account",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryColor)),
                  const SizedBox(height: 8),
                  const Text("Start your journey", style: TextStyle(color: Color(0xFFAFA8BA))),
                  const SizedBox(height: 30),

                  TextField(
                    controller: _regFirstNameCtrl,
                    decoration: _inputDecoration("First Name", Icons.person),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _regLastNameCtrl,
                    decoration: _inputDecoration("Last Name", Icons.person_outline),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _regContactCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration("Contact Number", Icons.phone),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _regEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
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
                    Text(_error, style: const TextStyle(color: Colors.red)),

                  const SizedBox(height: 20),

                  _loading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _register,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("Register", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),

                  const SizedBox(height: 12),

                  TextButton(
                    onPressed: () =>
                        setState(() => _currentScreen = ScreenType.login),
                    child: const Text("Already have an account? Login", style: TextStyle(color: Color(0xFFAFA8BA))),
                  ),
                ],
              ),
            ),
          ),
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

