import 'package:flutter/material.dart';
import 'timer_activity_screen.dart';
import 'breathing_activity_screen.dart';
import 'journal_activity_screen.dart';
import 'guided_activity_screen.dart';
import 'checklist_activity_screen.dart';
import 'digital_peace_screen.dart';
import 'single_task_screen.dart';
import 'posture_activity_screen.dart';
import 'switch_task_screen.dart';
import 'hydrate_activity_screen.dart';
import 'habit_stacking_screen.dart';
import 'active_recall_screen.dart';

class ActivityRouter {
  static Widget getRoute(Map<String, dynamic> item, String category) {
    final title = (item['title'] ?? '').toString().toLowerCase();
    final suggestions = _getSuggestionsForTitle(title);

    // Breathing Screen
    if (title.contains('breathe') || title.contains('breathing')) {
      return BreathingActivityScreen(item: item);
    }

    // Timer Screen
    if (title.contains('timed') || 
        title.contains('pomodoro') || 
        title.contains('walk') || 
        title.contains('eyes') ||
        title.contains('2-minute')) {
      int minutes = 5;
      if (title.contains('pomodoro')) minutes = 25;
      else if (title.contains('timed')) minutes = 10;
      else if (title.contains('2-minute')) minutes = 2;
      else if (title.contains('eyes')) minutes = 1;
      
      return TimerActivityScreen(item: item, durationMinutes: minutes, suggestions: suggestions);
    }

    // Journal/Typing Screen
    if (title.contains('write') || 
        title.contains('feynman') || 
        title.contains('self-talk')) {
      return JournalActivityScreen(item: item, category: category, suggestions: suggestions);
    }

    // Custom 5 Specific Logic Screens
    if (title.contains('digital') || title.contains('peace')) {
      return DigitalPeaceScreen(item: item);
    }
    if (title.contains('multitask') || title.contains('no multi')) {
      return SingleTaskScreen(item: item);
    }
    if (title.contains('posture')) {
      return PostureActivityScreen(item: item);
    }
    if (title.contains('switch')) {
      return SwitchTaskScreen(item: item);
    }
    if (title.contains('hydrate') || title.contains('snack')) {
      return HydrateActivityScreen(item: item);
    }
    if (title.contains('stack')) {
      return HabitStackingScreen(item: item);
    }
    if (title.contains('recall')) {
      return ActiveRecallScreen(item: item);
    }

    // Checklist Screen
    if (title.contains('break') || title.contains('list') || title.contains('track') || title.contains('repetition')) {
      return ChecklistActivityScreen(item: item, suggestions: suggestions);
    }

    // Fallback: Guided Reflection Screen
    return GuidedActivityScreen(item: item, suggestions: suggestions);
  }

  static List<String> _getSuggestionsForTitle(String title) {
    if (title.contains('self-talk')) {
      return ["I am capable of doing this.", "Progress over perfection.", "I will focus on one step at a time."];
    } else if (title.contains('feynman')) {
      return ["How would I explain this to a 5-year-old?", "What is the core concept in one sentence?", "What analogy can I use?"];
    } else if (title.contains('write') || title.contains('journal')) {
      return ["What is distracting me right now?", "The main thing I need to do is...", "I feel stuck because..."];
    } else if (title.contains('pomodoro') || title.contains('timed')) {
      return ["Pick one single task to focus on.", "Keep a piece of paper nearby for distractions.", "Don't break the timer!"];
    } else if (title.contains('walk')) {
      return ["Try walking outside if possible.", "Focus on your breathing.", "Leave your phone behind."];
    } else if (title.contains('eyes')) {
      return ["Look at an object 20 feet away.", "Close your eyes completely.", "Relax your jaw and face."];
    } else if (title.contains('posture')) {
      return ["Roll your shoulders back.", "Stand up and stretch.", "Adjust your screen height."];
    } else if (title.contains('workspace') || title.contains('clear')) {
      return ["Put away items you don't need right now.", "Close unused tabs on your computer."];
    } else if (title.contains('digital') || title.contains('peace')) {
      return ["Turn on Do Not Disturb mode.", "Put your phone out of reach.", "Close your email client."];
    } else if (title.contains('break')) {
      return ["Step 1: Get out materials", "Step 2: Read instructions", "Step 3: Write first draft"];
    } else if (title.contains('setting') || title.contains('new')) {
      return ["Move to a different room.", "Change the lighting in your workspace.", "Try working from a cafe or library."];
    } else if (title.contains('goal') || title.contains('read')) {
      return ["What is the ultimate purpose of this task?", "How will finishing this make you feel?", "Write down your 'Why' and keep it visible."];
    } else if (title.contains('start small') || title.contains('small')) {
      return ["Read 1 page.", "Do 1 pushup.", "Write 1 sentence.", "Just open the app/book."];
    } else if (title.contains('environment')) {
      return ["Put your running shoes by the door.", "Hide the junk food.", "Log out of distracting apps."];
    } else if (title.contains('sleep')) {
      return ["Set a wind-down alarm.", "Put devices away 1 hour before bed.", "Try brown noise."];
    } else if (title.contains('mind map') || title.contains('map')) {
      return ["Start with the core topic in the center.", "Draw branches for sub-topics.", "Use different colors."];
    } else if (title.contains('forgive')) {
      return ["Missing one day doesn't ruin a streak.", "I will try again tomorrow.", "Perfection is the enemy of progress."];
    } else if (title.contains('track')) {
      return ["Create a visual calendar.", "Don't break the chain.", "Tick off today's box."];
    } else if (title.contains('spaced') || title.contains('repetition')) {
      return ["Review notes from yesterday.", "Review notes from last week.", "Test yourself on old material."];
    }
    return ["Take a deep breath and begin.", "Focus on what you can control.", "Every small step counts."];
  }
}
