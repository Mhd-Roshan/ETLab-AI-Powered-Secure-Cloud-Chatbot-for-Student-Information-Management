import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/firebase_options.dart';

void main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;
  final snapshot = await firestore.collection('announcements').get();

  for (var doc in snapshot.docs) {
    print('ID: ${doc.id}, Title: ${doc.data()['title']}');
  }
}
