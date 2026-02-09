import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Staff Seeder Service
/// Adds 10 sample staff members (5 MCA + 5 MBA) to Firestore
class StaffSeeder {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Seed staff to Firebase
  static Future<Map<String, dynamic>> seedStaff() async {
    debugPrint('🌱 Starting Staff Seeder...');

    final staffCollection = _db.collection('staff');

    // MCA Staff Data
    final List<Map<String, dynamic>> mcaStaff = [
      {
        'firstName': 'Dr. Rajesh',
        'lastName': 'Kumar',
        'staffId': 'MCA-PROF-001',
        'email': 'rajesh.kumar@kmct.edu.in',
        'phone': '+91 9876501001',
        'designation': 'Professor',
        'department': 'MCA',
        'status': 'Active',
        'qualification': 'Ph.D. in Computer Science',
        'experience': 15,
        'specialization': 'Machine Learning, Data Science',
      },
      {
        'firstName': 'Dr. Lakshmi',
        'lastName': 'Menon',
        'staffId': 'MCA-PROF-002',
        'email': 'lakshmi.menon@kmct.edu.in',
        'phone': '+91 9876501002',
        'designation': 'Professor',
        'department': 'MCA',
        'status': 'Active',
        'qualification': 'Ph.D. in Software Engineering',
        'experience': 12,
        'specialization': 'Software Engineering, Cloud Computing',
      },
      {
        'firstName': 'Suresh',
        'lastName': 'Nair',
        'staffId': 'MCA-ASST-001',
        'email': 'suresh.nair@kmct.edu.in',
        'phone': '+91 9876501003',
        'designation': 'Asst. Professor',
        'department': 'MCA',
        'status': 'Active',
        'qualification': 'M.Tech in Computer Science',
        'experience': 6,
        'specialization': 'Web Technologies, Mobile Development',
      },
      {
        'firstName': 'Priya',
        'lastName': 'Sharma',
        'staffId': 'MCA-ASST-002',
        'email': 'priya.sharma@kmct.edu.in',
        'phone': '+91 9876501004',
        'designation': 'Asst. Professor',
        'department': 'MCA',
        'status': 'Active',
        'qualification': 'M.Tech in Computer Science',
        'experience': 5,
        'specialization': 'Database Systems, Big Data',
      },
      {
        'firstName': 'Arun',
        'lastName': 'Pillai',
        'staffId': 'MCA-LAB-001',
        'email': 'arun.pillai@kmct.edu.in',
        'phone': '+91 9876501005',
        'designation': 'Lab Assistant',
        'department': 'MCA',
        'status': 'Active',
        'qualification': 'MCA',
        'experience': 3,
        'specialization': 'Programming Labs, System Administration',
      },
    ];

    // MBA Staff Data
    final List<Map<String, dynamic>> mbaStaff = [
      {
        'firstName': 'Dr. Anand',
        'lastName': 'Varma',
        'staffId': 'MBA-PROF-001',
        'email': 'anand.varma@kmct.edu.in',
        'phone': '+91 9876502001',
        'designation': 'Professor',
        'department': 'MBA',
        'status': 'Active',
        'qualification': 'Ph.D. in Management',
        'experience': 18,
        'specialization': 'Strategic Management, Marketing',
      },
      {
        'firstName': 'Dr. Kavitha',
        'lastName': 'Reddy',
        'staffId': 'MBA-PROF-002',
        'email': 'kavitha.reddy@kmct.edu.in',
        'phone': '+91 9876502002',
        'designation': 'Professor',
        'department': 'MBA',
        'status': 'Active',
        'qualification': 'Ph.D. in Finance',
        'experience': 14,
        'specialization': 'Financial Management, Investment Analysis',
      },
      {
        'firstName': 'Ramesh',
        'lastName': 'Iyer',
        'staffId': 'MBA-ASST-001',
        'email': 'ramesh.iyer@kmct.edu.in',
        'phone': '+91 9876502003',
        'designation': 'Asst. Professor',
        'department': 'MBA',
        'status': 'Active',
        'qualification': 'MBA, M.Phil',
        'experience': 7,
        'specialization': 'Human Resource Management, OB',
      },
      {
        'firstName': 'Deepa',
        'lastName': 'Shetty',
        'staffId': 'MBA-ASST-002',
        'email': 'deepa.shetty@kmct.edu.in',
        'phone': '+91 9876502004',
        'designation': 'Asst. Professor',
        'department': 'MBA',
        'status': 'Active',
        'qualification': 'MBA, M.Com',
        'experience': 5,
        'specialization': 'Operations Management, Supply Chain',
      },
      {
        'firstName': 'Vinod',
        'lastName': 'Kumar',
        'staffId': 'MBA-ADMIN-001',
        'email': 'vinod.kumar@kmct.edu.in',
        'phone': '+91 9876502005',
        'designation': 'Admin Staff',
        'department': 'MBA',
        'status': 'Active',
        'qualification': 'B.Com',
        'experience': 8,
        'specialization': 'Administration, Student Affairs',
      },
    ];

    final allStaff = [...mcaStaff, ...mbaStaff];

    debugPrint('📚 Adding ${allStaff.length} staff members to Firestore...');

    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    List<String> errors = [];

    for (var staff in allStaff) {
      try {
        // Check if staff already exists by staffId
        final existingStaff = await staffCollection
            .where('staffId', isEqualTo: staff['staffId'])
            .get();

        if (existingStaff.docs.isNotEmpty) {
          debugPrint('⚠️  ${staff['staffId']} already exists, skipping...');
          skippedCount++;
          continue;
        }

        // Check if email already exists
        final existingEmail = await staffCollection
            .where('email', isEqualTo: staff['email'])
            .get();

        if (existingEmail.docs.isNotEmpty) {
          debugPrint('⚠️  Email ${staff['email']} already exists, skipping...');
          skippedCount++;
          continue;
        }

        // Add timestamp
        staff['joinDate'] = FieldValue.serverTimestamp();

        // Add to staff collection using staffId as document ID
        await staffCollection.doc(staff['staffId']).set(staff);

        debugPrint('✅ ${staff['staffId']} - ${staff['firstName']} ${staff['lastName']} (${staff['designation']})');
        successCount++;
      } catch (e) {
        debugPrint('❌ Error adding ${staff['staffId']}: $e');
        errors.add('${staff['staffId']}: $e');
        errorCount++;
      }
    }

    debugPrint('🎉 Seeding Complete! Success: $successCount, Skipped: $skippedCount, Errors: $errorCount');

    return {
      'success': true,
      'total': allStaff.length,
      'added': successCount,
      'skipped': skippedCount,
      'errors': errorCount,
      'errorDetails': errors,
      'message': 'Successfully added $successCount staff members. Skipped $skippedCount existing staff.',
    };
  }
}
