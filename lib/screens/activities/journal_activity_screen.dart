import 'package:flutter/material.dart';

class JournalActivityScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final String category;
  final List<String>? suggestions;

  const JournalActivityScreen({super.key, required this.item, required this.category, this.suggestions});

  @override
  State<JournalActivityScreen> createState() => _JournalActivityScreenState();
}

class _JournalActivityScreenState extends State<JournalActivityScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.item['colorHex'] ?? 0xFF9a882a);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFFFFF)),
        title: Text(widget.item['title'] ?? 'Journal', style: const TextStyle(color: Color(0xFFFFFFFF))),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item['desc'] ?? 'Write down your thoughts below.',
                style: const TextStyle(fontSize: 18, color: Color(0xFFFFFFFF), fontWeight: FontWeight.w500),
              ),
              if (widget.suggestions != null && widget.suggestions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Ideas to get started:", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFAFA8BA))),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.suggestions!.map((s) => ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    backgroundColor: color.withOpacity(0.1),
                    side: BorderSide.none,
                    onPressed: () {
                      setState(() {
                        _controller.text = _controller.text + (_controller.text.isEmpty ? "" : "\n") + s;
                      });
                    },
                  )).toList(),
                ),
              ],
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A1333),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Color(0xFFFFFFFF).withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Start typing here...",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // For now, we return true to indicate completion. 
                    // In the future, the text could be passed back to be saved in Firestore if needed:
                    // Navigator.pop(context, _controller.text);
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    "Finish & Claim Points",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1333)),
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

