import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final VoidCallback onLogout;
  final bool isDarkMode;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
    final dividerColor = isDarkMode ? Colors.white10 : Colors.grey.shade200;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Container(
      color: bgColor,
      child: Column(
        children: [
          // --- LOGO AREA ---
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: dividerColor)),
            ),
            child: Row(
              children: [
                // Replaced Text with Image
                Image.asset(
                  "assets/edlab.png",
                  height: 45,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => 
                    Icon(Icons.hub, size: 40, color: Colors.blueAccent),
                ),
                const SizedBox(width: 12),
                Text(
                  "EDLAB",
                  style: GoogleFonts.courierPrime(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),

          // --- NAVIGATION ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildNavItem(0, Icons.dashboard_rounded, "Dashboard"),
                _buildNavItem(1, Icons.supervisor_account_rounded, "Staff Advisor"),
                _buildNavItem(2, Icons.class_rounded, "My Classes"),
                _buildNavItem(3, Icons.calculate_rounded, "FA Calculator"),
                _buildNavItem(4, Icons.calendar_view_week_rounded, "My Timetable"),
                _buildNavItem(5, Icons.swap_horiz_rounded, "Substitutions"),
              ],
            ),
          ),

          // --- LOGOUT ---
          Padding(
            padding: const EdgeInsets.all(16),
            child: InkWell(
              onTap: onLogout,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: Colors.red, size: 24),
                    const SizedBox(width: 16),
                    Text(
                      "Logout",
                      style: GoogleFonts.inter(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = selectedIndex == index;
    final activeColor = const Color(0xFF007AFF); // iOS Blue
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected 
                  ? activeColor.withOpacity(0.1) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Bigger Icons (Size 26)
                Icon(
                  icon, 
                  color: isSelected ? activeColor : (isDarkMode ? Colors.grey[400] : Colors.grey[600]), 
                  size: 26 
                ),
                const SizedBox(width: 16),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: isSelected ? activeColor : (isDarkMode ? Colors.white : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}