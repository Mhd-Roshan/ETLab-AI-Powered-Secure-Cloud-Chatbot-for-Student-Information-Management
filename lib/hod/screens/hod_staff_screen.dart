import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';
import 'package:edlab/hod/widgets/hod_header.dart';
import 'package:edlab/services/hod_service.dart';

class HodStaffScreen extends StatefulWidget {
  final String userId;
  const HodStaffScreen({super.key, this.userId = 'hod@gmail.com'});

  @override
  State<HodStaffScreen> createState() => _HodStaffScreenState();
}

class _HodStaffScreenState extends State<HodStaffScreen> {
  final HodService _hodService = HodService();
  String _department = "MCA";
  bool _seeding = false;
  String _selectedStatus = "All";
  String _searchQuery = "";
  String _viewType = "Directory";

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    try {
      final snap = await _hodService.getDepartmentStaff('MCA').first;
      if (snap.docs.isEmpty) {
        if (mounted) setState(() => _seeding = true);
        await _hodService.seedStaff();
        if (mounted) setState(() => _seeding = false);
      }
      // Always verify and seed subject data — checks the sub-collection depth
      await _hodService.seedStaffSubjectsIfNeeded();
    } catch (e) {
      debugPrint('Seed error: $e');
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _loadProfile() async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .get();
    if (snap.exists && mounted) {
      setState(() => _department = snap.data()?['department'] ?? "MCA");
    }
  }

  List<Map<String, dynamic>> _getFilteredStaff(
    List<Map<String, dynamic>> allStaff,
  ) {
    return allStaff.where((s) {
      final name = s['name'].toString().toLowerCase();
      final status = s['status'].toString();
      final matchSearch = name.contains(_searchQuery.toLowerCase());
      final matchStatus = _selectedStatus == "All" || status == _selectedStatus;
      return matchSearch && matchStatus;
    }).toList();
  }

  int _getActiveCount(List<Map<String, dynamic>> allStaff) => allStaff
      .where((s) => s['status'] == 'Active' || s['status'] == 'In Class')
      .length;

  int _getOnLeaveCount(List<Map<String, dynamic>> allStaff) =>
      allStaff.where((s) => s['status'] == 'On Leave').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          HodSidebar(activeIndex: -1, userId: widget.userId),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _hodService.getDepartmentStaff(_department),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !_seeding) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allDocs = snapshot.data?.docs ?? [];
                final List<Map<String, dynamic>> allStaff = allDocs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return {...data, 'id': doc.id};
                }).toList();

                final filteredStaff = _getFilteredStaff(allStaff);

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HodHeader(
                        title: "Department Staff",
                        subtitle: "MCA — Master of Computer Applications",
                        userId: widget.userId,
                      ),
                      const SizedBox(height: 32),
                      _buildStatsRow(allStaff),
                      const SizedBox(height: 48),
                      Row(
                        children: [
                          Text(
                            "FACULTY DIRECTORY",
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          _buildAddButton(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildControls(),
                      const SizedBox(height: 32),
                      if (_seeding)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48),
                            child: CircularProgressIndicator(
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        )
                      else if (_viewType == "Directory")
                        _buildStaffGrid(filteredStaff)
                      else
                        _buildWorkloadView(filteredStaff),
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

  // ─── CONTROLS ────────────────────────────────────────────────────────────────

  Widget _buildControls() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              _viewToggleItem("Directory", Icons.grid_view_rounded),
              _viewToggleItem("Workload", Icons.analytics_outlined),
            ],
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search faculty members...",
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        ...["All", "Active", "In Class", "On Leave"].map((s) {
          final sel = _selectedStatus == s;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedStatus = s),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _viewToggleItem(String label, IconData icon) {
    final sel = _viewType == label;
    return InkWell(
      onTap: () => setState(() => _viewType = label),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: sel ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: sel ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── WORKLOAD VIEW (FIRESTORE-DRIVEN) ────────────────────────────────────────

  Widget _buildWorkloadView(List<Map<String, dynamic>> staff) {
    if (staff.isEmpty) return _buildEmptyState();

    return Column(
      children: [
        // Summary banner
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.analytics_rounded,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Academic Coverage Monitor",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    "Subject-wise syllabus coverage & completion tracking",
                    style: GoogleFonts.inter(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Per-faculty cards — each streams from Firestore
        ...staff.map((s) => _buildFacultyWorkloadCard(s)),
      ],
    );
  }

  Widget _buildFacultyWorkloadCard(Map<String, dynamic> s) {
    final email = s['email'] as String? ?? '';
    final Color color = Color(s['colorHex'] as int);

    return StreamBuilder<QuerySnapshot>(
      stream: _hodService.getStaffSubjects(email),
      builder: (context, subSnap) {
        final subjectDocs = subSnap.data?.docs ?? [];
        final subjects = subjectDocs
            .map((d) => d.data() as Map<String, dynamic>)
            .toList();

        final avgCoverage = subjects.isNotEmpty
            ? subjects
                      .map((sub) => (sub['coverage'] as num).toDouble())
                      .reduce((a, b) => a + b) /
                  subjects.length
            : 0.0;
        final avgCompletion = subjects.isNotEmpty
            ? subjects
                      .map((sub) => (sub['completion'] as num).toDouble())
                      .reduce((a, b) => a + b) /
                  subjects.length
            : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: color.withOpacity(0.1),
                      child: Text(
                        s['initials'] ?? '?',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['name'],
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            s['designation'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (subjects.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "${(avgCoverage * 100).round()}% Coverage",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _coverageColor(avgCoverage),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${(avgCompletion * 100).round()}% Complete",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Overall coverage bar
              if (subjects.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: LinearProgressIndicator(
                      value: avgCoverage,
                      minHeight: 6,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: AlwaysStoppedAnimation(
                        _coverageColor(avgCoverage),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),

              // Subject breakdown
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SUBJECT BREAKDOWN",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (subSnap.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      )
                    else if (subjects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Text(
                          "No subject data available.",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      )
                    else
                      ...subjects.map((sub) {
                        final coverage = (sub['coverage'] as num).toDouble();
                        final completion = (sub['completion'] as num)
                            .toDouble();
                        final modules = sub['modules'] as List<dynamic>? ?? [];

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Subject Title & Progress Row
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF6366F1,
                                      ).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.menu_book_rounded,
                                      size: 18,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      sub['name'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ),
                                  _statusPill(
                                    "${(coverage * 100).round()}% Covered",
                                    _coverageColor(coverage),
                                  ),
                                  const SizedBox(width: 8),
                                  _statusPill(
                                    "${(completion * 100).round()}% Done",
                                    _completionColor(completion),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Render Modules if they exist
                              if (modules.isNotEmpty)
                                ...modules.map(
                                  (mod) => _buildModuleSection(mod),
                                ),

                              if (modules.isEmpty)
                                Row(
                                  children: [
                                    Expanded(
                                      child: _progressTrack(
                                        "Syllabus Coverage",
                                        coverage,
                                        _coverageColor(coverage),
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      child: _progressTrack(
                                        "Assessment Completion",
                                        completion,
                                        _completionColor(completion),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _progressTrack(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleSection(Map<String, dynamic> mod) {
    final name = mod['name'] as String? ?? 'Untitled Module';
    final progress = (mod['progress'] as num?)?.toDouble() ?? 0.0;
    final topics = mod['topics'] as List<dynamic>? ?? [];

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Progress",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${(progress * 100).round()}% Completed",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildTopicGrid(topics),
        ],
      ),
    );
  }

  Widget _buildTopicGrid(List<dynamic> topics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: topics.map((topic) {
            final tName = topic['name'] as String? ?? '';
            final tStatus = topic['status'] as String? ?? 'pending';
            final width = (constraints.maxWidth - 24) / 3;

            Color bgColor;
            Color textColor = Colors.white;
            IconData icon = Icons.arrow_right_alt_rounded;

            if (tStatus == 'completed') {
              bgColor = const Color(
                0xFF5DBB87,
              ); // Green variant from screenshot
            } else if (tStatus == 'in_progress') {
              bgColor = const Color(0xFF4289AD); // Blue variant from screenshot
            } else {
              bgColor = const Color(0xFFF1F5F9);
              textColor = const Color(0xFF64748B);
              icon = Icons.lock_outline_rounded;
            }

            return Container(
              width: width,
              padding: const EdgeInsets.all(12),
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(
                  4,
                ), // Slightly sharper corners like screenshot
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 16, color: textColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tName,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _statusPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _coverageColor(double value) {
    if (value >= 0.8) return const Color(0xFF10B981);
    if (value >= 0.6) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Color _completionColor(double value) {
    if (value >= 0.8) return const Color(0xFF6366F1);
    if (value >= 0.6) return const Color(0xFF0EA5E9);
    return const Color(0xFFF43F5E);
  }

  // ─── STATS ROW ───────────────────────────────────────────────────────────────

  Widget _buildStatsRow(List<Map<String, dynamic>> allStaff) {
    return Row(
      children: [
        _buildStatCard(
          "Total Staff",
          allStaff.isEmpty ? '—' : allStaff.length.toString().padLeft(2, '0'),
          Icons.people_alt_rounded,
          const Color(0xFF6366F1),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Active Faculty",
          allStaff.isEmpty
              ? '—'
              : _getActiveCount(allStaff).toString().padLeft(2, '0'),
          Icons.bolt_rounded,
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "On Leave",
          allStaff.isEmpty
              ? '—'
              : _getOnLeaveCount(allStaff).toString().padLeft(2, '0'),
          Icons.event_busy_rounded,
          const Color(0xFFF43F5E),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Avg Exp",
          "7 yrs",
          Icons.workspace_premium_rounded,
          const Color(0xFFF59E0B),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD BUTTON ──────────────────────────────────────────────────────────────

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddStaffDialog(),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Add Staff",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAddStaffDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final designationCtrl = TextEditingController();
    final speciCtrl = TextEditingController();
    String dialogStatus = 'Active';

    final colorPalette = [
      0xFF6366F1,
      0xFF10B981,
      0xFF8B5CF6,
      0xFFF59E0B,
      0xFFEC4899,
    ];
    final nextColor = colorPalette[Random().nextInt(colorPalette.length)];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Add New Staff",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _dlgField(
                    ctrl: nameCtrl,
                    label: "Full Name",
                    hint: "e.g. Dr. Jane Smith",
                    icon: Icons.person_outline,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  _dlgField(
                    ctrl: emailCtrl,
                    label: "Email",
                    hint: "e.g. jane@edlab.com",
                    icon: Icons.email_outlined,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _dlgField(
                          ctrl: designationCtrl,
                          label: "Designation",
                          hint: "e.g. Professor",
                          icon: Icons.badge_outlined,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _dlgField(
                          ctrl: speciCtrl,
                          label: "Specialization",
                          hint: "e.g. AI",
                          icon: Icons.science_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Status",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: ['Active', 'In Class', 'On Leave'].map((s) {
                      final sel = dialogStatus == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: InkWell(
                          onTap: () => setDlgState(() => dialogStatus = s),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: sel
                                  ? _statusColor(s).withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sel
                                    ? _statusColor(s)
                                    : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Text(
                              s,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: sel
                                    ? _statusColor(s)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          await _hodService.addStaff({
                            'name': nameCtrl.text.trim(),
                            'email': emailCtrl.text.trim(),
                            'designation': designationCtrl.text.trim(),
                            'specialization': speciCtrl.text.trim(),
                            'status': dialogStatus,
                            'initials': nameCtrl.text
                                .trim()
                                .substring(0, 1)
                                .toUpperCase(),
                            'colorHex': nextColor,
                            'subjects': 0,
                            'department': 'MCA',
                          });
                          if (context.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Staff member added successfully",
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text("Add Staff"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _dlgField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctrl,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  // ─── DIRECTORY GRID ───────────────────────────────────────────────────────────

  Widget _buildStaffGrid(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) return _buildEmptyState();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        mainAxisExtent: 220,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildStaffCard(filtered[index]),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> data) {
    final status = data['status'] as String;
    final Color color = Color(data['colorHex'] as int);
    final bool isActive = status == 'Active' || status == 'In Class';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showStaffDetails(data),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        data['designation']?.toString().toUpperCase() ??
                            'FACULTY',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Icon(
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.history_rounded,
                      size: 18,
                      color: isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  data['name'] as String,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  data['specialization'] ?? "Faculty Member",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.book_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${data['subjects']} Subjects",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF6366F1),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── STAFF DETAIL SHEET ───────────────────────────────────────────────────────

  void _showStaffDetails(Map<String, dynamic> staff) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Color(staff['colorHex']).withOpacity(0.1),
                  child: Text(
                    staff['initials'] ?? '?',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(staff['colorHex']),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff['name'],
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        staff['designation'],
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            Text(
              "FACULTY OVERVIEW",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF94A3B8),
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons.email_outlined,
                    "EMAIL ADDRESS",
                    staff['email'],
                  ),
                ),
                Expanded(
                  child: _infoItem(
                    Icons.phone_outlined,
                    "CONTACT PHONE",
                    staff['phone'] ?? 'Not provided',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _infoItem(
                    Icons.workspace_premium_outlined,
                    "EXPERIENCE",
                    staff['experience'] ?? 'N/A',
                  ),
                ),
                Expanded(
                  child: _infoItem(
                    Icons.science_outlined,
                    "SPECIALIZATION",
                    staff['specialization'] ?? 'N/A',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 48),
            Container(
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
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: Color(0xFF6366F1),
                        size: 18,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Academic Workload",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Currently managing ${staff['subjects']} active subjects. Faculty performance and workload are within optimal department standards.",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Done",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(IconData icon, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6366F1)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 80),
        child: Column(
          children: [
            Icon(
              Icons.person_search_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              "No faculty members found",
              style: GoogleFonts.inter(
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF10B981);
      case 'In Class':
        return const Color(0xFF6366F1);
      case 'On Leave':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
