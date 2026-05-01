import 'dart:async';
import 'dart:convert';

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

  static const String _backendUrl = String.fromEnvironment(
    'SMART_CHAT_BACKEND_URL',
    defaultValue: 'http://192.168.18.26:8000',
  );

  static bool get hasBackendConfigured => _backendUrl.isNotEmpty;

  String _buildAssistantInstructions(UserContext? ctx) {
    String base = 'You are Zenify Assistant, a role-based mental health and focus support bot inside the MindReset app. '
        'Your main job is mental wellness, stress, mood, sleep, focus, study burnout, tasks, meditation, breathing, grounding, focus strategies, and focus games. '
        'For vague, casual, emotional, or app-related messages, answer helpfully and connect the reply to wellbeing or focus. '
        'Only refuse clearly unrelated requests. If the user asks about coding, politics, general facts, entertainment, shopping, finance, sports, weather, or unrelated homework, reply: "I am a mental health support bot, so I can only help with wellbeing, focus, sleep, mood, stress, tasks, and app-based suggestions." '
        'You are not a doctor or therapist. Do not diagnose. For crisis or self-harm, tell the user to contact local emergency services or a trusted person immediately. '
        'Keep responses warm, practical, and plain text. Usually give 3 to 5 helpful sentences with one clear next step. '
        'Always personalize using the user context when available. Mention their name naturally, not in every sentence. '
        'If the user says "hy", "hi", or similar, greet them with their name if available and say you are Zenify. '
        'Suggest app tools based on evidence: breathing/grounding for anxiety, focus strategies for task paralysis, games for short cognitive reset, task splitting for pending work, and sleep guidance when sleep is poor.';
    
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
        reply: 'Hi, I am Zenify Assistant. How can I help you today?',
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
        const Duration(seconds: 120),
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
          'max_new_tokens': 320,
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
             return 'Hello ${context.name}, I am Zenify. I can see you are feeling low, but you have completed all your tasks. Let\'s relax first with a breathing exercise from the meditation section.';
         } else if (context.pendingTasks > 0) {
             return 'Hello ${context.name}, I am Zenify. I see you have ${context.pendingTasks} tasks pending. Don\'t worry, divide them into small steps and start with one.';
         }
         return 'Hello ${context.name}, I am Zenify. How are you doing? I am here to assist.';
      }
      return 'Hello, I am Zenify. How are you doing? I am here to assist.';
    }

    if (_hasAny(message, const [
      'anxious',
      'stress',
      'panic',
      'nervous',
      'overthinking',
    ])) {
      return 'I hear that you are feeling stressed. Why don\'t we try a gentle breathing exercise to calm your mind?';
    }

    if (_hasAny(message, const ['my name', 'who am i', 'about me', 'profile'])) {
      if (context != null) {
        return 'You are ${context.name}. Today your mood is ${context.moodString}, your sleep is ${context.sleepString}, and you have ${context.pendingTasks} pending task(s).';
      }
      return 'I could not load your profile yet. Please try again after your profile finishes loading.';
    }

    if (_hasAny(message, const ['task', 'tasks', 'todo', 'to do', 'planner'])) {
      if (context != null && context.pendingTasks > 0) {
        return '${context.name}, you have ${context.pendingTasks} pending task(s). Pick the smallest one first, work for 10 minutes, then take a short reset. ${context.taskSummary}';
      }
      return 'Your task list looks clear right now. This is a good moment for a short breathing exercise or a focus game to maintain momentum.';
    }

    if (_hasAny(message, const ['game', 'games', 'played', 'focus game'])) {
      if (context != null && context.gameHistory != 'No recent game sessions.') {
        return 'I can see your recent focus game activity: ${context.gameHistory}. Use games as a short reset, then return to one small task.';
      }
      return 'Focus games can help as a quick reset. Play one short round, then come back to your next task.';
    }

    if (_hasAny(message, const ['strategy', 'strategies', 'focus strategy'])) {
      if (context != null &&
          context.focusStrategyHistory != 'No recent focus strategies tried.') {
        return 'You recently tried: ${context.focusStrategyHistory}. Let\'s build on that with one small timed session.';
      }
      return 'Try one focus strategy now: clear your workspace, set a 10-minute timer, and start the smallest task.';
    }

    if (_hasAny(message, const [
      'procrastin',
      'stuck',
      'lazy',
      'avoid',
      'start',
    ])) {
      return 'It can be hard to start. Let\'s pick one tiny task for 10 minutes.';
    }

    if (_hasAny(message, const ['exam', 'test', 'quiz', 'revision', 'memor'])) {
      return 'Exams can be overwhelming. Let\'s do a quick revision quiz together to build confidence.';
    }

    if (_hasAny(message, const [
      'tired',
      'burnout',
      'drained',
      'sleep',
      'exhausted',
      'low'
    ])) {
      return 'It sounds like your energy is low. I suggest playing a relaxing game in the app to gently recharge.';
    }

    return 'I hear you. Take it step by step, and let me know if you want to try a calming exercise.';
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
      return 'Zenify Assistant is connected and responding.';
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
