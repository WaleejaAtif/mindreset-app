import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/activity_service.dart';
import '../widgets/animated_background.dart';

// ─────────────────────────────────────────────
//  GAMES SCREEN  (hub)
// ─────────────────────────────────────────────
class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  static const List<_GameMeta> _games = [
    _GameMeta(
      title: 'Balance Puzzle',
      subtitle: 'Moon & Star logic puzzle',
      emoji: '🌓',
      color: Color(0xFF6C3DD6),
      rules: [
        'Tap cells to cycle empty, moon, and star.',
        'Match the hidden valid board.',
        'Solve with fewer moves for a bonus.',
      ],
      scoring: ['Solve puzzle: +15 loot', 'Efficient solve bonus: up to +5 loot'],
      builder: _BalancePuzzleGame.new,
    ),
    _GameMeta(
      title: 'Wordle',
      subtitle: 'Guess the 5-letter word',
      emoji: '🟩',
      color: Color(0xFF2E7D32),
      rules: [
        'Guess the 5-letter focus word.',
        'Green means correct place, yellow means correct letter.',
        'You have 6 attempts.',
      ],
      scoring: ['Win: +15 loot', 'Lose after trying: +3 loot'],
      builder: _WordleGame.new,
    ),
    _GameMeta(
      title: 'Tetris',
      subtitle: 'Classic block stacking',
      emoji: '🟦',
      color: Color(0xFF0277BD),
      rules: [
        'Move and rotate blocks to complete rows.',
        'Completed rows increase your score.',
        'Game ends when new pieces cannot spawn.',
      ],
      scoring: ['Every 100 score: +3 loot', 'Maximum per session: +20 loot'],
      builder: _TetrisGame.new,
    ),
    _GameMeta(
      title: '2048',
      subtitle: 'Slide tiles to reach 2048',
      emoji: '🔢',
      color: Color(0xFFE65100),
      rules: [
        'Swipe to merge matching tiles.',
        'Build larger numbers without filling the board.',
        'Reach 2048 to win.',
      ],
      scoring: ['Reach 2048: +30 loot', 'Game over score bonus: up to +25 loot'],
      builder: _Game2048.new,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AnimatedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Focus Games',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1333),
              fontSize: 22,
            ),
          ),
        ),
        body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Train your mind 🧠',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.88,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                      ),
                      itemCount: _games.length,
                      itemBuilder: (context, i) => _GameCard(meta: _games[i]),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Game metadata holder
// ─────────────────────────────────────────────
class _GameMeta {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final List<String> rules;
  final List<String> scoring;
  final Widget Function() builder;
  const _GameMeta({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.rules,
    required this.scoring,
    required this.builder,
  });
}

class _GameCard extends StatelessWidget {
  final _GameMeta meta;
  const _GameCard({required this.meta});

  Future<void> _logGameStarted() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'totalGameSessions': FieldValue.increment(1),
      'lastGamePlayed': meta.title,
      'lastGamePlayedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('game_sessions')
        .add({
      'game': meta.title,
      'result': 'started',
      'timestamp': FieldValue.serverTimestamp(),
    });
    await ActivityService.recordDaily(
      values: {
        'gamesPlayed': FieldValue.increment(1),
        'lastGamePlayed': meta.title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await _logGameStarted();
        if (!context.mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => _GameRulesScreen(meta: meta)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              meta.color.withOpacity(0.85),
              meta.color.withOpacity(0.55),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Color(0x3DFFFFFF), width: 1),
          boxShadow: [
            BoxShadow(
              color: meta.color.withOpacity(0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(meta.emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 10),
            Text(
              meta.title,
              style: const TextStyle(
                color: Color(0xFF1A1333),
                fontWeight: FontWeight.bold,
                fontSize: 16,
                fontFamily: 'LeagueSpartan',
              ),
            ),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                meta.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameRulesScreen extends StatelessWidget {
  final _GameMeta meta;

  const _GameRulesScreen({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121826),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1333)),
        title: Text(meta.title, style: const TextStyle(color: Color(0xFF1A1333))),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Text(meta.emoji, style: const TextStyle(fontSize: 64))),
              const SizedBox(height: 18),
              Text(
                meta.subtitle,
                style: const TextStyle(
                  color: Color(0xFF1A1333),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _RulePanel(title: 'Rules', lines: meta.rules, color: meta.color),
              const SizedBox(height: 14),
              _RulePanel(title: 'Loot scoring', lines: meta.scoring, color: meta.color),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: meta.color,
                    foregroundColor: Color(0xFF1A1333),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => meta.builder()),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text(
                    'Start Game',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RulePanel extends StatelessWidget {
  final String title;
  final List<String> lines;
  final Color color;

  const _RulePanel({
    required this.title,
    required this.lines,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1333).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(color: Color(0xB3FFFFFF), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _awardGameLoot({
  required String game,
  required String result,
  required int points,
  int? score,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
  await userRef.set({
    'points': FieldValue.increment(points),
    'lastGameResult': result,
    'lastGameScore': score,
    'lastGameReward': points,
    'lastGameRewardAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
  await userRef.collection('game_sessions').add({
    'game': game,
    'result': result,
    'score': score,
    'pointsAwarded': points,
    'date': ActivityService.dateKey(),
    'timestamp': FieldValue.serverTimestamp(),
  });
  await ActivityService.recordDaily(
    values: {
      'gameCompletedToday': true,
      'lastGameCompleted': game,
      'lastGameReward': points,
      if (score != null) 'lastGameScore': score,
      if (points >= 15) 'goodGameScore': true,
    },
  );
}

// ═══════════════════════════════════════════════════════════════════
//  GAME 1 — BALANCE PUZZLE  (Moon & Star logic)
//  Inspired by hsynadguzel/balance-puzzle
//  Rules: place moons and stars so each row and column
//  has exactly half of each, matching the hidden solution.
// ═══════════════════════════════════════════════════════════════════
class _BalancePuzzleGame extends StatefulWidget {
  const _BalancePuzzleGame();
  @override
  State<_BalancePuzzleGame> createState() => _BalancePuzzleGameState();
}

class _BalancePuzzleGameState extends State<_BalancePuzzleGame> {
  static const int _size = 6;
  // 0 = empty, 1 = moon, 2 = star
  late List<List<int>> _board;
  late List<List<bool>> _locked;
  bool _solved = false;
  bool _rewarded = false;
  int _moves = 0;

  // A valid 6x6 solution
  static const List<List<int>> _solution = [
    [1, 2, 1, 2, 1, 2],
    [2, 1, 2, 1, 2, 1],
    [1, 1, 2, 2, 1, 2],
    [2, 2, 1, 1, 2, 1],
    [1, 2, 2, 1, 2, 1],
    [2, 1, 1, 2, 1, 2],
  ];

  @override
  void initState() {
    super.initState();
    _initBoard();
  }

  void _initBoard() {
    _board = List.generate(_size, (r) => List.filled(_size, 0));
    _locked = List.generate(_size, (r) => List.filled(_size, false));
    _solved = false;
    _rewarded = false;
    _moves = 0;
    final rng = Random();
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (rng.nextDouble() < 0.30) {
          _board[r][c] = _solution[r][c];
          _locked[r][c] = true;
        }
      }
    }
  }

  void _tap(int r, int c) {
    if (_locked[r][c] || _solved) return;
    setState(() {
      _board[r][c] = (_board[r][c] + 1) % 3;
      _moves++;
      _checkWin();
    });
  }

  void _checkWin() {
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_board[r][c] != _solution[r][c]) return;
      }
    }
    _solved = true;
    if (!_rewarded) {
      _rewarded = true;
      final bonus = (5 - (_moves ~/ 8)).clamp(0, 5).toInt();
      _awardGameLoot(
        game: 'Balance Puzzle',
        result: 'solved',
        points: 15 + bonus,
        score: _moves,
      );
    }
  }

  Color _cellColor(int r, int c) {
    if (_locked[r][c]) return const Color(0xFF4A3580);
    final v = _board[r][c];
    if (v == 0) return Color(0x1AFFFFFF);
    if (v == 1) return const Color(0xFF7B52E8).withOpacity(0.7);
    return const Color(0xFFFFD600).withOpacity(0.7);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1035),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A1A55),
        title: const Text('Balance Puzzle',
            style: TextStyle(color: Color(0xFF1A1333))),
        iconTheme: const IconThemeData(color: Color(0xFF1A1333)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1333)),
            onPressed: () => setState(_initBoard),
          )
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12),
            child: Text(
              'Tap to cycle: empty → 🌙 → ⭐\nEach row & column needs 3 moons + 3 stars',
              style: TextStyle(color: Color(0x99FFFFFF), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            _statBadge('Moves', '$_moves'),
            const SizedBox(width: 20),
            _statBadge('Status', _solved ? '✅ Solved!' : '🔄 Playing'),
          ]),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _size,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _size * _size,
                    itemBuilder: (_, idx) {
                      final r = idx ~/ _size, c = idx % _size;
                      final v = _board[r][c];
                      return GestureDetector(
                        onTap: () => _tap(r, c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: _cellColor(r, c),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _locked[r][c]
                                  ? Colors.purpleAccent.withOpacity(0.7)
                                  : Color(0x1FFFFFFF),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              v == 0 ? '' : (v == 1 ? '🌙' : '⭐'),
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_solved)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const Text('🎉 Puzzle Solved!',
                      style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6C3DD6)),
                    onPressed: () => setState(_initBoard),
                    child: const Text('New Puzzle',
                        style: TextStyle(color: Color(0xFF1A1333))),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Color(0x1FFFFFFF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label,
                style: const TextStyle(color: Color(0x8AFFFFFF), fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Color(0xFF1A1333),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      );
}

// ═══════════════════════════════════════════════════════════════════
//  GAME 2 — WORDLE CLONE
//  Inspired by Spid3r0/Wordle-Clone-FlutterWordGame
// ═══════════════════════════════════════════════════════════════════
class _WordleGame extends StatefulWidget {
  const _WordleGame();
  @override
  State<_WordleGame> createState() => _WordleGameState();
}

class _WordleGameState extends State<_WordleGame> {
  static const List<String> _wordList = [
    'BRAIN', 'PEACE', 'FOCUS', 'DREAM', 'HEART',
    'SMILE', 'RELAX', 'THINK', 'SLEEP', 'LIGHT',
    'GRACE', 'TRUST', 'BLOOM', 'QUIET', 'CLEAR',
    'POWER', 'PLANT', 'FLAME', 'OCEAN', 'CLOUD',
    'STONE', 'WATER', 'EARTH', 'FRESH', 'SWEET',
  ];

  late String _target;
  final List<String> _guesses = [];
  String _current = '';
  bool _won = false;
  bool _lost = false;
  bool _rewarded = false;
  final Map<String, int> _letterState = {};
  static const int _maxGuesses = 6;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final rng = Random();
    _target = _wordList[rng.nextInt(_wordList.length)];
    _guesses.clear();
    _current = '';
    _won = false;
    _lost = false;
    _rewarded = false;
    _letterState.clear();
  }

  void _type(String ch) {
    if (_won || _lost || _current.length >= 5) return;
    setState(() => _current += ch);
  }

  void _delete() {
    if (_current.isEmpty) return;
    setState(() => _current = _current.substring(0, _current.length - 1));
  }

  void _submit() {
    if (_current.length < 5 || _won || _lost) return;
    setState(() {
      _guesses.add(_current);
      _updateLetterStates(_current);
      if (_current == _target) {
        _won = true;
        _rewardWordle(points: 15, result: 'won');
      } else if (_guesses.length >= _maxGuesses) {
        _lost = true;
        _rewardWordle(points: 3, result: 'lost');
      }
      _current = '';
    });
  }

  void _rewardWordle({required int points, required String result}) {
    if (_rewarded) return;
    _rewarded = true;
    _awardGameLoot(
      game: 'Wordle',
      result: result,
      points: points,
      score: _guesses.length,
    );
  }

  void _updateLetterStates(String guess) {
    for (int i = 0; i < 5; i++) {
      final ch = guess[i];
      if (_target[i] == ch) {
        _letterState[ch] = 3;
      } else if (_target.contains(ch)) {
        if ((_letterState[ch] ?? 0) < 2) _letterState[ch] = 2;
      } else {
        if ((_letterState[ch] ?? 0) == 0) _letterState[ch] = 1;
      }
    }
  }

  List<int> _evalGuess(String guess) {
    final result = List.filled(5, 1);
    final remaining = _target.split('');
    for (int i = 0; i < 5; i++) {
      if (guess[i] == _target[i]) {
        result[i] = 3;
        remaining[i] = '';
      }
    }
    for (int i = 0; i < 5; i++) {
      if (result[i] == 3) continue;
      final idx = remaining.indexOf(guess[i]);
      if (idx != -1) {
        result[i] = 2;
        remaining[idx] = '';
      }
    }
    return result;
  }

  Color _stateColor(int state) {
    switch (state) {
      case 3: return const Color(0xFF538D4E);
      case 2: return const Color(0xFFB59F3B);
      case 1: return const Color(0xFF3A3A3C);
      default: return Colors.transparent;
    }
  }

  Color _keyColor(String ch) {
    switch (_letterState[ch] ?? 0) {
      case 3: return const Color(0xFF538D4E);
      case 2: return const Color(0xFFB59F3B);
      case 1: return const Color(0xFF3A3A3C);
      default: return const Color(0xFF818384);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121213),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1B),
        title: const Text('Wordle', style: TextStyle(color: Color(0xFF1A1333))),
        iconTheme: const IconThemeData(color: Color(0xFF1A1333)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1333)),
            onPressed: () => setState(_newGame),
          )
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int row = 0; row < _maxGuesses; row++) _buildRow(row),
              ],
            ),
          ),
          if (_won)
            const Text('🎉 You got it!',
                style: TextStyle(
                    color: Color(0xFF538D4E),
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          if (_lost)
            Text('The word was $_target',
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          _buildKeyboard(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildRow(int row) {
    List<String> letters;
    List<int> states;
    if (row < _guesses.length) {
      letters = _guesses[row].split('');
      states = _evalGuess(_guesses[row]);
    } else if (row == _guesses.length && !_won && !_lost) {
      letters = _current.padRight(5).split('');
      states = List.filled(5, -1);
    } else {
      letters = List.filled(5, '');
      states = List.filled(5, -1);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(5, (col) {
          final ch = letters[col].trim();
          final state = states[col];
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 52,
            height: 52,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: state == -1
                  ? (ch.isEmpty ? Colors.transparent : const Color(0xFF3A3A3C))
                  : _stateColor(state),
              border: Border.all(
                color: ch.isNotEmpty
                    ? const Color(0xFF565758)
                    : const Color(0xFF3A3A3C),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Center(
              child: Text(ch,
                  style: const TextStyle(
                      color: Color(0xFF1A1333),
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeyboard() {
    final rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENT', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'DEL'],
    ];
    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((ch) {
              final isSpecial = ch == 'ENT' || ch == 'DEL';
              return GestureDetector(
                onTap: () {
                  if (ch == 'ENT') _submit();
                  else if (ch == 'DEL') _delete();
                  else _type(ch);
                },
                child: Container(
                  width: isSpecial ? 48 : 32,
                  height: 46,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: isSpecial ? const Color(0xFF818384) : _keyColor(ch),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(ch,
                        style: const TextStyle(
                            color: Color(0xFF1A1333),
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  GAME 3 — TETRIS
//  Inspired by priyanshudutta04/Tetris
// ═══════════════════════════════════════════════════════════════════

const int _tRows = 20;
const int _tCols = 10;

const List<List<List<List<int>>>> _tetrominoes = [
  // I
  [[[0,0],[0,1],[0,2],[0,3]], [[0,0],[1,0],[2,0],[3,0]]],
  // O
  [[[0,0],[0,1],[1,0],[1,1]]],
  // T
  [[[0,1],[1,0],[1,1],[1,2]], [[0,0],[1,0],[2,0],[1,1]],
   [[0,0],[0,1],[0,2],[1,1]], [[0,1],[1,1],[2,1],[1,0]]],
  // S
  [[[0,1],[0,2],[1,0],[1,1]], [[0,0],[1,0],[1,1],[2,1]]],
  // Z
  [[[0,0],[0,1],[1,1],[1,2]], [[0,1],[1,0],[1,1],[2,0]]],
  // J
  [[[0,0],[1,0],[1,1],[1,2]], [[0,0],[0,1],[1,0],[2,0]],
   [[0,0],[0,1],[0,2],[1,2]], [[0,1],[1,1],[2,0],[2,1]]],
  // L
  [[[0,2],[1,0],[1,1],[1,2]], [[0,0],[1,0],[2,0],[2,1]],
   [[0,0],[0,1],[0,2],[1,0]], [[0,0],[0,1],[1,1],[2,1]]],
];

const List<Color> _pieceColors = [
  Color(0xFF00BFFF), Color(0xFFFFD700), Color(0xFF9B59B6),
  Color(0xFF2ECC71), Color(0xFFE74C3C), Color(0xFF3498DB), Color(0xFFE67E22),
];

class _TetrisGame extends StatefulWidget {
  const _TetrisGame();
  @override
  State<_TetrisGame> createState() => _TetrisGameState();
}

class _TetrisGameState extends State<_TetrisGame> {
  late List<List<int>> _board;
  late List<List<int>> _piece;
  late int _pieceType, _rot, _px, _py;
  Timer? _timer;
  int _score = 0;
  bool _gameOver = false, _started = false;
  bool _rewarded = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    _board = List.generate(_tRows, (_) => List.filled(_tCols, 0));
    _score = 0;
    _gameOver = false;
    _rewarded = false;
    _started = true;
    _spawnPiece();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (!_gameOver) setState(_moveDown);
    });
  }

  void _spawnPiece() {
    _pieceType = Random().nextInt(_tetrominoes.length);
    _rot = 0;
    _piece = _tetrominoes[_pieceType][_rot];
    _px = 0;
    _py = _tCols ~/ 2 - 1;
    if (!_canPlace(_piece, _px, _py)) {
      setState(() => _gameOver = true);
      _timer?.cancel();
      _rewardTetris();
    }
  }

  void _rewardTetris() {
    if (_rewarded) return;
    _rewarded = true;
    final points = (_score ~/ 100 * 3).clamp(3, 20).toInt();
    _awardGameLoot(
      game: 'Tetris',
      result: 'game_over',
      points: points,
      score: _score,
    );
  }

  bool _canPlace(List<List<int>> piece, int row, int col) {
    for (final cell in piece) {
      final r = row + cell[0], c = col + cell[1];
      if (r < 0 || r >= _tRows || c < 0 || c >= _tCols) return false;
      if (_board[r][c] != 0) return false;
    }
    return true;
  }

  void _moveDown() {
    if (_canPlace(_piece, _px + 1, _py)) {
      _px++;
    } else {
      _lock();
    }
  }

  void _lock() {
    for (final cell in _piece) {
      _board[_px + cell[0]][_py + cell[1]] = _pieceType + 1;
    }
    _clearLines();
    _spawnPiece();
  }

  void _clearLines() {
    int cleared = 0;
    for (int r = _tRows - 1; r >= 0; r--) {
      if (_board[r].every((c) => c != 0)) {
        _board.removeAt(r);
        _board.insert(0, List.filled(_tCols, 0));
        cleared++;
        r++;
      }
    }
    _score += cleared * 100;
  }

  void _rotate() {
    final rots = _tetrominoes[_pieceType];
    final next = (_rot + 1) % rots.length;
    if (_canPlace(rots[next], _px, _py)) {
      setState(() { _rot = next; _piece = rots[_rot]; });
    }
  }

  void _moveLeft() {
    if (_canPlace(_piece, _px, _py - 1)) setState(() => _py--);
  }

  void _moveRight() {
    if (_canPlace(_piece, _px, _py + 1)) setState(() => _py++);
  }

  void _hardDrop() {
    while (_canPlace(_piece, _px + 1, _py)) _px++;
    setState(_lock);
  }

  List<List<int>> _renderGrid() {
    final grid = List.generate(_tRows, (r) => List<int>.from(_board[r]));
    if (!_gameOver) {
      for (final cell in _piece) {
        final r = _px + cell[0], c = _py + cell[1];
        if (r >= 0 && r < _tRows && c >= 0 && c < _tCols) {
          grid[r][c] = _pieceType + 1;
        }
      }
    }
    return grid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      appBar: AppBar(
        backgroundColor: const Color(0xFF161B22),
        title: const Text('Tetris', style: TextStyle(color: Color(0xFF1A1333))),
        iconTheme: const IconThemeData(color: Color(0xFF1A1333)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Center(
              child: Text('Score: $_score',
                  style: const TextStyle(
                      color: Color(0xFF1A1333), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: !_started
          ? Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0277BD),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 36, vertical: 16)),
                onPressed: () => setState(_start),
                child: const Text('Start Game',
                    style: TextStyle(color: Color(0xFF1A1333), fontSize: 18)),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: _tCols / _tRows,
                      child: LayoutBuilder(builder: (ctx, box) {
                        final cellW = box.maxWidth / _tCols;
                        final cellH = box.maxHeight / _tRows;
                        final grid = _renderGrid();
                        return Stack(
                          children: [
                            Container(color: const Color(0xFF0D1117)),
                            for (int r = 0; r < _tRows; r++)
                              for (int c = 0; c < _tCols; c++)
                                if (grid[r][c] != 0)
                                  Positioned(
                                    left: c * cellW,
                                    top: r * cellH,
                                    width: cellW - 1,
                                    height: cellH - 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: _pieceColors[grid[r][c] - 1],
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ),
                            CustomPaint(
                              size: Size(box.maxWidth, box.maxHeight),
                              painter: _GridPainter(_tRows, _tCols, cellW, cellH),
                            ),
                            if (_gameOver)
                              Container(
                                color: Color(0xFFAFA8BA),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('GAME OVER',
                                          style: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 28,
                                              fontWeight: FontWeight.bold)),
                                      Text('Score: $_score',
                                          style: const TextStyle(
                                              color: Color(0xFF1A1333), fontSize: 20)),
                                      const SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed: () => setState(_start),
                                        child: const Text('Restart'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                Container(
                  color: const Color(0xFF161B22),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ctrlBtn(Icons.arrow_left, _moveLeft),
                      _ctrlBtn(Icons.rotate_right, _rotate),
                      _ctrlBtn(Icons.arrow_downward, _hardDrop),
                      _ctrlBtn(Icons.arrow_right, _moveRight),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _ctrlBtn(IconData icon, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF21262D),
            shape: BoxShape.circle,
            border: Border.all(color: Color(0x3DFFFFFF)),
          ),
          child: Icon(icon, color: Color(0xFF1A1333), size: 26),
        ),
      );
}

class _GridPainter extends CustomPainter {
  final int rows, cols;
  final double cellW, cellH;
  _GridPainter(this.rows, this.cols, this.cellW, this.cellH);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Color(0x1AFFFFFF)..strokeWidth = 0.5;
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * cellH), Offset(size.width, r * cellH), paint);
    }
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cellW, 0), Offset(c * cellW, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_) => true;
}

// ═══════════════════════════════════════════════════════════════════
//  GAME 4 — 2048
//  Inspired by banghuazhao/classic_2048
// ═══════════════════════════════════════════════════════════════════
class _Game2048 extends StatefulWidget {
  const _Game2048();
  @override
  State<_Game2048> createState() => _Game2048State();
}

class _Game2048State extends State<_Game2048> {
  static const int _size = 4;
  late List<List<int>> _board;
  int _score = 0;
  bool _won = false, _over = false;
  bool _rewarded = false;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    _board = List.generate(_size, (_) => List.filled(_size, 0));
    _score = 0;
    _won = false;
    _over = false;
    _rewarded = false;
    _addTile();
    _addTile();
  }

  void _addTile() {
    final empty = <List<int>>[];
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_board[r][c] == 0) empty.add([r, c]);
      }
    }
    if (empty.isEmpty) return;
    final pos = empty[Random().nextInt(empty.length)];
    _board[pos[0]][pos[1]] = Random().nextDouble() < 0.9 ? 2 : 4;
  }

  List<int> _merge(List<int> row) {
    final filtered = row.where((v) => v != 0).toList();
    for (int i = 0; i < filtered.length - 1; i++) {
      if (filtered[i] == filtered[i + 1]) {
        _score += filtered[i] * 2;
        filtered[i] *= 2;
        if (filtered[i] == 2048) _won = true;
        filtered.removeAt(i + 1);
      }
    }
    while (filtered.length < _size) filtered.add(0);
    return filtered;
  }

  void _move(String dir) {
    final prev = List.generate(_size, (r) => List<int>.from(_board[r]));
    for (int i = 0; i < _size; i++) {
      if (dir == 'left') {
        _board[i] = _merge(_board[i]);
      } else if (dir == 'right') {
        _board[i] = _merge(_board[i].reversed.toList()).reversed.toList();
      } else if (dir == 'up') {
        final col = List.generate(_size, (r) => _board[r][i]);
        final merged = _merge(col);
        for (int r = 0; r < _size; r++) _board[r][i] = merged[r];
      } else {
        final col = List.generate(_size, (r) => _board[r][i]).reversed.toList();
        final merged = _merge(col);
        for (int r = 0; r < _size; r++) _board[_size - 1 - r][i] = merged[r];
      }
    }
    bool changed = false;
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_board[r][c] != prev[r][c]) { changed = true; break; }
      }
      if (changed) break;
    }
    if (changed) _addTile();
    _checkOver();
    if (_won) {
      _reward2048(result: 'won', points: 30);
    } else if (_over) {
      final points = (_score ~/ 512 * 5).clamp(3, 25).toInt();
      _reward2048(result: 'game_over', points: points);
    }
    setState(() {});
  }

  void _reward2048({required String result, required int points}) {
    if (_rewarded) return;
    _rewarded = true;
    _awardGameLoot(
      game: '2048',
      result: result,
      points: points,
      score: _score,
    );
  }

  void _checkOver() {
    if (_board.any((row) => row.any((v) => v == 0))) return;
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size - 1; c++) {
        if (_board[r][c] == _board[r][c + 1]) return;
      }
    }
    for (int c = 0; c < _size; c++) {
      for (int r = 0; r < _size - 1; r++) {
        if (_board[r][c] == _board[r + 1][c]) return;
      }
    }
    _over = true;
  }

  Color _tileColor(int v) {
    const map = {
      0: Color(0xFFCDC1B4), 2: Color(0xFFEEE4DA), 4: Color(0xFFEDE0C8),
      8: Color(0xFFF2B179), 16: Color(0xFFF59563), 32: Color(0xFFF67C5F),
      64: Color(0xFFF65E3B), 128: Color(0xFFEDCF72), 256: Color(0xFFEDCC61),
      512: Color(0xFFEDC850), 1024: Color(0xFFEDC53F), 2048: Color(0xFFEDC22E),
    };
    return map[v] ?? const Color(0xFF3C3A32);
  }

  Color _textColor(int v) => v <= 4 ? const Color(0xFF776E65) : Color(0xFF1A1333);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8EF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBBADA0),
        title: const Text('2048',
            style: TextStyle(
                color: Color(0xFF1A1333), fontWeight: FontWeight.bold, fontSize: 22)),
        iconTheme: const IconThemeData(color: Color(0xFF1A1333)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFBBADA0),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('SCORE',
                        style: TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    Text('$_score',
                        style: const TextStyle(
                            color: Color(0xFF1A1333),
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF1A1333)),
            onPressed: () => setState(_newGame),
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (d) => _dragStart = d.localPosition,
            onPanEnd: (d) {
              if (_dragStart == null || _over) return;
              final delta = d.localPosition - _dragStart!;
              String dir;
              if (delta.dx.abs() > delta.dy.abs()) {
                dir = delta.dx > 0 ? 'right' : 'left';
              } else {
                dir = delta.dy > 0 ? 'down' : 'up';
              }
              _move(dir);
              _dragStart = null;
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFBBADA0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _size,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _size * _size,
                      itemBuilder: (_, idx) {
                        final r = idx ~/ _size, c = idx % _size;
                        final v = _board[r][c];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          decoration: BoxDecoration(
                            color: _tileColor(v),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              v == 0 ? '' : '$v',
                              style: TextStyle(
                                color: _textColor(v),
                                fontSize: v >= 1000 ? 20 : 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_won || _over)
            Container(
              color: Color(0x73FFFFFF),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF8EF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _won ? '🏆 You reached 2048!' : '😔 Game Over',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _won
                              ? const Color(0xFFEDC22E)
                              : const Color(0xFF776E65),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text('Score: $_score',
                          style: const TextStyle(
                              fontSize: 18, color: Color(0xFF776E65))),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8F7A66)),
                        onPressed: () => setState(_newGame),
                        child: const Text('New Game',
                            style: TextStyle(color: Color(0xFF1A1333))),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}


