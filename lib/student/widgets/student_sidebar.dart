import 'package:flutter/material.dart';

class StudentSidebar extends StatelessWidget {
  final String name, email, profileUrl;
  const StudentSidebar({super.key, required this.name, required this.email, required this.profileUrl});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF5C51E1)),
            currentAccountPicture: CircleAvatar(backgroundImage: NetworkImage(profileUrl)),
            accountName: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            accountEmail: Text(email),
          ),
          _drawerItem(Icons.dashboard_outlined, "Dashboard", () => Navigator.pop(context)),
          _drawerItem(Icons.calendar_month_outlined, "Attendance", () {}),
          _drawerItem(Icons.receipt_long_outlined, "Fee Details", () {}),
          _drawerItem(Icons.book_outlined, "Academics", () {}),
          _drawerItem(Icons.chat_bubble_outline, "AI Assistant", () {}),
          const Spacer(),
          const Divider(),
          _drawerItem(Icons.logout, "Logout", () => Navigator.pushReplacementNamed(context, '/login')),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF5C51E1)),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }
}