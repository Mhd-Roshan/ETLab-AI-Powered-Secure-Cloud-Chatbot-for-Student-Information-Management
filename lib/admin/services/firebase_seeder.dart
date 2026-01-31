import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static Future<void> seedAll() async {
    await seedDepartments();
    await seedCourses();
    await seedStaff();
    await seedStudents();
    await seedFeeStructures();
  }

  static Future<void> seedDepartments() async {
    final List<Map<String, dynamic>> departments = [
      {"code": "CSE", "name": "Computer Science"},
      {"code": "MCA", "name": "Computer Applications"},
      {"code": "ME", "name": "Mechanical Engineering"},
      {"code": "CE", "name": "Civil Engineering"},
      {"code": "ECE", "name": "Electronics & Communication"},
      {"code": "EEE", "name": "Electrical & Electronics"},
      {"code": "AIML", "name": "Artificial Intelligence"},
      {"code": "ADS", "name": "Data Science"},
    ];

    for (var dept in departments) {
      await _db.collection('departments').doc(dept['code']).set(dept);
    }
  }

  static Future<void> seedCourses() async {
    final List<Map<String, dynamic>> courses = [
      {
        "courseCode": "CST201",
        "courseName": "Data Structures",
        "credits": 4,
        "instructor": "Dr. Smith",
        "department": "CSE",
      },
      {
        "courseCode": "CST202",
        "courseName": "Operating Systems",
        "credits": 4,
        "instructor": "Prof. Jane",
        "department": "CSE",
      },
      {
        "courseCode": "MAT101",
        "courseName": "Linear Algebra",
        "credits": 3,
        "instructor": "Dr. Wilson",
        "department": "All",
      },
    ];

    for (var course in courses) {
      await _db.collection('courses').doc(course['courseCode']).set(course);
    }
  }

  static Future<void> seedStaff() async {
    final List<Map<String, dynamic>> staff = [
      {
        "staffId": "ST001",
        "name": "Dr. Rajesh Kumar",
        "dept": "CSE",
        "designation": "Professor",
        "email": "rajesh@edlab.edu",
      },
      {
        "staffId": "ST002",
        "name": "Mrs. Priya Nair",
        "dept": "ECE",
        "designation": "Asst. Professor",
        "email": "priya@edlab.edu",
      },
    ];

    for (var s in staff) {
      await _db.collection('staff').doc(s['staffId']).set(s);
    }
  }

  static Future<void> seedStudents() async {
    final List<Map<String, dynamic>> students = [
      {
        "regNo": "KMCT20CS001",
        "name": "Adithya Kumar",
        "dept": "CSE",
        "batch": "2024-2028",
        "semester": "S2",
        "email": "adithya@student.com",
      },
      {
        "regNo": "KMCT20CS005",
        "name": "Ben Johnson",
        "dept": "CSE",
        "batch": "2024-2028",
        "semester": "S2",
        "email": "ben@student.com",
      },
    ];

    for (var student in students) {
      await _db.collection('students').doc(student['regNo']).set(student);
    }
  }

  static Future<void> seedFeeStructures() async {
    final List<Map<String, dynamic>> feeStructures = [
      {
        'title': 'Tuition Fee - CSE S1',
        'amount': 45000.0,
        'department': 'CSE',
        'semester': 'S1',
        'createdAt': FieldValue.serverTimestamp(),
      },
      {
        'title': 'Hostel Fee - Annual',
        'amount': 25000.0,
        'department': 'All',
        'semester': 'Annual',
        'createdAt': FieldValue.serverTimestamp(),
      },
    ];

    for (var fee in feeStructures) {
      await _db.collection('fee_structures').add(fee);
    }
  }
}
