import 'package:flutter/material.dart';

class StudentSidebar extends StatelessWidget {
  final String name, email, profileUrl;
  const StudentSidebar({super.key, required this.name, required this.email, required this.profileUrl});

  @override
  Widget build(BuildContext context) {
    // Extract initials for fallback - with safety checks
    List<String> nameParts = name.trim().split(' ').where((part) => part.isNotEmpty).toList();
    String initials = 'S'; // Default
    
    if (nameParts.isNotEmpty) {
      if (nameParts.length >= 2 && nameParts[0].isNotEmpty && nameParts[1].isNotEmpty) {
        initials = '${nameParts[0][0]}${nameParts[1][0]}';
      } else if (nameParts[0].isNotEmpty) {
        initials = nameParts[0][0];
      }
    }

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
                    return Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
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
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    );
                  },
                ),
              ),
            ),
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