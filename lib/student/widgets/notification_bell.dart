import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../notifications_screen.dart';

class NotificationBell extends StatelessWidget {
  final String? studentId;
  const NotificationBell({super.key, this.studentId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('announcements')
          .orderBy('postedDate', descending: true)
          .limit(1)
          .snapshots(),
      builder: (context, snapshot) {
        return FutureBuilder<SharedPreferences>(
          future: SharedPreferences.getInstance(),
          builder: (context, prefsSnapshot) {
            bool showBadge = false;

            if (snapshot.hasData &&
                snapshot.data!.docs.isNotEmpty &&
                prefsSnapshot.hasData) {
              final latestDoc = snapshot.data!.docs.first;
              final latestTime =
                  (latestDoc.data() as Map<String, dynamic>)['postedDate']
                      as Timestamp?;
              final lastReadStr = prefsSnapshot.data!.getString(
                'notifications_last_read_at',
              );
              final clearedStr = prefsSnapshot.data!.getString(
                'notifications_cleared_at',
              );

              if (latestTime != null) {
                final latestDateTime = latestTime.toDate();

                // 1. Check if it's after last read
                if (lastReadStr == null) {
                  showBadge = true;
                } else {
                  final lastReadDateTime = DateTime.parse(lastReadStr);
                  if (latestDateTime.isAfter(lastReadDateTime)) {
                    showBadge = true;
                  }
                }

                // 2. But if it's been cleared AFTER the notification was posted, don't show badge
                if (clearedStr != null) {
                  final clearedDateTime = DateTime.parse(clearedStr);
                  if (clearedDateTime.isAfter(latestDateTime)) {
                    showBadge = false;
                  }
                }
              }
            }

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        NotificationsScreen(studentId: studentId),
                  ),
                );
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined, size: 28),
                  if (showBadge)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

