// Run this file to add upcoming events to Firebase
// Command: dart run add_events_to_firebase.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  print('🚀 Starting Firebase Events Seeder...\n');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;
  final announcementsRef = firestore.collection('announcements');

  // Define upcoming events
  final List<Map<String, dynamic>> events = [
    {
      'title': 'Guest Lecture: Future of AI',
      'content': 'Join us for an insightful session on Artificial Intelligence',
      'postedDate': DateTime.now().add(const Duration(days: 1)), // Tomorrow
      'priority': 'medium',
      'isActive': true,
      'type': 'lecture',
      'location': 'Main Auditorium',
      'department': 'CSE',
      'time': '2:00 PM',
      'speaker': 'Dr. John Smith',
    },
    {
      'title': 'Data Structure Mid-Term Exam',
      'content': 'Mid-term examination for Data Structures course',
      'postedDate': DateTime.now().add(const Duration(days: 4)), // 4 days from now
      'priority': 'high',
      'isActive': true,
      'type': 'exam',
      'location': 'Exam Hall B',
      'department': 'CSE',
      'time': '9:00 AM',
      'duration': '2 hours',
    },
    {
      'title': 'Python Project Submission',
      'content': 'Final project submission deadline for Python Programming',
      'postedDate': DateTime.now().add(const Duration(days: 7)), // 1 week
      'priority': 'high',
      'isActive': true,
      'type': 'assignment',
      'location': 'Online Portal',
      'department': 'CSE',
      'time': '11:59 PM',
      'submissionLink': 'https://portal.edlab.edu',
    },
    {
      'title': 'Android Development Workshop',
      'content': 'Hands-on workshop on building Android apps with Flutter',
      'postedDate': DateTime.now().add(const Duration(days: 8)), // 8 days
      'priority': 'medium',
      'isActive': true,
      'type': 'workshop',
      'location': 'Computer Lab 3',
      'department': 'CSE',
      'time': '10:00 AM',
      'duration': '3 hours',
      'registrationRequired': true,
    },
    {
      'title': 'Inter-Department Football Match',
      'content': 'CSE vs ECE - Annual sports tournament',
      'postedDate': DateTime.now().add(const Duration(days: 9)), // 9 days
      'priority': 'low',
      'isActive': true,
      'type': 'sports',
      'location': 'Sports Ground',
      'department': 'All',
      'time': '4:00 PM',
      'teams': 'CSE vs ECE',
    },
    {
      'title': 'Career Guidance Seminar',
      'content': 'Industry experts share insights on career opportunities',
      'postedDate': DateTime.now().add(const Duration(days: 11)), // 11 days
      'priority': 'medium',
      'isActive': true,
      'type': 'seminar',
      'location': 'Seminar Hall',
      'department': 'All',
      'time': '3:00 PM',
      'speakers': 'Industry Professionals',
    },
    {
      'title': 'Mathematics Quiz Competition',
      'content': 'Test your mathematical skills and win prizes',
      'postedDate': DateTime.now().add(const Duration(days: 5)), // 5 days
      'priority': 'low',
      'isActive': true,
      'type': 'competition',
      'location': 'Room A-201',
      'department': 'All',
      'time': '2:30 PM',
      'prizes': 'Cash prizes for winners',
    },
    {
      'title': 'Technical Fest Registration',
      'content': 'Register for the annual technical festival TechFest 2024',
      'postedDate': DateTime.now().add(const Duration(days: 3)), // 3 days
      'priority': 'high',
      'isActive': true,
      'type': 'event',
      'location': 'Online Registration',
      'department': 'All',
      'time': 'Open Now',
      'deadline': 'Feb 20, 2024',
    },
  ];

  print('📝 Adding ${events.length} events to Firebase...\n');

  int successCount = 0;
  int errorCount = 0;

  for (var i = 0; i < events.length; i++) {
    try {
      final event = events[i];
      await announcementsRef.add(event);
      
      print('✅ [${i + 1}/${events.length}] Added: ${event['title']}');
      successCount++;
    } catch (e) {
      print('❌ [${i + 1}/${events.length}] Error: $e');
      errorCount++;
    }
  }

  print('\n${'=' * 50}');
  print('📊 Summary:');
  print('   ✅ Successfully added: $successCount events');
  if (errorCount > 0) {
    print('   ❌ Failed: $errorCount events');
  }
  print('=' * 50);
  print('\n🎉 Done! Check your Firebase Console to verify.');
  print('📱 Open your app and go to Academics tab to see the events!\n');
}
