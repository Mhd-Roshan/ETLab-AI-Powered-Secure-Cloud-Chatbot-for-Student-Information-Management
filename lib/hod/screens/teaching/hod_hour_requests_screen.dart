import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/services/hod_service.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';

class HodHourRequestsScreen extends StatefulWidget {
  final String userId;
  const HodHourRequestsScreen({super.key, required this.userId});

  @override
  State<HodHourRequestsScreen> createState() => _HodHourRequestsScreenState();
}

class _HodHourRequestsScreenState extends State<HodHourRequestsScreen> {
  final TextEditingController _subFromController = TextEditingController();
  final TextEditingController _hourController = TextEditingController();
  String _statusFilter = 'select';
  String _batchFilter = 'select';
  DateTime _fromDate = DateTime(2026, 3, 2);
  DateTime _toDate = DateTime(2026, 3, 5);

  final HodService _hodService = HodService();
  bool _isSeeding = false;

  @override
  void initState() {
    super.initState();
    _seedData();
  }

  Future<void> _seedData() async {
    setState(() => _isSeeding = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('hour_requests')
          .where('department', isEqualTo: 'MCA')
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        await _hodService.seedHourRequests();
      }
    } catch (e) {
      debugPrint("Seeding error: $e");
    } finally {
      if (mounted) setState(() => _isSeeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEEF2FF),
                    Color(0xFFF1F5F9),
                    Color(0xFFE0E7FF),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _AuroraPainter())),
          Row(
            children: [
              HodSidebar(activeIndex: 5, userId: widget.userId),
              Expanded(
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isSeeding)
                            Container(
                              margin: const EdgeInsets.only(bottom: 24),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF6366F1,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    "Initializing sample data for your department...",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _buildHeader(),
                          const SizedBox(height: 56),
                          _buildStatsRow(),
                          const SizedBox(height: 56),
                          _buildModernRequestSection(
                            title: "Staff Substitution Requests",
                            isByMe: false,
                            stream: _hodService.getHourRequests(
                              'MCA',
                              status: _statusFilter,
                              batch: _batchFilter,
                            ),
                          ),
                          const SizedBox(height: 48),
                          _buildModernRequestSection(
                            title: "Requests Initiated by You",
                            isByMe: true,
                            stream: _hodService.getHourRequestsByUser(
                              widget.userId,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "HOD OPERATIONS",
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF6366F1),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Hour Requests",
              style: GoogleFonts.outfit(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
                letterSpacing: -1,
              ),
            ),
            Text(
              "Manage faculty substitutions and scheduling effortlessly",
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        _actionButton(
          Icons.add_rounded,
          "New Request",
          const Color(0xFF6366F1),
          onPressed: _showNewRequestDialog,
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: _hodService.getHourRequests('MCA'),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SizedBox.shrink();
        }
        int pending = 0;
        int approved = 0;
        if (snapshot.hasData) {
          pending = snapshot.data!.docs
              .where(
                (doc) =>
                    doc.exists &&
                    (doc.data() as Map<String, dynamic>).containsKey(
                      'status',
                    ) &&
                    doc.get('status') == 'Pending',
              )
              .length;
          approved = snapshot.data!.docs
              .where(
                (doc) =>
                    doc.exists &&
                    (doc.data() as Map<String, dynamic>).containsKey(
                      'status',
                    ) &&
                    doc.get('status') == 'Approved',
              )
              .length;
        }
        return Row(
          children: [
            _statCard(
              "Pending",
              pending.toString(),
              const Color(0xFFF59E0B),
              Icons.pending_actions_rounded,
            ),
            const SizedBox(width: 24),
            _statCard(
              "Approved",
              approved.toString(),
              const Color(0xFF10B981),
              Icons.check_circle_outline_rounded,
            ),
            const SizedBox(width: 24),
            _statCard(
              "Substitute",
              "03",
              const Color(0xFF6366F1),
              Icons.swap_horiz_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        height: 120,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 32,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernRequestSection({
    required String title,
    required bool isByMe,
    required Stream<QuerySnapshot> stream,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.table_chart_rounded,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _buildModernFilterItem(
                  "Status",
                  _buildModernDropdown(
                    _statusFilter,
                    (v) => setState(() => _statusFilter = v!),
                  ),
                ),
                _buildModernFilterItem(
                  "Batch",
                  _buildModernDropdown(
                    _batchFilter,
                    (v) => setState(() => _batchFilter = v!),
                  ),
                ),
                _buildModernFilterItem(
                  "Substitution",
                  _buildModernTextField(_subFromController, "Search staff..."),
                ),
                _buildModernFilterItem(
                  "Hour Unit",
                  _buildModernTextField(_hourController, "e.g. 2 hrs"),
                ),
                _buildModernFilterItem(
                  "From Date",
                  _buildModernDateField(
                    _fromDate,
                    (d) => setState(() => _fromDate = d),
                  ),
                ),
                _buildModernFilterItem(
                  "To Date",
                  _buildModernDateField(
                    _toDate,
                    (d) => setState(() => _toDate = d),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Row(
              children: [
                _actionButton(
                  Icons.search_rounded,
                  "Search Requests",
                  const Color(0xFF1E293B),
                  onPressed: () => setState(() {}),
                ),
                const SizedBox(width: 16),
                _outlineButton(
                  Icons.refresh_rounded,
                  "Clear Filters",
                  onPressed: () {
                    setState(() {
                      _statusFilter = 'select';
                      _batchFilter = 'select';
                      _subFromController.clear();
                      _hourController.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildRequestGrid(stream, isByMe),
        ],
      ),
    );
  }

  Widget _buildRequestGrid(Stream<QuerySnapshot> stream, bool isByMe) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(64.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    "Error loading data",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: Colors.redAccent),
                  ),
                ],
              ),
            ),
          );
        }
        final docs = (snapshot.data?.docs ?? []).toList();
        if (docs.isEmpty) return _buildEmptyState();

        // Sort manually by timestamp (newest first) to avoid needing a composite index
        docs.sort((a, b) {
          final aTime =
              (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          final bTime =
              (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return Padding(
          padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return _buildRequestCard(docs[index].id, data, isByMe);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              size: 64,
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Active Requests Found",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "All substitution requests for this filters have been processed.",
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(String id, Map<String, dynamic> data, bool isByMe) {
    final status = data['status'] ?? 'Pending';
    final date = (data['date'] as Timestamp).toDate();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statusBadge(status),
                Row(
                  children: [
                    if (isByMe) ...[
                      _compactIconButton(
                        Icons.edit_outlined,
                        Colors.blue,
                        () => _showEditRequestDialog(id, data),
                      ),
                      const SizedBox(width: 8),
                      _compactIconButton(
                        Icons.delete_outline_rounded,
                        Colors.red,
                        () => _showDeleteConfirmation(id),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (status == 'Pending' &&
                        data['requesterId'] != widget.userId)
                      _compactActionButton(
                        Icons.check_rounded,
                        "Approve",
                        Colors.green,
                        () =>
                            _hodService.updateHourRequestStatus(id, 'Approved'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['subject'] ?? 'No Subject',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      data['batch'] ?? 'N/A',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _cardDetailItem(
                      Icons.calendar_today_outlined,
                      DateFormat('MMM dd').format(date),
                    ),
                    const SizedBox(width: 16),
                    _cardDetailItem(
                      Icons.schedule_outlined,
                      data['period'] ?? 'N/A',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: const Color(
                          0xFF6366F1,
                        ).withValues(alpha: 0.1),
                        child: Text(
                          (data['requesterName'] ?? 'U')[0],
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6366F1),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isByMe
                            ? "You"
                            : (data['requesterName'] ?? 'Unknown Staff'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        "Requester",
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _cardDetailItem(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 12, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _compactActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _compactIconButton(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Request",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete this hour request?",
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await _hodService.deleteHourRequest(id);
              if (context.mounted) Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _showEditRequestDialog(String id, Map<String, dynamic> data) {
    final TextEditingController subjectController = TextEditingController(
      text: data['subject'],
    );
    final TextEditingController periodController = TextEditingController(
      text: data['period'],
    );
    String selectedBatch = data['batch'] ?? 'MCA 2023-2025';
    DateTime selectedDate = (data['date'] as Timestamp).toDate();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            "Edit Hour Request",
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectController,
                decoration: const InputDecoration(labelText: "Subject"),
              ),
              TextField(
                controller: periodController,
                decoration: const InputDecoration(labelText: "Period"),
              ),
              const SizedBox(height: 16),
              DropdownButton<String>(
                value: selectedBatch,
                isExpanded: true,
                items: ['MCA 2023-2025', 'MCA 2024-2026']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setDialogState(() => selectedBatch = v!),
              ),
              const SizedBox(height: 16),
              _buildModernDateField(
                selectedDate,
                (d) => setDialogState(() => selectedDate = d),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                await _hodService.updateHourRequest(id, {
                  'subject': subjectController.text,
                  'period': periodController.text,
                  'batch': selectedBatch,
                  'date': Timestamp.fromDate(selectedDate),
                });
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewRequestDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController periodController = TextEditingController();
    String selectedBatch = 'MCA 2023-2025';
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "New Hour Request",
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: "Subject"),
            ),
            TextField(
              controller: periodController,
              decoration: const InputDecoration(labelText: "Period"),
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedBatch,
              isExpanded: true,
              items: [
                'MCA 2023-2025',
                'MCA 2024-2026',
              ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
              onChanged: (v) => selectedBatch = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await _hodService.createHourRequest({
                'requesterId': widget.userId,
                'requesterName': 'HOD User',
                'subject': subjectController.text,
                'period': periodController.text,
                'batch': selectedBatch,
                'date': Timestamp.fromDate(selectedDate),
                'department': 'MCA',
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Request"),
          ),
        ],
      ),
    );
  }

  Widget _buildModernFilterItem(String label, Widget child) {
    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF94A3B8),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildModernDropdown(String value, void Function(String?) onChanged) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'select', child: Text("All Statuses")),
            DropdownMenuItem(value: 'Approved', child: Text("Approved")),
            DropdownMenuItem(value: 'Pending', child: Text("Pending")),
          ],
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6366F1),
            size: 20,
          ),
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 12,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDateField(
    DateTime date,
    void Function(DateTime) onSelected,
  ) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d != null) onSelected(d);
      },
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
    );
  }

  Widget _outlineButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    paint.color = const Color(0xFF6366F1).withValues(alpha: 0.1);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 200, paint);
    paint.color = const Color(0xFFA5B4FC).withValues(alpha: 0.1);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 300, paint);
    paint.color = const Color(0xFF818CF8).withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 250, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
