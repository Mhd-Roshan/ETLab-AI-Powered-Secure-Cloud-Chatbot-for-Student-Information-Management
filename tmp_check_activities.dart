import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  print('--- Announcements ---');
  final announcements = await firestore
      .collection('announcements')
      .limit(5)
      .get();
  for (var doc in announcements.docs) {
    print('Announcement: ${doc.data()['title']}');
  }

  print('\n--- Alerts ---');
  final alerts = await firestore.collection('alerts').limit(5).get();
  for (var doc in alerts.docs) {
    print('Alert: ${doc.data()['title']}');
  }

  print('\n--- HOD Activities (Checking custom collection) ---');
  try {
    final hodActivities = await firestore
        .collection('hod_activities')
        .limit(5)
        .get();
    for (var doc in hodActivities.docs) {
      print('HOD Activity: ${doc.data()['title']}');
    }
  } catch (e) {
    print('hod_activities collection might not exist');
  }
}
