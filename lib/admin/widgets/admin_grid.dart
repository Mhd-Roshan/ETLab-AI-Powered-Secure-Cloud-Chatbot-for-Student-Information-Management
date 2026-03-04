import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../screens/departments_screen.dart';
import '../screens/students_screen.dart';
import '../screens/staff_screen.dart';
import '../screens/attendance_screen.dart';
import '../screens/hostel_screen.dart';
import '../screens/placement_screen.dart';
import '../screens/subject_pool_screen.dart';
import '../screens/suspended_users_screen.dart';
import '../screens/university_exam_screen.dart';
import '../screens/generic_page.dart';
import '../screens/semester_registration_screen.dart';
import '../screens/fees/fees_dashboard.dart';
import '../screens/surveys_screen.dart';
import '../screens/alerts_screen.dart';
import '../screens/sms_screen.dart';
import '../screens/library_screen.dart';
import '../screens/transport_screen.dart';

class AdminWorkspaceGrid extends StatelessWidget {
  const AdminWorkspaceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.apartment_outlined,
        'label': 'Department',
        'color': Colors.orange,
        'route': const DepartmentsScreen(),
      },
      {
        'icon': Icons.school_outlined,
        'label': 'Students',
        'color': Colors.green,
        'route': const StudentsScreen(),
      },
      {
        'icon': Icons.badge_outlined,
        'label': 'Staff',
        'color': Colors.purpleAccent,
        'route': const StaffScreen(),
      },
      {
        'icon': Icons.assignment_ind_outlined,
        'label': 'Attendance',
        'color': Colors.redAccent,
        'route': const AttendanceScreen(),
      },
      {
        'icon': Icons.king_bed_outlined,
        'label': 'Hostel',
        'color': Colors.teal,
        'route': const HostelScreen(color: Colors.teal),
      },
      {
        'icon': Icons.rocket_launch_outlined,
        'label': 'Placement',
        'color': Colors.pinkAccent,
        'route': const PlacementScreen(),
      },
      {
        'icon': Icons.emoji_events_outlined,
        'label': 'Attain',
        'color': Colors.amber,
        'route': const GenericPage(title: 'Attainment'),
      },
      {
        'icon': Icons.app_registration_outlined,
        'label': 'Sem. Register',
        'color': Colors.deepPurpleAccent,
        'route': const SemesterRegistrationScreen(),
      },
      {
        'icon': Icons.library_books_outlined,
        'label': 'Subjects',
        'color': Colors.cyan,
        'route': const SubjectPoolScreen(),
      },
      {
        'icon': Icons.block_outlined,
        'label': 'Suspended',
        'color': Colors.grey,
        'route': const SuspendedUsersScreen(),
      },
      {
        'icon': Icons.history_edu_outlined,
        'label': 'Univ. Exam',
        'color': Colors.deepOrange,
        'route': const UniversityExamScreen(),
      },
      {
        'icon': Icons.payments_outlined,
        'label': 'Fees',
        'color': Colors.pink,
        'route': const FeesDashboard(),
      },
      {
        'icon': Icons.local_library_outlined,
        'label': 'Library',
        'color': Colors.tealAccent,
        'route': const LibraryScreen(),
      },
      {
        'icon': Icons.sms_outlined,
        'label': 'SMS',
        'color': Colors.blueAccent,
        'route': const SmsScreen(),
      },
      {
        'icon': Icons.bus_alert_outlined,
        'label': 'Transport',
        'color': Colors.lightBlue,
        'route': const TransportScreen(),
      },
      {
        'icon': Icons.notifications_active_outlined,
        'label': 'Alerts',
        'color': Colors.lightGreen,
        'route': const AlertsScreen(),
      },
      {
        'icon': Icons.description_outlined,
        'label': 'Surveys',
        'color': Colors.indigoAccent,
        'route': const SurveyScreen(),
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
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
