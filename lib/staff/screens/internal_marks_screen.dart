import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../widgets/staff_sidebar.dart';
import '../widgets/staff_header.dart';

class InternalMarksScreen extends StatefulWidget {
  final String userId;
  const InternalMarksScreen({super.key, required this.userId});

  @override
  State<InternalMarksScreen> createState() => _InternalMarksScreenState();
}

class _InternalMarksScreenState extends State<InternalMarksScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _seedStudents();
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
                        title: "Internal Marks",
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
                          _buildBreadcrumb("Home"),
                          _buildBreadcrumbSeparator(),
                          _buildBreadcrumb("My Classes"),
                          _buildBreadcrumbSeparator(),
                          _buildBreadcrumb("MCA - 1st semester"),
                          _buildBreadcrumbSeparator(),
                          _buildBreadcrumb("Internal Marks", isLast: true),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(40, 20, 40, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Live Stats Overview Cards
                            StreamBuilder<QuerySnapshot>(
                              stream: _firestore
                                  .collection('internal_marks')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                double avg = 0;
                                int highest = 0;
                                int lowest = 0;

                                if (snapshot.hasData &&
                                    snapshot.data!.docs.isNotEmpty) {
                                  final docs = snapshot.data!.docs;
                                  final marks = docs.map((d) {
                                    final data =
                                        d.data() as Map<String, dynamic>;
                                    return (data['internalMark'] ?? 0) as int;
                                  }).toList();
                                  highest = marks.reduce(
                                    (a, b) => a > b ? a : b,
                                  );
                                  lowest = marks.reduce(
                                    (a, b) => a < b ? a : b,
                                  );
                                  avg =
                                      marks.reduce((a, b) => a + b) /
                                      marks.length;
                                }

                                return Row(
                                  children: [
                                    _buildStatCard(
                                      "Average Score",
                                      avg.toStringAsFixed(1),
                                      Icons.analytics_rounded,
                                      const Color(0xFFEFF6FF),
                                      const Color(0xFF3B82F6),
                                    ),
                                    const SizedBox(width: 24),
                                    _buildStatCard(
                                      "Highest Score",
                                      "$highest",
                                      Icons.emoji_events_rounded,
                                      const Color(0xFFF0FDF4),
                                      const Color(0xFF22C55E),
                                    ),
                                    const SizedBox(width: 24),
                                    _buildStatCard(
                                      "Lowest Score",
                                      "$lowest",
                                      Icons.warning_amber_rounded,
                                      const Color(0xFFFFF1F2),
                                      const Color(0xFFF43F5E),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // Main Glass Card
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
                                children: [
                                  // Action Buttons & Downloads
                                  _buildActionBar(),
                                  const Divider(
                                    height: 1,
                                    color: Color(0xFFF1F5F9),
                                  ),

                                  // Student List Container
                                  _buildStudentListContainer(),
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

  Widget _buildBreadcrumb(String label, {bool isLast = false}) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        color: isLast ? Colors.white : Colors.white.withOpacity(0.7),
        fontSize: 12,
        fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildBreadcrumbSeparator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Icon(
        Icons.chevron_right_rounded,
        color: Colors.white.withOpacity(0.5),
        size: 14,
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgColor,
    Color iconColor,
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
              decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
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
  }

  Widget _buildActionBar() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Left Actions
          _buildActionButton(
            Icons.lock_outline_rounded,
            "Revert Attendance Lock",
            const Color(0xFFFEE2E2),
            const Color(0xFFEF4444),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            Icons.settings_outlined,
            "Calculation Settings",
            const Color(0xFFF8FAFC),
            const Color(0xFF1E293B),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            Icons.info_outline_rounded,
            "Instructions",
            const Color(0xFFF8FAFC),
            const Color(0xFF1E293B),
          ),

          const Spacer(),

          // Download Group
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "DOWNLOADS",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildDownloadButton(
                    Icons.description_outlined,
                    "KTU Format",
                    () => _generateReport("KTU"),
                  ),
                  const SizedBox(width: 8),
                  _buildDownloadButton(
                    Icons.picture_as_pdf_outlined,
                    "PDF",
                    () => _generateReport("PDF"),
                  ),
                  const SizedBox(width: 8),
                  _buildDownloadButton(
                    Icons.table_view_outlined,
                    "Excel",
                    () => _generateReport("Excel"),
                  ),
                  const SizedBox(width: 8),
                  _buildDownloadButton(
                    Icons.list_alt_rounded,
                    "Detailed",
                    () => _generateReport("Detailed"),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _generateReport(String format) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("📥 Generating $format report..."),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF001FF4),
      ),
    );

    // Fetch current marks data
    final snapshot = await _firestore
        .collection('internal_marks')
        .snapshots()
        .first;
    final studentSnapshot = await _firestore
        .collection('students')
        .snapshots()
        .first;

    final Map<String, Map<String, dynamic>> studentMap = {
      for (var doc in studentSnapshot.docs)
        doc.id: doc.data() as Map<String, dynamic>,
    };

    final List<Map<String, dynamic>> rows = [];
    for (var doc in snapshot.docs) {
      final marks = doc.data() as Map<String, dynamic>;
      final student = studentMap[doc.id] ?? {};
      rows.add({
        'rollNo': student['rollNo'] ?? doc.id.split('-').last,
        'name': student['name'] ?? 'Unknown',
        'regNo': doc.id,
        'attendance': marks['attendance'] ?? 0,
        'assignments': marks['assignments'] ?? 0,
        'seriesTests': marks['seriesTests'] ?? 0,
        'internalMark': marks['internalMark'] ?? 0,
      });
    }

    // Sort by rollNo
    rows.sort(
      (a, b) => (a['rollNo'] ?? '').toString().compareTo(
        (b['rollNo'] ?? '').toString(),
      ),
    );

    if (format == "PDF" || format == "KTU" || format == "Detailed") {
      await _generatePDF(rows, format);
    } else if (format == "Excel") {
      await _generateCSV(rows);
    }
  }

  Future<void> _generatePDF(
    List<Map<String, dynamic>> rows,
    String format,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                format == "KTU"
                    ? 'Internal Marks - KTU Format'
                    : format == "Detailed"
                    ? 'Detailed Internal Marks Report'
                    : 'Internal Marks Report',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Department: MCA  |  Semester: 1  |  Generated: ${DateTime.now().toString().split('.').first}',
            ),
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blue50),
              cellAlignment: pw.Alignment.center,
              headers: format == "Detailed"
                  ? [
                      'Roll No',
                      'Name',
                      'Reg No',
                      'Att %',
                      'Assign',
                      'Series',
                      'Internal',
                      'Grade',
                    ]
                  : [
                      'Roll No',
                      'Name',
                      'Att %',
                      'Assign',
                      'Series',
                      'Internal Mark',
                    ],
              data: rows.map((r) {
                final mark = r['internalMark'] as int;
                if (format == "Detailed") {
                  String grade = mark >= 45
                      ? 'A+'
                      : mark >= 40
                      ? 'A'
                      : mark >= 35
                      ? 'B+'
                      : mark >= 30
                      ? 'B'
                      : 'C';
                  return [
                    r['rollNo'].toString(),
                    r['name'].toString(),
                    r['regNo'].toString(),
                    '${r['attendance']}%',
                    r['assignments'].toString(),
                    r['seriesTests'].toString(),
                    mark.toString(),
                    grade,
                  ];
                }
                return [
                  r['rollNo'].toString(),
                  r['name'].toString(),
                  '${r['attendance']}%',
                  r['assignments'].toString(),
                  r['seriesTests'].toString(),
                  mark.toString(),
                ];
              }).toList(),
            ),
            if (format == "Detailed") ...[
              pw.SizedBox(height: 24),
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Total Students: ${rows.length}'),
              pw.Text(
                'Class Average: ${rows.isEmpty ? 0 : (rows.map((r) => r['internalMark'] as int).reduce((a, b) => a + b) / rows.length).toStringAsFixed(1)}',
              ),
              pw.Text(
                'Highest Score: ${rows.isEmpty ? 0 : rows.map((r) => r['internalMark'] as int).reduce((a, b) => a > b ? a : b)}',
              ),
              pw.Text(
                'Lowest Score: ${rows.isEmpty ? 0 : rows.map((r) => r['internalMark'] as int).reduce((a, b) => a < b ? a : b)}',
              ),
            ],
          ];
        },
      ),
    );

    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Future<void> _generateCSV(List<Map<String, dynamic>> rows) async {
    // Build CSV content
    final buffer = StringBuffer();
    buffer.writeln(
      'Roll No,Name,Reg No,Attendance %,Assignments,Series Tests,Internal Mark',
    );
    for (var r in rows) {
      buffer.writeln(
        '${r['rollNo']},${r['name']},${r['regNo']},${r['attendance']},${r['assignments']},${r['seriesTests']},${r['internalMark']}',
      );
    }

    // Use printing to save as PDF with CSV content (fallback for Flutter web/desktop)
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Text(
                'Internal Marks - Excel Export',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 10,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.green50,
              ),
              cellAlignment: pw.Alignment.center,
              headers: [
                'Roll No',
                'Name',
                'Reg No',
                'Att %',
                'Assign',
                'Series',
                'Internal',
              ],
              data: rows
                  .map(
                    (r) => [
                      r['rollNo'].toString(),
                      r['name'].toString(),
                      r['regNo'].toString(),
                      '${r['attendance']}%',
                      r['assignments'].toString(),
                      r['seriesTests'].toString(),
                      r['internalMark'].toString(),
                    ],
                  )
                  .toList(),
            ),
          ];
        },
      ),
    );
    final Uint8List bytes = await pdf.save();
    await Printing.layoutPdf(onLayout: (_) => bytes);
  }

  Widget _buildActionButton(
    IconData icon,
    String label,
    Color bgColor,
    Color textColor,
  ) {
    return InkWell(
      onTap: () {
        if (label == "Revert Attendance Lock") {
          _confirmRevertLock();
        } else if (label == "Calculation Settings") {
          _showCalculationSettings();
        } else if (label == "Instructions") {
          _showInstructionsDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$label action triggered"),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmRevertLock() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Revert Attendance Lock?"),
        content: const Text(
          "This will allow students to modify their attendance for the current period.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Attendance lock reverted successfully"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showCalculationSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.settings, color: Color(0xFF001FF4)),
            const SizedBox(width: 12),
            Text(
              "Calculation Settings",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: GoogleFonts.plusJakartaSans(
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
            onPressed: () => Navigator.pop(context),
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
            style: GoogleFonts.plusJakartaSans(
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
              style: GoogleFonts.plusJakartaSans(
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

  void _showInstructionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFF001FF4)),
            const SizedBox(width: 12),
            Text(
              "Instructions",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SizedBox(
          width: 450,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _instructionStep(
                "1",
                "Click on any student row to edit their marks.",
              ),
              _instructionStep(
                "2",
                "Enter Attendance %, Assignment marks, and Series Test marks.",
              ),
              _instructionStep(
                "3",
                "The Internal Mark is automatically calculated using the formula.",
              ),
              _instructionStep(
                "4",
                "Use the Download buttons to export reports in PDF, KTU, or Excel format.",
              ),
              _instructionStep(
                "5",
                "Use 'Revert Attendance Lock' to unlock attendance editing for students.",
              ),
              _instructionStep(
                "6",
                "Search students using the search bar by name or registration number.",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!"),
          ),
        ],
      ),
    );
  }

  Widget _instructionStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF001FF4),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF475569)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentListContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Search Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Text(
                  "Student List",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                Container(
                  width: 300,
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: "Search by name or reg no...",
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: [
                _buildColHead("ROLL NO", flex: 1),
                _buildColHead("STUDENT NAME", flex: 2),
                _buildColHead("ATTENDANCE %", flex: 1, center: true),
                _buildColHead("ASSIGNMENTS", flex: 1, center: true),
                _buildColHead("SERIES TESTS", flex: 1, center: true),
                _buildColHead("INTERNAL MARK", flex: 1, center: true),
              ],
            ),
          ),

          // Combined Student and Marks Stream
          StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final students = studentSnapshot.data?.docs ?? [];

              if (students.isEmpty) {
                // Secondary fallback to students collection
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('students').snapshots(),
                  builder: (context, fallbackSnapshot) {
                    if (fallbackSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return _buildMarksStream(
                      context,
                      fallbackSnapshot.data?.docs ?? [],
                    );
                  },
                );
              }

              return _buildMarksStream(context, students);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMarksStream(
    BuildContext context,
    List<QueryDocumentSnapshot> students,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('internal_marks').snapshots(),
      builder: (context, marksSnapshot) {
        if (marksSnapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final marksList = marksSnapshot.data?.docs ?? [];
        final Map<String, Map<String, dynamic>> marksMap = {
          for (var doc in marksList) doc.id: doc.data() as Map<String, dynamic>,
        };

        // Filter students based on search query
        final filteredStudents = students.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['name'] ?? data['fullName'] ?? "")
              .toString()
              .toLowerCase();
          final regNo = (data['regNo'] ?? data['studentId'] ?? doc.id)
              .toString()
              .toLowerCase();
          return name.contains(_searchQuery.toLowerCase()) ||
              regNo.contains(_searchQuery.toLowerCase());
        }).toList();

        if (filteredStudents.isEmpty) return _buildEmptyState();

        return Column(
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredStudents.length,
              itemBuilder: (context, index) {
                final studentDoc = filteredStudents[index];
                final studentData = studentDoc.data() as Map<String, dynamic>;
                final String regNo =
                    studentData['regNo'] ??
                    studentData['studentId'] ??
                    studentDoc.id;

                // Merge student data with internal marks
                final markData =
                    marksMap[regNo] ??
                    {
                      'attendance': 0,
                      'assignments': 0,
                      'seriesTests': 0,
                      'internalMark': 0,
                    };

                final displayData = {
                  'rollNo': studentData['rollNo'] ?? regNo.split('-').last,
                  'name':
                      studentData['name'] ??
                      studentData['fullName'] ??
                      "Unknown",
                  'regNo': regNo,
                  ...markData,
                };

                return _buildStudentRow(displayData);
              },
            ),

            // Footer
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Text(
                    "Showing ${filteredStudents.length} of ${students.length} students",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _buildPaginationBtn("Previous"),
                  const SizedBox(width: 8),
                  _buildPaginationBtn("Next"),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColHead(String label, {int flex = 1, bool center = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: center ? TextAlign.center : TextAlign.left,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStudentRow(Map<String, dynamic> data) {
    return InkWell(
      onTap: () => _showEditMarksDialog(data),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: Text(
                data['rollNo'] ?? "-",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                data['name'] ?? "-",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "${data['attendance'] ?? 0}%",
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "${data['assignments'] ?? 0}",
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "${data['seriesTests'] ?? 0}",
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "${data['internalMark'] ?? 0}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF001FF4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditMarksDialog(Map<String, dynamic> data) {
    final attController = TextEditingController(
      text: (data['attendance'] ?? 0).toString(),
    );
    final assController = TextEditingController(
      text: (data['assignments'] ?? 0).toString(),
    );
    final serController = TextEditingController(
      text: (data['seriesTests'] ?? 0).toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Edit Marks: ${data['name']}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField("Attendance %", attController),
            const SizedBox(height: 12),
            _buildDialogField("Assignments", assController),
            const SizedBox(height: 12),
            _buildDialogField("Series Tests", serController),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final int attendance = int.tryParse(attController.text) ?? 0;
              final int assignments = int.tryParse(assController.text) ?? 0;
              final int series = int.tryParse(serController.text) ?? 0;

              // Simple calculation logic
              final int total = (attendance / 10 + assignments + series)
                  .round();

              await _firestore
                  .collection('internal_marks')
                  .doc(data['regNo'])
                  .set({
                    'attendance': attendance,
                    'assignments': assignments,
                    'seriesTests': series,
                    'internalMark': total,
                    'lastUpdated': FieldValue.serverTimestamp(),
                  });

              if (context.mounted) Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ Marks updated for ${data['name']}"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80),
      alignment: Alignment.center,
      child: Column(
        children: [
          Text(
            "No student data available.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _seedStudents,
            icon: const Icon(Icons.person_add_rounded),
            label: const Text("Seed Test Students"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001FF4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedStudents() async {
    final List<Map<String, dynamic>> mockStudents = [
      {
        'name': 'Roshan',
        'regNo': 'MCA001',
        'rollNo': '1',
        'department': 'MCA',
        'semester': '1',
        'role': 'student',
        'attendance': 95,
        'assignments': 19,
        'seriesTests': 18,
      },
      {
        'name': 'Abhidev',
        'regNo': 'MCA002',
        'rollNo': '2',
        'department': 'MCA',
        'semester': '1',
        'role': 'student',
        'attendance': 88,
        'assignments': 16,
        'seriesTests': 15,
      },
      {
        'name': 'Sruthi',
        'regNo': 'MCA003',
        'rollNo': '3',
        'department': 'MCA',
        'semester': '1',
        'role': 'student',
        'attendance': 92,
        'assignments': 18,
        'seriesTests': 17,
      },
      {
        'name': 'Adithyan',
        'regNo': 'MCA004',
        'rollNo': '4',
        'department': 'MCA',
        'semester': '1',
        'role': 'student',
        'attendance': 85,
        'assignments': 14,
        'seriesTests': 14,
      },
      {
        'name': 'Anjali',
        'regNo': 'MCA005',
        'rollNo': '5',
        'department': 'MCA',
        'semester': '1',
        'role': 'student',
        'attendance': 90,
        'assignments': 17,
        'seriesTests': 16,
      },
    ];

    try {
      final batch = _firestore.batch();
      for (var student in mockStudents) {
        // Add to students collection
        final studentRef = _firestore
            .collection('students')
            .doc(student['regNo']);
        batch.set(studentRef, {
          'name': student['name'],
          'regNo': student['regNo'],
          'rollNo': student['rollNo'],
          'department': student['department'],
          'semester': student['semester'],
          'role': student['role'],
        });

        // Add to users collection
        final userRef = _firestore.collection('users').doc(student['regNo']);
        batch.set(userRef, {
          'fullName': student['name'],
          'role': 'student',
          'department': 'MCA',
          'semester': '1',
        });

        // Add to internal_marks collection
        final int tot =
            ((student['attendance'] as int) / 10 +
                    (student['assignments'] as int) +
                    (student['seriesTests'] as int))
                .round();
        final markRef = _firestore
            .collection('internal_marks')
            .doc(student['regNo']);
        batch.set(markRef, {
          'attendance': student['attendance'],
          'assignments': student['assignments'],
          'seriesTests': student['seriesTests'],
          'internalMark': tot,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✅ Class data seeded with marks & roll numbers!"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("❌ Error seeding: $e"),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildPaginationBtn(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}
