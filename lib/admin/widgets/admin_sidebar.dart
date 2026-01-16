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
    // 2026 Palette
    final bgColor = isDarkMode ? const Color(0xFF0F172A) : Colors.white;
    final borderColor = isDarkMode ? Colors.white.withOpacity(0.08) : Colors.grey.shade200;
    
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 1. BRAND HEADER ---
          _buildBrandHeader(),

          const SizedBox(height: 30),

          // --- 2. NAVIGATION LINKS ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildSectionLabel("OVERVIEW"),
                _buildNavItem(0, Icons.grid_view_rounded, "Dashboard"),
                
                const SizedBox(height: 24),
                
                _buildSectionLabel("ACADEMICS"),
                _buildNavItem(1, Icons.supervisor_account_outlined, "Batches"),
                _buildNavItem(2, Icons.class_outlined, "Classes"),
                _buildNavItem(4, Icons.calendar_today_rounded, "Timetable"),
                
                const SizedBox(height: 24),

                _buildSectionLabel("INTELLIGENCE"),
                _buildNavItem(3, Icons.smart_toy_outlined, "Chatbots"),
                
                const SizedBox(height: 24),
                
                _buildSectionLabel("NOTIFICATIONS"),
                _buildNavItem(5, Icons.swap_horiz_rounded, "Notifications"),
              ],
            ),
          ),

          // --- 3. MODERN LOGOUT BUTTON ---
          Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onLogout,
                borderRadius: BorderRadius.circular(12),
                hoverColor: Colors.red.withOpacity(0.05),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: isDarkMode 
                        ? Colors.red.withOpacity(0.1) 
                        : Colors.red.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, color: Colors.red.shade400, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        "Sign Out",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- BRAND HEADER ---
  Widget _buildBrandHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              "assets/edlab.png",
              height: 56, // Increased size
              width: 56,  // Increased size
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  // --- SECTION LABELS ---
  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
        ),
      ),
    );
  }

  // --- NAVIGATION ITEM ---
  Widget _buildNavItem(int index, IconData icon, String label, {bool isSpecial = false}) {
    final isSelected = selectedIndex == index;
    
    // Modern Colors
    final activeBg = isDarkMode ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF); 
    final activeIcon = const Color(0xFF3B82F6); 
    final inactiveIcon = isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500;
    final activeText = isDarkMode ? Colors.white : const Color(0xFF1E293B);
    final inactiveText = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;

    final specialGradient = LinearGradient(
      colors: [const Color(0xFF6366F1).withOpacity(0.15), const Color(0xFFA855F7).withOpacity(0.15)],
    );
    final specialIconColor = const Color(0xFF8B5CF6);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onItemSelected(index),
          borderRadius: BorderRadius.circular(12),
          hoverColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (isSpecial ? Colors.transparent : activeBg) 
                  : Colors.transparent,
              gradient: (isSelected && isSpecial) ? specialGradient : null,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected && !isSpecial 
                    ? activeIcon.withOpacity(0.1) 
                    : Colors.transparent
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected 
                      ? (isSpecial ? specialIconColor : activeIcon) 
                      : inactiveIcon,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      color: isSelected ? activeText : inactiveText,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSpecial ? specialIconColor : activeIcon,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isSpecial ? specialIconColor : activeIcon).withOpacity(0.4),
                          blurRadius: 6,
                        )
                      ]
                    ),
                  ),
                if (isSpecial && !isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "NEW",
                      style: GoogleFonts.inter(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  )
              ],
            ),
          ),
        ),
      ),
    );
  }
}