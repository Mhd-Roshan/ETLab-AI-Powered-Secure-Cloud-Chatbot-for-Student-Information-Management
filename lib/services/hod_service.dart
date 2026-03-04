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
    await _db.collection('users').doc(userId).update(data);
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
        'id': 'staff1@gmail.com',
        'name': 'Dr. Sarah Wilson',
        'email': 'sarah.wilson@edlab.com',
        'role': 'staff',
        'designation': 'Associate Professor',
        'department': 'MCA',
        'specialization': 'Machine Learning',
        'status': 'Active',
        'phone': '+91 9876543210',
        'avatar': 'https://i.pravatar.cc/150?u=sarah',
      },
      {
        'id': 'staff2@gmail.com',
        'name': 'Prof. James Bond',
        'email': 'james.bond@edlab.com',
        'role': 'staff',
        'designation': 'Assistant Professor',
        'department': 'MCA',
        'specialization': 'Cyber Security',
        'status': 'In Class',
        'phone': '+91 9876543211',
        'avatar': 'https://i.pravatar.cc/150?u=james',
      },
      {
        'id': 'staff3@gmail.com',
        'name': 'Dr. Robert Fox',
        'email': 'robert.fox@edlab.com',
        'role': 'staff',
        'designation': 'Professor',
        'department': 'MCA',
        'specialization': 'Cloud Computing',
        'status': 'On Leave',
        'phone': '+91 9876543212',
        'avatar': 'https://i.pravatar.cc/150?u=robert',
      },
      {
        'id': 'staff4@gmail.com',
        'name': 'Ms. Emily Blunt',
        'email': 'emily.blunt@edlab.com',
        'role': 'staff',
        'designation': 'Assistant Professor',
        'department': 'MCA',
        'specialization': 'Data Structures',
        'status': 'Active',
        'phone': '+91 9876543213',
        'avatar': 'https://i.pravatar.cc/150?u=emily',
      },
    ];

    for (final staff in staffList) {
      await _db
          .collection('users')
          .doc(staff['id'] as String)
          .set(staff, SetOptions(merge: true));
    }
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
}
