import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/staff_sidebar.dart';
import '../widgets/staff_header.dart';

class CoursePlanScreen extends StatefulWidget {
  final String userId;
  final String subjectCode;
  final String subjectName;
  const CoursePlanScreen({
    super.key,
    required this.userId,
    this.subjectCode = '',
    this.subjectName = '',
  });

  @override
  State<CoursePlanScreen> createState() => _CoursePlanScreenState();
}

class _CoursePlanScreenState extends State<CoursePlanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffSidebar(activeIndex: -1, userId: widget.userId),
          Expanded(
            child: Stack(
              children: [
                // --- Premium Aurora Background ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 380,
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
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                      child: StaffHeader(
                        title: "Course Plan",
                        userId: widget.userId,
                        showBackButton: true,
                        isWhite: true,
                        showDate: false,
                      ),
                    ),
                    _buildBreadcrumbs(),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(40, 12, 40, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildActionBar(),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Column: Slots
                                Expanded(
                                  flex: 4,
                                  child: _buildDeliveriesSection(),
                                ),
                                const SizedBox(width: 40),
                                // Right Column: Outline
                                Expanded(
                                  flex: 3,
                                  child: _buildOutlineSection(),
                                ),
                              ],
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

  Widget _buildBreadcrumbs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        children: [
          _breadcrumbItem("Home"),
          _breadcrumbSeparator(),
          _breadcrumbItem("My Classes"),
          _breadcrumbSeparator(),
          _breadcrumbItem("MCA 2025 - 1st semester"),
          _breadcrumbSeparator(),
          _breadcrumbItem("${widget.subjectCode} - ${widget.subjectName}"),
          _breadcrumbSeparator(),
          _breadcrumbItem("Course Plan", isLast: true),
        ],
      ),
    );
  }

  Widget _breadcrumbItem(String text, {bool isLast = false}) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
        color: isLast ? Colors.white : Colors.white.withOpacity(0.7),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _breadcrumbSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 14,
        color: Colors.white.withOpacity(0.4),
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          // Glassmorphic Custom TabBar
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                _tabItem("Syllabus", Icons.description_outlined, 0),
                _tabItem("Subject Plan", Icons.grid_view_rounded, 1),
                _tabItem(
                  "Subject Coverage",
                  Icons.assignment_turned_in_outlined,
                  2,
                ),
                _tabItem("Source Books", Icons.menu_book_outlined, 3),
              ],
            ),
          ),
          const Spacer(),
          // Action Buttons
          _actionButton(
            Icons.info_outline,
            "Instructions",
            const Color(0xFFD97706),
            const Color(0xFFFFFBEB),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String text, IconData icon, int index) {
    bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.index = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFF001FF4)
                  : Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF001FF4)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveriesSection() {
    return Column(
      children: [
        // Glassmorphic Legend & Header Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _legendItem(const Color(0xFF10B981), "Timetable Hour"),
              const SizedBox(width: 24),
              _legendItem(const Color(0xFF3B82F6), "Extra/Special Class"),
              const SizedBox(width: 24),
              _legendItem(const Color(0xFFEF4444), "Untracked"),
              const Spacer(),
              GestureDetector(
                onTap: _showViewStatusDialog,
                child: _outlineActionBtn(
                  Icons.visibility_outlined,
                  "View Status",
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _exportToPdf,
                child: _outlineActionBtn(
                  Icons.file_download_outlined,
                  "Export",
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        // Slots Grid — also a DragTarget for dropped outline topics
        DragTarget<Map<String, dynamic>>(
          onAcceptWithDetails: (details) {
            _showAddDeliveryDialog(prefillTopic: details.data['title']);
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: isHovering ? const EdgeInsets.all(12) : EdgeInsets.zero,
              decoration: isHovering
                  ? BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF3B82F6),
                        width: 2,
                      ),
                    )
                  : null,
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('course_deliveries')
                    .where('subjectCode', isEqualTo: widget.subjectCode)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  final sortedDocs = List.from(docs);
                  sortedDocs.sort((a, b) {
                    final aDate = (a.data() as Map)['date'] as Timestamp;
                    final bDate = (b.data() as Map)['date'] as Timestamp;
                    return bDate.compareTo(aDate);
                  });

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isHovering)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.drag_indicator_rounded,
                                color: Color(0xFF3B82F6),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Drop topic to create a slot",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF3B82F6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...sortedDocs.map((doc) => _buildDeliveryCard(doc)),
                          _buildAddSlotCard(),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _outlineActionBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF1E293B)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  // ── View Status ──────────────────────────────────────────────
  void _showViewStatusDialog() async {
    final deliveries = await _db
        .collection('course_deliveries')
        .where('subjectCode', isEqualTo: widget.subjectCode)
        .get();
    final outlines = await _db
        .collection('course_outlines')
        .where('subjectCode', isEqualTo: widget.subjectCode)
        .get();

    final allDocs = deliveries.docs
        .map((d) => d.data() as Map<String, dynamic>)
        .toList();
    final totalSlots = allDocs.length;
    final covered = allDocs.where((d) => d['isCovered'] == true).length;
    final uncovered = totalSlots - covered;
    final totalHours = allDocs.fold<int>(
      0,
      (sum, d) => sum + (int.tryParse(d['hour']?.toString() ?? '0') ?? 0),
    );
    final totalOutlineTopics = outlines.docs.length;
    final coveredTopics = outlines.docs
        .where((d) => (d.data() as Map)['isCovered'] == true)
        .length;
    final coveragePct = totalOutlineTopics == 0
        ? 0.0
        : coveredTopics / totalOutlineTopics;
    final slotCoveragePct = totalSlots == 0 ? 0.0 : covered / totalSlots;

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Course Delivery Status",
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            Text(
              "${widget.subjectCode} · ${widget.subjectName}",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),
            // Stat cards row
            Row(
              children: [
                _statCard(
                  "Total Slots",
                  "$totalSlots",
                  Icons.layers_rounded,
                  const Color(0xFF3B82F6),
                ),
                const SizedBox(width: 12),
                _statCard(
                  "Covered",
                  "$covered",
                  Icons.check_circle_rounded,
                  const Color(0xFF10B981),
                ),
                const SizedBox(width: 12),
                _statCard(
                  "Uncovered",
                  "$uncovered",
                  Icons.pending_rounded,
                  const Color(0xFFF97316),
                ),
                const SizedBox(width: 12),
                _statCard(
                  "Total Hours",
                  "$totalHours h",
                  Icons.schedule_rounded,
                  const Color(0xFF8B5CF6),
                ),
              ],
            ),
            const SizedBox(height: 28),
            // Slot coverage bar
            _statusProgressBar(
              "Slot Coverage",
              slotCoveragePct,
              "$covered of $totalSlots slots covered",
              const Color(0xFF10B981),
            ),
            const SizedBox(height: 16),
            // Outline topic coverage bar
            _statusProgressBar(
              "Syllabus Coverage",
              coveragePct,
              "$coveredTopics of $totalOutlineTopics topics covered",
              const Color(0xFF3B82F6),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusProgressBar(
    String title,
    double pct,
    String subtitle,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              "${(pct * 100).toStringAsFixed(0)}%",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // ── Export to PDF ─────────────────────────────────────────────
  Future<void> _exportToPdf() async {
    final deliverySnap = await _db
        .collection('course_deliveries')
        .where('subjectCode', isEqualTo: widget.subjectCode)
        .get();
    final outlineSnap = await _db
        .collection('course_outlines')
        .where('subjectCode', isEqualTo: widget.subjectCode)
        .get();

    final deliveries =
        deliverySnap.docs.map((d) => d.data() as Map<String, dynamic>).toList()
          ..sort((a, b) {
            final aTs = a['date'] as Timestamp;
            final bTs = b['date'] as Timestamp;
            return aTs.compareTo(bTs);
          });

    final outlines =
        outlineSnap.docs.map((d) => d.data() as Map<String, dynamic>).toList()
          ..sort(
            (a, b) =>
                ((a['order'] ?? 0) as int).compareTo((b['order'] ?? 0) as int),
          );

    final pdf = pw.Document();
    final headerColor = PdfColor.fromHex('#001FF4');
    final lightBlue = PdfColor.fromHex('#EFF6FF');
    final slate = PdfColor.fromHex('#64748B');
    final dark = PdfColor.fromHex('#0F172A');
    final green = PdfColor.fromHex('#10B981');
    final orange = PdfColor.fromHex('#F97316');
    final divider = PdfColor.fromHex('#E2E8F0');

    final df = DateFormat('dd MMM yyyy');
    final now = DateFormat('dd MMM yyyy, h:mm a').format(DateTime.now());

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: headerColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        "Course Plan Report",
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        "${widget.subjectCode} · ${widget.subjectName}",
                        style: pw.TextStyle(
                          color: const PdfColor(1, 1, 1, 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  pw.Text(
                    "Generated: $now",
                    style: pw.TextStyle(
                      color: const PdfColor(1, 1, 1, 0.7),
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
          ],
        ),
        build: (ctx) => [
          // ── Delivery Records ──
          pw.Text(
            "Course Deliveries",
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: dark,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: divider, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(28),
              1: const pw.FixedColumnWidth(70),
              2: const pw.FixedColumnWidth(30),
              3: const pw.FlexColumnWidth(),
              4: const pw.FixedColumnWidth(36),
              5: const pw.FixedColumnWidth(55),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: lightBlue),
                children: [
                  _pdfCell("Slot", bold: true, color: slate),
                  _pdfCell("Date", bold: true, color: slate),
                  _pdfCell("Hrs", bold: true, color: slate),
                  _pdfCell("Topic", bold: true, color: slate),
                  _pdfCell("Type", bold: true, color: slate),
                  _pdfCell("Status", bold: true, color: slate),
                ],
              ),
              ...deliveries.map((d) {
                final isCovered = d['isCovered'] == true;
                final dateStr = d['date'] != null
                    ? df.format((d['date'] as Timestamp).toDate())
                    : '-';
                return pw.TableRow(
                  children: [
                    _pdfCell(d['slot']?.toString() ?? '-'),
                    _pdfCell(dateStr),
                    _pdfCell(d['hour']?.toString() ?? '-'),
                    _pdfCell(d['topic'] ?? '-'),
                    _pdfCell(d['type'] ?? '-'),
                    _pdfCell(
                      isCovered ? 'Covered' : 'Uncovered',
                      color: isCovered ? green : orange,
                      bold: true,
                    ),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 24),
          // ── Course Outline ──
          pw.Text(
            "Course Outline",
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: dark,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder(
              horizontalInside: pw.BorderSide(color: divider, width: 0.5),
            ),
            columnWidths: {
              0: const pw.FixedColumnWidth(36),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(3),
              3: const pw.FixedColumnWidth(38),
              4: const pw.FixedColumnWidth(55),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: lightBlue),
                children: [
                  _pdfCell("ID", bold: true, color: slate),
                  _pdfCell("Title", bold: true, color: slate),
                  _pdfCell("Description", bold: true, color: slate),
                  _pdfCell("Dur.", bold: true, color: slate),
                  _pdfCell("Status", bold: true, color: slate),
                ],
              ),
              ...outlines.map((d) {
                final isCovered = d['isCovered'] == true;
                return pw.TableRow(
                  children: [
                    _pdfCell(d['id'] ?? '-'),
                    _pdfCell(d['title'] ?? '-'),
                    _pdfCell(d['desc'] ?? '-'),
                    _pdfCell(d['duration'] ?? '-'),
                    _pdfCell(
                      isCovered ? 'Done' : 'Pending',
                      color: isCovered ? green : orange,
                      bold: true,
                    ),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    if (!mounted) return;
    await Printing.layoutPdf(
      onLayout: (_) async => pdf.save(),
      name: 'course_plan_${widget.subjectCode}_$now.pdf',
    );
  }

  pw.Widget _pdfCell(String text, {bool bold = false, PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? const PdfColor.fromInt(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();
    final status = data['status'] ?? 'Untracked';
    final type = data['type'] ?? 'Regular';
    final isCovered = data['isCovered'] ?? false;

    Color accentColor;
    if (status == 'Timetable Hour') {
      accentColor = const Color(0xFF10B981);
    } else if (type == 'Extra') {
      accentColor = const Color(0xFF3B82F6);
    } else {
      accentColor = const Color(0xFFEF4444);
    }

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isCovered
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header with Dynamic Accent Color
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: isCovered ? const Color(0xFF10B981) : accentColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date row
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      size: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEE, MMM d yyyy').format(date).toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Slot + Status
                Row(
                  children: [
                    Text(
                      "Slot ${data['slot']}",
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: accentColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Topic Covered box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isCovered
                        ? const Color(0xFFF0FDF4)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isCovered
                          ? const Color(0xFF10B981).withValues(alpha: 0.3)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isCovered
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                            size: 12,
                            color: isCovered
                                ? const Color(0xFF10B981)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isCovered ? "TOPIC COVERED" : "TOPIC UNCOVERED",
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isCovered
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['topic'] ?? 'No topic set',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Hour + Type row
                Row(
                  children: [
                    _infoBadge("Hours", data['hour']?.toString() ?? '-'),
                    const Spacer(),
                    _typeBadge(data['type'] ?? 'Regular'),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),
                // Covered/Uncovered Toggle
                GestureDetector(
                  onTap: () {
                    doc.reference.update({'isCovered': !isCovered});
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isCovered
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isCovered
                            ? const Color(0xFF10B981).withValues(alpha: 0.4)
                            : const Color(0xFFF97316).withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCovered
                              ? Icons.visibility_off_rounded
                              : Icons.check_circle_outline_rounded,
                          size: 16,
                          color: isCovered
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF97316),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCovered ? "Mark as Uncovered" : "Mark as Covered",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCovered
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF97316),
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

  Widget _infoBadge(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _typeBadge(String type) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          "Type",
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.check_circle, size: 14, color: Color(0xFF001FF4)),
            const SizedBox(width: 4),
            Text(
              type,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label, {bool isWarning = false}) {
    return Column(
      children: [
        Icon(
          icon,
          size: 18,
          color: isWarning ? const Color(0xFFF43F5E) : const Color(0xFF94A3B8),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isWarning
                ? const Color(0xFFF43F5E)
                : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildAddSlotCard() {
    return GestureDetector(
      onTap: _showAddDeliveryDialog,
      child: Container(
        width: 200,
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            style: BorderStyle.solid,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF001FF4),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Add Next Slot",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.06),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_mosaic_rounded,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  "Course Outline",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                _countBadge("14 Left"),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                // Search Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      icon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF94A3B8),
                        size: 20,
                      ),
                      hintText: "Search topics...",
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Topics List
                StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('course_outlines')
                      .where('subjectCode', isEqualTo: widget.subjectCode)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    final docs = snapshot.data?.docs ?? [];
                    // Sort client-side by order
                    final sortedDocs = List.from(docs);
                    sortedDocs.sort((a, b) {
                      final aOrder = (a.data() as Map)['order'] ?? 0;
                      final bOrder = (b.data() as Map)['order'] ?? 0;
                      return aOrder.compareTo(bOrder);
                    });

                    final filtered = sortedDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['title'].toString().toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }).toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _buildOutlineItem(filtered[index]),
                    );
                  },
                ),
                const SizedBox(height: 32),
                // Add Topic Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddTopicDialog,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                    ),
                    label: const Text("Add Custom Topic"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
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

  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildOutlineItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isCovered = data['isCovered'] ?? false;

    return Draggable<Map<String, dynamic>>(
      data: {'title': data['title'], 'id': data['id']},
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF001FF4), Color(0xFF4F46E5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.drag_indicator_rounded,
                color: Colors.white70,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data['title'],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.4,
        child: _buildOutlineItemContent(data, isCovered, doc),
      ),
      child: _buildOutlineItemContent(data, isCovered, doc),
    );
  }

  Widget _buildOutlineItemContent(
    Map<String, dynamic> data,
    bool isCovered,
    DocumentSnapshot doc,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isCovered ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCovered
              ? const Color(0xFF10B981).withValues(alpha: 0.4)
              : const Color(0xFFF1F5F9),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.drag_indicator_rounded,
              color: const Color(0xFFCBD5E1),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCovered
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data['id'],
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isCovered
                              ? const Color(0xFF16A34A)
                              : const Color(0xFF001FF4),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      data['duration'],
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    if (isCovered) ...[
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 16,
                        color: Color(0xFF10B981),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  data['title'],
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isCovered
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF1E293B),
                    decoration: isCovered ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data['desc'],
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDeliveryDialog({String? prefillTopic}) {
    final topicController = TextEditingController(text: prefillTopic ?? '');
    final slotController = TextEditingController();
    final hourController = TextEditingController(text: '1');
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Add Delivery Record",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Picker
                Text(
                  "Class Date",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF001FF4),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEEE, MMM d yyyy').format(selectedDate),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: const Color(0xFF001FF4),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.edit_rounded,
                          color: Color(0xFF001FF4),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Slot number
                TextField(
                  controller: slotController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Slot Number",
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                // Topic covered
                TextField(
                  controller: topicController,
                  decoration: InputDecoration(
                    labelText: "Topic Covered",
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 12),
                // Hours
                TextField(
                  controller: hourController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Hours",
                    labelStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001FF4),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              onPressed: () {
                if (topicController.text.trim().isEmpty) return;
                _db.collection('course_deliveries').add({
                  'subjectCode': widget.subjectCode,
                  'date': Timestamp.fromDate(selectedDate),
                  'slot': slotController.text.trim().isEmpty
                      ? '1'
                      : slotController.text.trim(),
                  'topic': topicController.text.trim(),
                  'hour': hourController.text.trim().isEmpty
                      ? '1'
                      : hourController.text.trim(),
                  'type': 'Extra',
                  'status': 'Untracked',
                  'isCovered': false,
                  'timestamp': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              },
              child: Text(
                "Save",
                style: GoogleFonts.inter(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTopicDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Custom Topic"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: "Topic Title"),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: "Description"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _db.collection('course_outlines').add({
                'subjectCode': widget.subjectCode,
                'id': 'Custom',
                'title': titleController.text,
                'desc': descController.text,
                'duration': 'N/A',
                'isCompleted': false,
                'order': 99,
              });
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

