import 'package:cloud_firestore/cloud_firestore.dart';

class AdminService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- TOP STATS ---
  Stream<int> getCount(String collectionName) {
    return _db
        .collection(collectionName)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // --- TASKS ---

  // Get Tasks
  Stream<QuerySnapshot> getTasks() {
    return _db
        .collection('admin_tasks')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add Task
  Future<void> addTask(String title, String time) async {
    await _db.collection('admin_tasks').add({
      'title': title,
      'isDone': false,
      'timestamp': FieldValue.serverTimestamp(),
      'timeLabel': time,
    });
  }

  // Toggle Status
  Future<void> toggleTask(String taskId, bool currentStatus) async {
    await _db.collection('admin_tasks').doc(taskId).update({
      'isDone': !currentStatus,
    });
  }

  // Update Task Title (New)
  Future<void> updateTask(
    String taskId,
    String newTitle,
    String newTime,
  ) async {
    await _db.collection('admin_tasks').doc(taskId).update({
      'title': newTitle,
      'timeLabel': newTime,
    });
  }

  // Delete Task
  Future<void> deleteTask(String taskId) async {
    await _db.collection('admin_tasks').doc(taskId).delete();
  }

  // --- ACTIVITIES ---
  Stream<QuerySnapshot> getAdminActivities() {
    return _db
        .collection('admin_activities')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .snapshots();
  }

  Future<void> logAdminActivity({
    required String title,
    required String subtitle,
    required String type, // e.g. 'user_added', 'department_updated', 'system'
  }) async {
    await _db.collection('admin_activities').add({
      'title': title,
      'subtitle': subtitle,
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Legacy fallback or other uses
  Stream<QuerySnapshot> getRecentActivities() {
    return _db
        .collection('announcements')
        .orderBy('postedDate', descending: true)
        .limit(20)
        .snapshots();
  }

  // --- PROFILE ---
  Stream<DocumentSnapshot> getProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }
}
