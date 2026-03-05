import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/hod/hod_dashboard.dart';
import 'package:edlab/hod/screens/hod_profile_screen.dart';
import 'package:edlab/hod/screens/ai_chat_screen.dart';
import 'package:edlab/hod/screens/hod_timetable_screen.dart';
import 'package:edlab/hod/screens/hod_surveys_screen.dart';
import 'package:edlab/hod/screens/teaching/hod_hour_requests_screen.dart';
import 'package:edlab/hod/screens/hod_classes_screen.dart';
import 'package:edlab/services/staff_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HodSidebar extends StatefulWidget {
  final int activeIndex;
  final String userId;

  static bool isExpanded = false;

  const HodSidebar({
    super.key,
    this.activeIndex = -1,
    this.userId = 'hod@gmail.com',
  });

  @override
  State<HodSidebar> createState() => _HodSidebarState();
}

class _HodSidebarState extends State<HodSidebar> {
  void _toggleSidebar() {
    setState(() {
      HodSidebar.isExpanded = !HodSidebar.isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isExpanded = HodSidebar.isExpanded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
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
                IconButton(
                  onPressed: _toggleSidebar,
                  icon: Icon(
                    isExpanded ? Icons.menu_open_rounded : Icons.menu_rounded,
                    color: const Color(0xFF001FF4),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- MENU ITEMS ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isExpanded ? 16 : 8),
              children: [
                _buildModernNavItem(
                  index: 0,
                  icon: Icons.grid_view_outlined,
                  label: "Dashboard",
                  page: HodDashboard(),
                ),
                _buildModernNavItem(
                  index: 1,
                  icon: Icons.auto_awesome_rounded,
                  label: "EdLab AI",
                  page: AiChatScreen(userId: widget.userId),
                ),
                _buildModernNavItem(
                  index: 2,
                  icon: Icons.school_outlined,
                  label: "My Classes",
                  page: HodClassesScreen(userId: widget.userId),
                ),
                _buildModernNavItem(
                  index: 3,
                  icon: Icons.calendar_today_rounded,
                  label: "My Timetable",
                  page: HodTimetableScreen(userId: widget.userId),
                ),

                _buildModernNavItem(
                  index: 4,
                  icon: Icons.assignment_outlined,
                  label: "Surveys",
                  page: HodSurveysScreen(userId: widget.userId),
                ),

                _buildModernNavItem(
                  index: 5,
                  icon: Icons.access_time_outlined,
                  label: "Hour Request",
                  page: HodHourRequestsScreen(userId: widget.userId),
                ),
              ],
            ),
          ),

          // --- STAFF/HOD PROFILE ---
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: StreamBuilder<DocumentSnapshot>(
              stream: StaffService().getProfile(
                widget.userId,
              ), // Reusing StaffService for now
              builder: (context, snapshot) {
                String displayName = widget.userId.split('@')[0];
                String avatarName = widget.userId;

                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final fullName =
                      data['fullName'] ?? data['username'] ?? "HOD User";
                  avatarName = fullName;
                  displayName = fullName.split(' ')[0];
                }

                return InkWell(
                  onTap: () {
                    HodSidebar.isExpanded = false;
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, _, __) =>
                            HodProfileScreen(userId: widget.userId),
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
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFF1F5F9),
                          backgroundImage: NetworkImage(
                            'https://ui-avatars.com/api/?name=$avatarName&background=random',
                          ),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
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
                      Text(
                        "Logout",
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
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
  }) {
    bool isActive = widget.activeIndex == index;
    bool isExpanded = HodSidebar.isExpanded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          if (!isActive) {
            HodSidebar.isExpanded = false;
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
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                    color: isActive ? Colors.white : const Color(0xFF64748B),
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
