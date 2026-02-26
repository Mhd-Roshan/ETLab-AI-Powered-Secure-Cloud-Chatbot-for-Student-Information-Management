import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/manual_service.dart';
import '../widgets/staff_sidebar.dart';
import '../widgets/staff_header.dart';

class ManualScreen extends StatefulWidget {
  final String userId;
  const ManualScreen({super.key, required this.userId});

  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen>
    with SingleTickerProviderStateMixin {
  final ManualService _manualService = ManualService();
  late TabController _tabController;
  late PageController _pageController;

  final List<String> _tabs = [
    "Overview",
    "Core Features",
    "Knowledge Base",
    "Support",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_pageController.hasClients) {
          _pageController.animateToPage(
            _tabController.index,
            duration: const Duration(milliseconds: 200),
            curve: Curves.fastOutSlowIn,
          );
        }
      }
    });

    _manualService.seedInitialManualData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'auto_awesome_rounded':
        return Icons.auto_awesome_rounded;
      case 'how_to_reg_rounded':
        return Icons.how_to_reg_rounded;
      case 'assignment_outlined':
        return Icons.assignment_outlined;
      case 'poll_outlined':
        return Icons.poll_outlined;
      case 'alternate_email_rounded':
        return Icons.alternate_email_rounded;
      case 'chat_bubble_outline_rounded':
        return Icons.chat_bubble_outline_rounded;
      case 'lightbulb_outline_rounded':
        return Icons.lightbulb_outline_rounded;
      case 'star_outline_rounded':
        return Icons.star_outline_rounded;
      case 'help_center_rounded':
        return Icons.help_center_rounded;
      case 'support_agent_rounded':
        return Icons.support_agent_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffSidebar(activeIndex: 10, userId: widget.userId),
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _manualService.streamManualContent(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const Center(child: Text("No manual content found."));
                }

                final data = snapshot.data!.data() as Map<String, dynamic>;

                return Stack(
                  children: [
                    // --- Premium Aurora Background ---
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 320,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF001FF4),
                              Color(0xFF4F46E5),
                              Color(0xFF7C3AED),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // --- Main Content ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                          child: StaffHeader(
                            title: "User Manual",
                            userId: widget.userId,
                            showBackButton: true,
                            isWhite: true,
                            showDate: false,
                          ),
                        ),

                        // Breadcrumbs
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.home_outlined,
                                color: Colors.white.withOpacity(0.8),
                                size: 14,
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white.withOpacity(0.5),
                                size: 14,
                              ),
                              Text(
                                "Resources",
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 11,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: Colors.white.withOpacity(0.5),
                                size: 14,
                              ),
                              Text(
                                "System Guide",
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Text(
                            "Master the EdLab ecosystem with our structured documentation and feature guides.",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Modern Tab Bar
                        _buildModernTabBar(),

                        Expanded(
                          child: PageView(
                            controller: _pageController,
                            onPageChanged: (index) {
                              _tabController.animateTo(index);
                            },
                            physics: const BouncingScrollPhysics(),
                            children: [
                              _buildOverviewTab(data['overview'] ?? {}),
                              _buildFeaturesTab(data['features'] ?? []),
                              _buildFAQTab(data['faq'] ?? []),
                              _buildSupportTab(data['support'] ?? {}),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: const Color(0xFF001FF4),
        unselectedLabelColor: Colors.white,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: _tabs
            .map(
              (tab) => Tab(
                height: 44,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(tab),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTabContainer({required List<Widget> children}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildOverviewTab(Map<String, dynamic> overviewData) {
    final List modules = overviewData['modules'] ?? [];

    return _buildTabContainer(
      children: [
        _buildSectionHeader(
          _getIconData('lightbulb_outline_rounded'),
          "Getting Started",
          "Quick introduction to the system",
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  overviewData['intro'] ?? "No introduction available.",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF475569),
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              const Icon(
                Icons.auto_awesome_mosaic_rounded,
                size: 60,
                color: Color(0xFF001FF4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _buildSectionHeader(
          _getIconData('star_outline_rounded'),
          "Major Modules",
          "Core features of the application",
        ),
        const SizedBox(height: 24),
        Column(
          children: modules.map((m) {
            return _buildModuleListItem(
              m['code'] ?? "00",
              m['title'] ?? "Unknown",
              m['subtitle'] ?? "",
              _getIconData(m['icon'] ?? ""),
              Color(int.parse(m['color'] ?? "0xFF000000")),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildModuleListItem(
    String code,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                code,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(icon, size: 14, color: color),
                            const SizedBox(width: 8),
                            Text(
                              subtitle,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesTab(List featuresList) {
    return _buildTabContainer(
      children: featuresList.map((f) {
        final List cards = f['cards'] ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(
              _getIconData(f['icon'] ?? 'auto_awesome_rounded'),
              f['title'] ?? "Section",
              f['subtitle'] ?? "",
            ),
            const SizedBox(height: 24),
            ...cards.map((c) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDetailedFeatureCard(
                  c['title'] ?? "",
                  c['subtitle'] ?? "",
                  c['desc'] ?? "",
                  Color(int.parse(f['accentColor'] ?? "0xFF001FF4")),
                ),
              );
            }),
            const SizedBox(height: 40),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildFAQTab(List faqList) {
    return _buildTabContainer(
      children: [
        _buildSectionHeader(
          _getIconData('help_center_rounded'),
          "Knowledge Base",
          "Quick answers to common questions",
        ),
        const SizedBox(height: 32),
        ...faqList.map((f) {
          return _buildFAQCard(f['question'] ?? "", f['answer'] ?? "");
        }),
      ],
    );
  }

  Widget _buildSupportTab(Map<String, dynamic> supportData) {
    final List options = supportData['options'] ?? [];

    return _buildTabContainer(
      children: [
        _buildSectionHeader(
          _getIconData('support_agent_rounded'),
          "Technical Support",
          "Direct support channels",
        ),
        const SizedBox(height: 32),
        ...options.map((o) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildSupportOption(
              icon: _getIconData(o['icon'] ?? ""),
              title: o['title'] ?? "",
              content: o['content'] ?? "",
              buttonLabel: o['buttonLabel'] ?? "Contact",
              color: Color(int.parse(o['color'] ?? "0xFF001FF4")),
            ),
          );
        }),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Text(
                "System Version",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                supportData['version'] ?? "EdLab v2.4.0",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF001FF4).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: const Color(0xFF001FF4), size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailedFeatureCard(
    String title,
    String subtitle,
    String desc,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQCard(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Q:",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF001FF4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.only(left: 30),
            child: Text(
              answer,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String content,
    required String buttonLabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  content,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    color: const Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonLabel,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
