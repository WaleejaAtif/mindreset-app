import 'dart:io';

void main() {
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('lib directory not found');
    return;
  }

  final files = libDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));

  for (final file in files) {
    final path = file.path.replaceAll('\\', '/');
    if (path.contains('games.dart') ||
        path.contains('learning_assistant.dart') ||
        path.contains('meditate/meditate.dart') ||
        path.contains('meditate/breathing_exercises.dart') ||
        path.contains('meditate/sound_therapy.dart')) {
      continue;
    }

    var content = file.readAsStringSync();
    final originalContent = content;

    content = content.replaceAll(
      RegExp(r'foregroundColor:\s*(?:const\s*)?Color\(0xFF1A1333\)'),
      'foregroundColor: Colors.white',
    );
    content = content.replaceAll(
      RegExp(r'Color _textColor = Color\(0xFF1A1333\);'),
      'Color _textColor = Colors.white;',
    );

    // Replace color: Color(0xFF1A1333) inside TextStyle(...)
    content = content.replaceAllMapped(RegExp(r'(TextStyle|Icon|TextSpan)\s*\([^)]+\)'), (match) {
      return match.group(0)!.replaceAll('Color(0xFF1A1333)', 'Colors.white');
    });

    if (content != originalContent) {
      file.writeAsStringSync(content);
      print('Fixed $path');
    }
  }
}
