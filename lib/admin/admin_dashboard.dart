import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/screens/ai_chat_screen.dart';
import 'package:edlab/services/admin_service.dart';

// Ensure these widget files exist in your project
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_grid.dart';
import 'widgets/admin_calendar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();

  // ✅ Navigation Helper
  void _navigateToAi(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiChatScreen(
          initialPrompt: prompt, // ✅ Passes text to AI
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar (Ensure your AdminSidebar has a button that calls _navigateToAi('') )
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 0)),

          // 2. Main Content Area
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),

                  // --- SECTION 1: LIVE METRIC CARDS ---
                  Row(
                    children: [
                      Expanded(
                        child: _buildLiveCard(
                          collection: 'students',
                          title: 'Total Students',
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildLiveCard(
                          collection: 'staff',
                          title: 'Total Staff',
                          color: Colors.purpleAccent,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _buildLiveCard(
                          collection: 'courses',
                          title: 'Total Courses',
                          color: Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // --- SECTION 2: AI MODULES (UPDATED & INTERACTIVE) ---
                  Row(
                    children: [
                      // ✅ INTERACTIVE AI CHAT
                      Expanded(
                        flex: 3,
                        child: AiChatAssistantCard(
                          onSubmitted: (text) => _navigateToAi(text),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // ✅ CLICKABLE INSIGHTS
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _navigateToAi(
                            "Analyze current student stability and retention risks based on recent data.",
                          ),
                          child: const AiInsightCard(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- SECTION 3: WORKSPACE TITLE ---
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "EDLAB WORKSPACE",
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF64748B),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- SECTION 4: INTERACTIVE GRID ---
                  const AdminWorkspaceGrid(),
                ],
              ),
            ),
          ),

          // 3. Right Sidebar
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: const AdminRightPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard({
    required String collection,
    required String title,
    required Color color,
  }) {
    return StreamBuilder<int>(
      stream: _adminService.getCount(collection),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data.toString() : "...";
        // Wrapped in InkWell for future navigation to specific lists
        return InkWell(
          onTap: () {
            // Example: Navigator.pushNamed(context, '/$collection');
          },
          child: LiveMetricCarousel(
            baseColor: color,
            dataPoints: [
              {'title': title, 'count': count, 'percent': 'Live', 'isUp': true},
              {
                'title': 'Active Now',
                'count': count,
                'percent': '100%',
                'isUp': true,
              },
            ],
          ),
        );
      },
    );
  }
}

// ============================================================================
//  UPDATED WIDGETS
// ============================================================================

// 1. Live Metric Carousel (Unchanged visual, logic kept)
class LiveMetricCarousel extends StatefulWidget {
  final Color baseColor;
  final List<Map<String, dynamic>> dataPoints;

  const LiveMetricCarousel({
    super.key,
    required this.baseColor,
    required this.dataPoints,
  });

  @override
  State<LiveMetricCarousel> createState() => _LiveMetricCarouselState();
}

class _LiveMetricCarouselState extends State<LiveMetricCarousel> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.dataPoints.length;
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
    final currentData = widget.dataPoints[_currentIndex];
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.baseColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: WaveFlowPainter(
                  color: widget.baseColor.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (currentData['title'] as String).toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (currentData['isUp'] as bool)
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (currentData['isUp'] as bool)
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 12,
                              color: (currentData['isUp'] as bool)
                                  ? const Color(0xFF16A34A)
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentData['percent'],
                              style: GoogleFonts.poppins(
                                color: (currentData['isUp'] as bool)
                                    ? const Color(0xFF16A34A)
                                    : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currentData['count'],
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -1,
                    ),
                  ),
                  Row(
                    children: List.generate(widget.dataPoints.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 4),
                        height: 4,
                        width: _currentIndex == index ? 16 : 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? widget.baseColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveFlowPainter extends CustomPainter {
  final Color color;
  WaveFlowPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.60,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width,
      size.height * 0.65,
    );
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ------------------------------------------------------------------
// ✅ 3. UPDATED AI CHAT CARD (Now Interactive!)
// ------------------------------------------------------------------
class AiChatAssistantCard extends StatefulWidget {
  final Function(String) onSubmitted; // Callback for search

  const AiChatAssistantCard({super.key, required this.onSubmitted});

  @override
  State<AiChatAssistantCard> createState() => _AiChatAssistantCardState();
}

class _AiChatAssistantCardState extends State<AiChatAssistantCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFEC4899)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "EdLab AI",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        "Gemini 2.0", // Updated model name
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  "Ask about enrollment trends...",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                // ✅ REAL INPUT FIELD
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _controller,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    textAlignVertical: TextAlignVertical.center,
                    onSubmitted: (value) {
                      widget.onSubmitted(value); // Trigger navigation
                    },
                    decoration: InputDecoration(
                      hintText: "Type a command...",
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 0,
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Color(0xFF6366F1),
                        ),
                        onPressed: () {
                          if (_controller.text.isNotEmpty) {
                            widget.onSubmitted(_controller.text);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 4. AI Insight Card (Visuals unchanged, wrapped in GestureDetector in parent)
class AiInsightCard extends StatelessWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: 0.85,
                    strokeWidth: 10,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981),
                    ),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "85%",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      "Stability",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Risk",
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF0F172A),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "LOW",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF15803D),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "12 At Risk",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "45 Improving",
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
