import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'assignments_screen.dart';
import 'widgets/liquid_glass_button.dart';

class NotificationsScreen extends StatefulWidget {
  final String? studentId;
  const NotificationsScreen({super.key, this.studentId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  DateTime? _lastClearedAt;

  @override
  void initState() {
    super.initState();
    _loadClearedAt();
    _markAsRead();
  }

  Future<void> _loadClearedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final clearedStr = prefs.getString('notifications_cleared_at');
    if (clearedStr != null) {
      setState(() {
        _lastClearedAt = DateTime.parse(clearedStr);
      });
    }
  }

  Future<void> _markAsRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifications_last_read_at',
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    await prefs.setString('notifications_cleared_at', now.toIso8601String());
    setState(() {
      _lastClearedAt = now;
    });
  }

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
        actions: [
          LiquidGlassButton(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            onPressed: _clearAll,
            label: const Text(
              "Clear All",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
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

            final allDocs = snapshot.data?.docs ?? [];
            final filteredDocs = _lastClearedAt == null
                ? allDocs
                : allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final postedDate = (data['postedDate'] as Timestamp?)
                        ?.toDate();
                    return postedDate != null &&
                        postedDate.isAfter(_lastClearedAt!);
                  }).toList();

            if (filteredDocs.isEmpty) {
              return _buildEmptyState(
                "No new notifications",
                Icons.notifications_off_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: filteredDocs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final doc = filteredDocs[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = data['title'] ?? 'Notification';
                final content = data['content'] ?? 'No content';
                final DateTime? date = (data['postedDate'] as Timestamp?)
                    ?.toDate();
                final priority = data['priority'] ?? 'normal';

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
                  iconColor = Colors.green;
                  bgColor = Colors.green.withOpacity(0.1);
                  icon = Icons.info_outline;
                }

                String timeString = "Recently";
                if (date != null) {
                  timeString = DateFormat('MMM d, h:mm a').format(date);
                }

                final type = data['type'] ?? 'info';

                return _buildEventCard(
                  icon: icon,
                  iconColor: iconColor,
                  bgColor: bgColor,
                  title: title,
                  subtitle: "$content • $timeString",
                  onTap: () {
                    if (type == 'assignment') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AssignmentsScreen(studentId: widget.studentId),
                        ),
                      );
                    }
                  },
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
    VoidCallback? onTap,
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
        onTap: onTap,
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
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ),
    );
  }
}

