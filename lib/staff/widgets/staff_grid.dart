import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/staff/screens/staff_assignments_screen.dart';
import 'package:edlab/staff/screens/generic_page.dart';
import 'package:edlab/staff/screens/staff_attendance_screen.dart';
import 'package:edlab/staff/screens/staff_survey_screen.dart';
import 'package:edlab/staff/screens/staff_cert_scholarship_screen.dart';
import 'package:edlab/staff/screens/university_circulars_screen.dart';
import 'package:edlab/staff/screens/staff_timetable_screen.dart';
import 'package:edlab/staff/screens/staff_complaints_screen.dart';

class StaffWorkspaceGrid extends StatelessWidget {
  final String staffId;
  const StaffWorkspaceGrid({super.key, this.staffId = 'staff_member'});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Timetable',
        'color': const Color(0xFF001FF4),
        'route': StaffTimetableScreen(userId: staffId),
      },
      {
        'icon': Icons.task_outlined,
        'label': 'Assignments',
        'color': const Color(0xFFA855F7),
        'route': StaffAssignmentsScreen(staffId: staffId),
      },
      {
        'icon': Icons.fact_check_outlined,
        'label': 'Attendance',
        'color': const Color(0xFF10B981),
        'route': StaffAttendanceScreen(userId: staffId),
      },
      {
        'icon': Icons.card_membership_outlined,
        'label': 'Cert/Scholarship',
        'color': const Color(0xFFF59E0B),
        'route': StaffCertScholarshipScreen(userId: staffId),
      },
      {
        'icon': Icons.campaign_outlined,
        'label': 'KTU Circular',
        'color': const Color(0xFF14B8A6),
        'route': UniversityCircularsScreen(userId: staffId),
      },
      {
        'icon': Icons.poll_outlined,
        'label': 'Faculty Survey',
        'color': const Color(0xFF84CC16),
        'route': StaffSurveyScreen(userId: staffId),
      },
      {
        'icon': Icons.chat_bubble_outline_rounded,
        'label': 'Grievance',
        'color': const Color(0xFF64748B),
        'route': StaffComplaintsScreen(userId: staffId),
      },
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: items
          .map((item) => _buildModernGridItem(context, item))
          .toList(),
    );
  }

  Widget _buildModernGridItem(BuildContext context, Map<String, dynamic> item) {
    return InkWell(
      onTap: () {
        if (item['route'] != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => item['route']),
          );
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 175,
        height: 150,
        decoration: const BoxDecoration(color: Colors.transparent),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: (item['color'] as Color).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item['icon'], color: item['color'], size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              item['label'],
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
