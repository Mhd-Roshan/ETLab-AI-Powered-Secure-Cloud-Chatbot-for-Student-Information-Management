import 'package:cloud_firestore/cloud_firestore.dart';

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
}
