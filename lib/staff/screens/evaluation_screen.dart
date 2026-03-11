import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/staff_sidebar.dart';
import '../widgets/staff_header.dart';
import '../../hod/screens/teaching/hod_mark_entry_screen.dart';

class EvaluationScreen extends StatefulWidget {
  final String userId;
  const EvaluationScreen({super.key, required this.userId});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> _tabs = [
    'Evaluations',
    'Course Outcome',
    'Questions',
    'Question Papers',
    'Sample Sheets',
    'Templates',
    'Survey',
    'University Exam',
  ];
  int _activeTab = 0;

  final _nameFilter = TextEditingController();
  String? _typeFilter;

  @override
  void dispose() {
    _nameFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffSidebar(activeIndex: 2, userId: widget.userId),
          Expanded(
            child: Stack(
              children: [
                // ── Gradient Hero Background ──────────────────────────────
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 300,
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

                // ── Main Column ───────────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                      child: StaffHeader(
                        title: 'OBE',
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
                          _breadcrumb('Home'),
                          _breadcrumbSep(),
                          _breadcrumb('My Classes'),
                          _breadcrumbSep(),
                          _breadcrumb('OBE', isLast: true),
                        ],
                      ),
                    ),

                    // Scrollable content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(40, 16, 40, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Live Stat Cards ───────────────────────────
                            StreamBuilder<QuerySnapshot>(
                              stream: _db
                                  .collection('evaluations')
                                  .where('staffId', isEqualTo: widget.userId)
                                  .snapshots(),
                              builder: (context, snap) {
                                final docs = snap.data?.docs ?? [];
                                final types = docs
                                    .map(
                                      (d) =>
                                          (d.data()
                                                  as Map<
                                                    String,
                                                    dynamic
                                                  >)['type']
                                              as String? ??
                                          '',
                                    )
                                    .toSet();
                                return Row(
                                  children: [
                                    _statCard(
                                      'Total Evaluations',
                                      '${docs.length}',
                                      Icons.library_books_outlined,
                                      const Color(0xFFEFF6FF),
                                      const Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 20),
                                    _statCard(
                                      'Evaluation Types',
                                      '${types.length}',
                                      Icons.category_outlined,
                                      const Color(0xFFF0FDF4),
                                      const Color(0xFF22C55E),
                                    ),
                                    const SizedBox(width: 20),
                                    _statCard(
                                      'Series Exams',
                                      '${docs.where((d) => (d.data() as Map)['type'] == 'Series Exam').length}',
                                      Icons.assignment_outlined,
                                      const Color(0xFFFFF7ED),
                                      const Color(0xFFF97316),
                                    ),
                                    const SizedBox(width: 20),
                                    _statCard(
                                      'Assignments',
                                      '${docs.where((d) => (d.data() as Map)['type'] == 'Assignment').length}',
                                      Icons.edit_note_outlined,
                                      const Color(0xFFFDF4FF),
                                      const Color(0xFF9333EA),
                                    ),
                                  ],
                                );
                              },
                            ),

                            const SizedBox(height: 28),

                            // ── Main Glass Card ───────────────────────────
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(32),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.8),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF001FF4,
                                    ).withOpacity(0.06),
                                    blurRadius: 40,
                                    offset: const Offset(0, 20),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Action / Tab bar
                                  _buildActionBar(),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFF1F5F9),
                                  ),
                                  // Tab content
                                  _buildTableCard(),
                                ],
                              ),
                            ),
                          ],
                        ),
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

  // ── Breadcrumb helpers ─────────────────────────────────────────────────────
  Widget _breadcrumb(String label, {bool isLast = false}) => Text(
    label,
    style: GoogleFonts.inter(
      color: isLast ? Colors.white : Colors.white.withOpacity(0.7),
      fontSize: 12,
      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
    ),
  );

  Widget _breadcrumbSep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Icon(
      Icons.chevron_right_rounded,
      color: Colors.white.withOpacity(0.5),
      size: 14,
    ),
  );

  // ── Stat card ──────────────────────────────────────────────────────────────
  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
  ) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
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
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  // ── Action bar (tabs + buttons) ────────────────────────────────────────────
  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Section title
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.table_rows_rounded,
                  color: Color(0xFF4F46E5),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'CO Based Evaluations',
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              // Buttons
              _outlineBtn(Icons.bar_chart_outlined, 'Overall Attainment'),
              const SizedBox(width: 10),
              _outlineBtn(
                Icons.download_outlined,
                'Export CSV',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.download_done_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'CSV exported successfully',
                            style: GoogleFonts.inter(),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              _primaryBtn(
                Icons.add_rounded,
                'Add Evaluation',
                onTap: _showAddDialog,
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Tabs
          SizedBox(
            height: 42,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              itemBuilder: (context, i) {
                final active = i == _activeTab;
                return GestureDetector(
                  onTap: () => setState(() => _activeTab = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: active
                              ? const Color(0xFF4F46E5)
                              : Colors.transparent,
                          width: 2.5,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _tabs[i],
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: active
                              ? const Color(0xFF4F46E5)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _outlineBtn(IconData icon, String label, {VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF475569)),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _primaryBtn(IconData icon, String label, {VoidCallback? onTap}) =>
      ElevatedButton.icon(
        onPressed: onTap ?? () {},
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
      );

  // ── Table card ─────────────────────────────────────────────────────────────
  Widget _buildTableCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('evaluations')
          .where('staffId', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(80),
            child: Center(
              child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
            ),
          );
        }
        final docs = (snapshot.data?.docs ?? []).where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          if (_nameFilter.text.isNotEmpty &&
              !(d['name'] ?? '').toString().toLowerCase().contains(
                _nameFilter.text.toLowerCase(),
              ))
            return false;
          if (_typeFilter != null &&
              _typeFilter!.isNotEmpty &&
              (d['type'] ?? '') != _typeFilter)
            return false;
          return true;
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterRow(),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${docs.length} result${docs.length != 1 ? 's' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF4F46E5),
                  ),
                ),
              ),
            ),
            docs.isEmpty ? _buildEmptyState() : _buildTable(docs),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  // ── Filter row ─────────────────────────────────────────────────────────────
  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          SizedBox(
            width: 240,
            height: 40,
            child: TextField(
              controller: _nameFilter,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search exam name...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 17,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF4F46E5)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            height: 40,
            child: DropdownButtonFormField<String>(
              value: _typeFilter,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF1E293B),
              ),
              hint: Text(
                'All Types',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Types', style: TextStyle(fontSize: 13)),
                ),
                ...[
                  'Series Exam',
                  'Assignment',
                  'Quiz',
                  'Module Test',
                  'Seminar',
                  'Viva',
                  'CAD',
                ].map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _typeFilter = v),
            ),
          ),
          if (_nameFilter.text.isNotEmpty || _typeFilter != null) ...[
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () => setState(() {
                _nameFilter.clear();
                _typeFilter = null;
              }),
              icon: const Icon(Icons.close_rounded, size: 14),
              label: Text('Clear', style: GoogleFonts.inter(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Table ──────────────────────────────────────────────────────────────────
  // Fixed widths for all columns except Subject, which flexes to fill width.
  static const double _wName = 180;
  static const double _wType = 140;
  static const double _wBatch = 80;
  static const double _wMark = 100;
  static const double _wTime = 100;
  static const double _wCreated = 160;
  static const double _wActions = 130;
  static const double _fixedTotal =
      _wName + _wType + _wBatch + _wMark + _wTime + _wCreated + _wActions;

  Widget _buildTable(List<QueryDocumentSnapshot> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final subjectW = (constraints.maxWidth - _fixedTotal).clamp(
          160.0,
          double.infinity,
        );

        Widget headerCell(String label, double w, {bool flex = false}) {
          final child = Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: label.isEmpty
                  ? Colors.transparent
                  : const Color(0xFF1565C0),
              letterSpacing: 0.3,
            ),
          );
          final inner = Container(
            width: flex ? null : w,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0)),
                bottom: BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            child: child,
          );
          return flex ? Expanded(child: inner) : inner;
        }

        return Column(
          children: [
            // Header
            Container(
              color: const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  headerCell('Exam Name', _wName),
                  headerCell('Type', _wType),
                  headerCell('Batch', _wBatch),
                  headerCell('Subject', subjectW, flex: true),
                  headerCell('Total Mark', _wMark),
                  headerCell('Total Time', _wTime),
                  headerCell('Created By', _wCreated),
                  headerCell('', _wActions),
                ],
              ),
            ),
            // Data rows
            ...docs.asMap().entries.map(
              (e) => _buildRow(
                e.value.id,
                e.value.data() as Map<String, dynamic>,
                e.key,
                subjectW,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(
    String docId,
    Map<String, dynamic> d,
    int idx,
    double subjectW,
  ) {
    final isEven = idx % 2 == 0;
    return Container(
      color: isEven ? Colors.white : const Color(0xFFFAFAFC),
      child: Row(
        children: [
          // Exam Name
          SizedBox(
            width: _wName,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: InkWell(
                onTap: () {},
                child: Text(
                  d['name'] ?? 'Untitled',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF1565C0),
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
          // Type badge
          SizedBox(
            width: _wType,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _typeColor(d['type'])[0],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    d['type'] ?? 'Series Exam',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _typeColor(d['type'])[1],
                    ),
                  ),
                ),
              ),
            ),
          ),
          _cell(d['batch'] ?? '2025', _wBatch),
          // Subject — flexible
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Text(
                d['subject']?.toString().isNotEmpty == true
                    ? d['subject']
                    : 'Digital Fundamentals and Architecture',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF475569),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          _cell('${d['totalMark'] ?? '40'}', _wMark, bold: true),
          _cell(d['duration'] ?? '2 Hrs', _wTime),
          // Created By
          SizedBox(
            width: _wCreated,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: const Color(0xFF4F46E5).withOpacity(0.1),
                    child: Text(
                      (d['createdByName'] ?? 'F')
                          .toString()
                          .substring(0, 1)
                          .toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d['createdByName'] ?? 'Faculty',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF475569),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action buttons
          SizedBox(
            width: _wActions,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _rowIconBtn(
                    Icons.remove_red_eye_outlined,
                    const Color(0xFF4F46E5),
                    () {
                      final cos = List<String>.from(d['cosMapped'] ?? []);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HodMarkEntryScreen(
                            userId: widget.userId,
                            evaluationId: docId,
                            examName: d['name'] ?? 'Untitled',
                            examType: d['type'] ?? 'Series Exam',
                            subjectCode:
                                (d['subject']?.toString().isNotEmpty == true
                                ? d['subject']
                                : 'Digital Fundamentals and Architecture'),
                            subjectName:
                                (d['subject']?.toString().isNotEmpty == true
                                ? d['subject']
                                : 'Digital Fundamentals and Architecture'),
                            batchName: d['batch'] ?? '2025',
                            cosMapped: cos,
                            maxMark: '${d['totalMark'] ?? '40'}',
                            isPublished: d['status'] == 'Published',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  _rowIconBtn(
                    Icons.edit_outlined,
                    const Color(0xFF4F46E5),
                    () => _showEditDialog(docId, d),
                  ),
                  const SizedBox(width: 8),
                  _rowIconBtn(
                    Icons.delete_outline_rounded,
                    const Color(0xFFEF4444),
                    () => _showDeleteDialog(docId, d['name'] ?? ''),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List _typeColor(String? type) {
    switch (type) {
      case 'Series Exam':
        return [const Color(0xFFEEF2FF), const Color(0xFF4338CA)];
      case 'Assignment':
        return [const Color(0xFFF0FDF4), const Color(0xFF166534)];
      case 'Quiz':
        return [const Color(0xFFFFF7ED), const Color(0xFF9A3412)];
      case 'Module Test':
        return [const Color(0xFFFFF1F2), const Color(0xFF9F1239)];
      case 'Seminar':
        return [const Color(0xFFF0F9FF), const Color(0xFF075985)];
      case 'Viva':
        return [const Color(0xFFFDF4FF), const Color(0xFF7E22CE)];
      default:
        return [const Color(0xFFF1F5F9), const Color(0xFF334155)];
    }
  }

  Widget _cell(String text, double width, {bool bold = false}) => Container(
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: bold ? const Color(0xFF1E293B) : const Color(0xFF475569),
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );

  Widget _rowIconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: color),
    ),
  );

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.library_books_outlined,
                size: 48,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Evaluations Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first evaluation using the button above.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Evaluation',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add / Edit Dialogs ─────────────────────────────────────────────────────
  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final batchCtrl = TextEditingController(text: '2025');
    final subjectCtrl = TextEditingController(
      text: 'Digital Fundamentals and Architecture',
    );
    final markCtrl = TextEditingController(text: '40');
    final durationCtrl = TextEditingController(text: '2 Hrs');
    final createdByCtrl = TextEditingController();
    String type = 'Series Exam';
    _showFormDialog(
      title: 'Add New Evaluation',
      nameCtrl: nameCtrl,
      batchCtrl: batchCtrl,
      subjectCtrl: subjectCtrl,
      markCtrl: markCtrl,
      durationCtrl: durationCtrl,
      createdByCtrl: createdByCtrl,
      type: type,
      onTypeChanged: (v) => type = v,
      onSave: () async {
        await _db.collection('evaluations').add({
          'name': nameCtrl.text.trim(),
          'type': type,
          'batch': batchCtrl.text.trim(),
          'subject': subjectCtrl.text.trim(),
          'totalMark': markCtrl.text.trim(),
          'duration': durationCtrl.text.trim(),
          'createdByName': createdByCtrl.text.trim().isEmpty
              ? 'Faculty'
              : createdByCtrl.text.trim(),
          'staffId': widget.userId,
          'category': type,
          'status': 'Unpublished',
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });
      },
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> d) {
    final nameCtrl = TextEditingController(text: d['name']);
    final batchCtrl = TextEditingController(text: d['batch'] ?? '2025');
    final subjectCtrl = TextEditingController(text: d['subject']);
    final markCtrl = TextEditingController(text: '${d['totalMark'] ?? '40'}');
    final durationCtrl = TextEditingController(text: d['duration'] ?? '2 Hrs');
    final createdByCtrl = TextEditingController(text: d['createdByName'] ?? '');
    String type = d['type'] ?? 'Series Exam';
    _showFormDialog(
      title: 'Edit Evaluation',
      nameCtrl: nameCtrl,
      batchCtrl: batchCtrl,
      subjectCtrl: subjectCtrl,
      markCtrl: markCtrl,
      durationCtrl: durationCtrl,
      createdByCtrl: createdByCtrl,
      type: type,
      onTypeChanged: (v) => type = v,
      onSave: () async {
        await _db.collection('evaluations').doc(docId).update({
          'name': nameCtrl.text.trim(),
          'type': type,
          'batch': batchCtrl.text.trim(),
          'subject': subjectCtrl.text.trim(),
          'totalMark': markCtrl.text.trim(),
          'duration': durationCtrl.text.trim(),
          'createdByName': createdByCtrl.text.trim().isEmpty
              ? 'Faculty'
              : createdByCtrl.text.trim(),
        });
      },
    );
  }

  void _showFormDialog({
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController batchCtrl,
    required TextEditingController subjectCtrl,
    required TextEditingController markCtrl,
    required TextEditingController durationCtrl,
    required TextEditingController createdByCtrl,
    required String type,
    required ValueChanged<String> onTypeChanged,
    required Future<void> Function() onSave,
  }) {
    String localType = type;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_document,
                    color: Color(0xFF4F46E5),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            'Exam Name',
                            nameCtrl,
                            icon: Icons.short_text_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _formField(
                            'Batch',
                            batchCtrl,
                            icon: Icons.school_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _formField(
                      'Subject',
                      subjectCtrl,
                      icon: Icons.menu_book_outlined,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: localType,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Evaluation Type',
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      items:
                          [
                                'Series Exam',
                                'Assignment',
                                'Quiz',
                                'Module Test',
                                'Seminar',
                                'Viva',
                                'CAD',
                              ]
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setS(() => localType = v);
                          onTypeChanged(v);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            'Total Mark',
                            markCtrl,
                            icon: Icons.score_outlined,
                            keyboard: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _formField(
                            'Duration',
                            durationCtrl,
                            icon: Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _formField(
                      'Exam Created By',
                      createdByCtrl,
                      icon: Icons.person_outline_rounded,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  await onSave();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Evaluation',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('evaluations').doc(docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form field ─────────────────────────────────────────────────────────────
  Widget _formField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF64748B),
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: const Color(0xFF94A3B8))
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5)),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
