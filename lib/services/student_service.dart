import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class StudentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Get Profile - Check both students and users collections
  Stream<DocumentSnapshot> getStudentProfile(String regNo) {
    // First try students collection, if not found, try users collection
    return _db.collection('students').doc(regNo).snapshots().map((doc) {
      if (doc.exists) {
        return doc;
      }
      // If not in students, try users collection with username match
      return doc;
    });
  }

  // Alternative: Get from users collection by username/email
  Stream<DocumentSnapshot> getStudentProfileFromUsers(String identifier) =>
      _db.collection('users').doc(identifier).snapshots();

  // 2. Get Attendance Records
  Stream<QuerySnapshot> getAttendance(String regNo) => _db
      .collection('attendance')
      .where('studentId', isEqualTo: regNo)
      .snapshots();

  // 3. Get Fees
  Stream<QuerySnapshot> getFees(String regNo) =>
      _db.collection('fees').where('studentId', isEqualTo: regNo).snapshots();

  // 4. Get Notifications/Announcements
  Stream<QuerySnapshot> getNotifications(String collegeCode) => _db
      .collection('announcements')
      .where('collegeCode', isEqualTo: collegeCode)
      .orderBy('postedDate', descending: true)
      .snapshots();

  // 5. Update Profile (The Edit function)
  Future<void> updateProfileImage(String regNo, String url) =>
      _db.collection('students').doc(regNo).update({'profileUrl': url});

  // 6. Get Courses/Schedule
  Stream<QuerySnapshot> getCourses(String dept, dynamic sem) => _db
      .collection('courses')
      .where('department', isEqualTo: dept)
      .snapshots();

  // 7. Get Students by Dept
  Stream<QuerySnapshot> getStudentsByDept(String dept, {String? semester}) {
    Query query = _db
        .collection('students')
        .where('department', isEqualTo: dept);
    if (semester != null) {
      query = query.where('semester', isEqualTo: semester);
    }
    return query.snapshots();
  }

  // 8. Get user by email or username from users collection
  Future<DocumentSnapshot?> getUserByIdentifier(String identifier) async {
    // Try to find by username
    var querySnapshot = await _db
        .collection('users')
        .where('username', isEqualTo: identifier)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }

    // Try to find by email
    querySnapshot = await _db
        .collection('users')
        .where('email', isEqualTo: identifier)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }

    return null;
  }

  // 9. Initialize Attendance Data if missing
  // 9. Initialize Attendance Data if missing
  Future<void> initializeAttendanceData(String regNo) async {
    print(
      "Initializing attendance for student: $regNo",
    ); // Use print for debug console visibility

    try {
      final batch = _db.batch();
      final List<Map<String, dynamic>> subjects = [
        {
          'subjectName': 'Applied Mathematics-I',
          'subjectCode': 'AM101',
          'present': 28,
          'total': 35,
          'semester': 'Semester 1',
        },
        {
          'subjectName': 'Applied Physics-I',
          'subjectCode': 'AP102',
          'present': 30,
          'total': 38,
          'semester': 'Semester 1',
        },
        {
          'subjectName': 'Applied Chemistry',
          'subjectCode': 'AC103',
          'present': 32,
          'total': 36,
          'semester': 'Semester 1',
        },
        {
          'subjectName': 'Computer Fundamentals',
          'subjectCode': 'CF104',
          'present': 25,
          'total': 35,
          'semester': 'Semester 1',
        },
        {
          'subjectName': 'Communication Skills',
          'subjectCode': 'CS105',
          'present': 33,
          'total': 37,
          'semester': 'Semester 1',
        },
      ];

      for (var subject in subjects) {
        final docRef = _db.collection('attendance').doc();
        batch.set(docRef, {
          ...subject,
          'studentId': regNo,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      print("Committing batch of ${subjects.length} attendance records...");
      await batch.commit();
      print("Batch commit successful!");
    } catch (e) {
      print("Error initializing attendance data: $e");
      rethrow;
    }
  }

  // 10. Get Materials
  Stream<QuerySnapshot> getMaterials(String department, String semester) {
    return _db
        .collection('materials')
        .where('department', isEqualTo: department)
        .where('semester', isEqualTo: semester)
        .snapshots();
  }

  // 11. Seed Materials
  Future<void> seedMaterials() async {
    final batch = _db.batch();
    final materials = [
      // MCA Semester 1
      {
        'department': 'MCA',
        'semester': 'Semester 1',
        'subject': 'Data Structures',
        'title': 'Linked List Notes',
        'url': 'https://example.com/linked_list.pdf',
        'type': 'PDF',
      },
      {
        'department': 'MCA',
        'semester': 'Semester 1',
        'subject': 'Data Structures',
        'title': 'Stack & Queue PPT',
        'url': 'https://example.com/stack_queue.pptx',
        'type': 'PPT',
      },
      {
        'department': 'MCA',
        'semester': 'Semester 1',
        'subject': 'Python Programming',
        'title': 'Python Basics',
        'url': 'https://example.com/python_basics.pdf',
        'type': 'PDF',
      },
      // MCA Semester 2
      {
        'department': 'MCA',
        'semester': 'Semester 2',
        'subject': 'Database Management',
        'title': 'SQL normalization',
        'url': 'https://example.com/sql_norm.pdf',
        'type': 'PDF',
      },
    ];

    for (var material in materials) {
      final docRef = _db.collection('materials').doc();
      batch.set(docRef, {
        ...material,
        'dateAdded': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  // 12. Get Exams
  Stream<QuerySnapshot> getExams(String dept, String semester) {
    return _db
        .collection('exams')
        .where('department', isEqualTo: dept)
        .where('semester', isEqualTo: semester)
        .orderBy('date', descending: false)
        .snapshots();
  }

  // 13. Get Results (Mock for now, to match ResultsScreen)
  Future<Map<String, List<Map<String, dynamic>>>> getResults(
    String studentId,
  ) async {
    // Simulating API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return {
      "Series Exam 1": [
        {
          'subject': 'Data Structures',
          'code': 'CS401',
          'marks': 35,
          'maxMarks': 40,
          'grade': 'A+',
        },
        {
          'subject': 'Mathematics',
          'code': 'MA402',
          'marks': 32,
          'maxMarks': 40,
          'grade': 'A',
        },
        {
          'subject': 'Python Programming',
          'code': 'CS403',
          'marks': 38,
          'maxMarks': 40,
          'grade': 'A+',
        },
        {
          'subject': 'Digital Fundamentals',
          'code': 'EC404',
          'marks': 28,
          'maxMarks': 40,
          'grade': 'B+',
        },
        {
          'subject': 'English Literature',
          'code': 'EN405',
          'marks': 33,
          'maxMarks': 40,
          'grade': 'A',
        },
        {
          'subject': 'Computer Lab',
          'code': 'CS406',
          'marks': 37,
          'maxMarks': 40,
          'grade': 'A+',
        },
      ],
      "Series Exam 2": [
        {
          'subject': 'Data Structures',
          'code': 'CS401',
          'marks': 36,
          'maxMarks': 40,
          'grade': 'A+',
        },
        {
          'subject': 'Mathematics',
          'code': 'MA402',
          'marks': 30,
          'maxMarks': 40,
          'grade': 'B+',
        },
        {
          'subject': 'Python Programming',
          'code': 'CS403',
          'marks': 39,
          'maxMarks': 40,
          'grade': 'O',
        },
      ],
    };
  }

  // 14. Get Assignments (Real-time Stream)
  Stream<QuerySnapshot> getAssignmentsStream(String studentId) {
    return _db
        .collection('assignments')
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  // 14b. Get Assignments (Future for AI)
  Future<List<Map<String, dynamic>>> getAssignments(String studentId) async {
    // Simulating API delay
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    return [
      {
        'subject': 'Review',
        'type': 1,
        'status': 'submitted',
        'issueDate': now.subtract(const Duration(days: 10)),
        'dueDate': now.subtract(const Duration(days: 2)),
        'submittedDate': now.subtract(const Duration(days: 3)),
        'description': "Chapter 1-3 Review Questions",
      },
      {
        'subject': 'Physics',
        'type': 1,
        'status': 'submitted',
        'issueDate': now.subtract(const Duration(days: 12)),
        'dueDate': now.subtract(const Duration(days: 5)),
        'submittedDate': now.subtract(const Duration(days: 6)),
        'description': "Lab Report: Ohms Law",
      },
      {
        'subject': 'Chemistry',
        'type': 2,
        'status': 'pending',
        'issueDate': now.subtract(const Duration(days: 2)),
        'dueDate': now.add(const Duration(days: 5)),
        'description': "Periodic Table Analysis",
      },
      {
        'subject': 'Mathematics',
        'type': 1,
        'status': 'pending',
        'issueDate': now.subtract(const Duration(days: 1)),
        'dueDate': now.add(const Duration(days: 6)),
        'description': "Calculus Problem Set 4",
      },
      {
        'subject': 'Data Structures',
        'type': 1,
        'status': 'pending',
        'issueDate': now.subtract(const Duration(days: 4)),
        'dueDate': now.add(const Duration(days: 3)),
        'description': "Implement Doubly Linked List",
      },
    ];
  }

  // 15. Get Attendance (Future for AI)
  Future<List<Map<String, dynamic>>> getDetailedAttendance(
    String studentId,
  ) async {
    try {
      final snapshot = await _db
          .collection('attendance')
          .where('studentId', isEqualTo: studentId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => d.data()).toList();
      }

      // Fallback Mock Data (if DB empty)
      return [
        {'subjectName': 'Applied Mathematics-I', 'present': 28, 'total': 35},
        {'subjectName': 'Applied Physics-I', 'present': 30, 'total': 38},
        {'subjectName': 'Applied Chemistry', 'present': 32, 'total': 36},
        {'subjectName': 'Computer Fundamentals', 'present': 25, 'total': 35},
        {'subjectName': 'Communication Skills', 'present': 33, 'total': 37},
      ];
    } catch (e) {
      debugPrint("Attendance fetch error: $e");
      return [];
    }
  }

  // 16. Fetch Materials (Future for AI)
  Future<List<Map<String, dynamic>>> fetchMaterials(
    String dept,
    String semester,
  ) async {
    try {
      final snapshot = await _db
          .collection('materials')
          .where('department', isEqualTo: dept)
          .where('semester', isEqualTo: semester)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((d) => d.data()).toList();
      }

      // Fallback Mock Data
      return [
        {
          'subject': 'ADVANCED DATA STRUCTURES',
          'title': 'Linked List Notes',
          'type': 'PDF',
        },
        {
          'subject': 'ADVANCED SOFTWARE ENGINEERING',
          'title': 'Agile Methodology',
          'type': 'PPT',
        },
        {
          'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
          'title': 'Logic Gates Guide',
          'type': 'DOC',
        },
      ];
    } catch (e) {
      debugPrint("Materials fetch error: $e");
      return [];
    }
  }

  // 17. Get Holidays
  Stream<QuerySnapshot> getHolidays() {
    return _db
        .collection('holidays')
        .orderBy('date', descending: false)
        .snapshots();
  }

  // 18. Seed All Academics Data (Dev Tool)
  Future<void> seedDevData(String regNo) async {
    final batch = _db.batch();
    final now = DateTime.now();

    // 1. Seed Announcements (The Upcoming Feed)
    final announcements = [
      {
        'title': 'Mid-Term Exam Schedule',
        'content': 'Check the portal for your upcoming mid-term dates.',
        'type': 'exam',
        'postedDate': now,
        'isActive': true,
        'priority': 'high',
      },
      {
        'title': 'Onam Festival Holiday',
        'content': 'College will remain closed for Onam celebrations.',
        'type': 'holiday',
        'postedDate': now.add(const Duration(hours: 1)),
        'isActive': true,
        'priority': 'medium',
      },
      {
        'title': 'New Python Assignment',
        'content': 'Implement a Flask API for student management.',
        'type': 'assignment',
        'postedDate': now.add(const Duration(hours: 2)),
        'isActive': true,
        'priority': 'normal',
      },
    ];

    for (var a in announcements) {
      final ref = _db.collection('announcements').doc();
      batch.set(ref, a);
    }

    // 2. Seed Holidays Specifically
    final holidays = [
      {
        'name': 'National Youth Day',
        'date': now.add(const Duration(days: 10)),
        'type': 'Public',
      },
      {
        'name': 'Republic Day',
        'date': DateTime(2026, 1, 26),
        'type': 'National',
      },
      {
        'name': 'College Tech Fest',
        'date': now.add(const Duration(days: 20)),
        'type': 'Event',
      },
    ];

    for (var h in holidays) {
      final ref = _db.collection('holidays').doc();
      batch.set(ref, h);
    }

    // 3. Seed Exams
    final exams = [
      {
        'subject': 'ADVANCED DATA STRUCTURES',
        'title': 'Series Exam 1',
        'date': now.add(const Duration(days: 5)),
        'time': '10:00 AM',
        'venue': 'Room 101',
        'department': 'MCA',
        'semester': 'Semester 1',
        'type': 'Series',
        'status': 'Scheduled',
      },
      {
        'subject': 'ADVANCED SOFTWARE ENGINEERING',
        'title': 'Series Exam 1',
        'date': now.add(const Duration(days: 7)),
        'time': '02:00 PM',
        'venue': 'Lab 2',
        'department': 'MCA',
        'semester': 'Semester 1',
        'type': 'Series',
        'status': 'Scheduled',
      },
    ];

    for (var e in exams) {
      final ref = _db.collection('exams').doc();
      batch.set(ref, e);
    }

    // 4. Seed Assignments
    final assignments = [
      {
        'subject': 'ADVANCED DATA STRUCTURES',
        'title': 'Tree Implementation',
        'dueDate': now.add(const Duration(days: 4)),
        'status': 'pending',
        'type': 2, // Online
        'studentId': regNo,
        'description': 'Implement a Red-Black Tree in Java.',
      },
      {
        'subject': 'WEB PROGRAMMING LAB',
        'title': 'Personal Portfolio',
        'dueDate': now.add(const Duration(days: 8)),
        'status': 'pending',
        'type': 1, // Offline
        'studentId': regNo,
        'description': 'Design a responsive portfolio using HTML/CSS.',
      },
    ];

    for (var asm in assignments) {
      final ref = _db.collection('assignments').doc();
      batch.set(ref, asm);
    }

    await batch.commit();
  }
}
