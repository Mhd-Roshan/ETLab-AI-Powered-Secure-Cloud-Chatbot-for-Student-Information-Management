import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SurveyScreen extends StatefulWidget {
  final String studentId;
  const SurveyScreen({super.key, required this.studentId});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  // Cache of already-submitted survey IDs for this student session
  final Set<String> _submittedSurveyIds = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Student Surveys",
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          Expanded(child: _buildSurveyList()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Available Surveys",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Your feedback helps us improve your learning experience.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('surveys')
          .where('status', isEqualTo: 'Active')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final surveys = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
          itemCount: surveys.length,
          itemBuilder: (context, index) {
            final data = surveys[index].data() as Map<String, dynamic>;
            final docId = surveys[index].id;
            return _buildSurveyCardWithSubmissionCheck(docId, data);
          },
        );
      },
    );
  }

  /// Wraps each card with a FutureBuilder that checks if this student
  /// has already submitted a response to this survey.
  Widget _buildSurveyCardWithSubmissionCheck(
    String docId,
    Map<String, dynamic> data,
  ) {
    // If we already know it was submitted in this session, skip the Firestore check
    if (_submittedSurveyIds.contains(docId)) {
      return _buildSurveyCard(docId, data, alreadySubmitted: true);
    }

    return FutureBuilder<DocumentSnapshot>(
      future: _db
          .collection('surveys')
          .doc(docId)
          .collection('responses')
          .doc(widget.studentId)
          .get(),
      builder: (context, snapshot) {
        final alreadySubmitted = snapshot.hasData && snapshot.data!.exists;

        if (alreadySubmitted) {
          // Cache it so we don't re-query on rebuild
          _submittedSurveyIds.add(docId);
        }

        return _buildSurveyCard(
          docId,
          data,
          alreadySubmitted: alreadySubmitted,
        );
      },
    );
  }

  Widget _buildSurveyCard(
    String docId,
    Map<String, dynamic> data, {
    bool alreadySubmitted = false,
  }) {
    final String title = data['name'] ?? 'Untitled Survey';
    final String subject = data['subject'] ?? 'General';
    final String type = data['type'] ?? 'Standard';
    final Timestamp? createdAt = data['createdAt'] as Timestamp?;
    final String dateStr = createdAt != null
        ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
        : '--';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: alreadySubmitted
            ? Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.4),
                width: 1.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: alreadySubmitted
                ? const Color(0xFF10B981).withValues(alpha: 0.08)
                : const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          // Block tap if already submitted
          onTap: alreadySubmitted
              ? () => _showAlreadySubmittedMessage()
              : () => _showSurveyOptions(docId, title, subject),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: alreadySubmitted
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : const Color(0xFF001FF4).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    alreadySubmitted
                        ? Icons.check_circle_rounded
                        : Icons.poll_rounded,
                    color: alreadySubmitted
                        ? const Color(0xFF10B981)
                        : const Color(0xFF001FF4),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Title + subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: alreadySubmitted
                              ? const Color(0xFF64748B)
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "$subject • $type",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (alreadySubmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "Submitted ✓",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      )
                    else
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: Color(0xFF94A3B8),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
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

  void _showAlreadySubmittedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text("You have already submitted this survey."),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF64748B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSurveyOptions(String docId, String title, String subject) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Rate your experience",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subject != 'General') ...[
              const SizedBox(height: 2),
              Text(
                subject,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildOptionItem(
                  context,
                  docId,
                  "Excellent",
                  "🤩",
                  const Color(0xFF10B981),
                ),
                _buildOptionItem(
                  context,
                  docId,
                  "Good",
                  "😊",
                  const Color(0xFF001FF4),
                ),
                _buildOptionItem(context, docId, "Bad", "☹️", Colors.redAccent),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                "You can only submit once — choose carefully.",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem(
    BuildContext context,
    String docId,
    String label,
    String emoji,
    Color color,
  ) {
    return Column(
      children: [
        InkWell(
          onTap: _isSubmitting
              ? null
              : () => _submitFeedback(context, docId, label),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 86,
            height: 86,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25)),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 36)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback(
    BuildContext context,
    String docId,
    String rating,
  ) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    Navigator.pop(context); // Close bottom sheet

    try {
      final responseDocRef = _db
          .collection('surveys')
          .doc(docId)
          .collection('responses')
          .doc(
            widget.studentId,
          ); // Use studentId as doc ID → enforces uniqueness

      // --- Duplicate check before writing ---
      final existingResponse = await responseDocRef.get();
      if (existingResponse.exists) {
        if (mounted) {
          _submittedSurveyIds.add(docId);
          setState(() {});
          _showAlreadySubmittedMessage();
        }
        return;
      }

      // Use a batch to atomically write the response + update survey counters
      final surveyDocRef = _db.collection('surveys').doc(docId);
      final batch = _db.batch();

      // 1. Record the individual response (studentId as doc ID = no duplicates)
      batch.set(responseDocRef, {
        'studentId': widget.studentId,
        'rating': rating,
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // 2. Increment the survey counters
      batch.update(surveyDocRef, {
        'ratings.$rating': FieldValue.increment(1),
        'responseCount': FieldValue.increment(1),
      });

      await batch.commit();

      // Mark as submitted in local cache + rebuild
      if (mounted) {
        _submittedSurveyIds.add(docId);
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("Thank you! Your '$rating' feedback was saved."),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting feedback: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

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
            "No active surveys",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Check back later for new feedback forms.",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
