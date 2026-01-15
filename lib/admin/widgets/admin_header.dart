import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardHeader extends StatelessWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;
  final bool showMenu;

  const DashboardHeader({
    super.key,
    required this.toggleTheme,
    required this.isDarkMode,
    required this.showMenu,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final bgColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;

    return Container(
      height: 80, // Taller header for modern look
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Menu & Date
          Row(
            children: [
              if (showMenu) 
                IconButton(
                  icon: Icon(Icons.menu_rounded, color: textColor),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              if (showMenu) const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome back,",
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    "Admin Console",
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Right: Actions
          Row(
            children: [
              // Theme Toggle
              _buildIconButton(
                icon: isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                onTap: toggleTheme,
                isDarkMode: isDarkMode,
              ),
              const SizedBox(width: 16),
              
              // Notification
              Stack(
                children: [
                  _buildIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                    isDarkMode: isDarkMode,
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 24),

              // Profile
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white10 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: isDarkMode ? Colors.transparent : Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFF007AFF),
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "Super Admin",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey, size: 18),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, required bool isDarkMode}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDarkMode ? Colors.white10 : Colors.transparent,
        ),
        child: Icon(icon, color: Colors.grey, size: 24),
      ),
    );
  }
} 