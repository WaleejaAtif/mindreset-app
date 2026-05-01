import 'dart:ui';

import 'package:flutter/material.dart';

import '../services/smart_chat_service.dart';
import '../services/activity_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/animated_background.dart';

class LearningAssistantScreen extends StatefulWidget {
  const LearningAssistantScreen({super.key});

  @override
  State<LearningAssistantScreen> createState() => _LearningAssistantScreenState();
}

class _LearningAssistantScreenState extends State<LearningAssistantScreen> {
  final SmartChatService _chatService = SmartChatService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isThinking = false;
  UserContext? _userContext;
  
  List<_ChatEntry> _messages = const [
    _ChatEntry(
      text: 'Loading your profile...',
      isUser: false,
    ),
  ];
  String _statusLine = 'Zenify Assistant is ready.';

  @override
  void initState() {
    super.initState();
    _loadUserContext();
  }

  Future<void> _loadUserContext() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final uid = user.uid;

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      // 1. Get profile data
      final userDoc = await userRef.get();
      final profile = userDoc.data() ?? <String, dynamic>{};
      final firstName = _stringValue(profile['firstName']);
      final lastName = _stringValue(profile['lastName']);
      final fullName = [firstName, lastName]
          .where((part) => part.isNotEmpty)
          .join(' ')
          .trim();
      final name = _stringValue(
        profile['displayName'] ??
            profile['name'] ??
            (fullName.isNotEmpty ? fullName : null) ??
            user.displayName ??
            user.email?.split('@')[0],
        fallback: 'User',
      );
      final email = _stringValue(profile['email'] ?? user.email);
      final focusStyle = _stringValue(profile['focusStyle']);
      final focusChallenge = _joinList(profile['struggles']);
      final peakFocusTime = _stringValue(profile['timeOfDay']);

      // 2. Get Mood & Sleep for today
      final today = DateTime.now();
      final dateKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
      final logDoc = await userRef.collection('daily_logs').doc(dateKey).get();
      
      int mood = 2; // Default Okay
      int sleep = 2; // Default Fair
      if (logDoc.exists) {
        final data = logDoc.data()!;
        mood = _intValue(data['moodIndex'], fallback: mood);
        sleep = _intValue(data['sleepIndex'], fallback: sleep);
      } else {
        // Fallback to legacy mood_data if daily_logs missing
        final legacyLog = await userRef.collection('mood_data').doc(dateKey).get();
        if (legacyLog.exists) {
          final lData = legacyLog.data()!;
          mood = _intValue(lData['mood'], fallback: mood);
          sleep = _intValue(lData['sleep'], fallback: sleep);
        }
      }

      // 3. Get Tasks
      final tasksQuery = await userRef.collection('tasks').get();
      int completed = 0;
      int pending = 0;
      final pendingTaskNames = <String>[];
      for (var doc in tasksQuery.docs) {
        final data = doc.data();
        if (data['done'] == true) {
          completed++;
        } else {
          pending++;
          if (pendingTaskNames.length < 5) {
            final title = _stringValue(data['title']);
            final priority = _stringValue(data['priority']);
            final category = _stringValue(data['category']);
            pendingTaskNames.add([
              if (title.isNotEmpty) title,
              if (priority.isNotEmpty) 'priority: $priority',
              if (category.isNotEmpty) 'category: $category',
            ].join(' (') + (priority.isNotEmpty || category.isNotEmpty ? ')' : ''));
          }
        }
      }
      final taskSummary = pendingTaskNames.isEmpty
          ? 'No pending task details.'
          : pendingTaskNames.join('; ');

      // 4. Get recent app history for smarter responses.
      final dailyLogs = await userRef
          .collection('daily_logs')
          .orderBy(FieldPath.documentId, descending: true)
          .limit(7)
          .get();
      final moodHistory = _summarizeDailyLogs(dailyLogs.docs, 'mood');
      final sleepHistory = _summarizeDailyLogs(dailyLogs.docs, 'sleep');

      final meditationLogs = await userRef
          .collection('meditation_logs')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      final meditationHistory = _summarizeDocs(
        meditationLogs.docs,
        (data) => [
          _stringValue(data['category']),
          _stringValue(data['exercise'] ?? data['type']),
          data['completed'] == true ? 'completed' : 'started',
        ].where((part) => part.isNotEmpty).join(' - '),
        fallback: 'No recent meditation sessions.',
      );

      final focusLogs = await userRef
          .collection('focus_strategy_logs')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      final focusStrategyHistory = _summarizeDocs(
        focusLogs.docs,
        (data) => _stringValue(data['strategyTitle'] ?? data['title']),
        fallback: 'No recent focus strategies tried.',
      );

      final gameLogs = await userRef
          .collection('game_sessions')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();
      final gameHistory = _summarizeDocs(
        gameLogs.docs,
        (data) => [
          _stringValue(data['game']),
          _stringValue(data['result']),
          data['score'] == null ? '' : 'score ${data['score']}',
        ].where((part) => part.isNotEmpty).join(' - '),
        fallback: 'No recent game sessions.',
      );

      final soundLogs = await userRef
          .collection('sound_sessions')
          .orderBy('timestamp', descending: true)
          .limit(3)
          .get();
      final soundHistory = _summarizeDocs(
        soundLogs.docs,
        (data) => _stringValue(data['sound']),
        fallback: 'No recent sound therapy sessions.',
      );

      _userContext = UserContext(
        name: name,
        email: email,
        focusStyle: focusStyle.isEmpty ? 'Not set' : focusStyle,
        focusChallenge: focusChallenge.isEmpty ? 'Not set' : focusChallenge,
        peakFocusTime: peakFocusTime.isEmpty ? 'Not set' : peakFocusTime,
        mood: mood,
        sleep: sleep,
        pendingTasks: pending,
        completedTasks: completed,
        taskSummary: taskSummary,
        moodHistory: moodHistory,
        sleepHistory: sleepHistory,
        meditationHistory: meditationHistory,
        focusStrategyHistory: focusStrategyHistory,
        gameHistory: gameHistory,
        soundHistory: soundHistory,
        totalBreathingSessions:
            _intValue(profile['totalBreathingSessions'], fallback: 0),
        totalGroundingSessions:
            _intValue(profile['totalGroundingSessions'], fallback: 0),
        totalGameSessions: _intValue(profile['totalGameSessions'], fallback: 0),
      );

      // Generate greeting logic
      String greeting =
          'Hello ${_userContext!.name}, I am Zenify. How are you doing? I am here to assist.';
      if (_userContext!.mood <= 1 && _userContext!.pendingTasks == 0) {
        greeting =
            "Hello ${_userContext!.name}, I am Zenify. I can see you are feeling low, but you have completed all your tasks. Since your task list is clear, let's help you relax first with a breathing exercise from the meditation section.";
      } else if (_userContext!.pendingTasks > 0) {
        greeting =
            "Hello ${_userContext!.name}, I am Zenify. I see you have ${_userContext!.pendingTasks} tasks pending. Don't worry, divide them into small steps and start with one.";
      }

      if (mounted) {
        setState(() {
          _messages = [
            _ChatEntry(
              text: greeting,
              isUser: false,
            ),
          ];
        });
      }
    } catch (e) {
      debugPrint("Error loading user context: $e");
      if (mounted) {
        setState(() {
          _messages = [
            const _ChatEntry(
              text: 'Hi, I am Zenify Assistant. How can I help you today?',
              isUser: false,
            ),
          ];
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? preset]) async {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty || _isThinking) return;

    final history = _messages
        .map((entry) => SmartChatTurn(text: entry.text, isUser: entry.isUser))
        .toList();

    _controller.clear();
    FocusScope.of(context).unfocus();

    setState(() {
      _messages = [
        ..._messages,
        _ChatEntry(text: text, isUser: true),
      ];
      _isThinking = true;
      _statusLine = 'Thinking through the best response for you...';
    });
    _scrollToBottom();

    try {
      final reply = await _chatService.respond(text, history: history, context: _userContext);
      if (!mounted) return;
      await ActivityService.recordDaily(
        values: {
          'aiChats': FieldValue.increment(1),
          'chattedWithAi': true,
        },
      );

      setState(() {
        _messages = [
          ..._messages,
          _ChatEntry(text: reply.reply, isUser: false),
        ];
        _statusLine = reply.statusLine;
        _isThinking = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _messages = [
          ..._messages,
          const _ChatEntry(
            text:
                'Something went wrong while generating the reply, so I switched back to safe local support. Please try your message again.',
            isUser: false,
          ),
        ];
        _statusLine = 'The assistant recovered into safe local mode.';
        _isThinking = false;
      });
    }

    _scrollToBottom();
  }

  void _resetChat() {
    setState(() {
      _messages = const [
        _ChatEntry(
          text: 'Hi, I am Zenify Assistant. How can I help you today?',
          isUser: false,
        ),
      ];
      _statusLine = 'Zenify Assistant is ready.';
      _isThinking = false;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 220,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String _stringValue(dynamic value, {String fallback = ''}) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  int _intValue(dynamic value, {required int fallback}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  String _joinList(dynamic value) {
    if (value is Iterable) {
      return value.map((item) => item.toString()).where((item) => item.isNotEmpty).join(', ');
    }
    return _stringValue(value);
  }

  String _summarizeDailyLogs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String fieldPrefix,
  ) {
    final parts = <String>[];
    for (final doc in docs) {
      final data = doc.data();
      final label = _stringValue(data[fieldPrefix]);
      final index = data['${fieldPrefix}Index'];
      if (label.isNotEmpty) {
        parts.add('${doc.id}: $label');
      } else if (index != null) {
        parts.add('${doc.id}: $index/4');
      }
    }
    if (parts.isEmpty) return 'No recent $fieldPrefix history.';
    return parts.take(7).join('; ');
  }

  String _summarizeDocs(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String Function(Map<String, dynamic> data) buildLine, {
    required String fallback,
  }) {
    final parts = docs
        .map((doc) => buildLine(doc.data()))
        .where((line) => line.trim().isNotEmpty)
        .take(5)
        .toList();
    return parts.isEmpty ? fallback : parts.join('; ');
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 14),
                    Expanded(child: _buildChatShell()),
                  ],
                ),
              ),
            ),
          ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.15),
                Colors.white.withOpacity(0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Zenify Assistant',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'A simple AI chat assistant for calm support and thoughtful conversation.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        height: 1.35,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildHeaderButton(
                icon: Icons.refresh_rounded,
                onTap: _isThinking ? null : _resetChat,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
      ),
    );
  }

  Widget _buildChatShell() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          child: Column(
            children: [
              _buildTopPanel(),
              Expanded(child: _buildMessages()),
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Column(
        children: [
          _buildStatusBanner(),
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF203A57).withOpacity(0.95),
            const Color(0xFF2C5364).withOpacity(0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.bolt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _statusLine,
              style: const TextStyle(
                color: Colors.white,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      children: [
        ..._messages.map(_buildMessageBubble),
        if (_isThinking)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F536F).withOpacity(0.88),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'Thinking through the best answer for you...',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMessageBubble(_ChatEntry message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUser
                  ? [
                      const Color(0xFF7A5EA2).withOpacity(0.96),
                      const Color(0xFF6E85F5).withOpacity(0.92),
                    ]
                  : [
                      const Color(0xFF284766).withOpacity(0.94),
                      const Color(0xFF335D7D).withOpacity(0.90),
                    ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(22),
              topRight: const Radius.circular(22),
              bottomLeft: Radius.circular(isUser ? 22 : 8),
              bottomRight: Radius.circular(isUser ? 8 : 22),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              color: Colors.white,
              height: 1.46,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.16),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Chat with Zenify Assistant...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.56)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.08),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF56C7B8), Color(0xFF6E8EF6)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF56C7B8).withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              onPressed: _isThinking ? null : () => _sendMessage(),
              icon: Icon(
                _isThinking ? Icons.hourglass_top_rounded : Icons.send_rounded,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEntry {
  final String text;
  final bool isUser;

  const _ChatEntry({
    required this.text,
    required this.isUser,
  });
}
