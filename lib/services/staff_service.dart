import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StaffService {
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
        .collection('staff_tasks')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Add Task
  Future<void> addTask(String title, String time) async {
    await _db.collection('staff_tasks').add({
      'title': title,
      'isDone': false,
      'timestamp': FieldValue.serverTimestamp(),
      'timeLabel': time,
    });
  }

  // Toggle Status
  Future<void> toggleTask(String taskId, bool currentStatus) async {
    await _db.collection('staff_tasks').doc(taskId).update({
      'isDone': !currentStatus,
    });
  }

  // Update Task Title (New)
  Future<void> updateTask(
    String taskId,
    String newTitle,
    String newTime,
  ) async {
    await _db.collection('staff_tasks').doc(taskId).update({
      'title': newTitle,
      'timeLabel': newTime,
    });
  }

  // Delete Task
  Future<void> deleteTask(String taskId) async {
    await _db.collection('staff_tasks').doc(taskId).delete();
  }

  // --- ACTIVITIES ---
  Stream<QuerySnapshot> getRecentActivities() {
    return _db
        .collection('announcements')
        .orderBy('postedDate', descending: true)
        .limit(5)
        .snapshots();
  }

  // --- HOD ACTIVITIES (dedicated feed) ---
  Stream<QuerySnapshot> getHodActivities({String department = 'MCA'}) {
    return _db
        .collection('hod_activities')
        .where('department', isEqualTo: department)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  Future<void> logHodActivity({
    required String title,
    required String subtitle,
    required String icon, // e.g. 'assignment', 'people', 'check_circle'
    String department = 'MCA',
  }) async {
    await _db.collection('hod_activities').add({
      'title': title,
      'subtitle': subtitle,
      'icon': icon,
      'department': department,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- PROFILE ---
  Stream<DocumentSnapshot> getProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _db
        .collection('users')
        .doc(userId)
        .set(data, SetOptions(merge: true));
  }

  // --- ASSIGNMENTS ---

  // Create Assignment
  Future<void> createAssignment(Map<String, dynamic> assignmentData) async {
    // 1. Create the master assignment entry
    await _db.collection('assignments_master').add({
      ...assignmentData,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 2. Create an alert/notification for students
    final dueDate = assignmentData['dueDate'] as Timestamp;
    final dateStr = DateFormat('dd MMM').format(dueDate.toDate());

    await _db.collection('announcements').add({
      'title': 'New Assignment: ${assignmentData['title']}',
      'content':
          'Subject: ${assignmentData['subject']}. Due by $dateStr. Check assignments section for details.',
      'type': 'assignment',
      'postedDate': FieldValue.serverTimestamp(),
      'isActive': true,
      'priority': 'medium',
      'collegeCode': assignmentData['collegeCode'] ?? '',
      'department': assignmentData['department'] ?? 'MCA',
      'semester': assignmentData['semester']?.toString() ?? '1',
    });

    // 3. Log for HOD dashboard
    await logHodActivity(
      title: 'New Assignment Created',
      subtitle: '${assignmentData['title']} - ${assignmentData['subject']}',
      icon: 'assignment',
    );
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> getStaffAssignments(
    String staffId,
  ) {
    // Fetch all and filter in memory to be robust against missing indexes or slight data mismatches
    return _db.collection('assignments_master').snapshots().map((snapshot) {
      final assignments = snapshot.docs.where((doc) {
        final data = doc.data();
        final String? docStaffId = data['staffId']?.toString();

        // Basic matching by staffId
        return docStaffId == staffId;
      }).toList();

      // Sort in memory (newest first)
      assignments.sort((a, b) {
        final aTime = a.data()['timestamp'];
        final bTime = b.data()['timestamp'];

        if (aTime is! Timestamp && bTime is! Timestamp) return 0;
        if (aTime is! Timestamp) return -1; // Pending first
        if (bTime is! Timestamp) return 1;

        return bTime.compareTo(aTime);
      });

      return assignments;
    });
  }

  // Get Submissions for an Assignment
  Stream<QuerySnapshot> getSubmissions(String assignmentId) {
    return _db
        .collection('submissions')
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots();
  }

  // Mark Submission (Update grade & feedback)
  Future<void> markSubmission(
    String submissionId,
    String grade,
    String feedback,
  ) async {
    await _db.collection('submissions').doc(submissionId).update({
      'grade': grade,
      'feedback': feedback,
      'status': 'marked',
      'markedDate': FieldValue.serverTimestamp(),
    });
  }

  // Update Assignment
  Future<void> updateAssignment(String id, Map<String, dynamic> data) async {
    await _db.collection('assignments_master').doc(id).update(data);
  }

  // Delete Assignment and its Submissions
  Future<void> deleteAssignment(String id) async {
    // 1. Delete all submissions related to this assignment
    final submissions = await _db
        .collection('submissions')
        .where('assignmentId', isEqualTo: id)
        .get();

    final batch = _db.batch();
    for (var doc in submissions.docs) {
      batch.delete(doc.reference);
    }

    // 2. Delete the master assignment
    batch.delete(_db.collection('assignments_master').doc(id));

    await batch.commit();
  }

  // Helper: Delete assignment by title
  Future<void> deleteAssignmentByTitle(String title) async {
    final snapshot = await _db
        .collection('assignments_master')
        .where('title', isEqualTo: title)
        .get();

    for (var doc in snapshot.docs) {
      await deleteAssignment(doc.id);
    }
  }

  // Helper: Clear all submissions (Database Reset)
  Future<void> clearAllSubmissions() async {
    final submissions = await _db.collection('submissions').get();
    final batch = _db.batch();
    for (var doc in submissions.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // Get All Students in a department/semester for assignment creation
  Future<List<DocumentSnapshot>> getStudentsForAssignment(
    String dept,
    String semester,
  ) async {
    // 1. Try 'students' collection first
    final studentQuery = await _db
        .collection('students')
        .where('department', isEqualTo: dept)
        .where('semester', isEqualTo: semester)
        .get();

    if (studentQuery.docs.isNotEmpty) {
      return studentQuery.docs;
    }

    // 2. Fallback: Try 'users' collection for students
    final userQuery = await _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('department', isEqualTo: dept)
        // Note: Semester might be stored as int or string in users, handle carefully in UI
        .get();

    // Filter by semester manually to handle type mismatch (int vs string)
    final filteredUsers = userQuery.docs.where((doc) {
      final data = doc.data();
      return data['semester'].toString() == semester.toString();
    }).toList();

    return filteredUsers;
  }
}
