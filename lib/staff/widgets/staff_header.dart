import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Ensure intl is in pubspec.yaml
import 'package:edlab/staff/screens/alerts_screen.dart'; // To navigate to full list

class StaffHeader extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final bool isWhite;
  final bool showDate;
  final String userId;

  const StaffHeader({
    super.key,
    this.title = "Dashboard",
    this.showBackButton = false,
    this.isWhite = false,
    this.showDate = true,
    this.userId = 'staff789@gmail.com',
  });

  // --- HELPER: Mark Notification as Read ---
  void _markAsRead(String docId) {
    FirebaseFirestore.instance.collection('alerts').doc(docId).update({
      'isRead': true,
    });
  }

  // --- HELPER: Navigate to Alerts Page ---
  void _goToAlerts(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlertsScreen(userId: userId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = isWhite ? Colors.white : const Color(0xFF0F172A);
    final subColor = isWhite
        ? Colors.white.withValues(alpha: 0.7)
        : const Color(0xFF64748B);
    final containerColor = isWhite
        ? Colors.white.withValues(alpha: 0.15)
        : Colors.white;
    final borderColor = isWhite
        ? Colors.white.withValues(alpha: 0.25)
        : const Color(0xFFE2E8F0);

    return SizedBox(
      height: 80,
      child: Row(
        children: [
          if (showBackButton) ...[
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: textColor,
            ),
            const SizedBox(width: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
              if (showDate) ...[
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(DateTime.now()),
                  style: GoogleFonts.inter(
                    color: subColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const Spacer(flex: 1),
          // Search Bar
          Expanded(
            flex: 2,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.5),
                boxShadow: isWhite
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: TextField(
                textAlignVertical: TextAlignVertical.center,
                style: GoogleFonts.inter(
                  color: textColor,
                  fontSize: 15,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: "Search students, staff, or courses...",
                  hintStyle: GoogleFonts.inter(
                    color: isWhite
                        ? Colors.white.withValues(alpha: 0.5)
                        : const Color(0xFF94A3B8),
                    fontSize: 15,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: isWhite ? Colors.white : const Color(0xFF64748B),
                    size: 24,
                  ),
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(8),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isWhite
                          ? Colors.white.withValues(alpha: 0.2)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      size: 18,
                      color: isWhite ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Spacer(flex: 1),
          _buildNotificationBell(context, isWhite),
        ],
      ),
    );
  }

  // --- NOTIFICATION BELL WIDGET ---
  Widget _buildNotificationBell(BuildContext context, bool isWhite) {
    final bellBg = isWhite ? Colors.white.withValues(alpha: 0.2) : Colors.white;
    final bellIconColor = isWhite ? Colors.white : const Color(0xFF64748B);
    final bellBorder = isWhite
        ? Colors.white.withValues(alpha: 0.3)
        : const Color(0xFFE2E8F0);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .orderBy('timestamp', descending: true)
          .limit(10) // Fetch last 10
          .snapshots(),
      builder: (context, snapshot) {
        // 1. Calculate Unread Count
        int unreadCount = 0;
        List<DocumentSnapshot> alerts = [];

        if (snapshot.hasData) {
          alerts = snapshot.data!.docs;
          unreadCount = alerts.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['isRead'] == false || data['isRead'] == null;
          }).length;
        }

        return Theme(
          data: Theme.of(context).copyWith(
            popupMenuTheme: PopupMenuThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              surfaceTintColor: Colors.white,
            ),
          ),
          child: PopupMenuButton(
            offset: const Offset(0, 50),
            tooltip: "Notifications",
            // The Bell Icon
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bellBg,
                shape: BoxShape.circle,
                border: Border.all(color: bellBorder),
                boxShadow: isWhite
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFF64748B,
                          ).withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: bellIconColor,
                    size: 26,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // The Dropdown Content
            itemBuilder: (context) => [
              // Header
              PopupMenuItem(
                enabled: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Notifications",
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              "$unreadCount New",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: Color(0xFFF1F5F9)),
                  ],
                ),
              ),

              // List of Alerts
              if (alerts.isEmpty)
                const PopupMenuItem(
                  enabled: false,
                  child: Text(
                    "No notifications",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),

              ...alerts.take(5).map((doc) {
                var data = doc.data() as Map<String, dynamic>;
                bool isRead = data['isRead'] ?? false;

                // Color coding based on priority
                Color priorityColor = Colors.blue;
                if (data['priority'] == 'Critical') priorityColor = Colors.red;
                if (data['priority'] == 'High') priorityColor = Colors.orange;

                // Time
                String timeStr = "Just now";
                if (data['timestamp'] != null) {
                  timeStr = DateFormat(
                    'h:mm a',
                  ).format((data['timestamp'] as Timestamp).toDate());
                }

                return PopupMenuItem(
                  onTap: () => _markAsRead(doc.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isRead ? Colors.transparent : priorityColor,
                            shape: BoxShape.circle,
                            border: isRead
                                ? Border.all(color: Colors.grey.shade300)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['title'] ?? "Alert",
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                              Text(
                                data['message'] ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Footer
              PopupMenuItem(
                onTap: () => Future.delayed(
                  const Duration(seconds: 0),
                  () => _goToAlerts(context),
                ),
                child: Column(
                  children: [
                    const Divider(color: Color(0xFFF1F5F9)),
                    Center(
                      child: Text(
                        "View All Alerts",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF001FF4),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

