import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- IMPORTS ---
import '../widgets/admin_grid.dart'; // Ensure this file exists
import '../widgets/admin_calendar.dart'; // Ensure this file exists
import '../services/firebase_seeder.dart';

class DashboardHome extends StatefulWidget {
  const DashboardHome({super.key});

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Kept timer to ensure date updates if the app is open past midnight
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 2026 Trend: Airy layouts with significant whitespace
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top HUD: Breadcrumb + Date
          _buildHeaderHUD(context),

          const SizedBox(height: 40),

          LayoutBuilder(
            builder: (context, constraints) {
              // Responsive Logic
              if (constraints.maxWidth > 1100) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          AiToolsSection(),
                          SizedBox(height: 40),
                          AdminWorkspaceGrid(),
                        ],
                      ),
                    ),
                    SizedBox(width: 40),
                    // Right Panel: The Smart Calendar
                    Expanded(flex: 1, child: AdminRightPanel()),
                  ],
                );
              } else {
                return const Column(
                  children: [
                    AiToolsSection(),
                    SizedBox(height: 40),
                    AdminWorkspaceGrid(),
                    SizedBox(height: 40),
                    AdminRightPanel(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderHUD(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<String> months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final List<String> days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    String weekDay = days[_now.weekday - 1];
    String month = months[_now.month - 1];
    String day = _now.day.toString();
    String year = _now.year.toString();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Left: Context
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.workspaces,
                  size: 20,
                  color: const Color.fromARGB(255, 0, 75, 136),
                ),
                const SizedBox(width: 8),
                Text(
                  "EDLAB WORKSPACE",
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                    color: const Color.fromARGB(255, 28, 28, 28),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),

        // Right: Just the Date (Clock Removed)
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "Today",
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
            Text(
              "$weekDay, $month $day, $year",
              style: GoogleFonts.poppins(
                fontSize:
                    20, // Increased size slightly to replace the clock's visual weight
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AiToolsSection extends StatelessWidget {
  const AiToolsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Label
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 4),
          child: Text(
            "INTELLIGENCE",
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: Colors.grey.shade500,
            ),
          ),
        ),

        // Bento Grid Layout for AI Cards
        SizedBox(
          height: 180,
          child: Row(
            children: [
              Expanded(
                child: _buildHoloCard(
                  context,
                  title: "AI Assistant",
                  subtitle: "Analyze academic performance",
                  icon: Icons.auto_awesome_mosaic_rounded,
                  gradientColors: [
                    const Color(0xFF6366F1),
                    const Color(0xFFA855F7),
                  ], // Indigo -> Purple
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _buildHoloCard(
                  context,
                  title: "Database Seeder",
                  subtitle: "Populate real Firebase with dummy data",
                  icon: Icons.cloud_upload_rounded,
                  gradientColors: [
                    const Color(0xFFF59E0B),
                    const Color(0xFFEF4444),
                  ], // Amber -> Red
                  onTap: () async {
                    _showSeedingDialog(context);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHoloCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // 1. Base Glass Layer
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6),
                  width: 1,
                ),
              ),
            ),
          ),

          // 2. Ambient Gradient Glow
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    gradientColors.first.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: gradientColors.first.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, size: 28, color: gradientColors.first),
                    ),
                    Icon(
                      Icons.arrow_outward_rounded,
                      color: isDark ? Colors.white24 : Colors.black12,
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark ? Colors.white54 : Colors.black54,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 4. Click Ripple
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(24),
              splashColor: gradientColors.last.withValues(alpha: 0.1),
              highlightColor: gradientColors.first.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  void _showSeedingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Seed Database?"),
        content: const Text(
          "This will add dummy data for Departments, Courses, Staff, Students, and Fees to your real Firebase. Proceed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseSeeder.seedAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Database seeded successfully!"),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error seeding database: $e")),
                  );
                }
              }
            },
            child: const Text("Seed All"),
          ),
        ],
      ),
    );
  }
}
