import 'package:flutter/material.dart';
import '../screens/module_screen.dart';
import '../screens/departments_screen.dart'; // Ensure class 'DepartmentsScreen' is inside this file
import '../screens/students_screen.dart';
import '../screens/staff_screen.dart';

class AdministrationGrid extends StatelessWidget {
  const AdministrationGrid({super.key});

  final List<Map<String, dynamic>> items = const [
    {"icon": Icons.account_tree_rounded, "label": "Department", "color": Colors.orange},
    {"icon": Icons.school_rounded, "label": "Students", "color": Colors.green},
    {"icon": Icons.badge_rounded, "label": "Staff", "color": Colors.purple},
    {"icon": Icons.co_present_rounded, "label": "Attendance", "color": Colors.redAccent},
    {"icon": Icons.bedroom_parent_rounded, "label": "Hostel", "color": Colors.teal},
    {"icon": Icons.rocket_launch_rounded, "label": "Placement", "color": Colors.indigo},
    {"icon": Icons.psychology_alt_rounded, "label": "Attain", "color": Colors.amber},
    {"icon": Icons.app_registration_rounded, "label": "Sem. Register", "color": Colors.deepPurple},
    {"icon": Icons.auto_stories_rounded, "label": "Subject Pool", "color": Colors.cyan},
    {"icon": Icons.person_off_rounded, "label": "Suspended", "color": Colors.brown},
    {"icon": Icons.history_edu_rounded, "label": "Univ. Exam", "color": Colors.deepOrange},
    {"icon": Icons.payments_rounded, "label": "Fees", "color": Colors.pink},
    {"icon": Icons.local_library_rounded, "label": "Library", "color": Colors.tealAccent},
    {"icon": Icons.calendar_month_rounded, "label": "Timetable", "color": Colors.lightBlue},
    {"icon": Icons.directions_bus_rounded, "label": "Transport", "color": Colors.yellow},
    {"icon": Icons.notifications_active_rounded, "label": "Alerts", "color": Colors.lime},
    {"icon": Icons.summarize_rounded, "label": "Reports", "color": Colors.indigoAccent},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 15),
          child: Text(
            "BASIC",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              letterSpacing: 5.0,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 8 : (constraints.maxWidth > 800 ? 6 : 4);
            if (constraints.maxWidth < 400) crossAxisCount = 3;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 26,
                mainAxisSpacing: 4,
                childAspectRatio: 1.0,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildSimpleCircleItem(context, item);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSimpleCircleItem(BuildContext context, Map<String, dynamic> item) {
    final Color color = item['color'];

    // Logic for darker icon colors on light backgrounds
    Color displayColor = color;
    if (color == Colors.yellow) displayColor = Colors.orangeAccent;
    if (color == Colors.tealAccent) displayColor = Colors.teal;
    if (color == Colors.lime) displayColor = Colors.lime.shade700;

    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            // Routing Logic
            final String label = item['label'];
            
            // 1. Check for "Department" label (Updated from Batches)
            if (label == "Department") {
              Navigator.push(
                context, 
                // Updated to use DepartmentsScreen
                MaterialPageRoute(builder: (context) => DepartmentsScreen(color: displayColor))
              );
            } 
            // 2. Check for "Students"
            else if (label == "Students") {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => StudentsScreen(color: displayColor))
              );
            } 
            // 3. Check for "Staff"
            else if (label == "Staff") {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => StaffScreen(color: displayColor))
              );
            } 
            // 4. Default for others
            else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ModuleScreen(title: label, color: displayColor)
                )
              );
            }
          },
          borderRadius: BorderRadius.circular(64),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: displayColor.withOpacity(0.1),
              border: Border.all(
                color: displayColor.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                item['icon'],
                color: displayColor,
                size: 34,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          item['label'],
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 11,
            color: Colors.grey.shade700,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}