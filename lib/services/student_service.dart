import 'package:cloud_firestore/cloud_firestore.dart';

class StudentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Get Profile
  Stream<DocumentSnapshot> getStudentProfile(String regNo) =>
      _db.collection('students').doc(regNo).snapshots();

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
}
