import 'package:cloud_firestore/cloud_firestore.dart';

class StaffComplaintService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _complaintsCollection =>
      _db.collection('staff_complaints');

  // Submit a new complaint
  Future<void> submitComplaint({
    required String staffId,
    required String staffName,
    required String department,
    required String subject,
    required String category,
    required String description,
    String priority = 'Normal',
  }) async {
    await _complaintsCollection.add({
      'staffId': staffId,
      'staffName': staffName,
      'department': department,
      'subject': subject,
      'category': category,
      'description': description,
      'priority': priority,
      'status': 'Pending',
      'submittedAt': Timestamp.now(),
      'adminFeedback': null,
      'resolvedAt': null,
    });
  }

  // Stream complaints for a specific staff member
  Stream<QuerySnapshot> streamStaffComplaints(String staffId) {
    return _complaintsCollection
        .where('staffId', isEqualTo: staffId)
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Stream all complaints for admin
  Stream<QuerySnapshot> streamAllComplaints() {
    return _complaintsCollection
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Update complaint status (for admin)
  Future<void> updateComplaintStatus(
    String id,
    String status, {
    String? feedback,
  }) async {
    await _complaintsCollection.doc(id).update({
      'status': status,
      if (feedback != null) 'adminFeedback': feedback,
      if (status == 'Resolved') 'resolvedAt': Timestamp.now(),
    });
  }
}

