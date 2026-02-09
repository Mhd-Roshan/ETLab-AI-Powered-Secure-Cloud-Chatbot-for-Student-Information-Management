import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Student Seeder Service
/// Adds 10 sample students (5 MCA + 5 MBA) to Firestore
class StudentSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seed students to Firebase
  static Future<Map<String, dynamic>> seedStudents() async {
    debugPrint('🌱 Starting Student Seeder...');

    final studentsCollection = _db.collection('students');
    final usersCollection = _db.collection('users');

    // MCA Students Data
    final List<Map<String, dynamic>> mcaStudents = [
      {
        'firstName': 'Arjun',
        'lastName': 'Krishna',
        'registrationNumber': 'MCA2024001',
        'email': 'arjun.krishna@kmct.edu.in',
        'phone': '+91 9876543210',
        'department': 'MCA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 8.5,
        'status': 'active',
        'attendancePercentage': 85.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
      },
      {
        'firstName': 'Priya',
        'lastName': 'Menon',
        'registrationNumber': 'MCA2024002',
        'email': 'priya.menon@kmct.edu.in',
        'phone': '+91 9876543211',
        'department': 'MCA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 9.2,
        'status': 'active',
        'attendancePercentage': 92.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
      },
      {
        'firstName': 'Rahul',
        'lastName': 'Sharma',
        'registrationNumber': 'MCA2024003',
        'email': 'rahul.sharma@kmct.edu.in',
        'phone': '+91 9876543212',
        'department': 'MCA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 7.8,
        'status': 'active',
        'attendancePercentage': 78.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
      },
      {
        'firstName': 'Sneha',
        'lastName': 'Nair',
        'registrationNumber': 'MCA2024004',
        'email': 'sneha.nair@kmct.edu.in',
        'phone': '+91 9876543213',
        'department': 'MCA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 8.9,
        'status': 'active',
        'attendancePercentage': 88.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
      },
      {
        'firstName': 'Karthik',
        'lastName': 'Pillai',
        'registrationNumber': 'MCA2024005',
        'email': 'karthik.pillai@kmct.edu.in',
        'phone': '+91 9876543214',
        'department': 'MCA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 8.2,
        'status': 'active',
        'attendancePercentage': 82.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
      },
    ];

    // MBA Students Data
    final List<Map<String, dynamic>> mbaStudents = [
      {
        'firstName': 'Anjali',
        'lastName': 'Varma',
        'registrationNumber': 'MBA2024001',
        'email': 'anjali.varma@kmct.edu.in',
        'phone': '+91 9876543215',
        'department': 'MBA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 8.7,
        'status': 'active',
        'attendancePercentage': 87.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
        'specialization': 'Marketing',
      },
      {
        'firstName': 'Vikram',
        'lastName': 'Reddy',
        'registrationNumber': 'MBA2024002',
        'email': 'vikram.reddy@kmct.edu.in',
        'phone': '+91 9876543216',
        'department': 'MBA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 9.0,
        'status': 'active',
        'attendancePercentage': 90.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
        'specialization': 'Finance',
      },
      {
        'firstName': 'Divya',
        'lastName': 'Iyer',
        'registrationNumber': 'MBA2024003',
        'email': 'divya.iyer@kmct.edu.in',
        'phone': '+91 9876543217',
        'department': 'MBA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 8.4,
        'status': 'active',
        'attendancePercentage': 84.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
        'specialization': 'HR',
      },
      {
        'firstName': 'Aditya',
        'lastName': 'Kumar',
        'registrationNumber': 'MBA2024004',
        'email': 'aditya.kumar@kmct.edu.in',
        'phone': '+91 9876543218',
        'department': 'MBA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 7.9,
        'status': 'active',
        'attendancePercentage': 79.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
        'specialization': 'Operations',
      },
      {
        'firstName': 'Meera',
        'lastName': 'Shetty',
        'registrationNumber': 'MBA2024005',
        'email': 'meera.shetty@kmct.edu.in',
        'phone': '+91 9876543219',
        'department': 'MBA',
        'batch': '2024-2026',
        'semester': 1,
        'gpa': 8.6,
        'status': 'active',
        'attendancePercentage': 86.0,
        'collegeCode': 'KMCT',
        'collegeName': 'KMCT School of Business',
        'isActive': true,
        'role': 'student',
        'specialization': 'Marketing',
      },
    ];

    final allStudents = [...mcaStudents, ...mbaStudents];

    debugPrint('📚 Adding ${allStudents.length} students to Firestore...');

    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    List<String> errors = [];

    for (var student in allStudents) {
      try {
        // Check if student already exists
        final existingStudent = await studentsCollection
            .where('registrationNumber', isEqualTo: student['registrationNumber'])
            .get();

        if (existingStudent.docs.isNotEmpty) {
          debugPrint('⚠️  ${student['registrationNumber']} already exists, skipping...');
          skippedCount++;
          continue;
        }

        // Add timestamp
        student['createdAt'] = FieldValue.serverTimestamp();

        // Add to students collection
        await studentsCollection.add(student);

        // Also add to users collection for login
        final userEmail = student['email'] as String;
        final userDocId = userEmail.replaceAll('@', '_at_').replaceAll('.', '_');

        await usersCollection.doc(userDocId).set({
          'username': student['registrationNumber'],
          'email': userEmail,
          'firstname': student['firstName'],
          'lastname': student['lastName'],
          'phone': student['phone'],
          'department': student['department'],
          'semester': student['semester'],
          'batch': student['batch'],
          'gpa': student['gpa'],
          'collegeCode': student['collegeCode'],
          'collegeName': student['collegeName'],
          'isActive': student['isActive'],
          'role': student['role'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ ${student['registrationNumber']} - ${student['firstName']} ${student['lastName']}');
        successCount++;
      } catch (e) {
        debugPrint('❌ Error adding ${student['registrationNumber']}: $e');
        errors.add('${student['registrationNumber']}: $e');
        errorCount++;
      }
    }

    debugPrint('🎉 Seeding Complete! Success: $successCount, Skipped: $skippedCount, Errors: $errorCount');

    return {
      'success': true,
      'total': allStudents.length,
      'added': successCount,
      'skipped': skippedCount,
      'errors': errorCount,
      'errorDetails': errors,
      'message': 'Successfully added $successCount students. Skipped $skippedCount existing students.',
    };
  }
}
