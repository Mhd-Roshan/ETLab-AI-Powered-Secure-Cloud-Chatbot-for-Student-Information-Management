import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/staff_complaint_service.dart';
import '../../services/staff_service.dart';

class StaffComplaintsScreen extends StatefulWidget {
  final String userId;
  const StaffComplaintsScreen({super.key, required this.userId});

  @override
  State<StaffComplaintsScreen> createState() => _StaffComplaintsScreenState();
}

class _StaffComplaintsScreenState extends State<StaffComplaintsScreen> {
  final StaffComplaintService _complaintService = StaffComplaintService();
  final StaffService _staffService = StaffService();

  String _staffName = "MCA Staff";
  String _staffDept = "MCA";
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStaffProfile();
  }

  void _loadStaffProfile() {
    _staffService.getProfile(widget.userId).listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          final data = doc.data() as Map<String, dynamic>?;
          _staffName = data?['name'] ?? 'MCA Staff';
          _staffDept = data?['department'] ?? 'MCA';
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Staff Grievances",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildSummaryHeader(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _complaintService.streamStaffComplaints(widget.userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: snapshot.data!.docs.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildComplaintCard(doc.id, data);
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showSubmissionDialog(),
        backgroundColor: const Color(0xFF001FF4),
        icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
        label: Text(
          "SUBMIT COMPLAINT",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SUBMIT A GRIEVANCE",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    final date = data['submittedAt'] != null
        ? DateFormat(
            'dd MMM yyyy',
          ).format((data['submittedAt'] as Timestamp).toDate())
        : 'N/A';

    Color statusColor = const Color(0xFFF59E0B);
    if (status == 'Resolved') statusColor = const Color(0xFF10B981);
    if (status == 'Rejected') statusColor = const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['subject'] ?? "No Subject",
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['category'] ?? "General",
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Divider(height: 32),
          Text(
            data['description'] ?? "",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF475569),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _showComplaintDetails(data),
            child: Row(
              children: [
                Text(
                  "View Details",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF001FF4),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Color(0xFF001FF4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDialog() {
    final subController = TextEditingController(text: "Digital Fundamentals");
    final descController = TextEditingController();
    String category = 'Academic';
    String priority = 'Normal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                "Submit Grievance",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildInputLabel("Subject"),
              TextField(
                controller: subController,
                decoration: _inputDecoration("Enter subject..."),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("Category"),
                        DropdownButtonFormField<String>(
                          value: category,
                          items:
                              [
                                    'Academic',
                                    'Infrastructure',
                                    'Salary',
                                    'Professional',
                                    'Other',
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => setModalState(() => category = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputLabel("Priority"),
                        DropdownButtonFormField<String>(
                          value: priority,
                          items: ['Low', 'Normal', 'High', 'Urgent']
                              .map(
                                (p) =>
                                    DropdownMenuItem(value: p, child: Text(p)),
                              )
                              .toList(),
                          onChanged: (v) => setModalState(() => priority = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInputLabel("Description"),
              TextField(
                controller: descController,
                maxLines: 4,
                decoration: _inputDecoration(
                  "Describe your concern details...",
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (subController.text.isEmpty ||
                        descController.text.isEmpty)
                      return;
                    await _complaintService.submitComplaint(
                      staffId: widget.userId,
                      staffName: _staffName,
                      department: _staffDept,
                      subject: subController.text,
                      category: category,
                      description: descController.text,
                      priority: priority,
                    );
                    if (mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF001FF4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    "Submit to Admin",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComplaintDetails(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF001FF4).withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.assignment_late_rounded,
                    color: Color(0xFF001FF4),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      "Grievance Detail",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailItem("SUBJECT", data['subject']),
                  const Divider(height: 32),
                  _buildDetailItem("CATEGORY", data['category']),
                  const Divider(height: 32),
                  _buildDetailItem("DESCRIPTION", data['description']),
                  if (data['adminFeedback'] != null) ...[
                    const Divider(height: 32),
                    _buildDetailItem(
                      "ADMIN FEEDBACK",
                      data['adminFeedback'],
                      isHighlight: true,
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Dismiss",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
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

  Widget _buildDetailItem(
    String label,
    String? value, {
    bool isHighlight = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value ?? "N/A",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
            color: isHighlight
                ? const Color(0xFF001FF4)
                : const Color(0xFF1E293B),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.mark_chat_read_outlined,
            size: 64,
            color: const Color(0xFF94A3B8).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            "No Grievances Found",
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Complaints you submit will appear here.",
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF64748B),
          letterSpacing: 1,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }
}

