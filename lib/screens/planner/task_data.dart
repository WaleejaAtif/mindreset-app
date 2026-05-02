class Task {
  final String id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final int priorityOrder;
  final bool done;
  final DateTime? dueDate;
  final DateTime? createdAt;

  Task({
    this.id = '',
    required this.title,
    this.description = '',
    required this.category,
    required this.priority,
    this.done = false,
    this.dueDate,
    this.createdAt,
  }) : priorityOrder = priority == 'High' ? 1 : (priority == 'Medium' ? 2 : 3);

  // Convert Firestore doc → Task
  factory Task.fromMap(String id, Map<String, dynamic> map) {
    return Task(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      priority: map['priority'] ?? 'Medium',
      done: map['done'] ?? false,
      dueDate: map['dueDate'] != null
          ? DateTime.tryParse(map['dueDate'])
          : null,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : null,
    );
  }

  // Convert Task → Firestore map
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'category': category,
      'priority': priority,
      'priorityOrder': priorityOrder,
      'done': done,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
