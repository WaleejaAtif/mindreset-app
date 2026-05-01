import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityService {
  static String dateKey([DateTime? date]) {
    final value = date ?? DateTime.now();
    return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  }

  static String readableTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final suffix = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static DocumentReference<Map<String, dynamic>>? _userRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance.collection('users').doc(user.uid);
  }

  static Future<void> addPoints(int points) async {
    final userRef = _userRef();
    if (userRef == null || points == 0) return;
    await userRef.set({
      'points': FieldValue.increment(points),
    }, SetOptions(merge: true));
  }

  static Future<void> recordDaily({
    required Map<String, dynamic> values,
    int points = 0,
  }) async {
    final userRef = _userRef();
    if (userRef == null) return;
    if (points != 0) {
      await addPoints(points);
    }
    await userRef.collection('daily_logs').doc(dateKey()).set({
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> logActivity({
    required String collection,
    required Map<String, dynamic> data,
    Map<String, dynamic> dailyValues = const {},
    int points = 0,
  }) async {
    final userRef = _userRef();
    if (userRef == null) return;
    if (points != 0) {
      await addPoints(points);
    }
    await userRef.collection(collection).add({
      ...data,
      'date': dateKey(),
      'timestamp': FieldValue.serverTimestamp(),
    });
    if (dailyValues.isNotEmpty) {
      await userRef.collection('daily_logs').doc(dateKey()).set({
        ...dailyValues,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
