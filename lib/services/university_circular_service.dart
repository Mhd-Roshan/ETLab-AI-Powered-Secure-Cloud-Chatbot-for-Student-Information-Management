import 'package:cloud_firestore/cloud_firestore.dart';

class UniversityCircularService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _circularsCollection =>
      _db.collection('university_circulars');

  // Stream circulars filtered by department
  Stream<QuerySnapshot> streamCirculars({String? department}) {
    Query query = _circularsCollection;

    if (department != null && department != 'College Admin') {
      query = query.where('department', isEqualTo: department);
    }

    return query.orderBy('timestamp', descending: true).snapshots();
  }

  // Seed initial KTU circulars for demonstration
  Future<void> seedInitialCirculars() async {
    final snapshot = await _circularsCollection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final circulars = [
      {
        'title': 'MCA S4 Project Phase-II Assessment Guidelines',
        'refNo': 'KTU/AC/MCA/2024',
        'date': '24 Feb 2024',
        'category': 'Academic',
        'department': 'MCA',
        'pdfUrl': 'https://ktu.edu.in/data/mca_guidelines.pdf',
        'isLatest': true,
        'timestamp': Timestamp.now(),
      },
      {
        'title': 'MCA S1 & S3 Supplementary Exam Registration',
        'refNo': 'KTU/EX/MCA/442/2024',
        'date': '20 Feb 2024',
        'category': 'Examination',
        'department': 'MCA',
        'pdfUrl': 'https://ktu.edu.in/data/mca_exam.pdf',
        'isLatest': false,
        'timestamp': Timestamp.now(),
      },
      {
        'title': 'Revised MCA Academic Calendar 2023-24',
        'refNo': 'KTU/AC/MCA/CAL/2024',
        'date': '18 Feb 2024',
        'category': 'Academic',
        'department': 'MCA',
        'pdfUrl': 'https://ktu.edu.in/data/mca_calendar.pdf',
        'isLatest': false,
        'timestamp': Timestamp.now(),
      },
      {
        'title': 'MCA Bridge Course Completion - Instructions',
        'refNo': 'KTU/AC/MCA/BR/2024',
        'date': '15 Feb 2024',
        'category': 'General',
        'department': 'MCA',
        'pdfUrl': 'https://ktu.edu.in/data/bridge_course.pdf',
        'isLatest': false,
        'timestamp': Timestamp.now(),
      },
    ];

    for (var circular in circulars) {
      await _circularsCollection.add(circular);
    }
  }
}
