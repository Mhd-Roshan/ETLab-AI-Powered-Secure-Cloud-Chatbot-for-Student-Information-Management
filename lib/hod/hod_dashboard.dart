import 'package:flutter/material.dart';

class HodDashboard extends StatefulWidget {
  const HodDashboard({super.key});

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  // --- Constants based on Tailwind Config ---
  final Color primaryBlue = const Color(0xFF3B82F6);
  final Color pageBg = const Color(0xFFF3F5F9);
  final Color textSlate800 = const Color(0xFF1E293B);
  final Color textSlate500 = const Color(0xFF64748B);
  final Color aiPurple = const Color(0xFF6C5DD3);
  final Color aiGreen = const Color(0xFF10B981);

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to handle responsiveness if needed, 
    // for now we assume a standard desktop/tablet view as per dashboard standard.
    return Scaffold(
      backgroundColor: pageBg,
      body: Row(
        children: [
          // --- Left Sidebar ---
          Container(
            width: 260,
            color: Colors.white,
            child: Column(
              children: [
                _buildSidebarHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    children: [
                      _buildNavItem(Icons.dashboard, "Dashboard", isActive: true),
                      _buildNavItem(Icons.school, "Staff Advisor"),
                      _buildNavItem(Icons.book, "My Classes"),
                      _buildNavItem(Icons.calendar_view_week, "My Timetable"),
                      _buildNavItem(Icons.swap_horiz, "Substitutions"),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Text("AI TOOLS", style: TextStyle(color: Colors.grey[400], fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(4)),
                              child: Text("NEW", style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                            )
                          ],
                        ),
                      ),
                      _buildNavItem(Icons.psychology, "AI Insights"),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildNavItem(Icons.logout, "Logout", isLogout: true),
                ),
              ],
            ),
          ),
          
          // --- Vertical Divider ---
          VerticalDivider(width: 1, thickness: 1, color: Colors.grey[200]),

          // --- Main Content Area ---
          Expanded(
            child: Column(
              children: [
                // Header
                _buildTopHeader(),
                
                // Scrollable Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Alert Banner
                        _buildAlertBanner(),
                        const SizedBox(height: 32),

                        // Split View: Left (AI + Admin) | Right (Profile + Calendar + Notice)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            // If screen is wide, use Row, else Column
                            if (constraints.maxWidth > 1000) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      children: [
                                        _buildAIToolsSection(),
                                        const SizedBox(height: 32),
                                        _buildAdministrationGrid(),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    flex: 1,
                                    child: _buildRightPanel(),
                                  ),
                                ],
                              );
                            } else {
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

  // --- Sidebar Widgets ---

  Widget _buildSidebarHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.transparent)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: primaryBlue, borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.science, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(text: "EDLAB", style: TextStyle(color: textSlate800, fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter')),
                WidgetSpan(
                  child: Transform.translate(
                    offset: const Offset(2, -8),
                    child: Text("2026", style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false, bool isLogout = false}) {
    Color bg = isActive ? Colors.blue[50]! : Colors.transparent;
    Color text = isLogout ? Colors.red[500]! : (isActive ? primaryBlue : textSlate500);
    Color hoverBg = isLogout ? Colors.red[50]! : Colors.grey[50]!;

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
        hoverColor: hoverBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
      ),
    );
  }

  // --- Header Widgets ---

  Widget _buildTopHeader() {
    return Container(
      color: pageBg,
      child: Column(
        children: [
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[200]!))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Breadcrumbs
                Row(
                  children: [
                    Text("Home", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 8), child: Text("/", style: TextStyle(color: Colors.grey[300]))),
                    Text("Dashboard", style: TextStyle(color: textSlate800, fontSize: 14, fontWeight: FontWeight.w600)),
                  ],
                ),
                
                // Search Bar
                Expanded(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search student records...",
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                        suffixIcon: Icon(Icons.tune, color: Colors.grey[400], size: 18),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey[200]!)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide(color: Colors.grey[200]!)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                  ),
                ),

                // Right Actions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Row(children: [
                        Icon(Icons.schedule, size: 16, color: textSlate500),
                        const SizedBox(width: 6),
                        Text("Wed, 18 Sep 2026 | 12:55 PM", style: TextStyle(color: textSlate500, fontSize: 12, fontWeight: FontWeight.w500)),
                      ]),
                    ),
                    const SizedBox(width: 20),
                    Stack(
                      children: [
                        Icon(Icons.mail_outline, color: Colors.grey[400], size: 28),
                        Positioned(right: 0, top: 0, child: Container(width: 14, height: 14, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle), child: const Center(child: Text("1", style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold))))),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.only(left: 16),
                      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.grey[200]!))),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundColor: Colors.orange[100], child: const Icon(Icons.person, color: Colors.orange)),
                          const SizedBox(width: 12),
                          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                            Text("HOD", style: TextStyle(color: textSlate800, fontWeight: FontWeight.w600, fontSize: 14)),
                          ]),
                          const SizedBox(width: 4),
                          Icon(Icons.expand_more, color: Colors.grey[400]),
                        ],
                      ),
                    )
                  ],
                ),
              ],
            ),
          ),
          // Quick Action Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildQuickAction(Icons.groups, "Batch", isActive: true),
                  _buildQuickAction(Icons.person_search, "Student"),
                  _buildQuickAction(Icons.mark_email_unread, "Email"),
                  _buildQuickAction(Icons.summarize, "Report"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isActive ? Border.all(color: Colors.blue.withOpacity(0.2)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: isActive ? primaryBlue : textSlate500, size: 20),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isActive ? primaryBlue : textSlate500, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // --- Main Body Widgets ---

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
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: primaryBlue, shape: BoxShape.circle),
                child: const Icon(Icons.info, color: Colors.white, size: 16),
              ),
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
          Text("View Messages", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildAIToolsSection() {
    return Column(
      children: [
        Row(
          children: [
            Text("AI TOOLS", style: TextStyle(color: Colors.grey[400], fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(12)),
              child: Text("BETA", style: TextStyle(color: primaryBlue, fontSize: 10, fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildAICard("AI Assistant", Icons.smart_toy, aiPurple, "Ask AI...", Icons.arrow_upward)),
            const SizedBox(width: 16),
            Expanded(child: _buildAICard("Insights", Icons.bar_chart, aiGreen, "Analyze...", Icons.arrow_forward, hasMore: true)),
          ],
        ),
      ],
    );
  }

  Widget _buildAICard(String title, IconData icon, Color color, String hint, IconData actionIcon, {bool hasMore = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              if (!hasMore)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.green[100]!)),
                  child: Row(children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text("ON", style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ]),
                ),
              if (hasMore)
                 Row(children: [
                   Text("More", style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                   Icon(Icons.chevron_right, color: color, size: 16),
                 ]),
            ],
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: textSlate800, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          Container(
            height: 36,
            decoration: BoxDecoration(color: pageBg, borderRadius: BorderRadius.circular(8)),
            child: TextField(
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                border: InputBorder.none,
                suffixIcon: Icon(actionIcon, color: color, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdministrationGrid() {
    final List<Map<String, dynamic>> items = [
      {"icon": Icons.groups, "label": "Batches", "color": Colors.blue},
      {"icon": Icons.person_search, "label": "Student", "color": Colors.orange},
      {"icon": Icons.grid_view, "label": "Subject Pool", "color": Colors.purple},
      {"icon": Icons.subject, "label": "My Subjects", "color": Colors.yellow},
      {"icon": Icons.chat_bubble, "label": "Complaints", "color": Colors.grey},
      {"icon": Icons.forum, "label": "Chat Room", "color": Colors.teal},
      {"icon": Icons.assignment, "label": "Assignment", "color": Colors.red}, // Using Red for Rose
      {"icon": Icons.badge, "label": "Staff", "color": Colors.pink},
      {"icon": Icons.campaign, "label": "Circular", "color": Colors.indigo},
      {"icon": Icons.event, "label": "College Calendar", "color": Colors.cyan},
      {"icon": Icons.public, "label": "Website", "color": Colors.blue},
      {"icon": Icons.folder_open, "label": "Class Material", "color": Colors.lightGreen}, // Lime alternative
      {"icon": Icons.person, "label": "My Profile", "color": Colors.purpleAccent}, // Fuchsia
      {"icon": Icons.poll, "label": "Survey", "color": Colors.green}, // Emerald
      {"icon": Icons.school, "label": "Faculty", "color": Colors.amber},
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
            childAspectRatio: 1.1,
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
    Color color = item['color'];
    // Approximating the "50" shade for BG and "500/600" for icon
    Color bg = color.withOpacity(0.1); 
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[50]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Icon(item['icon'], color: color, size: 28),
          ),
          const SizedBox(height: 16),
          Text(item['label'], style: TextStyle(color: textSlate800, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  // --- Right Panel Widgets ---

  Widget _buildRightPanel() {
    return Column(
      children: [
        // Profile Abstract
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[50]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Profile Abstract", style: TextStyle(color: textSlate800, fontWeight: FontWeight.bold)),
                  Text("Edit", style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),
              Container(height: 8, width: 200, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 8),
              Container(height: 8, width: 120, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4))),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Calendar
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[50]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.calendar_month, color: textSlate800, size: 20),
                    const SizedBox(width: 8),
                    Text("Calendar", style: TextStyle(color: textSlate800, fontWeight: FontWeight.bold)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: const Row(children: [
                      Icon(Icons.edit, color: Colors.white, size: 10),
                      SizedBox(width: 2),
                      Text("Pending Task", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                  )
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.chevron_left, color: Colors.grey[400]),
                  Text("December 2026", style: TextStyle(color: textSlate800, fontWeight: FontWeight.bold, fontSize: 13)),
                  Icon(Icons.chevron_right, color: Colors.grey[400]),
                ],
              ),
              const SizedBox(height: 12),
              // Days Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"].map((day) => 
                  SizedBox(width: 30, child: Center(child: Text(day, style: TextStyle(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w500))))
                ).toList(),
              ),
              const SizedBox(height: 8),
              // Static Grid Logic to match visual
              _buildStaticCalendarGrid(),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Notice Board
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[50]!),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.campaign, color: primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text("Notice Board", style: TextStyle(color: textSlate800, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 24),
              _buildNoticeItem("15", "SEP", "Class Timing Update", "Regular online classes will be conducted from 8:30am to 1:30pm starting next week."),
              const SizedBox(height: 16),
              _buildNoticeItem("12", "SEP", "Exam Schedule", "Mid-term examination schedule has been published. Check circulars."),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: (){}, 
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.blue[100]!),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text("View All Notices", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600, fontSize: 12))
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStaticCalendarGrid() {
    // Recreating the specific visual from the HTML
    List<Widget> days = [];
    
    // Previous month (29, 30)
    days.add(_calDay("29", isGrey: true));
    days.add(_calDay("30", isGrey: true));
    
    // Days 1-18
    for(int i=1; i<=18; i++) {
       days.add(_calDay(i.toString()));
    }
    
    // Day 19 (Yellow Dot)
    days.add(Stack(alignment: Alignment.center, children: [
       _calDay("19"),
       const Positioned(top: 6, right: 6, child: CircleAvatar(radius: 3, backgroundColor: Colors.amber)),
    ]));

    // Days 20-28 (Red Block)
    for(int i=20; i<=28; i++) {
       days.add(Container(
         margin: const EdgeInsets.all(2),
         decoration: BoxDecoration(color: Colors.red[600], borderRadius: BorderRadius.circular(8)),
         child: Center(child: Text(i.toString(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500))),
       ));
    }

    // Days 29-31
    for(int i=29; i<=31; i++) {
       days.add(_calDay(i.toString()));
    }
    
    // Next month (1, 2)
    days.add(_calDay("1", isGrey: true));
    days.add(_calDay("2", isGrey: true));

    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 7,
      physics: const NeverScrollableScrollPhysics(),
      children: days,
    );
  }

  Widget _calDay(String text, {bool isGrey = false}) {
    return Center(
      child: Text(text, style: TextStyle(
        color: isGrey ? Colors.grey[300] : Colors.grey[600],
        fontSize: 13,
        fontWeight: FontWeight.w500
      )),
    );
  }

  Widget _buildNoticeItem(String day, String month, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 50,
          height: 56,
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(month, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text(day, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textSlate800)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: textSlate800, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(desc, style: const TextStyle(color: Colors.grey, fontSize: 11, height: 1.4)),
            ],
          ),
        )
      ],
    );
  }
}