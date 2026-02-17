import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('announcements')
              .orderBy('postedDate', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _buildEmptyState(
                "Error loading notifications: ${snapshot.error}",
                Icons.error_outline,
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState(
                "No new notifications",
                Icons.notifications_off_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = data['title'] ?? 'Notification';
                final content = data['content'] ?? 'No content';
                final DateTime? date = (data['postedDate'] as Timestamp?)
                    ?.toDate();
                final priority = data['priority'] ?? 'normal';

                // Consistent Colors with AcademicsScreen
                Color iconColor = Colors.green;
                Color bgColor = Colors.green.withOpacity(0.1);
                IconData icon = Icons.notifications_none;

                if (priority == 'high') {
                  iconColor = Colors.red;
                  bgColor = Colors.red.withOpacity(0.1);
                  icon = Icons.priority_high;
                } else if (priority == 'medium') {
                  iconColor = Colors.blue;
                  bgColor = Colors.blue.withOpacity(0.1);
                  icon = Icons.event;
                } else {
                  // Low/Normal
                  iconColor = Colors.green;
                  bgColor = Colors.green.withOpacity(0.1);
                  icon = Icons.info_outline;
                }

                String timeString = "Recently";
                if (date != null) {
                  timeString = DateFormat('MMM d, h:mm a').format(date);
                }

                return _buildEventCard(
                  icon: icon,
                  iconColor: iconColor,
                  bgColor: bgColor,
                  title: title,
                  subtitle: "$content • $timeString",
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          radius: 24,
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow
                .ellipsis, // Changed to 2 lines for notifications as content might be longer
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ),
    );
  }
}
