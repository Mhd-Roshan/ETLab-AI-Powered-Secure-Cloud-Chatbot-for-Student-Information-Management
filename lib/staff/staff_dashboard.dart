import 'package:flutter/material.dart';

class StaffDashboard extends StatefulWidget {
  final dynamic user; // Placeholder for user object
  const StaffDashboard({super.key, this.user});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  // --- Constants ---
  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color backgroundLight = const Color(0xFFF3F4F6);
  final Color surfaceLight = const Color(0xFFFFFFFF);
  final Color textSlate900 = const Color(0xFF0F172A);
  final Color textSlate500 = const Color(0xFF64748B);
  final Color borderLight = const Color(0xFFE2E8F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      body: Row(
        children: [
          // --- Sidebar (Desktop) ---
          if (MediaQuery.of(context).size.width > 900)
            Container(
              width: 260,
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
                        _buildNavItem(Icons.dashboard, "Dashboard", isActive: true),
                        _buildNavItem(Icons.supervisor_account, "Staff Advisor"),
                        _buildNavItem(Icons.class_, "My Classes"),
                        _buildNavItem(Icons.calendar_view_week, "My Timetable"),
                        _buildNavItem(Icons.swap_horiz, "Substitutions"),
                      ],
                    ),
                  ),
                  _buildSidebarFooter(),
                ],
              ),
            ),

          // --- Main Content ---
          Expanded(
            child: Column(
              children: [
                _buildTopHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Alert Banner
                        _buildAlertBanner(),
                        const SizedBox(height: 24),

                        // Main Layout (Left: AI+Admin, Right: Calendar+Notices)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 1100) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Left Column (AI + Admin)
                                  Expanded(
                                    flex: 8,
                                    child: Column(
                                      children: [
                                        _buildAIToolsSection(),
                                        const SizedBox(height: 32),
                                        _buildAdministrationGrid(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  // Right Column (Profile + Calendar + Notice)
                                  Expanded(
                                    flex: 4,
                                    child: _buildRightPanel(),
                                  ),
                                ],
                              );
                            } else {
                              // Stacked Layout
                              return Column(
                                children: [
                                  _buildAIToolsSection(),
                                  const SizedBox(height: 32),
                                  _buildAdministrationGrid(),
                                  const SizedBox(height: 32),
                                  _buildRightPanel(),
                                ],
                              );
                            }
                          },
                        ),
                        
                        // Footer
                        const SizedBox(height: 40),
                        Center(
                          child: Text(
                            "© 2026 EDLAB Campus Management System. All rights reserved.",
                            style: TextStyle(color: Colors.grey[400], fontSize: 12),
                          ),
                        ),

                        // Bottom Quick Links
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.only(top: 24),
                          // FIXED: Wrapped Border in BoxDecoration
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

  Widget _buildChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderLight),
      ),
      child: Text(
        label,
        style: TextStyle(color: textSlate500, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  // --- Sidebar ---
  Widget _buildSidebarHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderLight))),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(8)),
            alignment: Alignment.center,
            child: const Text("E", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "EDLAB", style: TextStyle(color: textSlate900, fontSize: 18, fontWeight: FontWeight.bold)),
                TextSpan(text: "2026", style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    Color bg = isActive ? primaryBlue.withOpacity(0.1) : Colors.transparent;
    Color text = isActive ? primaryBlue : textSlate500;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: text, size: 22),
        title: Text(label, style: TextStyle(color: text, fontSize: 14, fontWeight: FontWeight.w500)),
        onTap: () {},
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: borderLight))),
      child: TextButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout, color: Colors.red, size: 20),
        label: const Text("Logout", style: TextStyle(color: Colors.red)),
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.withOpacity(0.05),
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildTopHeader() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      // FIXED: Moved 'color' inside BoxDecoration to avoid conflict
      decoration: BoxDecoration(
        color: surfaceLight,
        border: Border(bottom: BorderSide(color: borderLight)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text("Home", style: TextStyle(color: textSlate500, fontSize: 14)),
              Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("/", style: TextStyle(color: Colors.grey[300]))),
              Text("Dashboard", style: TextStyle(color: textSlate900, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: backgroundLight, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: textSlate500),
                    const SizedBox(width: 6),
                    Text("Wed, 18 Sep 2026 | 12:55 PM", style: TextStyle(color: textSlate500, fontSize: 12, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Stack(
                children: [
                  Icon(Icons.mail_outline, color: textSlate500, size: 24),
                  Positioned(right: 0, top: 0, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
                ],
              ),
              const SizedBox(width: 16),
              const CircleAvatar(
                backgroundColor: Colors.blueAccent,
                radius: 16,
                backgroundImage: NetworkImage("https://lh3.googleusercontent.com/aida-public/AB6AXuBDE9T-50fuL2F8QWGhp4rZc__zJ891gyPeglyvzB_qHZp21aVY0Zq9TksjkgcbPfUu6RcmNaCBvEheyK_Z_RPqUWpB7kYF2Gi8NQMK10PDXPQfRtRHT8Qs_KCyH6CEtWqU6TlSLEGMvMPYaM3oDY1YkHIDJmr1Lfzw7Vq_1xhNE2cMduJ_ir1NjZvgoBDUVTHHhRqoRSk30h1k5dovmZir78rztYqjLXTMUAx9DI6HfaJbLLScEBzYhkOlmQ7UPOUr7AJCG2truXY"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Main Content Components ---
  Widget _buildAlertBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: primaryBlue, size: 20),
              const SizedBox(width: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: Colors.blue[900], fontSize: 14),
                  children: const [
                    TextSpan(text: "New Message: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: "You have 1 unread message in your inbox."),
                  ],
                ),
              ),
            ],
          ),
          Text("View Messages", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildAIToolsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text("AI TOOLS", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text("NEW", style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAICard("AI Assistant", Icons.smart_toy, [const Color(0xFF4F46E5), const Color(0xFF7C3AED)], "Hi Jithesh! Schedule check?")),
            const SizedBox(width: 16),
            Expanded(child: _buildAICard("AI Insights", Icons.analytics, [const Color(0xFF059669), const Color(0xFF10B981)], "Data Analysis & Retrieval")),
          ],
        ),
      ],
    );
  }

  Widget _buildAICard(String title, IconData icon, List<Color> colors, String subtitle) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: colors[0].withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const Icon(Icons.more_horiz, color: Colors.white70),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13)),
            ],
          ),
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.mic, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text("Ask anything...", style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                  child: Icon(Icons.arrow_upward, color: colors[0], size: 14),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildAdministrationGrid() {
    final List<Map<String, dynamic>> items = [
      {"icon": Icons.person, "label": "My Profile", "color": Colors.blue},
      {"icon": Icons.settings, "label": "Settings", "color": Colors.orange},
      {"icon": Icons.science, "label": "Laboratory", "color": Colors.purple},
      {"icon": Icons.event_note, "label": "Calendar", "color": Colors.green},
      {"icon": Icons.language, "label": "Website", "color": Colors.cyan},
      {"icon": Icons.badge, "label": "Staff ID Card", "color": Colors.indigo},
      {"icon": Icons.table_view, "label": "Bulk Marks", "color": Colors.pinkAccent},
      {"icon": Icons.live_tv, "label": "Live", "color": Colors.red},
      {"icon": Icons.subject, "label": "My Subjects", "color": Colors.amber},
      {"icon": Icons.feedback, "label": "Complaints", "color": Colors.grey},
      {"icon": Icons.campaign, "label": "Circulars", "color": Colors.teal},
      {"icon": Icons.folder_open, "label": "Class Materials", "color": Colors.lightGreen},
      {"icon": Icons.quiz, "label": "Question Banks", "color": Colors.yellow},
      {"icon": Icons.history_edu, "label": "Old Q. Papers", "color": Colors.blueGrey},
      {"icon": Icons.assignment_late, "label": "Notice Board", "color": Colors.deepOrange},
      {"icon": Icons.assignment_turned_in, "label": "Assignments", "color": Colors.lime},
      {"icon": Icons.timer, "label": "Exam/Quiz", "color": Colors.cyan},
      {"icon": Icons.co_present, "label": "Attendance", "color": Colors.orangeAccent},
      {"icon": Icons.play_circle, "label": "Lectures", "color": Colors.redAccent},
      {"icon": Icons.duo, "label": "Online Classes", "color": Colors.deepPurple},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("ADMINISTRATION", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, 
            childAspectRatio: 1.0,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return _buildAdminCard(items[index]);
          },
        ),
      ],
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderLight),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: item['color'].withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(item['icon'], color: item['color'], size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            item['label'],
            textAlign: TextAlign.center,
            style: TextStyle(color: textSlate900, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // --- Right Panel ---
  Widget _buildRightPanel() {
    return Column(
      children: [
        // Profile Abstract
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderLight),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Profile Abstract", style: TextStyle(color: textSlate900, fontWeight: FontWeight.bold)),
              Text("Edit", style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Calendar
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderLight),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.calendar_month, color: textSlate500, size: 20),
                    const SizedBox(width: 8),
                    Text("Calendar", style: TextStyle(color: textSlate900, fontWeight: FontWeight.bold)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: const Text("Pending Task", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 16),
              // Simplified Calendar Grid
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 7,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(35, (index) {
                  int day = index - 2; // Offset for starting day
                  bool isToday = day == 18;
                  if (day <= 0 || day > 31) return const SizedBox();
                  return Center(
                    child: Container(
                      width: 28, height: 28,
                      decoration: isToday ? const BoxDecoration(color: Colors.red, shape: BoxShape.circle) : null,
                      alignment: Alignment.center,
                      child: Text(
                        "$day",
                        style: TextStyle(
                          color: isToday ? Colors.white : textSlate900,
                          fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Notice Board
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.campaign, color: primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text("Notice Board", style: TextStyle(color: textSlate900, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 20),
              _buildNoticeItem("15", "SEP", "Class Timing Update", "Regular online classes 8:30am to 1:30pm."),
              const SizedBox(height: 16),
              _buildNoticeItem("12", "SEP", "Exam Schedule", "Mid-term schedule published."),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (){},
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: primaryBlue.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("View All Notices", style: TextStyle(color: primaryBlue)),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoticeItem(String day, String month, String title, String desc) {
    return Row(
      children: [
        Container(
          width: 50, height: 50,
          decoration: BoxDecoration(color: backgroundLight, borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(month, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(day, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textSlate900)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textSlate900, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          ),
        )
      ],
    );
  }
}