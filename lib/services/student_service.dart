import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloudinary/cloudinary.dart';
import '../config/api_config.dart';

class StudentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Cloudinary Instance
  late final Cloudinary _cloudinary;

  StudentService() {
    _cloudinary = Cloudinary.signedConfig(
      apiKey: ApiConfig.cloudinaryApiKey,
      apiSecret: ApiConfig.cloudinaryApiSecret,
      cloudName: ApiConfig.cloudinaryCloudName,
    );
  }

  // --- UPLOAD (Using Cloudinary) ---
  Future<String> uploadFile(String path, String fileName) async {
    try {
      final response = await _cloudinary.upload(
        file: path,
        resourceType: CloudinaryResourceType.auto,
        folder: 'edlab_assignments',
        fileName: fileName,
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl!;
      } else {
        throw Exception("Cloudinary Upload failed: ${response.error}");
      }
    } catch (e) {
      debugPrint("Cloudinary Error uploading file: $e");
      rethrow;
    }
  }

  Future<String> uploadBytes(Uint8List bytes, String fileName) async {
    try {
      final response = await _cloudinary.upload(
        fileBytes: bytes,
        resourceType: CloudinaryResourceType.auto,
        folder: 'edlab_assignments',
        fileName: fileName,
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl!;
      } else {
        throw Exception("Cloudinary Upload failed: ${response.error}");
      }
    } catch (e) {
      debugPrint("Cloudinary Error uploading bytes: $e");
      rethrow;
    }
  }

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
  Future<void> initializeAttendanceData(
    String regNo, {
    List<Map<String, dynamic>>? syllabusSubjects,
  }) async {
    print("Initializing attendance for student: $regNo");

    try {
      final batch = _db.batch();
      final List<Map<String, dynamic>> subjects = syllabusSubjects ?? [];

      if (subjects.isEmpty) {
        // Fallback or fetch from master if needed
        print("No subjects provided for initialization.");
        return;
      }

      for (var subject in subjects) {
        // Create a summary attendance record for the student-subject pair
        final docRef = _db
            .collection('attendance')
            .doc("${regNo}_${subject['name'].replaceAll(' ', '_')}");
        batch.set(docRef, {
          'studentId': regNo,
          'subject': subject['name'],
          'subjectCode': subject['id'] ?? '-',
          'present': subject['attended'] ?? 0,
          'total': subject['totalClasses'] ?? 0,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
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
    final materials = []; // Seed from external source if needed

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

  // 13. Get Results from Firestore
  Future<Map<String, List<Map<String, dynamic>>>> getResults(
    String studentId,
  ) async {
    try {
      QuerySnapshot? snapshot;

      // Try multiple identifier fields
      for (final field in ['studentId', 'regNo', 'email', 'username']) {
        final result = await _db
            .collection('results')
            .where(field, isEqualTo: studentId)
            .get();
        if (result.docs.isNotEmpty) {
          snapshot = result;
          debugPrint(
            '[getResults] Found ${result.docs.length} results by $field=$studentId',
          );
          break;
        }
      }

      // Case-insensitive fallback
      if (snapshot == null || snapshot.docs.isEmpty) {
        final lowerCaseId = studentId.toLowerCase();
        final allResults = await _db.collection('results').get();
        final matched = allResults.docs.where((doc) {
          final data = doc.data();
          return (data['studentId']?.toString().toLowerCase() == lowerCaseId) ||
              (data['regNo']?.toString().toLowerCase() == lowerCaseId) ||
              (data['email']?.toString().toLowerCase() == lowerCaseId) ||
              (data['username']?.toString().toLowerCase() == lowerCaseId);
        }).toList();

        if (matched.isEmpty) return {};

        // Process matched docs
        Map<String, List<Map<String, dynamic>>> groupedResults = {};
        for (var doc in matched) {
          final data = doc.data();
          final String examName = data['examName'] ?? 'General';
          if (!groupedResults.containsKey(examName)) {
            groupedResults[examName] = [];
          }
          groupedResults[examName]!.add({
            'subject': data['subject'] ?? 'Unknown',
            'code': data['subjectCode'] ?? 'N/A',
            'marks': data['marks'] ?? 0,
            'maxMarks': data['maxMarks'] ?? 40,
            'grade': data['grade'] ?? 'N/A',
          });
        }
        return groupedResults;
      }

      Map<String, List<Map<String, dynamic>>> groupedResults = {};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final String examName = data['examName'] ?? 'General';

        if (!groupedResults.containsKey(examName)) {
          groupedResults[examName] = [];
        }

        groupedResults[examName]!.add({
          'subject': data['subject'] ?? 'Unknown',
          'code': data['subjectCode'] ?? 'N/A',
          'marks': data['marks'] ?? 0,
          'maxMarks': data['maxMarks'] ?? 40,
          'grade': data['grade'] ?? 'N/A',
        });
      }

      return groupedResults;
    } catch (e) {
      debugPrint("Error fetching results: $e");
      return {};
    }
  }

  // 14. Get Assignments (Real-time Stream)
  Stream<QuerySnapshot> getAssignmentsStream(String studentId) {
    return _db
        .collection('assignments')
        .where('studentId', isEqualTo: studentId)
        .snapshots();
  }

  Stream<List<DocumentSnapshot<Map<String, dynamic>>>> getAssignmentsByClass(
    String dept,
    String sem, {
    String? collegeCode,
  }) {
    // Fetch all and filter in memory to be robust against naming discrepancies and index issues
    return _db.collection('assignments_master').snapshots().map((snapshot) {
      debugPrint(
        '[getAssignmentsByClass] Total docs in assignments_master: ${snapshot.docs.length}',
      );
      debugPrint(
        '[getAssignmentsByClass] Looking for dept=$dept, sem=$sem, college=$collegeCode',
      );

      final assignments = snapshot.docs.where((doc) {
        final data = doc.data();

        // 1. Semester matching (Robust)
        final String sSem = sem.toString().trim();
        final String dSem = (data['semester']?.toString() ?? '').trim();

        // If semester is 'ALL' or empty, or matches student semester
        bool semMatch = (dSem == sSem || dSem == 'ALL' || dSem.isEmpty);

        // 2. Department & Subject Matching (Lenient)
        final String sDept = dept.trim().toUpperCase();
        final String dDept = (data['department']?.toString() ?? '')
            .trim()
            .toUpperCase();

        // Match if:
        // - Departments match exactly or partially
        // - Assignment is for "ALL" departments
        // - Assignment department field is empty
        // - OR if the subject name contains "DIGITAL FUNDAMENTALS" (the forced subject)
        bool deptMatch =
            dDept == sDept ||
            dDept == 'ALL' ||
            dDept.isEmpty ||
            dDept.contains(sDept) ||
            sDept.contains(dDept);

        // 3. College Code check (Only filter if BOTH have values and THEY DISAGREE)
        bool collegeMatch = true;
        if (collegeCode != null && collegeCode.trim().isNotEmpty) {
          final String sCollege = collegeCode.trim().toUpperCase();
          final String dCollege = (data['collegeCode']?.toString() ?? '')
              .trim()
              .toUpperCase();
          if (dCollege.isNotEmpty &&
              dCollege != sCollege &&
              dCollege != 'ALL') {
            collegeMatch = false;
          }
        }

        if (!semMatch || !deptMatch || !collegeMatch) {
          debugPrint(
            '[getAssignmentsByClass] SKIPPED: ${data['title']} (semMatch=$semMatch [doc=$dSem vs student=$sSem], deptMatch=$deptMatch [doc=$dDept vs student=$sDept], collegeMatch=$collegeMatch)',
          );
        }

        return semMatch && deptMatch && collegeMatch;
      }).toList();

      debugPrint(
        '[getAssignmentsByClass] Matched assignments: ${assignments.length}',
      );

      // Sort by timestamp (newest first)
      assignments.sort((a, b) {
        final aTime = a.data()['timestamp'];
        final bTime = b.data()['timestamp'];

        if (aTime is! Timestamp && bTime is! Timestamp) return 0;
        if (aTime is! Timestamp) return -1;
        if (bTime is! Timestamp) return 1;

        return bTime.compareTo(aTime);
      });

      return assignments;
    });
  }

  // 14b. Get Submission for a specific assignment and student
  Stream<QuerySnapshot> getStudentSubmission(
    String studentId,
    String assignmentId,
  ) {
    return _db
        .collection('submissions')
        .where('studentId', isEqualTo: studentId)
        .where('assignmentId', isEqualTo: assignmentId)
        .snapshots();
  }

  // 14c. Submit Assignment
  Future<void> submitAssignment(Map<String, dynamic> submissionData) async {
    // 1. Add the submission
    await _db.collection('submissions').add({
      ...submissionData,
      'submittedAt': FieldValue.serverTimestamp(),
      'status': 'submitted',
    });

    // 2. Add an alert for the staff member
    if (submissionData['staffId'] != null) {
      await _db.collection('alerts').add({
        'title': 'New Submission: ${submissionData['subject']}',
        'message':
            '${submissionData['studentName']} (Sem ${submissionData['semester']}) has submitted the assignment. File: ${submissionData['fileName']}',
        'priority': 'Normal',
        'target': 'Staff',
        'targetStaffId': submissionData['staffId'],
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'submission_update',
        'fileUrl':
            submissionData['fileUrl'], // Directly allow viewing from notification
      });
    }
  }

  // 14b. Get Assignments for AI (fetches real data from Firestore)
  Future<List<Map<String, dynamic>>> getAssignments(String studentId) async {
    try {
      // First, resolve the student's department and semester
      String dept = 'MCA';
      String sem = '1';

      // Try students collection
      final studentDoc = await _db.collection('students').doc(studentId).get();
      if (studentDoc.exists) {
        final data = studentDoc.data()!;
        dept = data['department'] ?? 'MCA';
        sem = (data['semester'] ?? '1').toString();
      } else {
        // Try users collection by username or email
        final userDoc = await getUserByIdentifier(studentId);
        if (userDoc != null && userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          dept = data['department'] ?? 'MCA';
          sem = (data['semester'] ?? '1').toString();
        }
      }

      // Fetch assignments from assignments_master
      final assignmentsSnap = await _db.collection('assignments_master').get();
      final List<Map<String, dynamic>> result = [];

      for (var doc in assignmentsSnap.docs) {
        final data = doc.data();
        final String aDept = (data['department']?.toString() ?? '')
            .trim()
            .toUpperCase();
        final String aSem = (data['semester']?.toString() ?? '').trim();

        // Lenient matching
        bool match =
            (aDept.isEmpty ||
                aDept == 'ALL' ||
                aDept == dept.trim().toUpperCase()) &&
            (aSem.isEmpty || aSem == 'ALL' || aSem == sem);
        if (!match) continue;

        // Check if student has submitted this assignment
        String status = 'PENDING';
        final subSnap = await _db
            .collection('submissions')
            .where('assignmentId', isEqualTo: doc.id)
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();
        if (subSnap.docs.isNotEmpty) {
          status = (subSnap.docs.first.data()['status'] ?? 'submitted')
              .toString()
              .toUpperCase();
        }

        result.add({
          'id': doc.id,
          'title': data['title'] ?? 'Untitled',
          'subject': data['subject'] ?? 'N/A',
          'description': data['description'] ?? '',
          'status': status,
          'dueDate': data['dueDate'],
          'type': data['type'],
        });
      }

      return result;
    } catch (e) {
      debugPrint('Error fetching assignments for AI: $e');
      return [];
    }
  }

  // 15. Get Attendance (Future for AI) - aggregated by subject
  Future<List<Map<String, dynamic>>> getDetailedAttendance(
    String studentId,
  ) async {
    try {
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs = [];

      // Try multiple identifier fields to find attendance records
      for (final field in ['studentId', 'regNo', 'email', 'username']) {
        final snapshot = await _db
            .collection('attendance')
            .where(field, isEqualTo: studentId)
            .get();

        if (snapshot.docs.isNotEmpty) {
          debugPrint(
            '[getDetailedAttendance] Found ${snapshot.docs.length} records by $field=$studentId',
          );
          docs = snapshot.docs;
          break;
        }
      }

      // Also try case-insensitive match if nothing found
      if (docs.isEmpty) {
        final lowerCaseId = studentId.toLowerCase();
        final allAttendance = await _db.collection('attendance').get();
        docs = allAttendance.docs.where((doc) {
          final data = doc.data();
          return (data['studentId']?.toString().toLowerCase() == lowerCaseId) ||
              (data['regNo']?.toString().toLowerCase() == lowerCaseId) ||
              (data['email']?.toString().toLowerCase() == lowerCaseId) ||
              (data['username']?.toString().toLowerCase() == lowerCaseId);
        }).toList();

        if (docs.isNotEmpty) {
          debugPrint(
            '[getDetailedAttendance] Found ${docs.length} records by case-insensitive match',
          );
        }
      }

      if (docs.isEmpty) {
        debugPrint(
          '[getDetailedAttendance] No attendance records found for $studentId',
        );
        return [];
      }

      // Aggregate records by subject (same logic as attendance_screen.dart)
      // Records may be either:
      //   a) individual records with 'isPresent' boolean (per-class)
      //   b) summary records with 'present' and 'total' integers
      final Map<String, Map<String, dynamic>> aggregated = {};
      final bool hasRealRecords = docs.any(
        (doc) => doc.data().containsKey('isPresent'),
      );

      for (var doc in docs) {
        final data = doc.data();
        final subjectName =
            (data['subjectName'] ?? data['subject'] ?? 'Unknown')
                .toString()
                .toUpperCase();
        final isRealRecord = data.containsKey('isPresent');

        // If we have individual isPresent records, skip summary records
        if (hasRealRecords && !isRealRecord) continue;

        if (isRealRecord) {
          if (!aggregated.containsKey(subjectName)) {
            aggregated[subjectName] = {
              'subjectName': subjectName,
              'code': data['subjectCode'] ?? data['code'] ?? '-',
              'present': 0,
              'total': 0,
            };
          }
          aggregated[subjectName]!['total'] =
              (aggregated[subjectName]!['total'] as num).toInt() + 1;
          if (data['isPresent'] == true) {
            aggregated[subjectName]!['present'] =
                (aggregated[subjectName]!['present'] as num).toInt() + 1;
          }
        } else if (data.containsKey('present') && data.containsKey('total')) {
          final int p = (data['present'] as num?)?.toInt() ?? 0;
          final int t = (data['total'] as num?)?.toInt() ?? 0;
          if (!aggregated.containsKey(subjectName)) {
            aggregated[subjectName] = {
              'subjectName': subjectName,
              'code': data['subjectCode'] ?? data['code'] ?? '-',
              'present': p,
              'total': t,
            };
          } else {
            aggregated[subjectName]!['present'] =
                (aggregated[subjectName]!['present'] as num).toInt() + p;
            aggregated[subjectName]!['total'] =
                (aggregated[subjectName]!['total'] as num).toInt() + t;
          }
        }
      }

      debugPrint(
        '[getDetailedAttendance] Aggregated ${aggregated.length} subjects',
      );
      return aggregated.values.toList();
    } catch (e, stackTrace) {
      debugPrint("Attendance fetch error: $e");
      debugPrint("Stack trace: $stackTrace");
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

      return [];
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

  // 26. Get Dynamic Events
  Stream<QuerySnapshot> getEvents() {
    return _db
        .collection('events')
        .orderBy('date', descending: false)
        .snapshots();
  }

  // 27. Seed Events Data
  Future<void> seedEventsData() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    final List<Map<String, dynamic>> events = [
      {
        'title': "Maha Shivratri Holiday",
        'subtitle': "College Closed • State Holiday",
        'type': 'holiday',
        'date': Timestamp.fromDate(now),
        'icon': 'beach_access',
        'color': '0xFFFF5722', // deepOrange
      },
      {
        'title': "Tech Fest Innovate '26",
        'subtitle': "Main Campus • Annual Tech Event",
        'type': 'event',
        'date': Timestamp.fromDate(tomorrow),
        'icon': 'emoji_events',
        'color': '0xFFFFA000', // amber
      },
      {
        'title': "Guest Lecture: Future of AI",
        'subtitle': "Auditorium • Keynote Session",
        'type': 'lecture',
        'date': Timestamp.fromDate(now),
        'icon': 'mic',
        'color': '0xFF673AB7', // deepPurple
      },
      {
        'title': "Mid-Term Exam (MCA101)",
        'subtitle': "Exam Hall A • 10:00 AM",
        'type': 'exam',
        'date': Timestamp.fromDate(tomorrow),
        'icon': 'edit_calendar',
        'color': '0xFFF44336', // red
      },
    ];

    final batch = _db.batch();
    // Clear existing events first to avoid duplicates on multiple seeds
    final existingEvents = await _db.collection('events').get();
    for (var doc in existingEvents.docs) {
      batch.delete(doc.reference);
    }

    for (var event in events) {
      final docRef = _db.collection('events').doc();
      batch.set(docRef, event);
    }
    await batch.commit();
  }

  // 28. Seed Syllabus Data with Enriched Info
  Future<void> seedSyllabusData({String? studentId}) async {
    try {
      // Also seed events when seeding syllabus
      await seedEventsData();

      final List<Map<String, dynamic>> mcaSubjects = [
        {
          'id': 'MCA_201_ADS',
          'name': 'ADVANCED DATA STRUCTURES',
          'teacherName': 'Dr. Sarah Wilson',
          'totalClasses': 8,
          'attended': 6,
          'subjectCoverage': 85,
          'courseOutcomes': [
            'Analyze time and space complexity of algorithms',
            'Implement advanced tree and graph structures',
            'Apply hashing techniques for information retrieval',
          ],
          'modules': [
            'Module 1: Dynamic Programming & Greedy Approach',
            'Module 2: Advanced Tree Structures (B-Trees, AVL)',
            'Module 3: Graph Algorithms (Dijkstra, Floyd-Warshall)',
            'Module 4: String Matching Algorithms',
          ],
        },
        {
          'id': 'MCA_203_ASE',
          'name': 'ADVANCED SOFTWARE ENGINEERING',
          'teacherName': 'Prof. Michael Chen',
          'totalClasses': 8,
          'attended': 6,
          'subjectCoverage': 70,
          'courseOutcomes': [
            'Explain agile methodologies and DevOps practices',
            'Design scalable software architectures',
            'Implement automated testing frameworks',
          ],
          'modules': [
            'Module 1: Agile Software Development Life Cycle',
            'Module 2: Object-Oriented Design Patterns',
            'Module 3: Software Testing & Quality Assurance',
            'Module 4: Software Maintenance & Re-engineering',
          ],
        },
        {
          'id': 'MCA_205_DFCA',
          'name': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
          'teacherName': 'Dr. Robert Brown',
          'totalClasses': 8,
          'attended': 6,
          'subjectCoverage': 90,
          'courseOutcomes': [
            'Analyze digital logic circuits and boolean algebra',
            'Evaluate processor performance metrics',
            'Design memory hierarchies for optimal cache usage',
          ],
          'modules': [
            'Module 1: Number Systems & Boolean Algebra',
            'Module 2: Combinational & Sequential Circuits',
            'Module 3: Processor & Control Unit Design',
            'Module 4: Input/Output & Memory Organization',
          ],
        },
        {
          'id': 'MCA_206_WPL',
          'name': 'WEB PROGRAMMING LAB',
          'teacherName': 'Dr. Robert Brown',
          'totalClasses': 8,
          'attended': 6,
          'subjectCoverage': 100,
          'courseOutcomes': [
            'Build responsive websites using modern technologies',
            'Implement server-side logic and database connectivity',
            'Deploy full-stack web applications to cloud platforms',
          ],
          'modules': [
            'Module 1: HTML5, CSS3, & Modern UI Frameworks',
            'Module 2: Javascript (ES6+) & Frontend Architecture',
            'Module 3: Server-side PHP & Database Integration',
            'Module 4: Project Deployment & Cloud Infrastructure',
          ],
        },
      ];

      // 1. Seed Master Syllabus Data
      const docId = "MCA_2020_S1";
      await _db.collection('syllabus').doc(docId).set({
        'department': 'MCA',
        'semester': 1,
        'scheme': '2020',
        'subjects': mcaSubjects,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // 2. If studentId provided, also seed individual attendance records for them
      if (studentId != null && studentId.isNotEmpty) {
        await initializeAttendanceData(
          studentId,
          syllabusSubjects: mcaSubjects,
        );
      }

      debugPrint("Syllabus and Attendance data seeded successfully!");
    } catch (e) {
      debugPrint("Error seeding syllabus: $e");
      rethrow;
    }
  }

  // 19. Seed All Academics Data (Dev Tool)
  Future<void> seedDevData(String regNo) async {
    // Methods for seeding data should pull from a configuration or be removed in production
  }
}
