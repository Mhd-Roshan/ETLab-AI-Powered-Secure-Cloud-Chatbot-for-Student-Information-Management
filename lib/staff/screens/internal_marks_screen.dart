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
                              stream: _firestore.collection('internal_marks').snapshots(),
                              builder: (context, marksSnap) {
                                return StreamBuilder<QuerySnapshot>(
                                  stream: _firestore.collection('attendance').snapshots(),
                                  builder: (context, attSnap) {
                                    return StreamBuilder<QuerySnapshot>(
                                      stream: _firestore.collection('obe_marks').snapshots(),
                                      builder: (context, obeSnap) {
                                        return StreamBuilder<QuerySnapshot>(
                                          stream: _firestore.collection('obe_evaluations').snapshots(),
                                          builder: (context, evalSnap) {
                                            double avg = 0;
                                            int highest = 0;
                                            int lowest = 0;

                                            if (marksSnap.hasData) {
                                              // 1. Process Metadata
                                              final Map<String, String> evalTypes = {};
                                              for (var doc in evalSnap.data?.docs ?? []) {
                                                final d = doc.data() as Map<String, dynamic>;
                                                evalTypes[doc.id] = d['type']?.toString() ?? 'Series Exam';
                                              }

                                              // 2. Process attendance
                                              final Map<String, List<num>> attMap = {};
                                              for (var doc in attSnap.data?.docs ?? []) {
                                                final d = doc.data() as Map<String, dynamic>;
                                                final sId = d['studentId']?.toString() ?? '';
                                                if (sId.isNotEmpty) {
                                                  attMap.putIfAbsent(sId, () => []);
                                                  final total = (d['total'] as num?)?.toDouble() ?? 0;
                                                  final present = (d['present'] as num?)?.toDouble() ?? 0;
                                                  if (total > 0) attMap[sId]!.add((present / total) * 100);
                                                }
                                              }

                                              // 3. Process OBE
                                              final Map<String, Map<String, List<double>>> obeMap = {};
                                              for (var doc in obeSnap.data?.docs ?? []) {
                                                final d = doc.data() as Map<String, dynamic>;
                                                final sId = d['studentId']?.toString() ?? d['rollNo']?.toString() ?? '';
                                                final eId = d['evaluationId']?.toString() ?? '';
                                                if (sId.isNotEmpty && eId.isNotEmpty) {
                                                  final type = evalTypes[eId] ?? 'Series Exam';
                                                  final score = double.tryParse(d['total']?.toString() ?? '0') ?? 0.0;
                                                  obeMap.putIfAbsent(sId, () => {});
                                                  obeMap[sId]!.putIfAbsent(type, () => []).add(score);
                                                }
                                              }

                                              final marksDocs = marksSnap.data!.docs;
                                              final List<int> allInternalMarks = [];

                                              // We check against known internal_marks documents
                                              // In a real scenario, we'd iterate over all students, 
                                              // but here we use the ones that have some marks data.
                                              for (var doc in marksDocs) {
                                                final data = doc.data() as Map<String, dynamic>;
                                                final sId = doc.id;
                                                
                                                // 1. Attendance Marks
                                                double attPercent = (data['attendance'] as num?)?.toDouble() ?? 0;
                                                if (attPercent == 0 && attMap.containsKey(sId)) {
                                                  final list = attMap[sId]!;
                                                  attPercent = list.reduce((a, b) => a + b) / list.length;
                                                }
                                                final attMarks = _calculateAttendanceMarks(attPercent);

                                                // 2. Assignments
                                                double assignScore = (data['assignments'] as num?)?.toDouble() ?? 0;
                                                if (assignScore == 0 && obeMap[sId]?.containsKey('Assignment') == true) {
                                                  final scores = obeMap[sId]!['Assignment']!;
                                                  assignScore = scores.reduce((a, b) => a + b) / scores.length;
                                                }

                                                // 3. Series
                                                double seriesScore = (data['seriesTests'] as num?)?.toDouble() ?? 0;
                                                if (seriesScore == 0) {
                                                  final studentObe = obeMap[sId];
                                                  final scores = studentObe?['Series Exam'] ?? studentObe?['Series Test'] ?? [];
                                                  if (scores.isNotEmpty) {
                                                    seriesScore = scores.reduce((a, b) => a + b) / scores.length;
                                                  }
                                                }

                                                int total = (attMarks + assignScore + seriesScore).round();
                                                if (total > 50) total = 50; // Cap at 50
                                                allInternalMarks.add(total);
                                              }

                                              if (allInternalMarks.isNotEmpty) {
                                                highest = allInternalMarks.reduce((a, b) => a > b ? a : b);
                                                lowest = allInternalMarks.reduce((a, b) => a < b ? a : b);
                                                avg = allInternalMarks.reduce((a, b) => a + b) / allInternalMarks.length;
                                              }
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
                                                  Icons.report_problem_rounded,
                                                  const Color(0xFFFEF2F2),
                                                  const Color(0xFFEF4444),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      },
                                    );
                                  },
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
      style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
                    fontSize: 13,
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

    // --- FETCH DATA FROM ALL SOURCES ---
    final marksSnap = await _firestore.collection('internal_marks').get();
    final attendanceSnap = await _firestore.collection('attendance').get();
    final obeMarksSnap = await _firestore.collection('obe_marks').get();
    final evalSnap = await _firestore.collection('obe_evaluations').get();
    
    final studentSnapshot = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'student')
        .get();

    final Map<String, Map<String, dynamic>> studentMap = {
      for (var doc in studentSnapshot.docs)
        doc.id: doc.data(),
    };

    final Map<String, Map<String, dynamic>> marksMap = {
      for (var doc in marksSnap.docs) doc.id: doc.data(),
    };

    final Map<String, List<Map<String, dynamic>>> attendanceByStudent = {};
    for (var doc in attendanceSnap.docs) {
      final data = doc.data();
      final sId = data['studentId']?.toString() ?? '';
      if (sId.isNotEmpty) {
        attendanceByStudent.putIfAbsent(sId, () => []).add(data);
      }
    }

    final Map<String, Map<String, dynamic>> evals = {
      for (var doc in evalSnap.docs) doc.id: doc.data(),
    };

    final Map<String, Map<String, List<double>>> obeByStudent = {};
    for (var doc in obeMarksSnap.docs) {
      final data = doc.data();
      final sId = data['studentId']?.toString() ?? data['rollNo']?.toString() ?? '';
      final evalId = data['evaluationId']?.toString() ?? '';
      if (sId.isNotEmpty && evalId.isNotEmpty) {
        final eval = evals[evalId];
        final type = eval?['type']?.toString() ?? 'Series Exam';
        final score = double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;
        obeByStudent.putIfAbsent(sId, () => {});
        obeByStudent[sId]!.putIfAbsent(type, () => []).add(score);
      }
    }

    final List<Map<String, dynamic>> rows = [];
    for (var studentId in studentMap.keys) {
      final student = studentMap[studentId]!;
      final regNo = student['regNo']?.toString() ?? 
                    student['studentId']?.toString() ?? 
                    studentId;
      final email = student['email']?.toString() ?? 
                    student['userEmail']?.toString() ?? '';

      // Find marks from manual map first
      final manualMarks = marksMap[regNo] ?? (email.isNotEmpty ? marksMap[email] : null) ?? {};

      // 1. Attendance Calculation
      double attPercentage = 0;
      final attDocs = attendanceByStudent[regNo] ?? (email.isNotEmpty ? attendanceByStudent[email] : null) ?? [];
      if (attDocs.isNotEmpty) {
        int totalSum = 0;
        int presentSum = 0;
        for (var doc in attDocs) {
          totalSum += (doc['total'] as num?)?.toInt() ?? 0;
          presentSum += (doc['present'] as num?)?.toInt() ?? 0;
        }
        attPercentage = totalSum > 0 ? (presentSum / totalSum) * 100 : 0;
      }
      // Override if manual exists and non-zero
      if (manualMarks['attendance'] != null && manualMarks['attendance'] != 0) {
        attPercentage = (manualMarks['attendance'] as num).toDouble();
      }

      // 2. OBE / Series Tests
      double seriesTotal = 0;
      final studentObe = obeByStudent[regNo] ?? (email.isNotEmpty ? obeByStudent[email] : null) ?? {};
      final seriesScores = studentObe['Series Exam'] ?? studentObe['Series Test'] ?? [];
      if (seriesScores.isNotEmpty) {
        seriesTotal = seriesScores.reduce((a, b) => a + b) / seriesScores.length;
      }
      if (manualMarks['seriesTests'] != null && manualMarks['seriesTests'] != 0) {
        seriesTotal = (manualMarks['seriesTests'] as num).toDouble();
      }

      // 3. Assignments
      double assignTotal = 0;
      final assignScores = studentObe['Assignment'] ?? [];
      if (assignScores.isNotEmpty) {
        assignTotal = assignScores.reduce((a, b) => a + b) / assignScores.length;
      }
      if (manualMarks['assignments'] != null && manualMarks['assignments'] != 0) {
        assignTotal = (manualMarks['assignments'] as num).toDouble();
      }

      // Robust name extraction
      String fullName = 'Unknown';
      if (student['name'] != null) {
        fullName = student['name'].toString();
      } else if (student['fullName'] != null) {
        fullName = student['fullName'].toString();
      } else if (student['firstname'] != null || student['lastname'] != null) {
        fullName = '${student['firstname'] ?? ''} ${student['lastname'] ?? ''}'.trim();
      }

      rows.add({
        'email': email.isNotEmpty ? email : regNo,
        'name': fullName,
        'regNo': regNo,
        'attendance': attPercentage.round(),
        'assignments': assignTotal.round(),
        'seriesTests': seriesTotal.round(),
        'internalMark': (attPercentage / 10 + assignTotal / 2 + seriesTotal / 2).round(),
      });
    }

    // Sort by name
    rows.sort(
      (a, b) => (a['name'] ?? '').toString().compareTo(
        (b['name'] ?? '').toString(),
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
                      'Email',
                      'Name',
                      'Reg No',
                      'Att %',
                      'Assign',
                      'Series',
                      'Internal',
                      'Grade',
                    ]
                  : [
                      'Email',
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
                    r['email'].toString(),
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
                  r['email'].toString(),
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
      'Email,Name,Reg No,Attendance %,Assignments,Series Tests,Internal Mark',
    );
    for (var r in rows) {
      buffer.writeln(
        '${r['email']},${r['name']},${r['regNo']},${r['attendance']},${r['assignments']},${r['seriesTests']},${r['internalMark']}',
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
                'Email',
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
                      r['email'].toString(),
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
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(
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
                            hintStyle: GoogleFonts.inter(
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
                _buildColHead("EMAIL", flex: 2),
                _buildColHead("STUDENT NAME", flex: 2),
                _buildColHead("ATTENDANCE %", flex: 1, center: true),
                _buildColHead("ASSIGNMENTS", flex: 1, center: true),
                _buildColHead("SERIES TESTS", flex: 1, center: true),
                _buildColHead("INTERNAL MARK", flex: 1, center: true),
                _buildColHead("ACTIONS", flex: 1, center: true),
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
              return _buildMarksStream(context, students);
            },
          ),
        ],
      ),
    );
  }

  double _calculateAttendanceMarks(double percentage) {
    if (percentage >= 90) return 5.0;
    if (percentage >= 85) return 4.0;
    if (percentage >= 80) return 3.0;
    if (percentage >= 75) return 2.0;
    return 0.0;
  }

  Widget _buildMarksStream(
    BuildContext context,
    List<QueryDocumentSnapshot> students,
  ) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('internal_marks').snapshots(),
      builder: (context, marksSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('attendance').snapshots(),
          builder: (context, attendanceSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('obe_marks').snapshots(),
              builder: (context, obeMarksSnapshot) {
                return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('obe_evaluations').snapshots(),
                  builder: (context, evalSnapshot) {
                    if (marksSnapshot.connectionState == ConnectionState.waiting ||
                        attendanceSnapshot.connectionState == ConnectionState.waiting ||
                        obeMarksSnapshot.connectionState == ConnectionState.waiting ||
                        evalSnapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // --- PROCESS ATTENDANCE DATA ---
                    final attendanceDocs = attendanceSnapshot.data?.docs ?? [];
                    final Map<String, List<Map<String, dynamic>>> attendanceByStudent = {};
                    for (var doc in attendanceDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final sId = data['studentId']?.toString() ?? '';
                      if (sId.isNotEmpty) {
                        attendanceByStudent.putIfAbsent(sId, () => []).add(data);
                      }
                    }

                    // --- PROCESS EVALUATION TYPES ---
                    final Map<String, String> evalTypes = {};
                    for (var doc in evalSnapshot.data?.docs ?? []) {
                      final data = doc.data() as Map<String, dynamic>;
                      evalTypes[doc.id] = data['type']?.toString() ?? 'Series Exam';
                    }

                    // --- PROCESS OBE MARKS ---
                    final Map<String, Map<String, List<double>>> obeByStudent = {};
                    for (var doc in obeMarksSnapshot.data?.docs ?? []) {
                      final data = doc.data() as Map<String, dynamic>;
                      final sId = data['studentId']?.toString() ?? data['rollNo']?.toString() ?? '';
                      final evalId = data['evaluationId']?.toString() ?? '';
                      if (sId.isNotEmpty && evalId.isNotEmpty) {
                        final type = evalTypes[evalId] ?? 'Series Exam';
                        final double score = double.tryParse(data['total']?.toString() ?? '0') ?? 0.0;
                        obeByStudent.putIfAbsent(sId, () => {});
                        obeByStudent[sId]!.putIfAbsent(type, () => []).add(score);
                      }
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
                      final email = (data['email'] ?? data['userEmail'] ?? "")
                          .toString()
                          .toLowerCase();
                      return name.contains(_searchQuery.toLowerCase()) ||
                          regNo.contains(_searchQuery.toLowerCase()) ||
                          email.contains(_searchQuery.toLowerCase());
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
                            final String email = studentData['email']?.toString() ?? 
                                                 (studentData['userEmail']?.toString() ?? '');

                            // Lookup marks with fallbacks
                            final manualMarks = marksMap[regNo] ?? (email.isNotEmpty ? marksMap[email] : null) ?? {};

                            // 1. Exact Attendance
                            double attPercent = 0;
                            final attDocs = attendanceByStudent[regNo] ?? (email.isNotEmpty ? attendanceByStudent[email] : null) ?? [];
                            if (attDocs.isNotEmpty) {
                              int total = 0;
                              int present = 0;
                              for (var d in attDocs) {
                                total += (d['total'] as num?)?.toInt() ?? 0;
                                present += (d['present'] as num?)?.toInt() ?? 0;
                              }
                              attPercent = total > 0 ? (present / total) * 100 : 0;
                            }
                            if (manualMarks['attendance'] != null && manualMarks['attendance'] != 0) {
                              attPercent = (manualMarks['attendance'] as num).toDouble();
                            }

                            // 2. Exact Series Tests
                            double seriesVal = 0;
                            final studentObeData = obeByStudent[regNo] ?? (email.isNotEmpty ? obeByStudent[email] : null) ?? {};
                            final scores = studentObeData['Series Exam'] ?? studentObeData['Series Test'] ?? [];
                            if (scores.isNotEmpty) {
                              seriesVal = scores.reduce((a, b) => a + b) / scores.length;
                            }
                            if (manualMarks['seriesTests'] != null && manualMarks['seriesTests'] != 0) {
                              seriesVal = (manualMarks['seriesTests'] as num).toDouble();
                            }

                            // 3. Exact Assignments
                            double assignVal = 0;
                            final assignScores = studentObeData['Assignment'] ?? [];
                            if (assignScores.isNotEmpty) {
                              assignVal = assignScores.reduce((a, b) => a + b) / assignScores.length;
                            }
                            if (manualMarks['assignments'] != null && manualMarks['assignments'] != 0) {
                              assignVal = (manualMarks['assignments'] as num).toDouble();
                            }

                            final attMarks = _calculateAttendanceMarks(attPercent);
                            final displayData = {
                              'uid': studentDoc.id,
                              'regNo': regNo,
                              'email': email.isNotEmpty ? email : regNo,
                              'name': () {
                                if (studentData['name'] != null) return studentData['name'];
                                if (studentData['fullName'] != null) return studentData['fullName'];
                                return '${studentData['firstname'] ?? ''} ${studentData['lastname'] ?? ''}'.trim();
                              }(),
                              'attendance': attPercent.round(),
                              'assignments': assignVal.round(),
                              'seriesTests': seriesVal.round(),
                              'internalMark': (attMarks + assignVal + seriesVal).round(),
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
                                style: GoogleFonts.inter(
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
              },
            );
          },
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
        style: GoogleFonts.inter(
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
              flex: 2,
              child: Text(
                data['email'] ?? "-",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                data['name'] ?? "-",
                style: GoogleFonts.inter(
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
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "${data['assignments'] ?? 0}",
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "${data['seriesTests'] ?? 0}",
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: Text(
                  "${data['internalMark'] ?? 0}",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF001FF4),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => _showEditMarksDialog(data),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001FF4).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.edit_note_rounded,
                        color: Color(0xFF001FF4),
                        size: 20,
                      ),
                    ),
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
      builder: (BuildContext context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 450,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF001FF4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF001FF4),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Update Assessment",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            data['name'] ?? "Student",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildEditField(
                      "Attendance Percentage",
                      Icons.fact_check_rounded,
                      attController,
                      "e.g. 95",
                    ),
                    const SizedBox(height: 20),
                    _buildEditField(
                      "Assignments Mark",
                      Icons.assignment_rounded,
                      assController,
                      "e.g. 20",
                    ),
                    const SizedBox(height: 20),
                    _buildEditField(
                      "Series Tests Average",
                      Icons.analytics_rounded,
                      serController,
                      "e.g. 45",
                    ),
                    
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F9FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBAE6FD)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calculate_rounded,
                                color: Color(0xFF0369A1),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Internal Calculation (Max 50)",
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0369A1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "• Attendance: 90%+=5, 85%+=4, 80%+=3, 75%+=2\n• Assignments: Max 5\n• Series Tests: Max 40",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF0C4A6E),
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Cancel",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final double attendance = double.tryParse(attController.text) ?? 0;
                          final double assignments = double.tryParse(assController.text) ?? 0;
                          final double series = double.tryParse(serController.text) ?? 0;

                          // Calculation: Convert attendance % to marks (Max 5)
                          final double attMarks = _calculateAttendanceMarks(attendance);
                          final double internal = attMarks + assignments + series;

                          // Save using regNo as primary key (fallback to UID if regNo is empty)
                          final String docId = (data['regNo'] != null && data['regNo'].toString().isNotEmpty) 
                                              ? data['regNo'].toString() 
                                              : data['uid'].toString();

                          await _firestore
                              .collection('internal_marks')
                              .doc(docId)
                              .set({
                            'attendance': attendance,
                            'assignments': assignments,
                            'seriesTests': series,
                            'internalMark': internal.round(),
                            'studentName': data['name'],
                            'studentEmail': data['email'],
                            'lastUpdated': FieldValue.serverTimestamp(),
                          }, SetOptions(merge: true));

                          if (context.mounted) Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("✅ Assessment updated for ${data['name']}"),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: const Color(0xFF10B981),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001FF4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          "Save Changes",
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(String label, IconData icon, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF64748B)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
              borderSide: const BorderSide(color: Color(0xFF001FF4), width: 1.5),
            ),
          ),
        ),
      ],
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
          Icon(
            Icons.group_off_rounded,
            size: 48,
            color: const Color(0xFF94A3B8).withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            "No student data available in the database.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Student records will appear here once they are added to the system.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8).withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
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
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }
}

