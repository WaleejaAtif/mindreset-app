import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserContext {
  final String name;
  final String email;
  final String focusStyle;
  final String focusChallenge;
  final String peakFocusTime;
  final int mood; // 0 (Very Low) to 4 (Great)
  final int sleep; // 0 (Terrible) to 4 (Amazing)
  final int pendingTasks;
  final int completedTasks;
  final String taskSummary;
  final String moodHistory;
  final String sleepHistory;
  final String meditationHistory;
  final String focusStrategyHistory;
  final String gameHistory;
  final String soundHistory;
  final int totalBreathingSessions;
  final int totalGroundingSessions;
  final int totalGameSessions;

  const UserContext({
    required this.name,
    required this.email,
    required this.focusStyle,
    required this.focusChallenge,
    required this.peakFocusTime,
    required this.mood,
    required this.sleep,
    required this.pendingTasks,
    required this.completedTasks,
    required this.taskSummary,
    required this.moodHistory,
    required this.sleepHistory,
    required this.meditationHistory,
    required this.focusStrategyHistory,
    required this.gameHistory,
    required this.soundHistory,
    required this.totalBreathingSessions,
    required this.totalGroundingSessions,
    required this.totalGameSessions,
  });

  String get moodString {
    switch (mood) {
      case 0: return "Very Low";
      case 1: return "Low";
      case 2: return "Okay";
      case 3: return "Good";
      case 4: return "Great";
      default: return "Unknown";
    }
  }

  String get sleepString {
    switch (sleep) {
      case 0: return "Terrible";
      case 1: return "Poor";
      case 2: return "Fair";
      case 3: return "Good";
      case 4: return "Amazing";
      default: return "Unknown";
    }
  }
}

class SmartChatTurn {
  final String text;
  final bool isUser;

  const SmartChatTurn({
    required this.text,
    required this.isUser,
  });
}

enum SmartModelState { live, fallback, inactive }

class SmartModelBadge {
  final String name;
  final String detail;
  final SmartModelState state;

  const SmartModelBadge({
    required this.name,
    required this.detail,
    required this.state,
  });
}

class SmartChatReply {
  final String reply;
  final String statusLine;
  final List<SmartModelBadge> activeModels;
  final List<SmartRecommendation> recommendations;

  const SmartChatReply({
    required this.reply,
    required this.statusLine,
    required this.activeModels,
    required this.recommendations,
  });
}

class SmartRecommendation {
  final String title;
  final String subtitle;
  final String reason;
  final IconData icon;
  final String route;
  final Color accentColor;

  const SmartRecommendation({
    required this.title,
    required this.subtitle,
    required this.reason,
    required this.icon,
    required this.route,
    required this.accentColor,
  });
}

class SmartChatService {
  SmartChatService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static String get _backendUrl {
    const envUrl = String.fromEnvironment('SMART_CHAT_BACKEND_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    try {
      if (io.Platform.isAndroid) {
        return 'https://8e705ba3cd3992.lhr.life'; // Public URL bypasses firewall!
      }
    } catch (_) {}
    
    return 'http://127.0.0.1:8000';
  }

  static bool get hasBackendConfigured => _backendUrl.isNotEmpty;

  String _buildAssistantInstructions(UserContext? ctx) {
    String base = 'You are Zenify bot — a warm, emotionally intelligent ADHD wellness coach and companion. Your role is to:\n'
        '- Understand the user\'s current mood and emotional state through thoughtful questions\n'
        '- Provide evidence-based knowledge about ADHD, focus, and mental wellness\n'
        '- Suggest personalized physical exercises based on the user\'s mood and energy level\n'
        '- Guide users step-by-step toward a specific exercise activity they can start immediately\n'
        '- Remember user preferences, past moods, and exercise history within each session\n\n'
        'You are NOT a therapist or doctor. Always remind users to consult professionals for medical concerns. '
        'Your tone is: warm, non-judgmental, curious, gently motivating — like a knowledgeable friend who genuinely cares.\n'
        'Keep responses conversational, extremely smart, and empathetic.\n\n'
        'HARD RULES — never break these:\n'
        '1. NEVER ask more than one question at a time. Always wait for the user\'s reply.\n'
        '2. NEVER give a generic "here are 10 exercises" list. Always personalize to their mood.\n'
        '3. NEVER dismiss or minimize negative emotions. Always validate first, suggest second.\n'
        '4. NEVER claim to diagnose ADHD or any condition.\n'
        '5. NEVER recommend stopping medication or replacing professional treatment.\n'
        '6. If a user expresses serious distress, self-harm, or crisis: immediately respond with compassion and direct them to a mental health helpline. Do not continue the exercise flow.\n'
        '7. NEVER be preachy or lecture. Share knowledge naturally in 1-2 sentences max.\n'
        '8. Keep responses SHORT. Maximum 3-4 sentences per message. Users with ADHD lose interest with walls of text.\n'
        '9. Use plain language. No jargon. No bullet-point overload in chat.\n'
        '10. ALWAYS end your message with either a question or a clear call to action — never leave the user hanging.\n\n'
        'ADHD KNOWLEDGE (weave naturally, ONE insight per turn max):\n'
        '- ADHD affects executive function, focus, impulse control, and emotional regulation. It is a neurodevelopmental condition, not laziness.\n'
        '- Exercise increases dopamine, norepinephrine, and serotonin. Even a 20-minute walk improves focus for 2-3 hours.\n'
        '- RSD (Rejection Sensitive Dysphoria) causes intense emotional reactions. Exercise is a great non-medication tool for mood regulation.\n'
        '- "Body doubling" helps ADHD people stay on task. Short movement breaks (5-10 min) reset focus better than pushing through.\n\n'
        'MOOD DETECTION RULES — follow these strictly:\n'
        '1. ANGRY or frustrated: Do NOT jump to suggestions immediately. First ask: "That sounds really tough — is there something specific that\'s bothering you right now, or just a general feeling?" Let them vent. Reflect their feelings back briefly before any advice. Suggest high-intensity physical release (boxing bag, fast run, jump rope, burpees).\n'
        '2. SAD or low: Ask gently: "It sounds like you\'re carrying something heavy today. Do you want to talk about it a little?" Suggest gentle movement (walk outside, slow yoga, stretching, breathing exercises).\n'
        '3. ANXIOUS or overwhelmed: Say: "Let\'s slow things down together. Can you take one slow breath with me before we continue?" Suggest grounding exercises, slow walk, box breathing + light movement.\n'
        '4. HAPPY or energetic: Match their energy enthusiastically. Suggest dynamic workouts (HIIT, dance, cycling, team sports).\n'
        '5. NEUTRAL or unclear: Ask 2-3 short questions to figure it out.\n\n'
        'CONVERSATION FLOW — always follow this sequence:\n'
        'STEP 1 — GREETING (first message only, handled mostly by app logic but acknowledge it): "Hi [Name], I am Zenify 👋 I\'m here to help you move and feel better. How are you feeling right now?"\n'
        'STEP 2 — MOOD CHECK-IN: Ask ONE question at a time, never stack questions. (e.g. "On a scale of 1–10, how is your energy right now?")\n'
        'STEP 3 — EMPATHY + REFLECTION: Always reflect what you heard before making suggestions. (e.g. "So it sounds like you are feeling drained... That makes a lot of sense.")\n'
        'STEP 4 — ADHD INSIGHT: Share ONE short ADHD-related insight that fits their situation. (e.g. "Did you know that even 10 minutes of movement can increase dopamine levels? That is exactly what the ADHD brain needs right now.")\n'
        'STEP 5 — EXERCISE SUGGESTION: Suggest 1 primary exercise and 1 alternative. Include Name, Duration, Why it helps, and a call to action ("You can find this in the app under [category]. Want to start?").\n'
        'STEP 6 — CLOSE THE LOOP: Always end with one of: "How does that sound? Want to give it a try?", "Should I save this recommendation for you?", or "Want me to remind you about this one next time?"\n\n'
        'DATA SAVING INSTRUCTIONS:\n'
        'If the conversation reaches a natural conclusion or the user accepts a suggestion, output a structured JSON block at the VERY END of your message inside ```json ... ``` tags exactly like this:\n'
        '```json\n{\n  "session_date": "[today\'s date]",\n  "mood_reported": "[e.g. anxious, tired, happy, angry]",\n  "mood_score_1_to_10": [number],\n  "energy_level_1_to_10": [number],\n  "adhd_insight_shared": "[the fact you shared]",\n  "exercise_recommended": {\n    "name": "[exercise name]",\n    "duration_minutes": [number],\n    "category": "[e.g. cardio, yoga, strength, outdoor]",\n    "reason": "[why this was suggested]"\n  },\n  "exercise_alternative": "[backup exercise name]",\n  "user_accepted_suggestion": true,\n  "follow_up_notes": "[anything the user shared that should be remembered next time]"\n}\n```\n';
    
    if (ctx == null) return base;

    return '$base\n\n'
           'IMPORTANT USER CONTEXT:\n'
           '- Name: ${ctx.name}\n'
           '- Email: ${ctx.email}\n'
           '- Focus Challenge: ${ctx.focusChallenge}\n'
           '- Peak Focus Time: ${ctx.peakFocusTime}\n'
           '- Focus Style: ${ctx.focusStyle}\n'
           '- Today\'s Mood: ${ctx.moodString}\n'
           '- Today\'s Sleep: ${ctx.sleepString}\n'
           '- Pending Tasks: ${ctx.pendingTasks}\n'
           '- Completed Tasks: ${ctx.completedTasks}\n'
           '- Task Details: ${ctx.taskSummary}\n'
           '- Recent Mood History: ${ctx.moodHistory}\n'
           '- Recent Sleep History: ${ctx.sleepHistory}\n'
           '- Meditation/Breathing/Grounding History: ${ctx.meditationHistory}\n'
           '- Focus Strategy History: ${ctx.focusStrategyHistory}\n'
           '- Focus Game History: ${ctx.gameHistory}\n'
           '- Sound Therapy History: ${ctx.soundHistory}\n'
           '- Total Breathing Sessions: ${ctx.totalBreathingSessions}\n'
           '- Total Grounding Sessions: ${ctx.totalGroundingSessions}\n'
           '- Total Game Sessions: ${ctx.totalGameSessions}\n\n'
           'Use this context to personalize your response. If they have pending tasks, name the most useful next step from the task details. If they recently used a strategy, game, breathing, grounding, or sound therapy, acknowledge it and adapt the suggestion.';
  }

  List<SmartModelBadge> initialBadges() => const [];

  Future<SmartChatReply> respond(
    String input, {
    List<SmartChatTurn> history = const [],
    UserContext? context,
  }) async {
    final message = input.trim();
    if (message.isEmpty) {
      return SmartChatReply(
        reply:
            'Hi, I am Zenify.\nWhat is the one thing you want help with right now?',
        statusLine: hasBackendConfigured
            ? 'Zenify Assistant is ready.'
            : 'Zenify Assistant is ready in local support mode.',
        activeModels: const [],
        recommendations: const [],
      );
    }

    if (_isClearlyIrrelevant(message)) {
      return SmartChatReply(
        reply:
            'I am a mental health support bot, so I can only help with wellbeing, focus, sleep, mood, stress, tasks, and app-based suggestions.',
        statusLine: 'Zenify Assistant kept the chat focused on wellbeing.',
        activeModels: const [],
        recommendations: const [],
      );
    }

    try {
      final recentHistory =
          history.length <= 6 ? history : history.sublist(history.length - 6);
      final ensemble = await _collectDrafts(message, recentHistory, context);
      final reply = _composeReply(
        message,
        ensemble.drafts,
        crisisDetected: ensemble.crisisDetected,
        context: context,
      );

      return SmartChatReply(
        reply: reply,
        statusLine: _buildStatusLine(ensemble.drafts),
        activeModels: const [],
        recommendations: const [],
      );
    } catch (_) {
      final fallbackDraft = _localHeuristicDraft(message, context);
      return SmartChatReply(
        reply: _composeReply(
          message,
          [fallbackDraft],
          crisisDetected: _detectCrisis(message),
          context: context,
        ),
        statusLine: 'Zenify Assistant recovered into safe local mode.',
        activeModels: const [],
        recommendations: const [],
      );
    }
  }

  Future<_EnsembleResult> _collectDrafts(
    String message,
    List<SmartChatTurn> history,
    UserContext? context,
  ) async {
    final localFuture = _localBrain(message, history, context);
    final backendFuture = _backendEnsemble(message, history, context);

    final results = await Future.wait<dynamic>([
      localFuture.timeout(
        const Duration(seconds: 2),
        onTimeout: () => _localHeuristicDraft(message, context),
      ),
      backendFuture.timeout(
        const Duration(seconds: 18),
        onTimeout: _backendOfflineResult,
      ),
    ]);

    final localDraft = results[0] as _ModelDraft;
    final backendResult = results[1] as _EnsembleResult;
    final drafts = <_ModelDraft>[localDraft, ...backendResult.drafts];
    final hasUsableDraft = drafts.any((draft) => draft.advice != null);

    return _EnsembleResult(
      drafts: hasUsableDraft ? drafts : [_localHeuristicDraft(message, context)],
      crisisDetected: backendResult.crisisDetected || _detectCrisis(message),
    );
  }

  Future<_EnsembleResult> _backendEnsemble(
    String message,
    List<SmartChatTurn> history,
    UserContext? context,
  ) async {
    if (_backendUrl.isEmpty) {
      return _backendOfflineResult();
    }

    try {
      final response = await _client.post(
        Uri.parse('$_backendUrl/chat/ensemble'),
        headers: const <String, String>{
          'Content-Type': 'application/json',
        },
        body: jsonEncode(<String, Object?>{
          'message': message,
          'system_prompt': _buildAssistantInstructions(context),
          'history': history
              .map(
                (turn) => <String, String>{
                  'role': turn.isUser ? 'user' : 'assistant',
                  'text': turn.text,
                },
              )
              .toList(),
          'include_gemini': true,
          'max_new_tokens': 300,
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return _backendOfflineResult(detail: 'Backend unavailable');
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final replies = decoded['replies'];
      final crisisDetected = decoded['crisis_detected'] == true;
      if (replies is! List) {
        return _backendOfflineResult(detail: 'Invalid backend response');
      }

      final drafts = replies
          .whereType<Map<String, dynamic>>()
          .map((payload) => _draftFromBackendReply(payload, message))
          .toList();

      return _EnsembleResult(
        drafts: drafts,
        crisisDetected: crisisDetected,
      );
    } catch (_) {
      return _backendOfflineResult(detail: 'Backend offline');
    }
  }

  _ModelDraft _draftFromBackendReply(
    Map<String, dynamic> payload,
    String userMessage,
  ) {
    final name = payload['name'] as String? ?? 'Gemini';
    final detail = payload['detail'] as String? ?? 'Unavailable';
    final stateRaw = payload['state'] as String? ?? 'inactive';
    final text = payload['text'] as String?;
    final normalizedState = switch (stateRaw) {
      'live' => SmartModelState.live,
      'fallback' => SmartModelState.fallback,
      _ => SmartModelState.inactive,
    };

    return _ModelDraft(
      name: name,
      detail: detail,
      state: normalizedState,
      advice: text?.trim(),
    );
  }

  Future<_ModelDraft> _localBrain(
    String message,
    List<SmartChatTurn> history,
    UserContext? context,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 220));

    final lowered = message.toLowerCase();
    final advice = _buildHeuristicAdvice(lowered, history, context);

    return _ModelDraft(
      name: 'Zenify Core',
      detail: 'Always-on fallback brain',
      state: SmartModelState.fallback,
      advice: advice,
    );
  }

  String _buildHeuristicAdvice(
    String message,
    List<SmartChatTurn> history,
    UserContext? context,
  ) {
    if (_hasAny(message, const ['hy', 'hello', 'hi', 'hey'])) {
      if (context != null) {
         if (context.mood <= 1 && context.pendingTasks == 0) {
             return 'Hi ${context.name}, I am Zenify. Let\'s keep it simple.\nDo you want to try one calming breath now?';
         } else if (context.pendingTasks > 0) {
             return 'Okay ${context.name}, let\'s keep it simple.\nWhat is the ONE task you want to finish in the next 10 minutes?';
         }
         return 'Hi ${context.name}, I am Zenify.\nWhat do you want to focus on for the next 10 minutes?';
      }
      return 'Hi, I am Zenify.\nWhat is the ONE thing you want help with right now?';
    }

    if (_hasAny(message, const [
      'anxious',
      'stress',
      'panic',
      'nervous',
      'overthinking',
    ])) {
      return 'I hear you. Let\'s slow it down.\nCan you take one deep breath with me now?';
    }

    if (_hasAny(message, const ['my name', 'who am i', 'about me', 'profile'])) {
      if (context != null) {
        return 'You are ${context.name}. Mood: ${context.moodString}. Sleep: ${context.sleepString}.\nWhat do you want to work on for 10 minutes?';
      }
      return 'I could not load your profile yet.\nWhat do you want help with right now?';
    }

    if (_hasAny(message, const ['task', 'tasks', 'todo', 'to do', 'planner'])) {
      if (context != null && context.pendingTasks > 0) {
        return _microStepReply(
          intro: '${context.name}, let\'s break one task down:',
          step1: 'Pick the easiest pending task.',
          step2: 'Open what you need for it.',
          step3: 'Start a 10-minute timer.',
        );
      }
      return _microStepReply(
        intro: 'Let\'s break it down:',
        step1: 'Write the task in one sentence.',
        step2: 'Open the first thing you need.',
        step3: 'Work for 10 minutes only.',
      );
    }

    if (_hasAny(message, const ['game', 'games', 'played', 'focus game'])) {
      if (context != null && context.gameHistory != 'No recent game sessions.') {
        return 'Nice, you already used a focus game.\nWhat small task will you return to now?';
      }
      return 'A focus game can be a quick reset.\nDo you want to play one short round now?';
    }

    if (_hasAny(message, const ['strategy', 'strategies', 'focus strategy'])) {
      if (context != null &&
          context.focusStrategyHistory != 'No recent focus strategies tried.') {
        return 'Good, you have tried a focus strategy before.\nWhat is one task for a 10-minute timer?';
      }
      return 'Let\'s make it easy.\nWhat is the smallest task you can start for 10 minutes?';
    }

    if (_hasAny(message, const [
      'procrastin',
      'stuck',
      'lazy',
      'avoid',
      'start',
    ])) {
      return _microStepReply(
        intro: 'Starting can feel heavy. Let\'s break it down:',
        step1: 'Clear one small space.',
        step2: 'Open the task or app.',
        step3: 'Do only 10 minutes.',
      );
    }

    if (_hasAny(message, const [
      'exam',
      'test',
      'quiz',
      'revision',
      'memor',
      'assignment',
      'study',
    ])) {
      return _microStepReply(
        intro: 'Let\'s make studying smaller:',
        step1: 'Choose one topic.',
        step2: 'Open the notes for that topic.',
        step3: 'Revise for 10 minutes.',
      );
    }

    if (_hasAny(message, const [
      'tired',
      'burnout',
      'drained',
      'sleep',
      'exhausted',
      'low'
    ])) {
      return 'Your energy sounds low.\nDo you want a 2-minute breathing reset first?';
    }

    return 'I hear you. Let\'s keep it simple.\nWhat is the ONE thing you want to handle next?';
  }

  String _microStepReply({
    required String intro,
    required String step1,
    required String step2,
    required String step3,
  }) {
    return '$intro\n'
        'Step 1: $step1\n'
        'Step 2: $step2\n'
        'Step 3: $step3';
  }

  String _composeReply(
    String message,
    List<_ModelDraft> drafts, {
    required bool crisisDetected,
    UserContext? context,
  }) {
    final geminiAdvice = drafts
        .where(
          (draft) =>
              draft.name.toLowerCase().contains('gemini') &&
              draft.state == SmartModelState.live &&
              draft.advice != null,
        )
        .map((draft) => draft.advice!)
        .toList();
    final liveAdvice = drafts
        .where(
          (draft) =>
              !draft.name.toLowerCase().contains('gemini') &&
              draft.state == SmartModelState.live &&
              draft.advice != null,
        )
        .map((draft) => draft.advice!)
        .toList();
    final fallbackAdvice = drafts
        .where(
          (draft) =>
              draft.state == SmartModelState.fallback && draft.advice != null,
        )
        .map((draft) => draft.advice!)
        .toList();
    final allAdvice = [...geminiAdvice, ...liveAdvice, ...fallbackAdvice];
    
    final best = allAdvice.isNotEmpty
        ? allAdvice.first
        : _buildHeuristicAdvice(message.toLowerCase(), const [], context);

    final lines = <String>[
      if (crisisDetected)
        'If you feel you may harm yourself or someone else, contact local emergency services or a trusted person right now.',
      best,
    ];

    return lines.join('\n\n');
  }

  String _buildStatusLine(List<_ModelDraft> drafts) {
    final liveCount =
        drafts.where((draft) => draft.state == SmartModelState.live).length;
    if (liveCount >= 1) {
      return 'Zenify Assistant is online and responding.';
    }
    if (_backendUrl.isEmpty) {
      return 'Zenify Assistant is ready in local support mode.';
    }
    return 'Zenify Assistant is using safe local support because the backend is offline.';
  }

  bool _hasAny(String source, List<String> terms) {
    return terms.any(source.contains);
  }

  bool _detectCrisis(String message) {
    final lowered = message.toLowerCase();
    return _hasAny(lowered, const [
      'suicide',
      'kill myself',
      'end my life',
      'self harm',
      'hurt myself',
      'want to die',
    ]);
  }

  bool _canAnswerLocally(String message) {
    final lowered = message.toLowerCase();
    if (_detectCrisis(lowered)) return false;
    return _hasAny(lowered, const [
      'hy',
      'hi',
      'hey',
      'hello',
      'my name',
      'who am i',
      'about me',
      'profile',
    ]);
  }

  bool _isClearlyIrrelevant(String message) {
    final lowered = message.toLowerCase();
    if (_detectCrisis(lowered)) return false;
    if (_hasAny(lowered, const [
      'hy',
      'hi',
      'hey',
      'hello',
      'mood',
      'feel',
      'feeling',
      'sad',
      'happy',
      'angry',
      'low',
      'stress',
      'stressed',
      'anxious',
      'anxiety',
      'panic',
      'worry',
      'overthinking',
      'sleep',
      'tired',
      'exhausted',
      'burnout',
      'focus',
      'adhd',
      'procrast',
      'lazy',
      'stuck',
      'motivation',
      'task',
      'todo',
      'planner',
      'study',
      'exam',
      'revision',
      'meditat',
      'breath',
      'ground',
      'calm',
      'relax',
      'game',
      'strategy',
      'strategies',
      'exercise',
      'sound',
      'therapy',
      'habit',
      'routine',
      'name',
      'profile',
      'history',
      'my data',
      'about me',
      'who am i',
    ])) {
      return false;
    }

    return _hasAny(lowered, const [
      'write code',
      'programming',
      'flutter code',
      'python',
      'javascript',
      'politics',
      'election',
      'president',
      'movie',
      'song',
      'recipe',
      'shopping',
      'stock price',
      'crypto',
      'football score',
      'cricket score',
      'solve math',
      'history of',
      'capital of',
      'weather',
    ]);
  }

  _ModelDraft _localHeuristicDraft(String message, UserContext? context) {
    return _ModelDraft(
      name: 'Zenify Core',
      detail: 'Always-on fallback brain',
      state: SmartModelState.fallback,
      advice: _buildHeuristicAdvice(message.toLowerCase(), const [], context),
    );
  }

  _EnsembleResult _backendOfflineResult({String detail = 'Backend offline'}) {
    return _EnsembleResult(
      drafts: [
        _ModelDraft(
          name: 'Gemini',
          detail: detail,
          state: SmartModelState.inactive,
        ),
      ],
      crisisDetected: false,
    );
  }

  void dispose() {
    _client.close();
  }
}

class _EnsembleResult {
  final List<_ModelDraft> drafts;
  final bool crisisDetected;

  const _EnsembleResult({
    required this.drafts,
    required this.crisisDetected,
  });
}

class _ModelDraft {
  final String name;
  final String detail;
  final SmartModelState state;
  final String? advice;

  const _ModelDraft({
    required this.name,
    required this.detail,
    required this.state,
    this.advice,
  });
}

