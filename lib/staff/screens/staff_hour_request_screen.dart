import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/services/hod_service.dart';
import '../widgets/staff_sidebar.dart';
import '../widgets/staff_header.dart';

class StaffHourRequestScreen extends StatefulWidget {
  final String userId;
  const StaffHourRequestScreen({super.key, required this.userId});

  @override
  State<StaffHourRequestScreen> createState() => _StaffHourRequestScreenState();
}

class _StaffHourRequestScreenState extends State<StaffHourRequestScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'select';
  DateTime _fromDate = DateTime(2026, 1, 1);
  DateTime _toDate = DateTime(2026, 12, 31);
  String _staffName = 'Faculty';

  final HodService _hodService = HodService();

  @override
  void initState() {
    super.initState();
    _loadStaffName();
  }

  Future<void> _loadStaffName() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['fullName'] ?? data['name'] ?? data['displayName'];
        if (name != null && name.toString().isNotEmpty) {
          if (mounted) setState(() => _staffName = name.toString());
          return;
        }
      }
      if (mounted) {
        setState(() => _staffName = widget.userId.split('@')[0]);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Aurora gradient background
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaffSidebar(activeIndex: 2, userId: widget.userId),
              Expanded(
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                          child: StaffHeader(
                            title: 'Hour Requests',
                            userId: widget.userId,
                            showBackButton: true,
                            showDate: false,
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(40, 24, 40, 48),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 40),
                                _buildStatsRow(),
                                const SizedBox(height: 40),
                                _buildRequestSection(),
                              ],
                            ),
                          ),
                        ),
                      ],
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

  // ── Header ────────────────────────────────────────────────────────────────
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
                    Icons.swap_horiz_rounded,
                    size: 14,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'STAFF OPERATIONS',
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
              'Hour Requests',
              style: GoogleFonts.outfit(
                fontSize: 38,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1E293B),
                letterSpacing: -1,
              ),
            ),
            Text(
              'Submit and track your substitution hour requests',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        _actionButton(
          Icons.add_rounded,
          'New Request',
          const Color(0xFF6366F1),
          onPressed: _showNewRequestDialog,
        ),
      ],
    );
  }

  // ── Stats row ─────────────────────────────────────────────────────────────
  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: _hodService.getHourRequestsByUser(widget.userId),
      builder: (context, snapshot) {
        int pending = 0, approved = 0, total = 0;
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          total = docs.length;
          pending = docs
              .where((d) => (d.data() as Map)['status'] == 'Pending')
              .length;
          approved = docs
              .where((d) => (d.data() as Map)['status'] == 'Approved')
              .length;
        }
        return Row(
          children: [
            _statCard(
              'Pending',
              pending.toString(),
              const Color(0xFFF59E0B),
              Icons.pending_actions_rounded,
            ),
            const SizedBox(width: 24),
            _statCard(
              'Approved',
              approved.toString(),
              const Color(0xFF10B981),
              Icons.check_circle_outline_rounded,
            ),
            const SizedBox(width: 24),
            _statCard(
              'Total Requests',
              total.toString(),
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
        height: 110,
        padding: const EdgeInsets.all(22),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.2),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.outfit(
                    fontSize: 30,
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

  // ── Request section ───────────────────────────────────────────────────────
  Widget _buildRequestSection() {
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
          // Card header
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
                  'My Hour Requests',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
          // Filters
          Padding(
            padding: const EdgeInsets.all(32),
            child: Wrap(
              spacing: 24,
              runSpacing: 24,
              children: [
                _filterItem(
                  'Status',
                  _buildDropdown(
                    _statusFilter,
                    (v) => setState(() => _statusFilter = v!),
                  ),
                ),
                _filterItem(
                  'Search Subject',
                  _buildTextField(_searchCtrl, 'Search subject...'),
                ),
                _filterItem(
                  'From Date',
                  _buildDateField(
                    _fromDate,
                    (d) => setState(() => _fromDate = d),
                  ),
                ),
                _filterItem(
                  'To Date',
                  _buildDateField(_toDate, (d) => setState(() => _toDate = d)),
                ),
              ],
            ),
          ),
          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            child: Row(
              children: [
                _actionButton(
                  Icons.search_rounded,
                  'Search',
                  const Color(0xFF1E293B),
                  onPressed: () => setState(() {}),
                ),
                const SizedBox(width: 16),
                _outlineButton(
                  Icons.refresh_rounded,
                  'Clear',
                  onPressed: () => setState(() {
                    _statusFilter = 'select';
                    _searchCtrl.clear();
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Request grid
          StreamBuilder<QuerySnapshot>(
            stream: _hodService.getHourRequestsByUser(widget.userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(64),
                    child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.inter(color: Colors.red),
                    ),
                  ),
                );
              }

              var docs = (snapshot.data?.docs ?? []).toList();

              // Apply filters
              if (_statusFilter != 'select') {
                docs = docs
                    .where((d) => (d.data() as Map)['status'] == _statusFilter)
                    .toList();
              }
              if (_searchCtrl.text.isNotEmpty) {
                docs = docs
                    .where(
                      (d) => ((d.data() as Map)['subject'] ?? '')
                          .toString()
                          .toLowerCase()
                          .contains(_searchCtrl.text.toLowerCase()),
                    )
                    .toList();
              }

              // Sort newest first
              docs.sort((a, b) {
                final aT = (a.data() as Map)['timestamp'] as Timestamp?;
                final bT = (b.data() as Map)['timestamp'] as Timestamp?;
                if (aT == null || bT == null) return 0;
                return bT.compareTo(aT);
              });

              if (docs.isEmpty) return _buildEmptyState();

              return Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 20),
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    return _buildRequestCard(docs[i].id, data);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Container(
      height: 280,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hourglass_empty_rounded,
              size: 56,
              color: const Color(0xFF6366F1).withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No Requests Found',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tap "New Request" above to submit your first hour request.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ── Request card ──────────────────────────────────────────────────────────
  Widget _buildRequestCard(String id, Map<String, dynamic> data) {
    final status = data['status'] ?? 'Pending';
    Timestamp? ts;
    try {
      ts = data['date'] as Timestamp?;
    } catch (_) {}
    final date = ts?.toDate() ?? DateTime.now();

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
          // Top row: status + actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statusBadge(status),
                Row(
                  children: [
                    _compactIconBtn(
                      Icons.edit_outlined,
                      Colors.blue,
                      () => _showEditDialog(id, data),
                    ),
                    const SizedBox(width: 8),
                    _compactIconBtn(
                      Icons.delete_outline_rounded,
                      Colors.red,
                      () => _showDeleteConfirmation(id),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['subject'] ?? 'No Subject',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                if ((data['batch'] ?? '').toString().isNotEmpty)
                  Row(
                    children: [
                      const Icon(
                        Icons.school_outlined,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        data['batch'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _detailItem(
                      Icons.calendar_today_outlined,
                      DateFormat('MMM dd, yyyy').format(date),
                    ),
                    const SizedBox(width: 16),
                    _detailItem(
                      Icons.schedule_outlined,
                      data['period'] ?? 'N/A',
                    ),
                  ],
                ),
                if ((data['targetStaffName'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(
                            0xFF6366F1,
                          ).withValues(alpha: 0.1),
                          child: Text(
                            (data['targetStaffName'] ?? 'S')[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          data['targetStaffName'] ?? '',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF334155),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Substitute',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showNewRequestDialog() {
    final subjectCtrl = TextEditingController(
      text: 'Digital Fundamentals and Architecture',
    );
    final periodCtrl = TextEditingController();
    final substituteCtrl = TextEditingController();
    String selectedBatch = 'MCA 2023-2025';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.swap_horiz_rounded,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'New Hour Request',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _dialogField('Subject', subjectCtrl),
                const SizedBox(height: 14),
                _dialogField('Period (e.g. 2nd Period)', periodCtrl),
                const SizedBox(height: 14),
                _dialogField(
                  'Substitute Staff Name (optional)',
                  substituteCtrl,
                ),
                const SizedBox(height: 14),
                // Batch dropdown
                Text(
                  'Batch',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedBatch,
                      isExpanded: true,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF1E293B),
                      ),
                      items: ['MCA 2023-2025', 'MCA 2024-2026']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => setS(() => selectedBatch = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Date picker
                Text(
                  'Request Date',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                _buildDateField(
                  selectedDate,
                  (d) => setS(() => selectedDate = d),
                ),
                const SizedBox(height: 28),
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _hodService.createHourRequest({
                            'requesterId': widget.userId,
                            'requesterName': _staffName,
                            'subject': subjectCtrl.text.trim(),
                            'period': periodCtrl.text.trim(),
                            'targetStaffName': substituteCtrl.text.trim(),
                            'batch': selectedBatch,
                            'date': Timestamp.fromDate(selectedDate),
                            'department': 'MCA',
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit Request',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
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

  void _showEditDialog(String id, Map<String, dynamic> data) {
    final subjectCtrl = TextEditingController(text: data['subject'] ?? '');
    final periodCtrl = TextEditingController(text: data['period'] ?? '');
    final substituteCtrl = TextEditingController(
      text: data['targetStaffName'] ?? '',
    );
    String selectedBatch = data['batch'] ?? 'MCA 2023-2025';
    DateTime selectedDate =
        ((data['date'] as Timestamp?)?.toDate()) ?? DateTime.now();

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        color: Color(0xFF6366F1),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Edit Hour Request',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _dialogField('Subject', subjectCtrl),
                const SizedBox(height: 14),
                _dialogField('Period', periodCtrl),
                const SizedBox(height: 14),
                _dialogField('Substitute Staff Name', substituteCtrl),
                const SizedBox(height: 14),
                Text(
                  'Batch',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedBatch,
                      isExpanded: true,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF1E293B),
                      ),
                      items: ['MCA 2023-2025', 'MCA 2024-2026']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => setS(() => selectedBatch = v!),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Request Date',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 6),
                _buildDateField(
                  selectedDate,
                  (d) => setS(() => selectedDate = d),
                ),
                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          await _hodService.updateHourRequest(id, {
                            'subject': subjectCtrl.text.trim(),
                            'period': periodCtrl.text.trim(),
                            'targetStaffName': substituteCtrl.text.trim(),
                            'batch': selectedBatch,
                            'date': Timestamp.fromDate(selectedDate),
                          });
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Update',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
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

  void _showDeleteConfirmation(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Request',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete this hour request?',
          style: GoogleFonts.inter(color: const Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _hodService.deleteHourRequest(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 0,
            ),
            child: Text('Delete', style: GoogleFonts.inter()),
          ),
        ],
      ),
    );
  }

  // ── Small helper widgets ──────────────────────────────────────────────────
  Widget _filterItem(String label, Widget child) {
    return SizedBox(
      width: 260,
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

  Widget _buildDropdown(String value, void Function(String?) onChanged) {
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
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6366F1),
            size: 20,
          ),
          items: const [
            DropdownMenuItem(value: 'select', child: Text('All Statuses')),
            DropdownMenuItem(value: 'Pending', child: Text('Pending')),
            DropdownMenuItem(value: 'Approved', child: Text('Approved')),
            DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        onChanged: (_) => setState(() {}),
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

  Widget _buildDateField(DateTime date, void Function(DateTime) onSelected) {
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

  Widget _dialogField(String label, TextEditingController ctrl) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
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
              borderSide: const BorderSide(color: Color(0xFF6366F1)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

  Color _statusColor(String status) {
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

  Widget _detailItem(IconData icon, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 11, color: const Color(0xFF6366F1)),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _compactIconBtn(IconData icon, Color color, VoidCallback onTap) {
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

  Widget _actionButton(
    IconData icon,
    String label,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed ?? () {},
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
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
      icon: Icon(icon, size: 17),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ── Aurora background painter ────────────────────────────────────────────────
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
