import 'package:flutter/material.dart';

import '../../services/student_service.dart';

class StudentSidebar extends StatelessWidget {
  final String name, email, profileUrl, regNo;
  const StudentSidebar({
    super.key,
    required this.name,
    required this.email,
    required this.profileUrl,
    required this.regNo,
  });

  @override
  Widget build(BuildContext context) {
    final StudentService studentService = StudentService();
    // ...
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFF5C51E1)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: ClipOval(
                child: Image.network(
                  profileUrl,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    List<String> nameParts = name
                        .trim()
                        .split(' ')
                        .where((part) => part.isNotEmpty)
                        .toList();
                    String initials = nameParts.length >= 2
                        ? '${nameParts[0][0]}${nameParts[1][0]}'
                        : (nameParts.isNotEmpty ? nameParts[0][0] : 'S');
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          initials.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            accountName: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            accountEmail: Text(email),
          ),
          _drawerItem(
            Icons.dashboard_outlined,
            "Dashboard",
            () => Navigator.pop(context),
          ),
          _drawerItem(Icons.calendar_month_outlined, "Attendance", () {}),
          _drawerItem(Icons.receipt_long_outlined, "Fee Details", () {}),
          _drawerItem(Icons.book_outlined, "Academics", () {}),
          _drawerItem(Icons.cloud_sync, "Seed All Data", () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Seeding database...")),
            );
            await studentService.seedDevData(regNo);
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Database seeded! Restart screen to see changes.",
                  ),
                ),
              );
            }
          }),
          const Spacer(),
          const Divider(),
          _drawerItem(
            Icons.logout,
            "Logout",
            () => Navigator.pushReplacementNamed(context, '/login'),
          ),
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
