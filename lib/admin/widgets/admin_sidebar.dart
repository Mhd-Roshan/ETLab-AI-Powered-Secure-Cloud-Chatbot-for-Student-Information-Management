import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/admin_dashboard.dart';
import 'package:edlab/admin/screens/students_screen.dart';
import 'package:edlab/admin/screens/courses_screen.dart';
import 'package:edlab/admin/screens/ai_chat_screen.dart';
import 'package:edlab/admin/screens/admin_profile_screen.dart';
import 'package:edlab/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminSidebar extends StatefulWidget {
  final int activeIndex;
  final String? userId; // Optional override
  final bool isShrinkOnly; // New: force shrunken state for inside pages

  static bool isExpanded = false; // Persists across navigations

  const AdminSidebar({
    super.key,
    this.activeIndex = -1,
    this.userId,
    this.isShrinkOnly = false,
  });

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    if (widget.userId != null) {
      setState(() => _userId = widget.userId);
    } else {
      final prefs = await SharedPreferences.getInstance();
      setState(() => _userId = prefs.getString('username'));
    }
  }

  void _toggleSidebar() {
    setState(() {
      AdminSidebar.isExpanded = !AdminSidebar.isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Force shrunken state if requested for inside pages
    final bool isExpanded = widget.isShrinkOnly
        ? false
        : AdminSidebar.isExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      width: isExpanded ? 260 : 80,
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
        crossAxisAlignment: isExpanded
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),

          // --- HEADER: LOGO & TOGGLE ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isExpanded ? 24 : 0),
            child: Row(
              mainAxisAlignment: isExpanded
                  ? MainAxisAlignment.spaceBetween
                  : MainAxisAlignment.center,
              children: [
                if (isExpanded)
                  Image.asset(
                    "assets/edlab.png",
                    height: 32,
                    errorBuilder: (context, error, stackTrace) => Text(
                      "EdLab",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF001FF4),
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
                  ),
                if (!widget.isShrinkOnly)
                  IconButton(
                    onPressed: _toggleSidebar,
                    icon: Icon(
                      isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                      color: const Color(0xFF001FF4),
                    ),
                  )
                else
                  const SizedBox(height: 48), // Spacer to maintain alignment
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- MENU ITEMS ---
          Expanded(
            child: Scrollbar(
              thumbVisibility: true,
              thickness: 4,
              radius: const Radius.circular(10),
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: isExpanded ? 16 : 4,
                ), // Reduced from 8 to 4
                children: [
                  _buildModernNavItem(
                    index: 0,
                    icon: Icons.grid_view_outlined,
                    label: "Dashboard",
                    page: const AdminDashboard(),
                    isSidebarExpanded: isExpanded,
                  ),
                  _buildModernNavItem(
                    index: 1,
                    icon: Icons.people_outline_rounded,
                    label: "Students",
                    page: const StudentsScreen(),
                    isSidebarExpanded: isExpanded,
                  ),
                  _buildModernNavItem(
                    index: 2,
                    icon: Icons.menu_book_outlined,
                    label: "Courses",
                    page: const CoursesScreen(),
                    isSidebarExpanded: isExpanded,
                  ),
                  _buildModernNavItem(
                    index: 3,
                    icon: Icons.auto_awesome_rounded,
                    label: "EdLab AI",
                    page: const AiChatScreen(),
                    isSidebarExpanded: isExpanded,
                  ),
                ],
              ),
            ),
          ),

          // --- ADMIN PROFILE HUB ---
          if (_userId != null) ...[
            const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: Color(0xFFF1F5F9),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: StreamBuilder<DocumentSnapshot>(
                stream: AdminService().getProfile(_userId!),
                builder: (context, snapshot) {
                  String displayName = _userId!.split('@')[0];
                  String avatarName = _userId!;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data() as Map<String, dynamic>;
                    final fullName =
                        data['fullName'] ?? data['username'] ?? "Admin User";
                    avatarName = fullName;
                    displayName = fullName.split(' ')[0];
                  }

                  return InkWell(
                    onTap: () {
                      AdminSidebar.isExpanded = false;
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, _, __) =>
                              AdminProfileScreen(userId: _userId!),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isExpanded ? 24 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: isExpanded
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF001FF4).withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFFF1F5F9),
                              backgroundImage: NetworkImage(
                                'https://ui-avatars.com/api/?name=$avatarName&background=random',
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    "Administrator",
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // --- LOGOUT ---
          Padding(
            padding: EdgeInsets.only(
              bottom: 32,
              left: isExpanded ? 16 : 0,
              right: isExpanded ? 16 : 0,
            ),
            child: InkWell(
              onTap: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                    (route) => false,
                  );
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: isExpanded
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.logout_rounded,
                      color: Colors.redAccent,
                      size: 24,
                    ),
                    if (isExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Logout",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Widget page,
    required bool isSidebarExpanded,
  }) {
    bool isActive = widget.activeIndex == index;
    bool isExpanded = isSidebarExpanded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          if (!isActive) {
            AdminSidebar.isExpanded = false;
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (context, _, __) => page,
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
                  color: const Color(0xFF001FF4),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF001FF4).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                )
              : const BoxDecoration(color: Colors.transparent),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Added for safety
            mainAxisAlignment: isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 28,
                color: isActive ? Colors.white : const Color(0xFF94A3B8),
              ),
              if (isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                      color: isActive ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
