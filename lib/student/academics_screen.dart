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

class AcademicsScreen extends StatefulWidget {
  final String? attendancePercentage;
  final String? studentId;
  const AcademicsScreen({super.key, this.attendancePercentage, this.studentId});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
      ),
    );
  }

  // --- 1. Top Bar ---
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Using a Drawer trigger if you have a drawer, else just an icon
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
              style: GoogleFonts.pressStart2p(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        ),
        Image.asset('assets/edlab.png', height: 40),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
          child: Stack(
            children: [
              const Icon(Icons.notifications_outlined, size: 28),
              Positioned(
                right: 2,
                top: 2,
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
        ),
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
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "See All",
                  style: TextStyle(
                    color: Color(0xFF3D6AF2),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
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

            var docs = snapshot.data!.docs;

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
    // Show dummy upcoming events when Firebase is empty
    return Column(
      children: [
        _buildEventCard(
          icon: Icons.mic,
          iconColor: Colors.deepPurple,
          bgColor: Colors.deepPurple.withValues(alpha: 0.1),
          title: "Guest Lecture: Future of AI",
          subtitle: "Auditorium • Tomorrow, 2:00 PM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.edit_calendar,
          iconColor: Colors.red,
          bgColor: Colors.red.withValues(alpha: 0.1),
          title: "Data Structure Mid-Term Exam",
          subtitle: "Exam Hall B • Monday, 9:00 AM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.assignment_turned_in,
          iconColor: Colors.orange,
          bgColor: Colors.orange.withValues(alpha: 0.1),
          title: "Python Project Submission",
          subtitle: "Online Portal • Due: Feb 15, 11:59 PM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.computer,
          iconColor: Colors.teal,
          bgColor: Colors.teal.withValues(alpha: 0.1),
          title: "Android Development Workshop",
          subtitle: "Computer Lab 3 • Friday, 10:00 AM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.sports_soccer,
          iconColor: Colors.green,
          bgColor: Colors.green.withValues(alpha: 0.1),
          title: "Inter-Department Football Match",
          subtitle: "Sports Ground • Saturday, 4:00 PM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.groups,
          iconColor: Colors.indigo,
          bgColor: Colors.indigo.withValues(alpha: 0.1),
          title: "Career Guidance Seminar",
          subtitle: "Seminar Hall • Next Week, 3:00 PM",
        ),
      ],
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
      ),
    );
  }

  // --- 4. Grid Menu with Navigation ---
  Widget _buildGridMenu(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.calendar_today,
        'label': 'Attendance',
        'color': Colors.blue,
      },
      {'icon': Icons.school, 'label': 'Results', 'color': Colors.indigo},
      {'icon': Icons.edit_document, 'label': 'Exams', 'color': Colors.red},
      {'icon': Icons.folder, 'label': 'Materials', 'color': Colors.orange},
      {'icon': Icons.payments, 'label': 'Fees', 'color': Colors.teal},
      {
        'icon': Icons.event,
        'label': 'Calendar',
        'color': Colors.blueAccent,
      }, // Links to Timetable
      {
        'icon': Icons.assignment,
        'label': 'Assignments',
        'color': Colors.deepPurple,
      },
      {
        'icon': Icons.quiz,
        'label': 'Q-Bank',
        'color': Colors.tealAccent.shade700,
      },
      {'icon': Icons.book, 'label': 'Syllabus', 'color': Colors.cyan},
      {'icon': Icons.work, 'label': 'Placement', 'color': Colors.purple},
      {'icon': Icons.newspaper, 'label': 'News', 'color': Colors.red},
      {'icon': Icons.poll, 'label': 'Survey', 'color': Colors.amber},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return GestureDetector(
          onTap: () {
            // Navigation Logic
            if (item['label'] == 'Calendar') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TimetableScreen(),
                ),
              );
            } else if (item['label'] == 'Attendance') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AttendanceScreen(
                    overallAttendance: widget.attendancePercentage,
                  ),
                ),
              );
            } else if (item['label'] == 'Results') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResultsScreen()),
              );
            } else if (item['label'] == 'Exams') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ExamsScreen(studentId: widget.studentId),
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
                  builder: (context) => const AssignmentsScreen(),
                ),
              );
            } else if (item['label'] == 'Syllabus') {
              // Placeholder for Syllabus
            } else if (item['label'] == 'Materials') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MaterialsScreen(),
                ),
              );
            } else if (item['label'] == 'Survey') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SurveyScreen(studentId: widget.studentId ?? ''),
                ),
              );
            }
          },
          child: Column(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: item['color'].withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'], color: item['color'], size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
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
