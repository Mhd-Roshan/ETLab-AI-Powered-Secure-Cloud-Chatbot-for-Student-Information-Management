import 'package:flutter/material.dart';
import '../screens/module_screen.dart';
// Make sure that module_screen.dart defines a ModuleScreen widget.

class AdministrationGrid extends StatelessWidget {
  const AdministrationGrid({super.key});

  final List<Map<String, dynamic>> items = const [
    {"icon": Icons.library_add, "label": "Course Creation", "color": Colors.blue},
    {"icon": Icons.group_add, "label": "Batch Creation", "color": Colors.blue},
    {"icon": Icons.school, "label": "Student Mgmt", "color": Colors.green},
    {"icon": Icons.badge, "label": "Staff Mgmt", "color": Colors.purple},
    {"icon": Icons.assignment_ind, "label": "Assign Teachers", "color": Colors.purple},
    {"icon": Icons.architecture, "label": "Stationary Mgmt", "color": Colors.orange},
    {"icon": Icons.inventory_2, "label": "Asset Mgmt", "color": Colors.orange},
    {"icon": Icons.groups, "label": "HR Mgmt", "color": Colors.pink},
    {"icon": Icons.query_stats, "label": "Login Stats", "color": Colors.grey},
    {"icon": Icons.apartment, "label": "Hostel Mgmt", "color": Colors.teal},
    {"icon": Icons.directions_bus, "label": "Transport Mgmt", "color": Colors.amber},
    {"icon": Icons.topic, "label": "Topic Mgmt", "color": Colors.indigo},
    {"icon": Icons.calendar_month, "label": "Time Table Gen", "color": Colors.cyan},
    {"icon": Icons.publish, "label": "Time Table Issue", "color": Colors.cyan},
    {"icon": Icons.calculate, "label": "FA Calculator", "color": Colors.red},
    {"icon": Icons.summarize, "label": "Report Gen", "color": Colors.pinkAccent},
    {"icon": Icons.sms, "label": "SMS Alerts", "color": Colors.lime},
    {"icon": Icons.event_note, "label": "Exam Schedules", "color": Colors.deepPurple},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("ADMINISTRATION", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            int crossAxisCount = constraints.maxWidth > 1200 ? 6 : (constraints.maxWidth > 600 ? 4 : 2);
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildGridItem(context, item);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildGridItem(BuildContext context, Map<String, dynamic> item) {
    final color = item['color'] as Color;
    return InkWell(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ModuleScreen(title: item['label'], color: color)));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(item['icon'], color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(item['label'], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}