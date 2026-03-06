import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/staff_sidebar.dart';
import '../widgets/staff_header.dart';
import 'staff_attendance_screen.dart';
import 'evaluation_screen.dart';
import 'internal_marks_screen.dart';
import 'course_plan_screen.dart';
import 'staff_survey_screen.dart';
import '../../hod/screens/teaching/hod_hour_requests_screen.dart';

class MyClassesScreen extends StatelessWidget {
  final String userId;
  const MyClassesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          StaffSidebar(activeIndex: 2, userId: userId),

          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Header (Similar to Dashboard)
                Padding(
                  padding: EdgeInsets.fromLTRB(32, 24, 32, 0),
                  child: StaffHeader(title: "My Classes", userId: userId),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- SERVICE GRID ---
                        _buildServiceGrid(),

                        const SizedBox(height: 32),

                        // --- STUDENT LIST TABLE (EMPTY STATE) ---
                        _buildStudentTable(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid() {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'Attendance',
        'icon': Icons.fact_check_outlined,
        'color': const Color(0xFF001FF4),
      },
      {
        'title': 'Evaluations',
        'icon': Icons.bar_chart_outlined,
        'color': const Color(0xFF001FF4),
      },
      {
        'title': 'Internal Marks',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF10B981),
      },

      {
        'title': 'Course Plan',
        'icon': Icons.book_outlined,
        'color': const Color(0xFFD97706),
      },
      {
        'title': 'Class Materials',
        'icon': Icons.folder_outlined,
        'color': const Color(0xFF001FF4),
      },
      {
        'title': 'Analysis',
        'icon': Icons.assessment_outlined,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Student List',
        'icon': Icons.groups_outlined,
        'color': const Color(0xFF10B981),
      },

      {
        'title': 'Communication',
        'icon': Icons.chat_bubble_outline_rounded,
        'color': const Color(0xFFFBBF24),
      },
      {
        'title': 'Special Classes',
        'icon': Icons.star_border_rounded,
        'color': const Color(0xFFFB7185),
      },
      {
        'title': 'Tutorial/Project',
        'icon': Icons.lightbulb_outline_rounded,
        'color': const Color(0xFF06B6D4),
      },
      {
        'title': 'Year Calendar',
        'icon': Icons.calendar_month_outlined,
        'color': const Color(0xFFEC4899),
      },

      {
        'title': 'Surveys',
        'icon': Icons.poll_outlined,
        'color': const Color(0xFF84CC16),
      },
      {
        'title': 'University Mark',
        'icon': Icons.school_outlined,
        'color': const Color(0xFF7C3AED),
      },
      {
        'title': 'Remedial',
        'icon': Icons.healing_outlined,
        'color': const Color(0xFFF43F5E),
      },
      {
        'title': 'Hour Request',
        'icon': Icons.history_outlined,
        'color': const Color(0xFF001FF4),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        mainAxisExtent: 130,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(context, services[index]);
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    return InkWell(
      onTap: () {
        if (service['title'] == 'Attendance') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffAttendanceScreen(userId: userId),
            ),
          );
          return;
        }

        if (service['title'] == 'Course Plan') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoursePlanScreen(userId: userId),
            ),
          );
          return;
        }

        if (service['title'] == 'Evaluations') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EvaluationScreen(userId: userId),
            ),
          );
          return;
        }

        if (service['title'] == 'Internal Marks') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => InternalMarksScreen(userId: userId),
            ),
          );
          return;
        }

        if (service['title'] == 'Surveys') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StaffSurveyScreen(userId: userId),
            ),
          );
          return;
        }

        if (service['title'] == 'Hour Request') {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HodHourRequestsScreen(userId: userId),
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Navigating to ${service['title']}..."),
            duration: const Duration(milliseconds: 500),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (service['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(service['icon'], color: service['color'], size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              service['title'],
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTableHeader("ROLL NO"),
                _buildTableHeader("UNI REGNO"),
                _buildTableHeader("NAME"),
                _buildTableHeader("ADD/VIEW REMARKS"),
                _buildTableHeader("ACADEMICS"),
                _buildTableHeader("PHOTO"),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            height: 100,
            alignment: Alignment.center,
            child: Text(
              "Displaying 1-28",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Expanded(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }
}
