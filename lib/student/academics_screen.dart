import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'exams_screen.dart';
import 'timetable_screen.dart';
import 'attendance_screen.dart';
import 'results_screen.dart';
import 'assignments_screen.dart';
import 'materials_screen.dart';
import 'fees_screen.dart';
import 'notifications_screen.dart';
import 'survey_screen.dart';
import 'subject_screen.dart';
import 'widgets/notification_bell.dart';
import 'widgets/liquid_glass_button.dart';
import '../services/student_service.dart';

class AcademicsScreen extends StatefulWidget {
  final String? attendancePercentage;
  final String? studentId;
  const AcademicsScreen({super.key, this.attendancePercentage, this.studentId});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  final StudentService _studentService = StudentService();
  final Stream<QuerySnapshot> _announcementsStream = FirebaseFirestore.instance
      .collection('announcements')
      .orderBy('postedDate', descending: true)
      .limit(5)
      .snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      // No BottomNavigationBar here! It should be in your Main Dashboard file.
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),

            const SizedBox(height: 24),
            // Real-world Firestore Section
            _buildRealtimeUpcomingSection(),
            const SizedBox(height: 24),
            _buildGridMenu(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "LIVE",
              style: GoogleFonts.inter(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
        Image.asset('assets/edlab.png', height: 40),
        NotificationBell(studentId: widget.studentId),
      ],
    );
  }

  // --- 3. Real-time Firestore Section ---
  Widget _buildRealtimeUpcomingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Upcoming",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            LiquidGlassButton(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              label: const Text(
                "See All",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        StreamBuilder<QuerySnapshot>(
          stream: _announcementsStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              // Fallback to local dummy data if database is empty - ensures UI is never blank
              return _buildEmptyState();
            }

            var docs = snapshot.data!.docs.take(3).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                var doc = docs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                // Determine Type & Styling
                String type =
                    data['type']?.toString().toLowerCase() ?? 'announcement';
                String title = data['title'] ?? 'Notice';
                String content = data['content'] ?? 'Important update';

                Color itemColor = Colors.blue;
                IconData itemIcon = Icons.notifications_none;

                if (type == 'exam' || title.toLowerCase().contains('exam')) {
                  itemColor = Colors.red;
                  itemIcon = Icons.edit_calendar;
                } else if (type == 'holiday' ||
                    title.toLowerCase().contains('holiday')) {
                  itemColor = Colors.green;
                  itemIcon = Icons.beach_access;
                } else if (type == 'assignment' ||
                    title.toLowerCase().contains('assignment')) {
                  itemColor = Colors.orange;
                  itemIcon = Icons.assignment_turned_in;
                } else if (data['priority'] == 'high') {
                  itemColor = Colors.redAccent;
                  itemIcon = Icons.priority_high;
                }

                // Format Date
                String timeStr = "Recently";
                if (data['postedDate'] != null) {
                  DateTime dt = (data['postedDate'] as Timestamp).toDate();
                  timeStr = DateFormat('MMM d, h:mm a').format(dt);
                }

                return _buildEventCard(
                  icon: itemIcon,
                  iconColor: itemColor,
                  bgColor: itemColor.withOpacity(0.1),
                  title: title,
                  subtitle: "$content • $timeStr",
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return StreamBuilder<QuerySnapshot>(
      stream: _studentService.getEvents(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final events = snapshot.data?.docs ?? [];
        if (events.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "No upcoming events",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
              ),
            ),
          );
        }

        return Column(
          children: events.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final iconName = data['icon'] ?? 'event';
            final colorHex = data['color'] ?? '0xFF001FF4';
            final iconColor = Color(int.parse(colorHex));

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildEventCard(
                icon: _getIconData(iconName),
                iconColor: iconColor,
                bgColor: iconColor.withOpacity(0.1),
                title: data['title'] ?? 'Event',
                subtitle: data['subtitle'] ?? 'Upcoming session',
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'beach_access':
        return Icons.beach_access_rounded;
      case 'emoji_events':
        return Icons.emoji_events_rounded;
      case 'mic':
        return Icons.mic_external_on_rounded;
      case 'edit_calendar':
        return Icons.edit_calendar_rounded;
      case 'event':
        return Icons.event_note_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'verified':
        return Icons.verified_rounded;
      default:
        return Icons.info_outline_rounded;
    }
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.65),
            Colors.white.withOpacity(0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.40),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.3),
            shape: BoxShape.circle,
            border: Border.all(color: iconColor.withOpacity(0.2), width: 1),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: Colors.grey.shade800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),
      ),
    );
  }

  // --- 4. Grid Menu with Navigation ---
  Widget _buildGridMenu(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.calendar_today_rounded,
        'label': 'Attendance',
        'color': const Color(0xFF001FF4),
      },
      {
        'icon': Icons.bar_chart_rounded,
        'label': 'Results',
        'color': Colors.purple,
      },
      {
        'icon': Icons.edit_calendar_rounded,
        'label': 'Exams',
        'color': Colors.red,
      },
      {
        'icon': Icons.folder_copy_rounded,
        'label': 'Materials',
        'color': Colors.orange,
      },
      {'icon': Icons.payments_rounded, 'label': 'Fees', 'color': Colors.teal},
      {
        'icon': Icons.calendar_month_rounded,
        'label': 'Calendar',
        'color': Colors.blueAccent,
      },
      {
        'icon': Icons.assignment_rounded,
        'label': 'Assignments',
        'color': Colors.indigo,
      },
      {
        'icon': Icons.analytics_rounded,
        'label': 'Internal Marks',
        'color': const Color(0xFF0EA5E9),
      },
      {'icon': Icons.quiz_rounded, 'label': 'Q-Bank', 'color': Colors.green},
      {'icon': Icons.book_rounded, 'label': 'Subjects', 'color': Colors.cyan},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        void navigateTo() {
          // Navigation Logic
          if (item['label'] == 'Calendar') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const TimetableScreen()),
            );
          } else if (item['label'] == 'Attendance') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AttendanceScreen(
                  studentRegNo: widget.studentId,
                  overallAttendance: widget.attendancePercentage,
                ),
              ),
            );
          } else if (item['label'] == 'Results') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultsScreen(studentId: widget.studentId),
              ),
            );
          } else if (item['label'] == 'Exams') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExamsScreen(studentId: widget.studentId),
              ),
            );
          } else if (item['label'] == 'Fees') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => FeesScreen(studentId: widget.studentId),
              ),
            );
          } else if (item['label'] == 'Assignments') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AssignmentsScreen(studentId: widget.studentId),
              ),
            );
          } else if (item['label'] == 'Materials') {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MaterialsScreen()),
            );
          } else if (item['label'] == 'Survey') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SurveyScreen(studentId: widget.studentId ?? ''),
              ),
            );
          } else if (item['label'] == 'Subjects') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SyllabusScreen(studentRegNo: widget.studentId ?? ''),
              ),
            );
          } else if (item['label'] == 'Internal Marks') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResultsScreen(
                  studentId: widget.studentId,
                  initialExam: 'Internal Assessment',
                ),
              ),
            );
          } else if (item['label'] == 'Q-Bank') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${item['label']} feature coming soon! ✨"),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }

        return GestureDetector(
          onTap: navigateTo,
          behavior: HitTestBehavior.opaque,
          child: Column(
            children: [
              LiquidGlassButton(
                height: 60,
                width: 60,
                padding: EdgeInsets.zero,
                borderRadius: BorderRadius.circular(30),
                onPressed: navigateTo,
                label: Icon(
                  item['icon'],
                  color: item['color'].withOpacity(0.8),
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item['label'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}
