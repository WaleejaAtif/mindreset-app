import 'package:flutter/material.dart';

class ChecklistActivityScreen extends StatefulWidget {
  final Map<String, dynamic> item;
  final List<String>? suggestions;

  const ChecklistActivityScreen({super.key, required this.item, this.suggestions});

  @override
  State<ChecklistActivityScreen> createState() => _ChecklistActivityScreenState();
}

class _ChecklistActivityScreenState extends State<ChecklistActivityScreen> {
  final List<Map<String, dynamic>> _tasks = [];
  final TextEditingController _controller = TextEditingController();

  void _addTask(String title) {
    if (title.trim().isEmpty) return;
    setState(() {
      _tasks.add({'title': title.trim(), 'completed': false});
    });
    _controller.clear();
  }

  void _toggleTask(int index) {
    setState(() {
      _tasks[index]['completed'] = !_tasks[index]['completed'];
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.item['colorHex'] ?? 0xFFb3957c);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F8FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: Text(widget.item['title'] ?? 'Break Tasks', style: const TextStyle(color: Colors.black87)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.item['desc'] ?? '',
                style: const TextStyle(fontSize: 16, color: Colors.black87),
              ),
              if (widget.suggestions != null && widget.suggestions!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: widget.suggestions!.map((s) => ActionChip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    backgroundColor: color.withOpacity(0.1),
                    side: BorderSide.none,
                    onPressed: () => _addTask(s),
                  )).toList(),
                ),
              ],
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: "Add a smaller step...",
                    hintStyle: const TextStyle(color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add_circle, color: color),
                      onPressed: () => _addTask(_controller.text),
                    ),
                  ),
                  onSubmitted: _addTask,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _tasks.isEmpty
                    ? Center(
                        child: Text(
                          "No steps yet. Break down your big task above!",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tasks.length,
                        itemBuilder: (context, index) {
                          final task = _tasks[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: task['completed'] ? color.withOpacity(0.5) : Colors.transparent),
                            ),
                            child: ListTile(
                              leading: Checkbox(
                                value: task['completed'],
                                activeColor: color,
                                onChanged: (val) => _toggleTask(index),
                              ),
                              title: Text(
                                task['title'],
                                style: TextStyle(
                                  decoration: task['completed'] ? TextDecoration.lineThrough : null,
                                  color: task['completed'] ? Colors.grey : Colors.black87,
                                ),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                                onPressed: () => _removeTask(index),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                  child: const Text(
                    "Finish & Claim Points",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
