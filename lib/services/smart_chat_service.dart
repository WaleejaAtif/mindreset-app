import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UserContext {
  final String name;
  final int mood; // 0 (Very Low) to 4 (Great)
  final int sleep; // 0 (Terrible) to 4 (Amazing)
  final int pendingTasks;
  final int completedTasks;

  const UserContext({
    required this.name,
    required this.mood,
    required this.sleep,
    required this.pendingTasks,
    required this.completedTasks,
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

  static final String _backendUrl = 'http://192.168.18.26:8000';

  static bool get hasBackendConfigured => _backendUrl.isNotEmpty;

  String _buildAssistantInstructions(UserContext? ctx) {
    String base = 'You are Zenify Assistant, a friendly mental wellness bot. '
        'Keep your responses simple, short, and plain text. '
        'If the user says "hy", "hi", or similar, reply exactly: "Hy, how are you doing? I am here to assist." '
        'If the user is feeling low, tired, or overwhelmed, suggest a suitable simple exercise within the app like playing some games or breathing.';
    
    if (ctx == null) return base;

    return '$base\n\n'
           'IMPORTANT USER CONTEXT:\n'
           '- Name: ${ctx.name}\n'
           '- Today\'s Mood: ${ctx.moodString}\n'
           '- Today\'s Sleep: ${ctx.sleepString}\n'
           '- Pending Tasks: ${ctx.pendingTasks}\n'
           '- Completed Tasks: ${ctx.completedTasks}\n'
           'Use this context to personalize your responses. If they have tasks pending, encourage them to divide and conquer.';
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
          'max_new_tokens': 128,
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
             return 'Hello ${context.name}, you are feeling low but you have completed all your tasks! Since you don\'t have any tasks in the list, let\'s get you relaxed at first. Try a breathing exercise from our meditation section.';
         } else if (context.pendingTasks > 0) {
             return 'Hello ${context.name}, I see you have ${context.pendingTasks} tasks pending. Don\'t worry, divide the tasks and take it step by step! I am here to assist.';
         }
         return 'Hy ${context.name}, how are you doing? I am here to assist.';
      }
      return 'Hy, how are you doing? I am here to assist.';
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
    final liveAdvice = drafts
        .where(
          (draft) =>
              draft.state == SmartModelState.live && draft.advice != null,
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
    final allAdvice = [...liveAdvice, ...fallbackAdvice];
    
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
