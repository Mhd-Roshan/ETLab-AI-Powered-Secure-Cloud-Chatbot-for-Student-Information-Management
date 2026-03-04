import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';
import 'package:edlab/hod/widgets/hod_header.dart';
import 'package:edlab/services/hod_service.dart';

class HodBatchDetailScreen extends StatefulWidget {
  final Map<String, dynamic> batch;
  final String userId;

  const HodBatchDetailScreen({
    super.key,
    required this.batch,
    required this.userId,
  });

  @override
  State<HodBatchDetailScreen> createState() => _HodBatchDetailScreenState();
}

class _HodBatchDetailScreenState extends State<HodBatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final HodService _hodService = HodService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final Color accent = batch['color'] as Color;
    final bool isActive = batch['status'] == 'Active';
    final String batchId = batch['id'] as String;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSidebar(activeIndex: -1, userId: widget.userId),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _hodService.getBatchStudents(batchId),
              builder: (context, snapshot) {
                // Compute derived stats from live data
                final students = snapshot.hasData
                    ? snapshot.data!.docs
                          .map((d) => d.data() as Map<String, dynamic>)
                          .toList()
                    : <Map<String, dynamic>>[];

                final avgAttendance = students.isEmpty
                    ? 0.0
                    : students
                              .map((s) => (s['attendance'] as num).toDouble())
                              .reduce((a, b) => a + b) /
                          students.length;

                final avgGpa = students.isEmpty
                    ? 0.0
                    : students
                              .map((s) => (s['gpa'] as num).toDouble())
                              .reduce((a, b) => a + b) /
                          students.length;

                final atRisk = students
                    .where((s) => s['status'] == 'At Risk')
                    .length;

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HodHeader(
                        title: batch['name'],
                        subtitle:
                            "${batch['status']} Batch · ${batch['semester']}",
                        userId: widget.userId,
                        showBackButton: true,
                      ),
                      const SizedBox(height: 32),

                      // --- Hero Banner ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [accent, accent.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isActive ? 'ACTIVE' : 'COMPLETED',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    batch['name'],
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -1,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Coordinator: ${batch['coordinator']}',
                                    style: GoogleFonts.inter(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _buildHeroStat(
                                  '${batch['totalStudents']}',
                                  'Total Students',
                                  Icons.groups_rounded,
                                ),
                                const SizedBox(height: 16),
                                _buildHeroStat(
                                  batch['semester'],
                                  'Current Semester',
                                  Icons.school_rounded,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // --- Quick Stats ---
                      Row(
                        children: [
                          _buildQuickStat(
                            'Avg Attendance',
                            '${avgAttendance.toStringAsFixed(1)}%',
                            Icons.bar_chart_rounded,
                            avgAttendance >= 75
                                ? const Color(0xFF10B981)
                                : const Color(0xFFEF4444),
                          ),
                          const SizedBox(width: 16),
                          _buildQuickStat(
                            'Avg GPA',
                            avgGpa.toStringAsFixed(2),
                            Icons.auto_graph_rounded,
                            const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 16),
                          _buildQuickStat(
                            'At Risk',
                            '$atRisk Students',
                            Icons.warning_amber_rounded,
                            atRisk > 0
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 16),
                          _buildQuickStat(
                            'Enrolled',
                            '${students.length} Shown',
                            Icons.people_alt_rounded,
                            const Color(0xFF0EA5E9),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // --- Tabs ---
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          padding: const EdgeInsets.all(6),
                          indicator: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          labelColor: Colors.white,
                          unselectedLabelColor: const Color(0xFF64748B),
                          dividerColor: Colors.transparent,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          tabs: const [
                            Tab(text: 'Student List'),
                            Tab(text: 'Batch Info'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        height: (students.length * 72.0) + 100,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildStudentList(
                              accent,
                              students,
                              snapshot.connectionState,
                            ),
                            _buildBatchInfo(batch, accent),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroStat(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.white.withOpacity(0.75),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(
    Color accent,
    List<Map<String, dynamic>> students,
    ConnectionState connectionState,
  ) {
    // Loading state
    if (connectionState == ConnectionState.waiting) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.all(48),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    // Empty state
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'No student data available',
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Student',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Reg No',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Attendance',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'GPA',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Status',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Table Rows
          ...students.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            final bool isAtRisk = s['status'] == 'At Risk';
            final int att = (s['attendance'] as num).toInt();
            final double gpa = (s['gpa'] as num).toDouble();
            final attColor = att >= 75
                ? const Color(0xFF10B981)
                : const Color(0xFFEF4444);

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: i.isEven ? Colors.white : const Color(0xFFFAFAFA),
                border: const Border(
                  bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(
                            'https://ui-avatars.com/api/?name=${Uri.encodeComponent(s['name'])}&background=random&size=60',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          s['name'],
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      s['regNo'],
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: attColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$att%',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: attColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      gpa.toStringAsFixed(1),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAtRisk
                            ? const Color(0xFFFEF3C7)
                            : s['status'] == 'Graduated'
                            ? const Color(0xFFE0F2FE)
                            : const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        s['status'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isAtRisk
                              ? const Color(0xFFF59E0B)
                              : s['status'] == 'Graduated'
                              ? const Color(0xFF0369A1)
                              : const Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBatchInfo(Map<String, dynamic> batch, Color accent) {
    final items = [
      {
        'label': 'Batch Name',
        'value': batch['name'],
        'icon': Icons.layers_rounded,
      },
      {
        'label': 'Programme',
        'value': 'Master of Computer Applications (MCA)',
        'icon': Icons.school_rounded,
      },
      {
        'label': 'Department',
        'value': 'Computer Science & Applications',
        'icon': Icons.business_rounded,
      },
      {
        'label': 'Coordinator',
        'value': batch['coordinator'],
        'icon': Icons.person_rounded,
      },
      {
        'label': 'Current Semester',
        'value': batch['semester'],
        'icon': Icons.calendar_today_rounded,
      },
      {
        'label': 'Total Strength',
        'value': '${batch['totalStudents']} Students',
        'icon': Icons.groups_rounded,
      },
      {
        'label': 'Batch Status',
        'value': batch['status'],
        'icon': Icons.info_rounded,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
            decoration: BoxDecoration(
              border: Border(
                bottom: i < items.length - 1
                    ? const BorderSide(color: Color(0xFFE2E8F0), width: 0.5)
                    : BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    Text(
                      item['value'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
