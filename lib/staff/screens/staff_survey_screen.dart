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

class _StaffSurveyScreenState extends State<StaffSurveyScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;

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
                      child: Row(
                        children: [
                          Expanded(
                            child: StaffHeader(
                              title: "Surveys",
                              userId: widget.userId,
                              showBackButton: true,
                              isWhite: true,
                              showDate: false,
                            ),
                          ),
                          Container(
                            height: 48,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              isScrollable: true,
                              indicator: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              labelColor: const Color(0xFF001FF4),
                              unselectedLabelColor: Colors.white.withOpacity(
                                0.7,
                              ),
                              labelStyle: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                              tabs: const [
                                Tab(text: "Evaluations Outgoing"),
                                Tab(text: "Incoming Feedback"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [_buildOutgoingList(), _buildIncomingList()],
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

  // ─── Survey List ──────────────────────────────────────────────────────────

  // ─── Outgoing List (Sent to Students) ───────────────────────────────────────

  Widget _buildOutgoingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionHeader(
                "Student Evaluations",
                "Manage and monitor the surveys you've published to your students",
              ),
              ElevatedButton.icon(
                onPressed: _showSendSurveyDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text("New Evaluation"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001FF4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('surveys')
                .where('type', isEqualTo: 'Teacher Evaluation')
                .where('createdBy', isEqualTo: widget.userId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty)
                return _buildEmptyState(
                  "No Evaluations Published",
                  "Start collecting feedback by sending a new survey to your students.",
                );
              return _listView(docs, isIncoming: false);
            },
          ),
        ),
      ],
    );
  }

  // ─── Incoming List (Sent from HOD/Admin) ───────────────────────────────────

  Widget _buildIncomingList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
          child: _sectionHeader(
            "Departmental Feedback",
            "Responsive to surveys and feedback requested by your HOD or Admin",
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('surveys')
                .where('targetRole', isEqualTo: 'Staff')
                .where('status', isEqualTo: 'Active')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData)
                return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;
              if (docs.isEmpty)
                return _buildEmptyState(
                  "No Incoming Surveys",
                  "You're all caught up! No active surveys from the department.",
                );
              return _listView(docs, isIncoming: true);
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _listView(List<DocumentSnapshot> docs, {required bool isIncoming}) {
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

        if (isIncoming) {
          return _buildIncomingCard(docs[index].id, data, createdAt);
        }

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
  }

  // ─── Incoming Survey Card ───────────────────────────────────────────────────

  Widget _buildIncomingCard(
    String docId,
    Map<String, dynamic> data,
    String date,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              _showVotingSheet(docId, data['name'] ?? "Department Feedback"),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.assignment_rounded,
                    color: Color(0xFF6366F1),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'] ?? "Unnamed Survey",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _chip(
                            Icons.person_pin_rounded,
                            data['creatorRole'] ?? "HOD",
                            const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 12),
                          _chip(
                            Icons.calendar_today_rounded,
                            date,
                            const Color(0xFF94A3B8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showVotingSheet(String docId, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              "How would you rate this?",
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _voteOption(docId, "Excellent", "🤩", const Color(0xFF10B981)),
                _voteOption(docId, "Good", "😊", const Color(0xFF001FF4)),
                _voteOption(docId, "Bad", "☹️", Colors.redAccent),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _voteOption(String docId, String label, String emoji, Color color) {
    return Column(
      children: [
        InkWell(
          onTap: () async {
            Navigator.pop(context);
            await _db.collection('surveys').doc(docId).update({
              'ratings.$label': FieldValue.increment(1),
              'responseCount': FieldValue.increment(1),
            });
            _showMsg("Feedback submitted for $label!");
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              border: Border.all(color: color.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
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
                    style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(String title, String subtitle) {
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
            title,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Text(
          "\"$title\" will be permanently removed and students will no longer see it.",
          style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Survey Title",
                style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
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

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$c",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              "${percent.toStringAsFixed(0)}%",
              style: GoogleFonts.inter(
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
