import 'package:cloud_firestore/cloud_firestore.dart';

class HodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- PROFILE MANAGEMENT ---

  /// Fetches the HOD's profile data from the 'users' collection
  Stream<DocumentSnapshot> getProfile(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  /// Updates specific fields in the HOD's profile
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _db.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  /// Adds a new staff member to the users collection
  Future<void> addStaff(Map<String, dynamic> staffData) async {
    final String email = staffData['email'];
    await _db.collection('users').doc(email).set({
      ...staffData,
      'id': email,
      'role': 'staff',
      'department': 'MCA', // Default for now
    }, SetOptions(merge: true));
  }

  // --- DEPARTMENT MANAGEMENT ---

  /// Fetches all batches for a specific department (e.g., 'MCA')
  Stream<QuerySnapshot> getDepartmentBatches(String department) {
    return _db
        .collection('batches')
        .where('department', isEqualTo: department)
        .snapshots();
  }

  /// Fetches all staff members belonging to a department
  Stream<QuerySnapshot> getDepartmentStaff(String department) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'staff')
        .where('department', isEqualTo: department)
        .snapshots();
  }

  /// Fetches all students belonging to a department
  Stream<QuerySnapshot> getDepartmentStudents(String department) {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'student')
        .where('department', isEqualTo: department)
        .snapshots();
  }

  // --- BATCH STUDENTS ---

  /// Fetches students for a specific batch from Firestore
  /// Collection path: batch_students/{batchId}/students
  Stream<QuerySnapshot> getBatchStudents(String batchId) {
    return _db
        .collection('batch_students')
        .doc(batchId)
        .collection('students')
        .orderBy('name')
        .snapshots();
  }

  /// Seeds all batch student data into Firestore.
  /// Call this once (e.g., from a dev/admin utility) to populate the database.
  Future<void> seedBatchStudents() async {
    final Map<String, List<Map<String, dynamic>>> data = {
      'mca_2023_2025': [
        {
          'name': 'Aditya Kumar',
          'regNo': 'MCA23001',
          'attendance': 88,
          'gpa': 8.7,
          'status': 'Regular',
        },
        {
          'name': 'Sneha Pillai',
          'regNo': 'MCA23002',
          'attendance': 72,
          'gpa': 7.9,
          'status': 'Regular',
        },
        {
          'name': 'Rahul Menon',
          'regNo': 'MCA23003',
          'attendance': 65,
          'gpa': 6.5,
          'status': 'At Risk',
        },
        {
          'name': 'Priya Nair',
          'regNo': 'MCA23004',
          'attendance': 91,
          'gpa': 9.1,
          'status': 'Regular',
        },
        {
          'name': 'Arjun Das',
          'regNo': 'MCA23005',
          'attendance': 78,
          'gpa': 8.2,
          'status': 'Regular',
        },
        {
          'name': 'Lakshmi Devi',
          'regNo': 'MCA23006',
          'attendance': 82,
          'gpa': 8.5,
          'status': 'Regular',
        },
        {
          'name': 'Kiran Raj',
          'regNo': 'MCA23007',
          'attendance': 60,
          'gpa': 6.1,
          'status': 'At Risk',
        },
        {
          'name': 'Meera Thomas',
          'regNo': 'MCA23008',
          'attendance': 95,
          'gpa': 9.4,
          'status': 'Regular',
        },
      ],
      'mca_2024_2026': [
        {
          'name': 'Vijay Sharma',
          'regNo': 'MCA24001',
          'attendance': 85,
          'gpa': 8.3,
          'status': 'Regular',
        },
        {
          'name': 'Anjali Singh',
          'regNo': 'MCA24002',
          'attendance': 90,
          'gpa': 9.0,
          'status': 'Regular',
        },
        {
          'name': 'Rohan Verma',
          'regNo': 'MCA24003',
          'attendance': 68,
          'gpa': 7.1,
          'status': 'Regular',
        },
        {
          'name': 'Divya Krishnan',
          'regNo': 'MCA24004',
          'attendance': 55,
          'gpa': 5.8,
          'status': 'At Risk',
        },
        {
          'name': 'Suresh Babu',
          'regNo': 'MCA24005',
          'attendance': 88,
          'gpa': 8.6,
          'status': 'Regular',
        },
        {
          'name': 'Nisha Mohan',
          'regNo': 'MCA24006',
          'attendance': 96,
          'gpa': 9.5,
          'status': 'Regular',
        },
      ],
      'mca_2022_2024': [
        {
          'name': 'Ravi Chandran',
          'regNo': 'MCA22001',
          'attendance': 84,
          'gpa': 8.4,
          'status': 'Graduated',
        },
        {
          'name': 'Sunita Rao',
          'regNo': 'MCA22002',
          'attendance': 79,
          'gpa': 7.8,
          'status': 'Graduated',
        },
        {
          'name': 'Manoj Kumar',
          'regNo': 'MCA22003',
          'attendance': 91,
          'gpa': 9.2,
          'status': 'Graduated',
        },
        {
          'name': 'Kavitha Reddy',
          'regNo': 'MCA22004',
          'attendance': 88,
          'gpa': 8.9,
          'status': 'Graduated',
        },
        {
          'name': 'Deepak Nair',
          'regNo': 'MCA22005',
          'attendance': 76,
          'gpa': 7.5,
          'status': 'Graduated',
        },
      ],
    };

    for (final entry in data.entries) {
      final batchId = entry.key;
      final students = entry.value;
      final batchRef = _db.collection('batch_students').doc(batchId);

      // Ensure the parent document exists
      await batchRef.set({
        'batchId': batchId,
        'seeded': true,
      }, SetOptions(merge: true));

      for (final student in students) {
        await batchRef
            .collection('students')
            .doc(student['regNo'] as String)
            .set(student);
      }
    }
  }

  /// Seeds the batch metadata into Firestore (batches collection).
  /// Call this once to populate batch documents used by HodBatchesScreen.
  Future<void> seedBatches() async {
    final List<Map<String, dynamic>> batches = [
      {
        'id': 'mca_2023_2025',
        'name': 'MCA 2023-2025',
        'department': 'MCA',
        'totalStudents': 60,
        'semester': 'S3/S4',
        'coordinator': 'Dr. Sarah Wilson',
        'status': 'Active',
        'colorHex': '6366F1',
      },
      {
        'id': 'mca_2024_2026',
        'name': 'MCA 2024-2026',
        'department': 'MCA',
        'totalStudents': 64,
        'semester': 'S1/S2',
        'coordinator': 'Prof. James Bond',
        'status': 'Active',
        'colorHex': '10B981',
      },
      {
        'id': 'mca_2022_2024',
        'name': 'MCA 2022-2024',
        'department': 'MCA',
        'totalStudents': 58,
        'semester': 'Graduated',
        'coordinator': 'Dr. Robert Fox',
        'status': 'Completed',
        'colorHex': '64748B',
      },
    ];

    for (final batch in batches) {
      await _db
          .collection('batches')
          .doc(batch['id'] as String)
          .set(batch, SetOptions(merge: true));
    }
  }

  /// Seeds demo staff data into Firestore.
  Future<void> seedStaff() async {
    final List<Map<String, dynamic>> staffList = [
      {
        'id': 'sarah.wilson@edlab.com',
        'name': 'Dr. Sarah Wilson',
        'email': 'sarah.wilson@edlab.com',
        'role': 'staff',
        'designation': 'Assistant Professor',
        'department': 'MCA',
        'specialization': 'Machine Learning & AI',
        'status': 'Active',
        'phone': '+91 98765 43210',
        'initials': 'SW',
        'colorHex': 0xFF6366F1,
        'batches': ['MCA 2023-25', 'MCA 2024-26'],
        'subjects': 4,
        'experience': '8 yrs',
      },
      {
        'id': 'james.bond@edlab.com',
        'name': 'Prof. James Bond',
        'email': 'james.bond@edlab.com',
        'role': 'staff',
        'designation': 'Assistant Professor',
        'department': 'MCA',
        'specialization': 'Cyber Security',
        'status': 'In Class',
        'phone': '+91 98765 43211',
        'initials': 'JB',
        'colorHex': 0xFF10B981,
        'batches': ['MCA 2023-25'],
        'subjects': 5,
        'experience': '5 yrs',
      },
      {
        'id': 'robert.fox@edlab.com',
        'name': 'Dr. Robert Fox',
        'email': 'robert.fox@edlab.com',
        'role': 'staff',
        'designation': 'Assistant Professor',
        'department': 'MCA',
        'specialization': 'Cloud Computing',
        'status': 'On Leave',
        'phone': '+91 98765 43212',
        'initials': 'RF',
        'colorHex': 0xFF8B5CF6,
        'batches': ['MCA 2022-24'],
        'subjects': 6,
        'experience': '14 yrs',
      },
      {
        'id': 'emily.blunt@edlab.com',
        'name': 'Ms. Emily Blunt',
        'email': 'emily.blunt@edlab.com',
        'role': 'staff',
        'designation': 'Assistant Professor',
        'department': 'MCA',
        'specialization': 'Data Structures & Algorithms',
        'status': 'Active',
        'phone': '+91 98765 43213',
        'initials': 'EB',
        'colorHex': 0xFFF59E0B,
        'batches': ['MCA 2024-26'],
        'subjects': 4,
        'experience': '3 yrs',
      },
      {
        'id': 'kavitha.s@edlab.com',
        'name': 'Dr. Kavitha Suresh',
        'email': 'kavitha.s@edlab.com',
        'role': 'staff',
        'designation': 'Assistant Professor',
        'department': 'MCA',
        'specialization': 'Software Engineering',
        'status': 'Active',
        'phone': '+91 98765 43214',
        'initials': 'KS',
        'colorHex': 0xFFEC4899,
        'batches': ['MCA 2023-25', 'MCA 2024-26'],
        'subjects': 5,
        'experience': '10 yrs',
      },
      {
        'id': 'arjun.nair@edlab.com',
        'name': 'Mr. Arjun Nair',
        'email': 'arjun.nair@edlab.com',
        'role': 'staff',
        'designation': 'Assistant Professor',
        'department': 'MCA',
        'specialization': 'Database Systems',
        'status': 'In Class',
        'phone': '+91 98765 43215',
        'initials': 'AN',
        'colorHex': 0xFF0EA5E9,
        'batches': ['MCA 2024-26'],
        'subjects': 3,
        'experience': '2 yrs',
      },
    ];

    for (final staff in staffList) {
      await _db
          .collection('users')
          .doc(staff['id'] as String)
          .set(staff, SetOptions(merge: true));
    }
  }

  // --- STAFF SUBJECTS / WORKLOAD ---

  /// Live stream of subjects for a single staff member.
  /// Collection: staff_subjects / {email} / subjects (sub-collection)
  Stream<QuerySnapshot> getStaffSubjects(String email) {
    return _db
        .collection('staff_subjects')
        .doc(email)
        .collection('subjects')
        .orderBy('order')
        .snapshots();
  }

  /// Returns true if the staff_subjects sub-collections need seeding.
  /// Checks actual subject docs inside a known staff member's sub-collection.
  Future<bool> _needsSubjectSeed() async {
    final snap = await _db
        .collection('staff_subjects')
        .doc('arjun.nair@edlab.com')
        .collection('subjects')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return true;

    // Check if the documents have the new 'modules' field
    final data = snap.docs.first.data();
    return !data.containsKey('modules');
  }

  /// Seeds subject data for all staff into Firestore.
  /// Document path: staff_subjects/{email}/subjects/{subjectDocId}
  Future<void> seedStaffSubjectsIfNeeded() async {
    if (!await _needsSubjectSeed()) return;
    await seedStaffSubjects();
  }

  Future<void> seedStaffSubjects() async {
    final Map<String, List<Map<String, dynamic>>> subjectsByEmail = {
      'sarah.wilson@edlab.com': [
        {
          'name': 'Machine Learning',
          'coverage': 0.82,
          'completion': 0.78,
          'order': 0,
          'modules': [
            {
              'name': 'Module 1: Introduction',
              'progress': 1.0,
              'topics': [
                {'name': 'Supervised Learning', 'status': 'completed'},
                {'name': 'Unsupervised Learning', 'status': 'completed'},
                {'name': 'Cost Functions', 'status': 'completed'},
              ],
            },
            {
              'name': 'Module 2: Regression',
              'progress': 0.65,
              'topics': [
                {'name': 'Linear Regression', 'status': 'completed'},
                {'name': 'Gradient Descent', 'status': 'in_progress'},
                {'name': 'Polynominal Regression', 'status': 'pending'},
              ],
            },
          ],
        },
        {
          'name': 'Deep Learning',
          'coverage': 0.65,
          'completion': 0.70,
          'order': 1,
          'modules': [
            {
              'name': 'Module 1: Neural Networks',
              'progress': 0.80,
              'topics': [
                {'name': 'Forward Propagation', 'status': 'completed'},
                {'name': 'Backpropagation', 'status': 'completed'},
                {'name': 'Activation Functions', 'status': 'in_progress'},
              ],
            },
          ],
        },
      ],
      'james.bond@edlab.com': [
        {
          'name': 'Network Security',
          'coverage': 0.75,
          'completion': 0.80,
          'order': 0,
          'modules': [
            {
              'name': 'Module 1: Basics',
              'progress': 0.90,
              'topics': [
                {'name': 'OSI Model Security', 'status': 'completed'},
                {'name': 'Threat Analysis', 'status': 'completed'},
                {'name': 'Risk Management', 'status': 'in_progress'},
              ],
            },
          ],
        },
      ],
      'robert.fox@edlab.com': [
        {
          'name': 'Cloud Architecture',
          'coverage': 0.88,
          'completion': 0.84,
          'order': 0,
          'modules': [
            {
              'name': 'Module 1: Virtualization',
              'progress': 1.0,
              'topics': [
                {'name': 'Hypervisors', 'status': 'completed'},
                {'name': 'Containers', 'status': 'completed'},
              ],
            },
          ],
        },
      ],
      'emily.blunt@edlab.com': [
        {
          'name': 'Data Structures',
          'coverage': 0.92,
          'completion': 0.90,
          'order': 0,
          'modules': [
            {
              'name': 'Module 1: Linear',
              'progress': 1.0,
              'topics': [
                {'name': 'Arrays', 'status': 'completed'},
                {'name': 'Linked Lists', 'status': 'completed'},
              ],
            },
          ],
        },
      ],
      'kavitha.s@edlab.com': [
        {
          'name': 'Software Design Patterns',
          'coverage': 0.85,
          'completion': 0.88,
          'order': 0,
          'modules': [
            {
              'name': 'Module 1: Creational',
              'progress': 0.85,
              'topics': [
                {'name': 'Singleton', 'status': 'completed'},
                {'name': 'Factory', 'status': 'completed'},
                {'name': 'Abstract Factory', 'status': 'in_progress'},
              ],
            },
          ],
        },
      ],
      'arjun.nair@edlab.com': [
        {
          'name': 'Database Systems',
          'coverage': 0.85,
          'completion': 0.82,
          'order': 0,
          'modules': [
            {
              'name': 'Module 1',
              'progress': 1.0,
              'topics': [
                {
                  'name': 'Database Users and Administrators',
                  'status': 'completed',
                },
                {'name': 'Database Architecture', 'status': 'completed'},
                {
                  'name': 'The Entity-Relationship model',
                  'status': 'completed',
                },
              ],
            },
            {
              'name': 'Module 2',
              'progress': 0.65,
              'topics': [
                {
                  'name': 'Improving the Design - Surrogate Key',
                  'status': 'completed',
                },
                {'name': 'Tutorial', 'status': 'in_progress'},
                {
                  'name': 'Normalization and Database Design',
                  'status': 'pending',
                },
                {'name': 'Join dependencies and 5NF', 'status': 'in_progress'},
                {'name': 'Fourth Normal Form', 'status': 'pending'},
                {'name': 'Higher Level Normal Forms', 'status': 'pending'},
                {
                  'name': 'Conversion to Third Normal Form',
                  'status': 'pending',
                },
                {'name': 'The Normalization Process', 'status': 'pending'},
                {
                  'name': 'Database Tables and Normalization',
                  'status': 'pending',
                },
              ],
            },
          ],
        },
      ],
    };

    final batch = _db.batch();

    for (final entry in subjectsByEmail.entries) {
      final email = entry.key;
      final subjects = entry.value;

      // Ensure parent document exists
      final parentRef = _db.collection('staff_subjects').doc(email);
      batch.set(parentRef, {
        'staffEmail': email,
        'seeded': true,
      }, SetOptions(merge: true));

      for (final subject in subjects) {
        final subRef = parentRef
            .collection('subjects')
            .doc(
              subject['name']
                  .toString()
                  .toLowerCase()
                  .replaceAll(' ', '_')
                  .replaceAll('&', 'and'),
            );
        batch.set(subRef, subject, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  /// Updates a single subject's coverage/completion for a staff member.
  Future<void> updateSubjectProgress(
    String email,
    String subjectDocId, {
    double? coverage,
    double? completion,
  }) async {
    final ref = _db
        .collection('staff_subjects')
        .doc(email)
        .collection('subjects')
        .doc(subjectDocId);
    final data = <String, dynamic>{};
    if (coverage != null) data['coverage'] = coverage;
    if (completion != null) data['completion'] = completion;
    if (data.isNotEmpty) await ref.update(data);
  }

  // --- ACADEMIC OPERATIONS ---

  /// Fetches the timetable for a specific department/batch
  Stream<QuerySnapshot> getDepartmentTimetable(
    String department,
    String batchId,
  ) {
    return _db
        .collection('timetables')
        .where('department', isEqualTo: department)
        .where('batchId', isEqualTo: batchId)
        .snapshots();
  }

  /// Fetches department-specific surveys/feedback
  Stream<QuerySnapshot> getDepartmentSurveys(String department) {
    return _db
        .collection('surveys')
        .where('department', isEqualTo: department)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- MONITORING & ANALYTICS ---

  /// Fetches recent faculty activities or logs for oversight
  Stream<QuerySnapshot> getFacultyActivities(String department) {
    return _db
        .collection('faculty_activities')
        .where('department', isEqualTo: department)
        .orderBy('timestamp', descending: true)
        .limit(10)
        .snapshots();
  }

  /// Fetches student complaints or requests for the HOD
  Stream<QuerySnapshot> getPendingComplaints(String department) {
    return _db
        .collection('complaints')
        .where('department', isEqualTo: department)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  /// Fetches university exams scheduled for a specific department
  Stream<QuerySnapshot> getDepartmentExams(String department) {
    return _db
        .collection('university_exams')
        .where('department', isEqualTo: department)
        .snapshots();
  }

  // --- UTILITIES ---

  /// Get live counts for the HOD dashboard dashboard
  Stream<Map<String, int>> getDepartmentBrief(String department) {
    return _db
        .collection('users')
        .where('department', isEqualTo: department)
        .snapshots()
        .map((snapshot) {
          int students = 0;
          int staff = 0;

          for (var doc in snapshot.docs) {
            final role = doc.get('role');
            if (role == 'student') students++;
            if (role == 'staff') staff++;
          }

          return {'studentCount': students, 'staffCount': staff};
        });
  }

  // --- HOUR REQUESTS ---

  /// Fetches hour requests with optional filtering
  Stream<QuerySnapshot> getHourRequests(
    String department, {
    String? status,
    String? batch,
  }) {
    Query query = _db
        .collection('hour_requests')
        .where('department', isEqualTo: department);

    if (status != null && status != 'select') {
      query = query.where('status', isEqualTo: status);
    }
    if (batch != null && batch != 'select') {
      query = query.where('batch', isEqualTo: batch);
    }

    // Order by timestamp to show newest first. Note: requires composite index.
    return query.snapshots();
  }

  /// Fetches hour requests made BY a specific user
  Stream<QuerySnapshot> getHourRequestsByUser(String userId) {
    return _db
        .collection('hour_requests')
        .where('requesterId', isEqualTo: userId)
        .snapshots();
  }

  /// Creates a new hour request
  Future<void> createHourRequest(Map<String, dynamic> requestData) async {
    await _db.collection('hour_requests').add({
      ...requestData,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'Pending',
    });
  }

  /// Updates the status of an hour request
  Future<void> updateHourRequestStatus(String requestId, String status) async {
    await _db.collection('hour_requests').doc(requestId).update({
      'status': status,
    });
  }

  /// Updates the entire content of an hour request
  Future<void> updateHourRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    await _db.collection('hour_requests').doc(requestId).update(data);
  }

  /// Deletes an hour request
  Future<void> deleteHourRequest(String requestId) async {
    await _db.collection('hour_requests').doc(requestId).delete();
  }

  /// Seeds demo hour requests
  Future<void> seedHourRequests() async {
    final List<Map<String, dynamic>> requests = [
      {
        'requesterId': 'sarah.wilson@edlab.com',
        'requesterName': 'Dr. Sarah Wilson',
        'targetStaffId': 'james.bond@edlab.com',
        'targetStaffName': 'Prof. James Bond',
        'date': Timestamp.fromDate(DateTime(2026, 3, 10)),
        'period': '2nd Period',
        'batch': 'MCA 2023-2025',
        'subject': 'Machine Learning',
        'status': 'Pending',
        'department': 'MCA',
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'requesterId': 'james.bond@edlab.com',
        'requesterName': 'Prof. James Bond',
        'targetStaffId': 'hod@gmail.com',
        'targetStaffName': 'HOD User',
        'date': Timestamp.fromDate(DateTime(2026, 3, 11)),
        'period': '4th Period',
        'batch': 'MCA 2024-2026',
        'subject': 'Network Security',
        'status': 'Approved',
        'department': 'MCA',
        'timestamp': FieldValue.serverTimestamp(),
      },
      {
        'requesterId': 'hod@gmail.com',
        'requesterName': 'HOD User',
        'targetStaffId': 'emily.blunt@edlab.com',
        'targetStaffName': 'Ms. Emily Blunt',
        'date': Timestamp.fromDate(DateTime(2026, 3, 12)),
        'period': '1st Period',
        'batch': 'MCA 2023-2025',
        'subject': 'Cloud Computing',
        'status': 'Pending',
        'department': 'MCA',
        'timestamp': FieldValue.serverTimestamp(),
      },
    ];

    for (final request in requests) {
      await _db.collection('hour_requests').add(request);
    }
  }
}
