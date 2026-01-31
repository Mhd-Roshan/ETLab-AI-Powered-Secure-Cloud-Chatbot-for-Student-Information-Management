import 'package:flutter/material.dart';
import 'package:edlab/admin/admin_dashboard.dart';
import 'package:edlab/admin/screens/students_screen.dart';
import 'package:edlab/admin/screens/courses_screen.dart';
import 'package:edlab/admin/screens/ai_chat_screen.dart';
import 'package:edlab/admin/screens/settings_screen.dart';
import 'package:edlab/login.dart';

class AdminSidebar extends StatelessWidget {
  final int activeIndex;

  /// [activeIndex] mapping:
  /// 0: Dashboard
  /// 1: Students
  /// 2: Courses
  /// 3: AI Chats
  /// 4: Univ. Schedules
  /// 5: Settings (Profile)
  /// -1: None (for sub-pages)
  const AdminSidebar({super.key, this.activeIndex = -1});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),

          // --- 1. BRAND LOGO (Home) ---
          InkWell(
            onTap: () {
              if (activeIndex != 0) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, __, ___) => const AdminDashboard(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }
            },
            child: Image.asset(
              "assets/edlab.png",
              height: 40,
              width: 40,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.hub_rounded,
                color: Colors.indigoAccent,
                size: 28,
              ),
            ),
          ),

          const SizedBox(height: 50),

          // --- 2. MENU ITEMS ---
          _buildModernNavItem(
            context,
            index: 0,
            icon: Icons.dashboard_rounded,
            tooltip: "Dashboard",
            page: const AdminDashboard(),
          ),
          _buildModernNavItem(
            context,
            index: 1,
            icon: Icons.people_alt_rounded,
            tooltip: "Students",
            page: const StudentsScreen(),
          ),
          _buildModernNavItem(
            context,
            index: 2,
            icon: Icons.library_books_rounded,
            tooltip: "Courses",
            page: const CoursesScreen(),
          ),
          _buildModernNavItem(
            context,
            index: 3,
            icon: Icons.auto_awesome_rounded,
            tooltip: "AI Chats",
            page: const AiChatScreen(),
          ),

          const Spacer(),

          // --- 3. LOGOUT ---
          IconButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: "Logout",
          ),
          const SizedBox(height: 16),

          // --- 4. PROFILE (Linked to Settings - Index 5) ---
          Tooltip(
            message: "Settings & Profile",
            child: InkWell(
              onTap: () {
                if (activeIndex != 5) {
                  Navigator.pushReplacement(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (_, __, ___) => const SettingsScreen(),
                      transitionDuration: Duration.zero,
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(30),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: activeIndex == 5
                        ? Colors.blueAccent
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    const CircleAvatar(
                      radius: 20,
                      backgroundColor: Color(0xFFF1F5F9),
                      backgroundImage: NetworkImage(
                        'assets/kmct.png',
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.settings,
                        size: 10,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildModernNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required String tooltip,
    required Widget page,
  }) {
    bool isActive = activeIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: () {
            if (!isActive) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, __, ___) => page,
                  transitionDuration: Duration.zero,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: isActive
                ? BoxDecoration(
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueAccent.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  )
                : const BoxDecoration(color: Colors.transparent),
            child: Icon(
              icon,
              size: 24,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}
