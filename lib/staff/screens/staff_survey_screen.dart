import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/staff_sidebar.dart';
import '../widgets/staff_header.dart';

class StaffSurveyScreen extends StatefulWidget {
  final String userId;
  const StaffSurveyScreen({super.key, required this.userId});

  @override
  State<StaffSurveyScreen> createState() => _StaffSurveyScreenState();
}

class _StaffSurveyScreenState extends State<StaffSurveyScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffSidebar(activeIndex: 7, userId: widget.userId),
          Expanded(
            child: Stack(
              children: [
                // Aurora header gradient
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 290,
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

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                      child: StaffHeader(
                        title: "Student Surveys",
                        userId: widget.userId,
                        showBackButton: true,
                        isWhite: true,
                        showDate: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Evaluation Surveys",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Surveys you've sent to your students",
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.75),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          ElevatedButton.icon(
                            onPressed: _showSendSurveyDialog,
                            icon: const Icon(Icons.send_rounded, size: 18),
                            label: const Text("Send New Survey"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF001FF4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                              textStyle: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(child: _buildSurveyList()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Survey List ──────────────────────────────────────────────────────────

  Widget _buildSurveyList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('surveys')
          .where('type', isEqualTo: 'Teacher Evaluation')
          .where('createdBy', isEqualTo: widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(40, 16, 40, 40),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final createdAt = data['createdAt'] != null
                ? DateFormat(
                    'MMM dd, yyyy',
                  ).format((data['createdAt'] as Timestamp).toDate())
                : 'Pending';
            return _buildEvalCard(
              docId: docs[index].id,
              title: data['name'] ?? 'Untitled Survey',
              subject: data['subject'] ?? '—',
              semester: data['semester'] ?? '—',
              department: data['department'] ?? '—',
              batch: data['batch'] ?? '—',
              createdAt: createdAt,
              responses: data['responseCount'] ?? 0,
              status: data['status'] ?? 'Active',
              ratings: data['ratings'] as Map<String, dynamic>? ?? {},
            );
          },
        );
      },
    );
  }

  // ─── Survey Card ─────────────────────────────────────────────────────────

  Widget _buildEvalCard({
    required String docId,
    required String title,
    required String subject,
    required String semester,
    required String department,
    required String batch,
    required String createdAt,
    required int responses,
    required String status,
    required Map<String, dynamic> ratings,
  }) {
    final isActive = status == 'Active';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                color: Color(0xFF10B981),
                size: 28,
              ),
            ),
            const SizedBox(width: 20),

            // Details
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
                  const SizedBox(height: 8),
                  // Row 1: Subject + Semester
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _chip(
                        Icons.book_outlined,
                        subject,
                        const Color(0xFF7C3AED),
                      ),
                      _chip(
                        Icons.layers_outlined,
                        semester,
                        const Color(0xFF001FF4),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Results Breakdown
                  if (responses > 0)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Student Feedback Results",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _resultIndicator(
                              "Excellent",
                              ratings['Excellent'] ?? 0,
                              responses,
                              const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 8),
                            _resultIndicator(
                              "Good",
                              ratings['Good'] ?? 0,
                              responses,
                              const Color(0xFF001FF4),
                            ),
                            const SizedBox(width: 8),
                            _resultIndicator(
                              "Bad",
                              ratings['Bad'] ?? 0,
                              responses,
                              Colors.redAccent,
                            ),
                          ],
                        ),
                      ],
                    ),
                  // Row 2: Dept/Batch + Responses + Date
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _chip(
                        Icons.group_outlined,
                        "$department • $batch",
                        const Color(0xFF64748B),
                      ),
                      _chip(
                        Icons.bar_chart_rounded,
                        "$responses response${responses == 1 ? '' : 's'}",
                        const Color(0xFF10B981),
                      ),
                      _chip(
                        Icons.calendar_today_outlined,
                        createdAt,
                        const Color(0xFF64748B),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status + Delete
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? const Color(0xFF15803D)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () => _deleteSurvey(docId, title),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.poll_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Surveys Sent Yet",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Click 'Send New Survey' to request feedback from your students.",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _showSendSurveyDialog,
            icon: const Icon(Icons.send_rounded, size: 18),
            label: const Text("Send New Survey"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001FF4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 0,
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Delete Dialog ────────────────────────────────────────────────────────

  void _deleteSurvey(String docId, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Delete Survey?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "\"$title\" will be permanently removed and students will no longer see it.",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _db.collection('surveys').doc(docId).delete();
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ─── Send Survey Dialog (Simplified) ───────────────────────────────────

  void _showSendSurveyDialog() {
    final titleController = TextEditingController(
      text: "Faculty Evaluation - ${widget.userId.split('@')[0]}",
    );

    const String selectedSubject =
        'Digital Fundamentals & Computer Architecture';
    const String selectedSemester = 'Semester 1';
    const String selectedBatch = '2024 to 2026';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          "Send Survey to Students",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Survey Title",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  hintText: "Enter survey title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.title_rounded),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _fixedInfoRow(
                      Icons.book_outlined,
                      "Subject",
                      selectedSubject,
                    ),
                    const Divider(height: 24),
                    _fixedInfoRow(
                      Icons.layers_outlined,
                      "Semester",
                      selectedSemester,
                    ),
                    const Divider(height: 24),
                    _fixedInfoRow(
                      Icons.calendar_month_outlined,
                      "Batch",
                      selectedBatch,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = titleController.text.trim();
              if (name.isEmpty) return;

              await _db.collection('surveys').add({
                'name': name,
                'type': 'Teacher Evaluation',
                'subject': selectedSubject,
                'semester': selectedSemester,
                'department': '', // No specific department required
                'batch': selectedBatch,
                'status': 'Active',
                'createdBy': widget.userId,
                'createdAt': FieldValue.serverTimestamp(),
                'responseCount': 0,
                'surveyId':
                    "TE-${DateFormat('yyMMdd').format(DateTime.now())}-${DateTime.now().millisecond}",
              });

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("✅ Survey sent to students successfully!"),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001FF4),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Send Now"),
          ),
        ],
      ),
    );
  }

  Widget _fixedInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF001FF4)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _resultIndicator(String label, dynamic count, int total, Color color) {
    final int c = count is int ? count : 0;
    final double percent = total > 0 ? (c / total) * 100 : 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$c",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              "${percent.toStringAsFixed(0)}%",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
