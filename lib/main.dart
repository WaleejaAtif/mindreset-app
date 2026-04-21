import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Core screens
import 'screens/logo_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup.dart';
import 'screens/home.dart';
import 'screens/learn.dart';

// Learn module
import 'screens/focus_strategies.dart';
import 'screens/study_hacks.dart';
import 'screens/habit_tips.dart';
import 'screens/pomodoro_timer.dart';
import 'screens/games.dart';

// Meditate module
import 'screens/meditate/meditate.dart';
import 'screens/meditate/breathing_exercises.dart';
import 'screens/meditate/sound_therapy.dart';
import 'screens/meditate/grounding_exercises.dart';

// Planner module
import 'screens/planner/planner.dart';
import 'screens/planner/add_task_screen.dart';
import 'screens/planner/daily_view_screen.dart';
import 'screens/planner/weekly_view_screen.dart';
import 'screens/planner/monthly_mood_screen.dart';

// Reflect module
import 'screens/reflect/reflect.dart';
import 'screens/reflect/streak_progress_screen.dart';
import 'screens/reflect/mood_graph_screen.dart';
import 'screens/reflect/daily_mood_screen.dart';
import 'screens/reflect/achievements_screen.dart';
import 'services/audio_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MindReset',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
      ),
      initialRoute: '/logo',
      routes: {
        // 🚀 Startup
        '/logo': (context) => LogoScreen(),
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/profileSetup': (context) => ProfileSetupScreen(),

        // 🏠 Main
        '/home': (context) => const HomeScreen(),
        '/learn': (context) => const LearnScreen(),
        '/meditate': (context) => const MeditateScreen(),
        '/planner': (context) => const PlannerScreen(),
        '/reflect': (context) => const ReflectScreen(),

        // 📘 Learn
        '/focusStrategies': (context) => const FocusStrategiesScreen(),
        '/studyHacks': (context) => const StudyHacksScreen(),
        '/habitTips': (context) => const HabitTipsScreen(),
        '/pomodoro': (context) => const PomodoroTimerScreen(),
        '/games': (context) => const GamesScreen(),

        // 🧘 Meditate
        '/breathing': (context) => const BreathingScreen(),
        '/soundTherapy': (context) => const SoundTherapyScreen(),
        '/grounding': (context) => const GroundingScreen(),

        // 🗓 Planner
        '/addTask': (context) => const AddTaskScreen(),
        '/dailyView': (context) => const DailyViewScreen(),
        '/weeklyView': (context) => const WeeklyViewScreen(),
        '/monthlyMood': (context) => const MonthlyMoodScreen(),

        // 🪞 Reflect
        '/streakProgress': (context) => const StreakProgressScreen(),
        '/moodGraph': (context) => const MoodGraphScreen(),
        '/dailyMood': (context) => const DailyMoodScreen(),
        '/achievements': (context) => const AchievementsScreen(),
      },
    );
  }
}