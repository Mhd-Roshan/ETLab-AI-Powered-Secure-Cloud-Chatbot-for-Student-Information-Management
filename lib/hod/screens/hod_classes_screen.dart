import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/hod_sidebar.dart';
import '../widgets/hod_header.dart';
import 'teaching/hod_internal_marks_screen.dart';
import 'teaching/hod_attendance_screen.dart';
import 'teaching/hod_evaluation_screen.dart';
import 'teaching/hod_course_plan_screen.dart';

class HodClassesScreen extends StatefulWidget {
  final String userId;
  const HodClassesScreen({super.key, required this.userId});

  @override
  State<HodClassesScreen> createState() => _HodClassesScreenState();
}

class _HodClassesScreenState extends State<HodClassesScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSidebar(activeIndex: 2, userId: widget.userId),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HodHeader(
                    title: "My Classes ",
                    subtitle: "Access and manage all teaching-related services",
                    userId: widget.userId,
                  ),
                  const SizedBox(height: 48),

                  // --- SERVICE GRID (15 ITEMS) ---
                  _buildServiceGrid(context),

                  const SizedBox(height: 64),

                  // --- STUDENT LIST TABLE HEADER ---
                  _buildStudentTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceGrid(BuildContext context) {
    final List<Map<String, dynamic>> services = [
      {
        'title': 'Attendance',
        'icon': Icons.fact_check_outlined,
        'color': const Color(0xFF6366F1),
      },
      {
        'title': 'Evaluations',
        'icon': Icons.bar_chart_outlined,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Internal Marks',
        'icon': Icons.analytics_outlined,
        'color': const Color(0xFF0EA5E9),
      },
      {
        'title': 'Course Plan',
        'icon': Icons.menu_book_outlined,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Class Materials',
        'icon': Icons.folder_outlined,
        'color': const Color(0xFF6366F1),
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
        mainAxisSpacing: 32,
        crossAxisSpacing: 32,
        mainAxisExtent: 130,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        final color = s['color'] as Color;
        return InkWell(
          onTap: () {
            if (s['title'] == 'Internal Marks') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HodInternalMarksScreen(userId: widget.userId),
                ),
              );
            } else if (s['title'] == 'Attendance') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HodAttendanceScreen(userId: widget.userId),
                ),
              );
            } else if (s['title'] == 'Evaluations') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HodEvaluationScreen(userId: widget.userId),
                ),
              );
            } else if (s['title'] == 'Course Plan') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HodCoursePlanScreen(userId: widget.userId),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(s['icon'], color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                s['title'] as String,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStudentTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Row(
              children: [
                _tableHeader("ROLL NO"),
                _tableHeader("UNI REGNO"),
                _tableHeader("NAME"),
                _tableHeader("ADD/VIEW REMARKS"),
                _tableHeader("ACADEMICS"),
                _tableHeader("PHOTO"),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            height: 140,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "No detailed student list selected.",
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Displaying 1-28",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(String title) {
    return Expanded(
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF1E293B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
