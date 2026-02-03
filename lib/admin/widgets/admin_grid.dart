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

class AdminWorkspaceGrid extends StatelessWidget {
  const AdminWorkspaceGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.apartment,
        'label': 'Department',
        'color': Colors.orange,
        'route': const DepartmentsScreen(),
      },
      {
        'icon': Icons.school,
        'label': 'Students',
        'color': Colors.green,
        'route': const StudentsScreen(),
      },
      {
        'icon': Icons.badge,
        'label': 'Staff',
        'color': Colors.purpleAccent,
        'route': const StaffScreen(),
      },
      {
        'icon': Icons.assignment_ind,
        'label': 'Attendance',
        'color': Colors.redAccent,
        'route': const AttendanceScreen(),
      },
      {
        'icon': Icons.king_bed,
        'label': 'Hostel',
        'color': Colors.teal,
        'route': const HostelScreen(color: Colors.teal),
      },
      {
        'icon': Icons.rocket_launch,
        'label': 'Placement',
        'color': Colors.pinkAccent,
        'route': const PlacementScreen(),
      },
      {
        'icon': Icons.emoji_events,
        'label': 'Attain',
        'color': Colors.amber,
        'route': const GenericPage(title: 'Attainment'),
      },
      {
        'icon': Icons.app_registration,
        'label': 'Sem. Register',
        'color': Colors.deepPurpleAccent,
        'route': const SemesterRegistrationScreen(),
      },
      {
        'icon': Icons.library_books,
        'label': 'Subjects',
        'color': Colors.cyan,
        'route': const SubjectPoolScreen(),
      },
      {
        'icon': Icons.block,
        'label': 'Suspended',
        'color': Colors.grey,
        'route': const SuspendedUsersScreen(),
      },
      {
        'icon': Icons.history_edu,
        'label': 'Univ. Exam',
        'color': Colors.deepOrange,
        'route': const UniversityExamScreen(),
      },
      {
        'icon': Icons.payments,
        'label': 'Fees',
        'color': Colors.pink,
        'route': const FeesDashboard(),
      },
      {
        'icon': Icons.local_library,
        'label': 'Library',
        'color': Colors.tealAccent,
        'route': const GenericPage(title: 'Library'),
      },
      {
        'icon': Icons.sms_rounded,
        'label': 'SMS',
        'color': Colors.blueAccent,
        'route': const SmsScreen(),
      },
      {
        'icon': Icons.bus_alert,
        'label': 'Transport',
        'color': Colors.yellow,
        'route': const GenericPage(title: 'Transport'),
      },
      {
        'icon': Icons.notifications_active_rounded,
        'label': 'Alerts',
        'color': Colors.lightGreen,
        'route': const AlertsScreen(),
      },
      {
        'icon': Icons.description,
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
        width: 100,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'], color: item['color'], size: 36),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              item['label'],
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
