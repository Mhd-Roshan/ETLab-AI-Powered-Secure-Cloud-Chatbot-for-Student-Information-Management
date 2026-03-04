import 'package:cloud_firestore/cloud_firestore.dart';

class ScholarshipService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _requestsCollection =>
      _db.collection('student_requests');
  CollectionReference get _configCollection => _db.collection('system_config');

  // Stream screen configuration
  Stream<DocumentSnapshot> streamScreenConfig() {
    return _configCollection.doc('cert_scholarship').snapshots();
  }

  // Stream requests filtered by department
  Stream<QuerySnapshot> streamRequests({String? department}) {
    Query query = _requestsCollection.where(
      'category',
      whereIn: ['Certificate', 'Scholarship'],
    );

    if (department != null &&
        department != 'MCA' &&
        department != 'College Admin') {
      query = query.where('department', isEqualTo: department);
    }

    // Removing OrderBy to prevent immediate index requirement errors
    return query.snapshots();
  }

  // Update request status
  Future<void> updateRequestStatus(
    String requestId,
    String status, {
    String? feedback,
  }) async {
    await _requestsCollection.doc(requestId).update({
      'status': status,
      'processedDate': FieldValue.serverTimestamp(),
      if (feedback != null) 'staffFeedback': feedback,
    });
  }

  // Seed initial config and dummy data
  Future<void> seedInitialData() async {
    // 1. Seed Config
    final configDoc = await _configCollection.doc('cert_scholarship').get();
    if (!configDoc.exists) {
      await _configCollection.doc('cert_scholarship').set({
        'title': "Certificates & Scholarships",
        'intro':
            "Review and process student applications for academic certificates and various merit-based scholarships.",
        'version': "v3.1.2026",
      });
    }

    // 2. Seed Dummy Requests
    final snapshot = await _requestsCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final dummyRequests = [
      {
        'studentId': 'STU001',
        'studentName': 'Adarsh S',
        'type': 'Conduct Certificate',
        'category': 'Certificate',
        'department': 'MCA',
        'reason': 'Applying for higher studies at IIT Madras.',
        'status': 'Pending',
        'timestamp': Timestamp.now(),
      },
      {
        'studentId': 'STU015',
        'studentName': 'Meera Nair',
        'type': 'Merit Scholarship',
        'category': 'Scholarship',
        'department': 'MCA',
        'reason': 'Academic excellence in Semester 4 (9.2 CGPA).',
        'status': 'Pending',
        'timestamp': Timestamp.now(),
      },
      {
        'studentId': 'STU042',
        'studentName': 'Rahul Vijay',
        'type': 'Transfer Certificate',
        'category': 'Certificate',
        'department': 'MCA',
        'reason': 'Personal reasons for relocating to Bengaluru.',
        'status': 'Approved',
        'timestamp': Timestamp.now(),
      },
      {
        'studentId': 'STU089',
        'studentName': 'Sneha K',
        'type': 'MOMA Scholarship',
        'category': 'Scholarship',
        'department': 'MCA',
        'reason': 'Renewal for final year MCA.',
        'status': 'Rejected',
        'timestamp': Timestamp.now(),
        'staffFeedback': 'Missing income certificate from Tehsildar.',
      },
    ];

    for (var req in dummyRequests) {
      await _requestsCollection.add(req);
    }
  }
}

