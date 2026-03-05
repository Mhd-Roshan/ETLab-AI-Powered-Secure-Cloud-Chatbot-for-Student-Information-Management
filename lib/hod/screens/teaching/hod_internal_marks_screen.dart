import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../widgets/hod_sidebar.dart';
import '../../widgets/hod_header.dart';

class HodInternalMarksScreen extends StatefulWidget {
  final String userId;
  const HodInternalMarksScreen({super.key, required this.userId});

  @override
  State<HodInternalMarksScreen> createState() => _HodInternalMarksScreenState();
}

class _HodInternalMarksScreenState extends State<HodInternalMarksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late List<Map<String, dynamic>> _batches;

  @override
  void initState() {
    super.initState();
    _batches = [
      {
        'name': 'MCA 2023-25',
        'subject': 'Data Strucutre & Algorithms',
        'code': 'MCA301',
        'color': const Color(0xFF6366F1),
        'collection': 'hod_marks_mca2023',
      },
      {
        'name': 'MCA 2024-26',
        'subject': 'Data Strucutre & Algorithms',
        'code': 'MCA103',
        'color': const Color(0xFF10B981),
        'collection': 'hod_marks_mca2024',
      },
    ];
    _tabController = TabController(length: _batches.length, vsync: this);
    _seedAllBatches();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _seedAllBatches() async {
    for (final batch in _batches) {
      final col = batch['collection'] as String;
      final snap = await _firestore.collection(col).limit(1).get();
      if (snap.docs.isEmpty) {
        await _seedBatch(col);
      }
    }
  }

  Future<void> _seedBatch(String collection) async {
    final names = [
      'Aditya Sharma',
      'Priya Nair',
      'Rahul Verma',
      'Sneha Pillai',
      'Kiran Das',
      'Meera Menon',
      'Arjun Krishnan',
      'Divya Suresh',
      'Vishnu Raj',
      'Lakshmi Iyer',
      'Rohan Thomas',
      'Anjali Mohan',
    ];
    final batch = _firestore.batch();
    for (int i = 0; i < names.length; i++) {
      final rollNo = (i + 1).toString().padLeft(3, '0');
      final regNo = 'REG${(2024001 + i)}';
      final att = 70 + (i % 25);
      final assign = 12 + (i % 8);
      final series = 15 + (i % 10);
      final internal = ((att / 10) + assign + series).round().clamp(0, 50);
      final ref = _firestore.collection(collection).doc(regNo);
      batch.set(ref, {
        'name': names[i],
        'rollNo': rollNo,
        'regNo': regNo,
        'attendance': att,
        'assignments': assign,
        'seriesTests': series,
        'internalMark': internal,
      });
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSidebar(activeIndex: 2, userId: widget.userId),
          Expanded(
            child: Column(
              children: [
                // --- GRADIENT HEADER ---
                Container(
                  width: double.infinity,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                        child: HodHeader(
                          title: "Internal Marks",
                          userId: widget.userId,
                          isWhite: true,
                          showBackButton: true,
                          showDate: false,
                        ),
                      ),
                      // Breadcrumb
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 8, 40, 0),
                        child: Row(
                          children: [
                            _breadcrumb("Home"),
                            _breadcrumbSep(),
                            _breadcrumb("My Classes"),
                            _breadcrumbSep(),
                            _breadcrumb("Internal Marks", isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Batch tabs
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white60,
                          tabs: _batches
                              .map((b) => Tab(text: b['name']))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // --- TAB BODY ---
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _batches
                        .map((batch) => _buildBatchTab(batch))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchTab(Map<String, dynamic> batch) {
    final col = batch['collection'] as String;
    final color = batch['color'] as Color;

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection(col).snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        final filtered = docs.where((d) {
          if (_searchQuery.isEmpty) return true;
          final data = d.data() as Map<String, dynamic>;
          final name = (data['name'] ?? '').toString().toLowerCase();
          final roll = (data['rollNo'] ?? '').toString().toLowerCase();
          return name.contains(_searchQuery) || roll.contains(_searchQuery);
        }).toList();

        // Stats
        double avg = 0;
        int highest = 0;
        int lowest = 0;
        if (docs.isNotEmpty) {
          final marks = docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return (data['internalMark'] ?? 0) as int;
          }).toList();
          avg = marks.reduce((a, b) => a + b) / marks.length;
          highest = marks.reduce((a, b) => a > b ? a : b);
          lowest = marks.reduce((a, b) => a < b ? a : b);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- STATS ROW ---
              Row(
                children: [
                  _statCard(
                    "Average Score",
                    avg.toStringAsFixed(1),
                    Icons.analytics_rounded,
                    const Color(0xFFEFF6FF),
                    const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 20),
                  _statCard(
                    "Highest Score",
                    highest.toString(),
                    Icons.emoji_events_rounded,
                    const Color(0xFFF0FDF4),
                    const Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 20),
                  _statCard(
                    "Lowest Score",
                    lowest.toString(),
                    Icons.warning_amber_rounded,
                    const Color(0xFFFFF1F2),
                    const Color(0xFFF43F5E),
                  ),
                  const SizedBox(width: 20),
                  _statCard(
                    "Total Students",
                    docs.length.toString(),
                    Icons.groups_rounded,
                    const Color(0xFFF5F3FF),
                    color,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- MAIN CARD ---
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF001FF4).withOpacity(0.06),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Action Bar
                    _buildActionBar(col, docs, batch),
                    const Divider(height: 1, color: Color(0xFFF1F5F9)),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            setState(() => _searchQuery = v.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: "Search by name or roll number...",
                          hintStyle: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Color(0xFF94A3B8),
                          ),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: color, width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- TABLE HEADER ---
                    _buildTableHeader(color),

                    // --- ROWS ---
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      _buildEmptyState()
                    else
                      ...filtered.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildStudentRow(doc.id, data, col, color);
                      }),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader(Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _headerCell("Roll No", flex: 1),
          _headerCell("Name", flex: 3),
          _headerCell("Reg No", flex: 2),
          _headerCell("Attendance %", flex: 2),
          _headerCell("Assignments", flex: 2),
          _headerCell("Series Tests", flex: 2),
          _headerCell("Internal Mark", flex: 2),
          _headerCell("Actions", flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStudentRow(
    String docId,
    Map<String, dynamic> data,
    String collection,
    Color color,
  ) {
    final mark = (data['internalMark'] ?? 0) as int;
    Color markColor = mark >= 40
        ? const Color(0xFF10B981)
        : mark >= 30
        ? const Color(0xFFF59E0B)
        : const Color(0xFFF43F5E);

    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 1),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          _rowCell(data['rollNo']?.toString() ?? '-', flex: 1, bold: true),
          _rowCell(
            data['name']?.toString() ?? '-',
            flex: 3,
            align: TextAlign.left,
          ),
          _rowCell(
            data['regNo']?.toString() ?? '-',
            flex: 2,
            color: const Color(0xFF64748B),
          ),
          _rowCell("${data['attendance'] ?? 0}%", flex: 2),
          _rowCell("${data['assignments'] ?? 0}", flex: 2),
          _rowCell("${data['seriesTests'] ?? 0}", flex: 2),
          // MARK CHIP
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: markColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  mark.toString(),
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: markColor,
                  ),
                ),
              ),
            ),
          ),
          // ACTIONS
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionIcon(Icons.edit_outlined, const Color(0xFF6366F1), () {
                  _showEditDialog(docId, data, collection, color);
                }),
                const SizedBox(width: 8),
                _actionIcon(
                  Icons.delete_outline_rounded,
                  const Color(0xFFF43F5E),
                  () {
                    _confirmDelete(
                      docId,
                      collection,
                      data['name'] ?? 'Student',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowCell(
    String text, {
    int flex = 1,
    bool bold = false,
    TextAlign align = TextAlign.center,
    Color? color,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: align,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          color: color ?? const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 17, color: color),
      ),
    );
  }

  void _showEditDialog(
    String docId,
    Map<String, dynamic> data,
    String collection,
    Color color,
  ) {
    final attCtrl = TextEditingController(
      text: (data['attendance'] ?? 0).toString(),
    );
    final assignCtrl = TextEditingController(
      text: (data['assignments'] ?? 0).toString(),
    );
    final seriesCtrl = TextEditingController(
      text: (data['seriesTests'] ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Marks",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                Text(
                  data['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        content: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _editField("Attendance (%)", attCtrl, color),
              const SizedBox(height: 16),
              _editField("Assignments (max 20)", assignCtrl, color),
              const SizedBox(height: 16),
              _editField("Series Tests (max 20)", seriesCtrl, color),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: () async {
              final att = int.tryParse(attCtrl.text) ?? 0;
              final assign = int.tryParse(assignCtrl.text) ?? 0;
              final series = int.tryParse(seriesCtrl.text) ?? 0;
              final internal = ((att / 10) + assign + series).round().clamp(
                0,
                50,
              );
              await _firestore.collection(collection).doc(docId).update({
                'attendance': att,
                'assignments': assign,
                'seriesTests': series,
                'internalMark': internal,
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(
              "Save",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(String docId, String collection, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFF43F5E)),
            const SizedBox(width: 12),
            Text(
              "Delete Record?",
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to delete the marks record for $name? This action cannot be undone.",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF43F5E),
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: () async {
              await _firestore.collection(collection).doc(docId).delete();
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(
    String collection,
    List<QueryDocumentSnapshot> docs,
    Map<String, dynamic> batch,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          _actionBtn(
            Icons.add_rounded,
            "Add Student",
            const Color(0xFFEFF6FF),
            const Color(0xFF3B82F6),
            () {
              _showAddDialog(collection, batch['color'] as Color);
            },
          ),
          const SizedBox(width: 12),
          _actionBtn(
            Icons.settings_outlined,
            "Calculation Settings",
            const Color(0xFFF8FAFC),
            const Color(0xFF1E293B),
            _showCalcSettings,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "DOWNLOADS",
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _downloadBtn(
                    Icons.picture_as_pdf_outlined,
                    "PDF",
                    () => _generateReport(docs, 'PDF'),
                  ),
                  const SizedBox(width: 8),
                  _downloadBtn(
                    Icons.table_view_outlined,
                    "Excel",
                    () => _generateReport(docs, 'Excel'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    IconData icon,
    String label,
    Color bg,
    Color fg,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: fg.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: fg),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _downloadBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(String collection, Color color) {
    final nameCtrl = TextEditingController();
    final rollCtrl = TextEditingController();
    final regCtrl = TextEditingController();
    final attCtrl = TextEditingController(text: '80');
    final assignCtrl = TextEditingController(text: '15');
    final seriesCtrl = TextEditingController(text: '18');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Add Student Record",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _editField("Student Name", nameCtrl, color),
                const SizedBox(height: 16),
                _editField("Roll Number", rollCtrl, color),
                const SizedBox(height: 16),
                _editField("Registration Number", regCtrl, color),
                const SizedBox(height: 16),
                _editField("Attendance (%)", attCtrl, color),
                const SizedBox(height: 16),
                _editField("Assignments (max 20)", assignCtrl, color),
                const SizedBox(height: 16),
                _editField("Series Tests (max 20)", seriesCtrl, color),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              final att = int.tryParse(attCtrl.text) ?? 0;
              final assign = int.tryParse(assignCtrl.text) ?? 0;
              final series = int.tryParse(seriesCtrl.text) ?? 0;
              final internal = ((att / 10) + assign + series).round().clamp(
                0,
                50,
              );
              final regNo = regCtrl.text.trim().isNotEmpty
                  ? regCtrl.text.trim()
                  : 'REG${DateTime.now().millisecondsSinceEpoch}';
              await _firestore.collection(collection).doc(regNo).set({
                'name': nameCtrl.text.trim(),
                'rollNo': rollCtrl.text.trim(),
                'regNo': regNo,
                'attendance': att,
                'assignments': assign,
                'seriesTests': series,
                'internalMark': internal,
              });
              if (mounted) Navigator.pop(ctx);
            },
            child: Text(
              "Add",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalcSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.settings, color: Color(0xFF001FF4)),
            const SizedBox(width: 12),
            Text(
              "Calculation Settings",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _settingsRow("Attendance Weightage", "10%"),
              const Divider(),
              _settingsRow("Assignments Weightage", "20 marks"),
              const Divider(),
              _settingsRow("Series Tests Weightage", "20 marks"),
              const Divider(),
              _settingsRow("Total Internal Mark", "50 marks"),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "Formula: Internal = (Attendance/10) + Assignments + Series Tests",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF0369A1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _settingsRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF475569),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF001FF4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(
    List<QueryDocumentSnapshot> docs,
    String format,
  ) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("📥 Generating $format report..."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF001FF4),
      ),
    );
    final rows = docs.map((d) => d.data() as Map<String, dynamic>).toList();
    rows.sort(
      (a, b) => (a['rollNo'] ?? '').toString().compareTo(
        (b['rollNo'] ?? '').toString(),
      ),
    );
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        build: (ctx) => [
          pw.Text(
            "Internal Marks Report — ${DateTime.now().year}",
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: [
              'Roll No',
              'Name',
              'Reg No',
              'Attendance %',
              'Assignments',
              'Series Tests',
              'Internal Mark',
            ],
            data: rows
                .map(
                  (r) => [
                    r['rollNo'],
                    r['name'],
                    r['regNo'],
                    '${r['attendance']}%',
                    r['assignments'],
                    r['seriesTests'],
                    r['internalMark'],
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo50),
            cellAlignment: pw.Alignment.center,
          ),
        ],
      ),
    );
    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(60),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              "No records found",
              style: GoogleFonts.inter(
                fontSize: 16,
                color: const Color(0xFF94A3B8),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color bg,
    Color fg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
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
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 22),
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
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 22,
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
  }

  Widget _breadcrumb(String label, {bool isLast = false}) => Text(
    label,
    style: GoogleFonts.inter(
      color: isLast ? Colors.white : Colors.white70,
      fontSize: 12,
      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
    ),
  );

  Widget _breadcrumbSep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 14),
  );
}
