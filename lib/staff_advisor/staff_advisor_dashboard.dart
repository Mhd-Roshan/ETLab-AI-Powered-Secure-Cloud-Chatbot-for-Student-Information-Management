import 'package:flutter/material.dart';

class StaffAdvisorDashboard extends StatefulWidget {
  const StaffAdvisorDashboard({super.key});

  @override
  State<StaffAdvisorDashboard> createState() => _StaffAdvisorDashboardState();
}

class _StaffAdvisorDashboardState extends State<StaffAdvisorDashboard> {
  // --- Theme Colors (Matches Tailwind Config) ---
  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color backgroundLight = const Color(0xFFF3F4F6);
  final Color surfaceLight = const Color(0xFFFFFFFF);
  final Color textGray900 = const Color(0xFF111827);
  final Color textGray500 = const Color(0xFF6B7280);
  final Color borderLight = const Color(0xFFE5E7EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Row(
        children: [
          // --- Left Sidebar ---
          Container(
            width: 260,
            // Fixed: Using decoration for border instead of invalid 'color: Border(...)'
            decoration: BoxDecoration(
              color: surfaceLight,
              border: Border(right: BorderSide(color: borderLight)),
            ),
            child: Column(
              children: [
                _buildSidebarHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    children: [
                      _buildNavItem(Icons.dashboard, "Dashboard"),
                      // Active Staff Advisor Item
                      _buildNavItem(Icons.person, "Staff Advisor", isActive: true, isPrimary: true),
                      _buildNavItem(Icons.class_, "My Classes"),
                      _buildNavItem(Icons.calendar_month, "My Timetable"),
                      _buildNavItem(Icons.swap_horiz, "Substitutions"),
                      _buildNavItem(Icons.schedule, "Hour Request"),
                      
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          "SUPPORT", 
                          style: TextStyle(color: textGray500, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)
                        ),
                      ),
                      _buildNavItem(Icons.menu_book, "User Manual"),
                    ],
                  ),
                ),
                _buildSidebarFooter(),
              ],
            ),
          ),
          
          // --- Main Content Area ---
          Expanded(
            child: Column(
              children: [
                // Top Header
                _buildTopHeader(),
                
                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Batch/Student Toggle & Last Updated
                        Row(
                          children: [
                            _buildToggleButton("Batch", isActive: true),
                            const SizedBox(width: 12),
                            _buildToggleButton("Student"),
                            const Spacer(),
                            Icon(Icons.update, size: 16, color: textGray500),
                            const SizedBox(width: 4),
                            Text("Last updated: Just now", style: TextStyle(color: textGray500, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // AI Tools Section (Assistant & Insights)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // Responsive Stack: Side by side on large screens, vertical on small
                            if (constraints.maxWidth > 900) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _buildAIAssistantCard()),
                                  const SizedBox(width: 24),
                                  Expanded(child: _buildAIInsightsCard()),
                                ],
                              );
                            } else {
                              return Column(
                                children: [
                                  _buildAIAssistantCard(),
                                  const SizedBox(height: 24),
                                  _buildAIInsightsCard(),
                                ],
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 32),

                        // Admin Grid
                        _buildAdministrationGrid(),

                        const SizedBox(height: 32),

                        // Bottom Quick Links
                        Container(
                          padding: const EdgeInsets.only(top: 24),
                          decoration: BoxDecoration(
                            border: Border(top: BorderSide(color: borderLight)),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildChip("Attendance"),
                              _buildChip("Series Exam"),
                              _buildChip("Assignments"),
                              _buildChip("Scheduled Hours"),
                              _buildChip("Outcomes"),
                              _buildChip("Internal Marks"),
                              _buildChip("University Exam"),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
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

  // ==========================================
  // WIDGET HELPERS
  // ==========================================

  // --- Sidebar Widgets ---
  Widget _buildSidebarHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderLight))),
      child: Row(
        children: [
          Icon(Icons.school, color: primaryBlue, size: 32),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "Edlab", style: TextStyle(color: textGray900, fontSize: 20, fontWeight: FontWeight.bold)),
                TextSpan(text: ".Next", style: TextStyle(color: primaryBlue, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false, bool isPrimary = false}) {
    Color bg = isPrimary ? primaryBlue.withOpacity(0.1) : (isActive ? Colors.grey[100]! : Colors.transparent);
    Color text = isPrimary ? primaryBlue : (isActive ? textGray900 : textGray500);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: text),
        title: Text(label, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w500)),
        onTap: () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        dense: true,
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: borderLight))),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[200],
            // Using an icon fallback instead of network image to prevent errors if offline
            child: Icon(Icons.person, color: textGray500), 
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text("Staff Advisor", style: TextStyle(color: textGray900, fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // --- Header Widgets ---
  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: surfaceLight,
        border: Border(bottom: BorderSide(color: borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Breadcrumbs
          Row(
            children: [
              Text("Home", style: TextStyle(color: textGray500, fontSize: 14, fontWeight: FontWeight.w500)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("/", style: TextStyle(color: Colors.grey[300]))),
              Text("Staff Advisor", style: TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
          // Actions
          Row(
            children: [
              Container(
                width: 260,
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: backgroundLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: textGray500, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search...",
                          hintStyle: TextStyle(color: textGray500, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Stack(
                children: [
                  Icon(Icons.notifications_outlined, color: textGray500, size: 24),
                  Positioned(right: 2, top: 2, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                ],
              ),
              const SizedBox(width: 16),
              Icon(Icons.settings_outlined, color: textGray500, size: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1F2937) : surfaceLight, // Dark Slate for Active
        borderRadius: BorderRadius.circular(8),
        border: isActive ? null : Border.all(color: borderLight),
        boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))] : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : textGray900,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  // --- AI Cards ---
  Widget _buildAIAssistantCard() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("AI Assistant", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF4ADE80), shape: BoxShape.circle)),
                          const SizedBox(width: 6),
                          const Text("ONLINE", style: TextStyle(color: Color(0xFFE0E7FF), fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                ],
              ),
              const Icon(Icons.more_horiz, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: const Text(
              "Hi! Schedule check? I can help optimize your timetable for next week.",
              style: TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
            ),
          ),
          const Spacer(),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Color(0xFFC7D2FE), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Ask anything...",
                      hintStyle: TextStyle(color: const Color(0xFFC7D2FE).withOpacity(0.7), fontSize: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 14,
                  child: const Icon(Icons.arrow_upward, color: Color(0xFF6366F1), size: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsCard() {
    return Container(
      height: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("AI Insights", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(width: 8),
                  Container(width: 6, height: 6, decoration: BoxDecoration(color: Colors.green[300], shape: BoxShape.circle)),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.analytics, color: Colors.white, size: 20),
              ),
            ],
          ),
          const Text("Data Analysis & Retrieval", style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 12)),
          const Spacer(),
          const Text("Deep dive into student performance with instant reports.", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: Text("Analyze Class 5 performance", style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 12)),
                ),
                Row(
                  children: [
                    const Icon(Icons.mic, color: Colors.white70, size: 18),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                      child: const Icon(Icons.arrow_forward, color: Color(0xFF059669), size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildInsightTag("Trends", Icons.trending_up),
              const SizedBox(width: 8),
              _buildInsightTag("Risk", Icons.warning),
              const SizedBox(width: 8),
              _buildInsightTag("Report", Icons.download),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildInsightTag(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // --- Admin Grid Widgets ---
  Widget _buildAdministrationGrid() {
    final List<Map<String, dynamic>> items = [
      {"icon": Icons.library_books, "label": "Subjects", "sub": "Manage syllabus", "color": Colors.blue},
      {"icon": Icons.calendar_view_week, "label": "Timetable", "sub": "Weekly schedule", "color": Colors.purple},
      {"icon": Icons.analytics, "label": "Academics", "sub": "Performance check", "color": Colors.green},
      {"icon": Icons.campaign, "label": "Notice Board", "sub": "Announcements", "color": Colors.orange, "badge": true},
      {"icon": Icons.block, "label": "Suspended Hours", "sub": "Track off-hours", "color": Colors.red},
      {"icon": Icons.school, "label": "University Exam", "sub": "Result Analysis", "color": Colors.indigo},
      {"icon": Icons.person_search, "label": "Student Record", "sub": "Performance log", "color": Colors.teal},
      {"icon": Icons.event_available, "label": "Special Days", "sub": "Working day setup", "color": Colors.cyan},
      {"icon": Icons.beach_access, "label": "Leave", "sub": "Applications", "color": Colors.amber},
      {"icon": Icons.event_note, "label": "Exam Schedule", "sub": "Internal dates", "color": Colors.pinkAccent},
      {"icon": Icons.poll, "label": "Surveys", "sub": "Feedback", "color": Colors.green},
      {"icon": Icons.work, "label": "Internship", "sub": "Industry record", "color": Colors.deepPurple},
      {"icon": Icons.description, "label": "OBE Reports", "sub": "Outcome based", "color": Colors.grey},
      {"icon": Icons.move_up, "label": "Promote/Transfer", "sub": "Batch updates", "color": Colors.pink},
      {"icon": Icons.report_problem, "label": "Complaints", "sub": "Suggestions", "color": Colors.yellow},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5, // You can make this responsive using LayoutBuilder
        childAspectRatio: 1.1,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildGridCard(items[index]);
      },
    );
  }

  Widget _buildGridCard(Map<String, dynamic> item) {
    Color color = item['color'];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item['icon'], color: color, size: 24),
              ),
              if (item['badge'] == true)
                const Positioned(top: -2, right: -2, child: CircleAvatar(radius: 4, backgroundColor: Colors.red)),
            ],
          ),
          const SizedBox(height: 12),
          Text(item['label'], textAlign: TextAlign.center, style: TextStyle(color: textGray900, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text(item['sub'], textAlign: TextAlign.center, style: TextStyle(color: textGray500, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 2, offset: const Offset(0, 1))],
      ),
      child: Text(label, style: TextStyle(color: textGray500, fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }
}