import os
import re

def process_file(filepath):
    # Skip specific files
    if "games.dart" in filepath or "learning_assistant.dart" in filepath:
        return
    if "meditate\\meditate.dart" in filepath or "meditate/meditate.dart" in filepath:
        return
    if "meditate\\breathing_exercises.dart" in filepath or "meditate/breathing_exercises.dart" in filepath:
        return
    if "meditate\\sound_therapy.dart" in filepath or "meditate/sound_therapy.dart" in filepath:
        return

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # Replace foregroundColor
    content = re.sub(r'foregroundColor:\s*(?:const\s*)?Color\(0xFF1A1333\)', 'foregroundColor: Colors.white', content)
    
    # Replace textColor constants
    content = re.sub(r'Color _textColor = Color\(0xFF1A1333\);', 'Color _textColor = Colors.white;', content)

    # Replace inside TextStyle, Icon, TextSpan, etc using a regex that looks behind for these words.
    # Python's lookbehind needs fixed width, so we can't use it easily.
    # Instead, we will replace `color: Color(0xFF1A1333)` with `color: Colors.white` everywhere
    # AND THEN change back `backgroundColor: Colors.white` to `backgroundColor: Color(0xFF1A1333)`
    # AND change `color: Colors.white` inside `BoxDecoration` or `Container` back to `color: Color(0xFF1A1333)`? 
    # That's too risky.
    
    # Let's use re.sub with a custom function to match any property block and replace inside it
    def replace_text_colors(match):
        text = match.group(0)
        return text.replace('Color(0xFF1A1333)', 'Colors.white')

    # Match TextStyle(...) and Icon(...) and TextSpan(...) blocks roughly
    content = re.sub(r'(?:TextStyle|Icon|TextSpan)\s*\([^)]+\)', replace_text_colors, content)

    # Match Text(..., style: TextStyle(...)) blocks roughly (nested parens might not match, but we already matched TextStyle)
    
    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

def main():
    lib_dir = os.path.join(os.getcwd(), 'lib')
    for root, dirs, files in os.walk(lib_dir):
        for file in files:
            if file.endswith('.dart'):
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
