import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback toggleTheme;
  final Function(String) onSearch; // Callback for search input
  final bool isDarkMode;
  final bool showMenu;

  const DashboardHeader({
    super.key,
    required this.toggleTheme,
    required this.onSearch,
    required this.isDarkMode,
    required this.showMenu,
  });

  @override
  Widget build(BuildContext context) {
    // Modern 2026 Color Palette
    final bgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
    final iconColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // --- 1. LEFT: MENU TOGGLE (Mobile/Tablet) ---
          if (showMenu)
            Padding(
              padding: const EdgeInsets.only(right: 20),
              child: IconButton(
                icon: Icon(Icons.menu_rounded, color: iconColor),
                onPressed: () => Scaffold.of(context).openDrawer(),
                tooltip: "Toggle Menu",
              ),
            ),

          // --- 2. CENTER: FUNCTIONAL SEARCH BAR ---
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildSearchBar(context),
            ),
          ),

          // --- 3. RIGHT: ACTIONS ---
          Row(
            children: [
              // Theme Toggle
              _buildActionButton(
                context,
                icon: isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                onTap: toggleTheme,
                tooltip: "Switch Theme",
              ),
              const SizedBox(width: 12),

              // Notifications with Red Dot
              Stack(
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.notifications_outlined,
                    onTap: () {},
                    tooltip: "Notifications",
                  ),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: bgColor, width: 1.5),
                      ),
                    ),
                  )
                ],
              ),
              
              const SizedBox(width: 24),
              
              // Vertical Divider
              Container(
                height: 24,
                width: 1,
                color: borderColor,
              ),
              
              const SizedBox(width: 24),

              // Profile Section
              _buildProfilePill(context),
            ],
          )
        ],
      ),
    );
  }

  // --- WIDGET: SEARCH BAR ---
  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    
    return Container(
      width: 400, // Fixed max width for desktop
      height: 44,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12), // Squircle shape
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 14),
          Icon(Icons.search_rounded, size: 20, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          
          // ACTUAL INPUT FIELD
          Expanded(
            child: TextField(
              onChanged: onSearch, // Calls the parent function on typing
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              cursorColor: Colors.blueAccent,
              decoration: InputDecoration(
                hintText: "Search students, staff, or courses...",
                hintStyle: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 2),
              ),
            ),
          ),
          
          // Visual Keyboard Shortcut Hint
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.grey.shade300,
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  )
                ],
              ),
              child: Text(
                "⌘ K",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET: ICON BUTTON ---
  Widget _buildActionButton(BuildContext context, {required IconData icon, required VoidCallback onTap, required String tooltip}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade200,
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  // --- WIDGET: PROFILE PILL ---
  Widget _buildProfilePill(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(30),
      hoverColor: Colors.transparent,
      child: Row(
        children: [
          // Avatar with Online Status
          Stack(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.withOpacity(0.2), width: 2),
                  image: const DecorationImage(
                    image: NetworkImage("https://i.pravatar.cc/150?img=11"), // Placeholder Image
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 1.5),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 12),
          
          // User Details
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Admin",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  fontSize: 13,
                ),
              ),
              Text(
                "Online",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}