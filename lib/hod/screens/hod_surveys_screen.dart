import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';
import 'package:edlab/hod/widgets/hod_header.dart';

class HodSurveysScreen extends StatefulWidget {
  final String userId;
  final String department;
  const HodSurveysScreen({
    super.key,
    required this.userId,
    this.department = 'MCA',
  });

  @override
  State<HodSurveysScreen> createState() => _HodSurveysScreenState();
}

class _HodSurveysScreenState extends State<HodSurveysScreen> {
  bool _isProcessing = false;

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _addSurvey() {
    final titleCtrl = TextEditingController();
    String targetType = 'Students';
    String? selectedBatch = 'All';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: Text(
              "Create New Survey",
              style: GoogleFonts.inter(fontWeight: FontWeight.w800),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Target Audience",
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _targetChip(
                        "Students",
                        targetType == "Students",
                        () => setDialogState(() => targetType = "Students"),
                      ),
                      const SizedBox(width: 8),
                      _targetChip(
                        "Staff",
                        targetType == "Staff",
                        () => setDialogState(() => targetType = "Staff"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: titleCtrl,
                    style: GoogleFonts.inter(),
                    decoration: InputDecoration(
                      labelText: "Survey Title",
                      hintText: "e.g., Academic Feedback Q1",
                      labelStyle: GoogleFonts.inter(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF001FF4),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (targetType == 'Students') ...[
                    DropdownButtonFormField<String>(
                      value: selectedBatch,
                      decoration: InputDecoration(
                        labelText: "Target Batch",
                        labelStyle: GoogleFonts.inter(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: ['All', '2023', '2024', '2025', '2026']
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      onChanged: (v) => setDialogState(() => selectedBatch = v),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: Text(
                  "Cancel",
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        String title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          _showMsg("Title is required", isError: true);
                          return;
                        }

                        setDialogState(() => _isProcessing = true);
                        final db = FirebaseFirestore.instance.collection(
                          'surveys',
                        );

                        try {
                          String datePart = DateFormat(
                            'yyMM',
                          ).format(DateTime.now());
                          String uniquePart = DateTime.now().millisecond
                              .toString();
                          String generatedId = "HOD-$datePart-$uniquePart";

                          await db.add({
                            'surveyId': generatedId,
                            'name': title,
                            'type': 'General',
                            'targetRole': targetType,
                            'status': 'Active',
                            'department': widget.department,
                            'batch': targetType == 'Students'
                                ? selectedBatch
                                : 'All',
                            'createdBy': widget.userId,
                            'creatorRole': 'HOD',
                            'createdAt': FieldValue.serverTimestamp(),
                            'responseCount': 0,
                          });

                          if (mounted) Navigator.pop(context);
                          _showMsg("Survey published successfully");
                        } catch (e) {
                          _showMsg("Error: $e", isError: true);
                        } finally {
                          setDialogState(() => _isProcessing = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001FF4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        "Publish",
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _targetChip(String label, bool isSelected, VoidCallback onSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) => onSelected(),
      selectedColor: const Color(0xFF001FF4).withOpacity(0.1),
      checkmarkColor: const Color(0xFF001FF4),
      labelStyle: GoogleFonts.inter(
        color: isSelected ? const Color(0xFF001FF4) : Colors.grey,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isSelected ? const Color(0xFF001FF4) : Colors.grey.shade300,
        ),
      ),
    );
  }

  void _deleteSurvey(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Survey?"),
        content: const Text(
          "This will permanently remove the survey and all collected responses.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('surveys')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              _showMsg("Survey deleted", isError: true);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSidebar(activeIndex: 4, userId: widget.userId),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HodHeader(title: "Academic Surveys", userId: widget.userId),
                  const SizedBox(height: 40),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('surveys')
                        .where('department', isEqualTo: widget.department)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int activeCount = 0;
                      int totalResponses = 0;
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          final data = doc.data() as Map<String, dynamic>;
                          if (data['status'] == 'Active') activeCount++;
                          totalResponses += (data['responseCount'] as num? ?? 0)
                              .toInt();
                        }
                      }

                      return Row(
                        children: [
                          _buildSummaryCard(
                            "Active Surveys",
                            "$activeCount",
                            Icons.assignment_turned_in_rounded,
                            const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 24),
                          _buildSummaryCard(
                            "Total Responses",
                            "$totalResponses",
                            Icons.people_rounded,
                            const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 24),
                          _buildSummaryCard(
                            "Avg Participation",
                            activeCount > 0
                                ? "${(totalResponses / activeCount).toStringAsFixed(1)}"
                                : "--",
                            Icons.trending_up_rounded,
                            const Color(0xFFF59E0B),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Recent Surveys",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Manage and track feedback from department members",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _addSurvey,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(
                          "Create Survey",
                          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001FF4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  _buildSurveyList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
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
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurveyList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('surveys')
          .where('department', isEqualTo: widget.department)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        var docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Column(
            children: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              bool isLast = docs.indexOf(doc) == docs.length - 1;
              return _buildSurveyItem(doc.id, data, isLast);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildSurveyItem(
    String docId,
    Map<String, dynamic> data,
    bool isLast,
  ) {
    DateTime? date = data['createdAt'] != null
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    String target = "${data['targetRole']} • ${data['batch']}";

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.assignment_rounded,
              color: Color(0xFF6366F1),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      target,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFFCBD5E1),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      date != null
                          ? DateFormat('MMM dd, yyyy').format(date)
                          : "Recent",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "${data['responseCount']} responses",
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(
              Icons.analytics_outlined,
              color: Color(0xFF94A3B8),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFF43F5E),
            ),
            onPressed: () => _deleteSurvey(docId),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(80),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 64,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 24),
          Text(
            "No active surveys found",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start collecting feedback by creating your first survey",
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
