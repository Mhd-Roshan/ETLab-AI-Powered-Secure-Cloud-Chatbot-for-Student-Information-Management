import 'package:flutter/material.dart';

class RightPanel extends StatelessWidget {
  const RightPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSection(context, 
          title: "Profile Abstract", 
          child: const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text("Admin User"),
            subtitle: Text("Super Administrator"),
          )
        ),
        const SizedBox(height: 24),
        _buildSection(context,
          title: "Calendar",
          child: CalendarDatePicker(
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            onDateChanged: (date) {},
          ),
        ),
        const SizedBox(height: 24),
        _buildSection(context,
          title: "Notice Board",
          child: Column(
            children: [
              _noticeItem("15 Sep", "Class Timing Update"),
              const Divider(),
              _noticeItem("12 Sep", "Exam Schedule"),
            ],
          )
        ),
      ],
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _noticeItem(String date, String title) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(date, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
    );
  }
}