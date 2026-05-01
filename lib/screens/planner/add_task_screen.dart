import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/activity_service.dart';

const Color _primaryColor = Color(0xFF755F84);

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  DateTime? selectedDate;
  String priority = 'Medium';
  String category = 'Study';
  bool _saving = false;

  final List<String> _categories = [
    'Study', 'Meeting', 'Travelling', 'Exercise', 'Personal', 'Work'
  ];

  String get _userId => FirebaseAuth.instance.currentUser?.uid ?? '';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: _primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _saveTask() async {
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a task title')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('tasks')
          .add({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': category,
        'priority': priority,
        'priorityOrder': priority == 'High' ? 1 : (priority == 'Medium' ? 2 : 3),
        'done': false,
        'dueDate': selectedDate?.toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      await ActivityService.recordDaily(
        values: {
          'tasksCreated': FieldValue.increment(1),
          'lastTaskCreated': _titleCtrl.text.trim(),
        },
        points: 2,
      );

      if (mounted) {
        Navigator.pop(context, true); // true = task was added
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving task: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Add New Task',
          style: TextStyle(
            color: Color(0xff3a2355),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff3a2355)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _label('Task Title *'),
            _inputField(
              controller: _titleCtrl,
              hint: 'Enter task title',
            ),
            const SizedBox(height: 16),

            // Description
            _label('Description'),
            _inputField(
              controller: _descCtrl,
              hint: 'Write task details (optional)',
              maxLines: 3,
            ),
            const SizedBox(height: 20),

            // Category
            _label('Category'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((c) {
                final selected = category == c;
                return GestureDetector(
                  onTap: () => setState(() => category = c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? _primaryColor
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? _primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color:
                        selected ? Colors.white : Colors.black87,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Due Date
            _label('Due Date'),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selectedDate != null
                        ? _primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      selectedDate == null
                          ? 'Select date (optional)'
                          : DateFormat('dd MMM yyyy')
                          .format(selectedDate!),
                      style: TextStyle(
                        fontSize: 14,
                        color: selectedDate == null
                            ? Colors.grey
                            : const Color(0xff3a2355),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: selectedDate != null
                          ? _primaryColor
                          : Colors.grey,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Priority
            _label('Priority'),
            Row(
              children: [
                _priorityBtn('Low', const Color(0xFF957C2E)),
                _priorityBtn('Medium', const Color(0xFF7D509F)),
                _priorityBtn('High', const Color(0xFF976565)),
              ],
            ),
            const SizedBox(height: 32),

            // Save button
            _saving
                ? const Center(
              child: CircularProgressIndicator(
                valueColor:
                AlwaysStoppedAnimation(_primaryColor),
              ),
            )
                : SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Save Task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
        color: Color(0xff608ba5),
      ),
    ),
  );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) =>
      TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide:
            const BorderSide(color: _primaryColor, width: 1.5),
          ),
        ),
      );

  Widget _priorityBtn(String label, Color color) {
    final selected = priority == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => priority = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? color : color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
