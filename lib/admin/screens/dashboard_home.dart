import 'dart:async';
import 'dart:ui'; // Required for ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../widgets/admin_grid.dart';
import '../widgets/admin_calendar.dart';

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
    // Update every second for live time
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Text(
            "Home / Dashboard",
            style: GoogleFonts.inter(
              color: Colors.grey, 
              fontSize: 13, 
              fontWeight: FontWeight.w500
            ),
          ),
          const SizedBox(height: 20),

          // --- NEW CLEAN DATE WIDGET ---
          _buildCompactDateHeader(context),
          
          const SizedBox(height: 32),

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 1100) {
                return const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          AiToolsSection(),
                          SizedBox(height: 32),
                          AdministrationGrid(),
                        ],
                      ),
                    ),
                    SizedBox(width: 32),
                    Expanded(flex: 1, child: RightPanel()),
                  ],
                );
              } else {
                return const Column(
                  children: [
                    AiToolsSection(),
                    SizedBox(height: 32),
                    AdministrationGrid(),
                    SizedBox(height: 32),
                    RightPanel(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDateHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Manual Formatting
    final List<String> months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final List<String> days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    
    String weekDay = days[_now.weekday - 1];
    String month = months[_now.month - 1];
    String day = _now.day.toString();
    String year = _now.year.toString();
    
    // Formatting Time
    String hour = _now.hour > 12 ? (_now.hour - 12).toString() : (_now.hour == 0 ? '12' : _now.hour.toString());
    String minute = _now.minute.toString().padLeft(2, '0');
    String period = _now.hour >= 12 ? 'PM' : 'AM';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          // Reduced padding for a "smaller portion" feel
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.03) 
                : Colors.white.withOpacity(0.4),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.4),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: Clean Date (No Icons, Just Text)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    weekDay.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5), // Indigo Accent
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$month $day, $year",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              
              // Right: Time (Floating, No Box)
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "$hour:$minute",
                    style: GoogleFonts.jetBrainsMono( // Monospace for numbers looks techy
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    period,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              "AI TOOLS", 
              style: GoogleFonts.inter(
                fontWeight: FontWeight.bold, 
                color: Colors.grey, 
                letterSpacing: 1.2
              )
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildGlassCard(
                context, 
                "AI Assistant", 
                "Ask anything...",
                Icons.smart_toy_rounded, 
                const Color(0xFFD946EF), // Fuchsia
                const Color(0xFF8B5CF6), // Violet
              )
            ),
            const SizedBox(width: 20),
            Expanded(
              child: _buildGlassCard(
                context, 
                "AI Insights", 
                "Performance Analytics",
                Icons.insights_rounded, 
                const Color(0xFF0EA5E9), // Sky Blue
                const Color(0xFF2DD4BF), // Teal
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGlassCard(BuildContext context, String title, String subtitle, IconData icon, Color color1, Color color2) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          height: 160,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark 
                ? Colors.white.withOpacity(0.05) 
                : Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color1.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title, 
                    style: GoogleFonts.inter(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    )
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle, 
                    style: GoogleFonts.inter(
                      fontSize: 13, 
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontWeight: FontWeight.w500,
                    )
                  ),
                ],
              ),
              Positioned(
                top: 0,
                right: 0,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [color1, color2],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Icon(
                    icon,
                    size: 56, 
                    color: Colors.white, 
                  ),
                ),
              ),
              Positioned(
                top: -10,
                right: -10,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [color1.withOpacity(0.2), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}