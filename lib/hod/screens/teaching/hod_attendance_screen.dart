import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/hod_sidebar.dart';
import '../../widgets/hod_header.dart';

class HodAttendanceScreen extends StatefulWidget {
  final String userId;
  const HodAttendanceScreen({super.key, required this.userId});

  @override
  State<HodAttendanceScreen> createState() => _HodAttendanceScreenState();
}

class _HodAttendanceScreenState extends State<HodAttendanceScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DateTime _selectedDate = DateTime.now();

  // Per-student toggle state for live marking (regNo -> isPresent)
  final Map<String, bool> _liveMarks = {};
  bool _isSaving = false;

  List<Map<String, dynamic>> _realStudents = [];
  bool _studentsLoaded = false;

  late List<Map<String, dynamic>> _batches;
  int _currentBatch = 0;
  late TabController _viewTabController;

  void _initLiveMarks() {
    for (final s in _realStudents) {
      _liveMarks[s['regNo']] = true; // Default: present
    }
  }

  @override
  void initState() {
    super.initState();
    _batches = [
      {
        'name': 'MCA 2023-25',
        'subject': 'Relational Database Systems',
        'color': const Color(0xFF6366F1),
        'collection': 'hod_attendance_mca2023',
      },
      {
        'name': 'MCA 2024-26',
        'subject': 'Advanced Computer Architecture',
        'color': const Color(0xFF10B981),
        'collection': 'hod_attendance_mca2024',
      },
    ];
    _tabController = TabController(length: _batches.length, vsync: this)
      ..addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _currentBatch = _tabController.index;
            _liveMarks.clear();
            _initLiveMarks();
          });
        }
      });
    _viewTabController = TabController(length: 3, vsync: this);
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      final students = <Map<String, dynamic>>[];
      int rollCounter = 1;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final firstName = data['firstname']?.toString() ??
            data['firstName']?.toString() ?? '';
        final lastName = data['lastname']?.toString() ??
            data['lastName']?.toString() ?? '';
        final fullName = data['fullName']?.toString() ??
            '$firstName $lastName'.trim();
        final username = data['username']?.toString() ?? doc.id;
        final rollNo = data['rollNo']?.toString() ??
            rollCounter.toString().padLeft(3, '0');

        students.add({
          'name': fullName.isNotEmpty ? fullName : 'Unknown',
          'rollNo': rollNo,
          'regNo': username,
        });
        rollCounter++;
      }

      students.sort((a, b) =>
          (a['rollNo'] ?? '').compareTo(b['rollNo'] ?? ''));

      setState(() {
        _realStudents = students;
        _studentsLoaded = true;
        _initLiveMarks();
      });
    } catch (e) {
      debugPrint('[HodAttendance] Error loading students: $e');
      setState(() => _studentsLoaded = true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _viewTabController.dispose();
    super.dispose();
  }

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSidebar(activeIndex: 2, userId: widget.userId),
          Expanded(
            child: Column(
              children: [
                // ── GRADIENT HEADER ──
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF4F46E5),
                        Color(0xFF4338CA),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 28, 40, 0),
                        child: HodHeader(
                          title: 'Attendance',
                          userId: widget.userId,
                          isWhite: true,
                          showBackButton: true,
                          showDate: false,
                        ),
                      ),
                      // Breadcrumb
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 6, 40, 0),
                        child: Row(
                          children: [
                            _bc('Home'),
                            _bcSep(),
                            _bc('My Classes'),
                            _bcSep(),
                            _bc('Attendance', isLast: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Batch tabs
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 0, 40, 0),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicatorColor: Colors.white,
                          indicatorWeight: 3,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white60,
                          labelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabs: _batches
                              .map((b) => Tab(text: b['name']))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── BODY ──
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: List.generate(
                      _batches.length,
                      (i) => _buildBatchBody(i),
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

  Widget _buildBatchBody(int idx) {
    if (!_studentsLoaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final batch = _batches[idx];
    final color = batch['color'] as Color;
    final students = _realStudents;
    final col = batch['collection'] as String;

    return Column(
      children: [
        // ── Date picker row ──
        _buildDateBar(color),

        // ── Inner tabs: Mark / View ──
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _viewTabController,
            labelColor: color,
            unselectedLabelColor: const Color(0xFF94A3B8),
            indicatorColor: color,
            labelStyle: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_note_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Mark Attendance'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('Staff Records'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 18),
                    SizedBox(width: 6),
                    Text('View Summary'),
                  ],
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: TabBarView(
            controller: _viewTabController,
            children: [
              _buildMarkTab(students, col, color, idx),
              _buildStaffRecordsTab(
                batch['name']?.toString().split(' ')[0] ?? 'MCA',
                color,
              ),
              _buildViewTab(col, color, students),
            ],
          ),
        ),
      ],
    );
  }

  // ── DATE BAR ─────────────────────────────────────────────
  Widget _buildDateBar(Color color) {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());
    final isYesterday = DateUtils.isSameDay(
      _selectedDate,
      DateTime.now().subtract(const Duration(days: 1)),
    );

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
      child: Row(
        children: [
          // Date chip
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    DateFormat('EEE, dd MMM yyyy').format(_selectedDate),
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_drop_down_rounded,
                    color: Colors.white70,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _quickDateBtn(
            'Today',
            isToday,
            () => setState(() => _selectedDate = DateTime.now()),
          ),
          const SizedBox(width: 8),
          _quickDateBtn(
            'Yesterday',
            isYesterday,
            () => setState(
              () => _selectedDate = DateTime.now().subtract(
                const Duration(days: 1),
              ),
            ),
          ),
          const Spacer(),
          // Prev / Next
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: const Color(0xFF64748B),
                ),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                IconButton(
                  onPressed: () => setState(
                    () => _selectedDate = _selectedDate.add(
                      const Duration(days: 1),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickDateBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? const Color(0xFF6366F1).withValues(alpha: 0.4)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? const Color(0xFF6366F1) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ── MARK ATTENDANCE TAB ───────────────────────────────────
  Widget _buildMarkTab(
      List<Map<String, dynamic>> students, String col, Color color, int batchIdx) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection(col)
          .where('dateKey', isEqualTo: _dateKey)
          .snapshots(),
      builder: (context, snapshot) {
        // Prefill liveMarks from existing records
        final existingMap = <String, bool>{};
        bool alreadySubmitted = false;
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          alreadySubmitted = true;
          for (final doc in snapshot.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            existingMap[d['regNo']] = d['isPresent'] == true;
          }
        }

        // Merge: use existing if submitted, else use liveMarks defaults
        final marks = <String, bool>{};
        for (final s in students) {
          final regNo = s['regNo'] as String;
          if (alreadySubmitted) {
            marks[regNo] = existingMap[regNo] ?? true;
          } else {
            marks[regNo] = _liveMarks[regNo] ?? true;
          }
        }

        final presentCount = marks.values.where((v) => v).length;
        final absentCount = marks.values.where((v) => !v).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Stats row
              Row(
                children: [
                  _statCard(
                    'Present',
                    presentCount.toString(),
                    Icons.check_circle_rounded,
                    const Color(0xFFF0FDF4),
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 16),
                  _statCard(
                    'Absent',
                    absentCount.toString(),
                    Icons.cancel_rounded,
                    const Color(0xFFFFF1F2),
                    const Color(0xFFF43F5E),
                  ),
                  const SizedBox(width: 16),
                  _statCard(
                    'Total',
                    students.length.toString(),
                    Icons.groups_rounded,
                    const Color(0xFFEEF2FF),
                    color,
                  ),
                  const SizedBox(width: 16),
                  _statCard(
                    'Attendance %',
                    students.isEmpty
                        ? '0%'
                        : '${(presentCount / students.length * 100).toStringAsFixed(0)}%',
                    Icons.donut_large_rounded,
                    const Color(0xFFFFFBEB),
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Subject info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _batches[batchIdx]['subject'],
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            '${_batches[batchIdx]['name']} • ${DateFormat('EEEE, dd MMM').format(_selectedDate)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (alreadySubmitted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Submitted',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Mark All buttons
              Row(
                children: [
                  _markAllBtn(
                    'Mark All Present',
                    Icons.done_all_rounded,
                    const Color(0xFF10B981),
                    () {
                      setState(() {
                        for (final s in students) {
                          _liveMarks[s['regNo']] = true;
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  _markAllBtn(
                    'Mark All Absent',
                    Icons.remove_done_rounded,
                    const Color(0xFFF43F5E),
                    () {
                      setState(() {
                        for (final s in students) {
                          _liveMarks[s['regNo']] = false;
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Student list
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          _th('Roll No', flex: 1),
                          _th('Name', flex: 4),
                          _th('Reg No', flex: 2),
                          _th('Status', flex: 2),
                        ],
                      ),
                    ),
                    ...students.asMap().entries.map((entry) {
                      final s = entry.value;
                      final regNo = s['regNo'] as String;
                      final isPresent = marks[regNo] ?? true;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFFF1F5F9),
                              width: entry.key < students.length - 1 ? 1 : 0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                s['rollNo'],
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                s['name'],
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                regNo,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    _liveMarks[regNo] = !isPresent;
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? const Color(0xFFDCFCE7)
                                          : const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isPresent
                                              ? Icons.check_circle_rounded
                                              : Icons.cancel_rounded,
                                          size: 16,
                                          color: isPresent
                                              ? const Color(0xFF16A34A)
                                              : const Color(0xFFDC2626),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isPresent ? 'Present' : 'Absent',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: isPresent
                                                ? const Color(0xFF16A34A)
                                                : const Color(0xFFDC2626),
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
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSaving
                      ? null
                      : () => _saveAttendance(students, col, color),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(
                          alreadySubmitted
                              ? Icons.update_rounded
                              : Icons.save_rounded,
                          size: 20,
                        ),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : alreadySubmitted
                        ? 'Update Attendance'
                        : 'Save Attendance',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveAttendance(
      List<Map<String, dynamic>> students, String col, Color color) async {
    setState(() => _isSaving = true);
    final batch = _db.batch();
    final batchInfo = _batches[_currentBatch];
    final dept = batchInfo['name']?.toString().split(' ')[0] ?? 'MCA';
    final subject = batchInfo['subject'] ?? 'Unknown';

    for (final s in students) {
      final regNo = s['regNo'] as String;

      // Batch-specific record
      final bRef = _db.collection(col).doc('${_dateKey}_$regNo');
      batch.set(bRef, {
        'regNo': regNo,
        'name': s['name'],
        'rollNo': s['rollNo'],
        'dateKey': _dateKey,
        'date': Timestamp.fromDate(_selectedDate),
        'isPresent': _liveMarks[regNo] ?? true,
        'markedBy': widget.userId,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Main attendance record (connected to system)
      // Use subject in ID to prevent overwriting different sessions on same day
      final mainRef = _db
          .collection('attendance')
          .doc('HOD_${_dateKey}_${subject.replaceAll(' ', '_')}_$regNo');
      batch.set(mainRef, {
        'date': Timestamp.fromDate(_selectedDate),
        'period': 1, // Default to 1 for HOD logs
        'subject': subject,
        'subjectName': subject,
        'department': dept,
        'studentId': regNo,
        'name': s['name'], // Ensure name is included for list display
        'isPresent': _liveMarks[regNo] ?? true,
        'markedBy': 'HOD',
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    setState(() => _isSaving = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text(
                'Attendance saved and synced for ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ── VIEW SUMMARY TAB ─────────────────────────────────────
  Widget _buildViewTab(String col, Color color, List<Map<String, dynamic>> students) {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection(col).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF6366F1)),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        // Group by dateKey
        final Map<String, Map<String, dynamic>> byDate = {};
        for (final doc in docs) {
          final d = doc.data() as Map<String, dynamic>;
          final key = d['dateKey']?.toString() ?? '';
          if (key.isEmpty) continue;
          if (!byDate.containsKey(key)) {
            byDate[key] = {'total': 0, 'present': 0, 'date': d['date']};
          }
          byDate[key]!['total'] = (byDate[key]!['total'] as int) + 1;
          if (d['isPresent'] == true) {
            byDate[key]!['present'] = (byDate[key]!['present'] as int) + 1;
          }
        }

        final sortedKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

        if (sortedKeys.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No attendance records yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start marking attendance using the Mark tab.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFFCBD5E1),
                  ),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ATTENDANCE HISTORY',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF94A3B8),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          _th('Date', flex: 3),
                          _th('Day', flex: 2),
                          _th('Present', flex: 2),
                          _th('Absent', flex: 2),
                          _th('Attendance %', flex: 2),
                          _th('Status', flex: 2),
                        ],
                      ),
                    ),
                    ...sortedKeys.asMap().entries.map((entry) {
                      final key = entry.value;
                      final info = byDate[key]!;
                      final total = info['total'] as int;
                      final present = info['present'] as int;
                      final absent = total - present;
                      final pct = total == 0 ? 0.0 : present / total * 100;
                      final ts = info['date'];
                      DateTime? dt;
                      if (ts is Timestamp) dt = ts.toDate();

                      Color pctColor = pct >= 75
                          ? const Color(0xFF10B981)
                          : pct >= 60
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFFF43F5E);

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: const Color(0xFFF1F5F9),
                              width: entry.key < sortedKeys.length - 1 ? 1 : 0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                dt != null
                                    ? DateFormat('dd MMM yyyy').format(dt)
                                    : key,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                dt != null
                                    ? DateFormat('EEEE').format(dt)
                                    : '-',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                present.toString(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF10B981),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                absent.toString(),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF43F5E),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '${pct.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                  color: pctColor,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: pctColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    pct >= 75
                                        ? 'Good'
                                        : pct >= 60
                                        ? 'Low'
                                        : 'Critical',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: pctColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── STAFF RECORDS TAB ────────────────────────────────────
  Widget _buildStaffRecordsTab(String department, Color color) {
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('attendance')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThan: Timestamp.fromDate(endOfDay))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snapshot.data?.docs ?? [];
        // Filter by department in code to avoid complex index requirements
        final docs = allDocs.where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final docDept = d['department']?.toString().toUpperCase() ?? '';
          return docDept == department.toUpperCase();
        }).toList();

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_ind_outlined,
                  size: 64,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'No staff attendance found for today',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        }

        // Group by subject and period
        final Map<String, List<QueryDocumentSnapshot>> grouped = {};
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          // Group by subject, period AND marker to separate HOD sessions from Staff sessions
          final key =
              "${data['subject']}_P${data['period']}_${data['markedBy']}";
          grouped.putIfAbsent(key, () => []).add(doc);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(32),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final key = grouped.keys.elementAt(index);
            final recordDocs = grouped[key]!;
            final firstData = recordDocs.first.data() as Map<String, dynamic>;
            final presentCount = recordDocs
                .where((d) => (d.data() as Map)['isPresent'] == true)
                .length;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.person_pin_rounded, color: color, size: 20),
                ),
                title: Row(
                  children: [
                    Text(
                      firstData['subject'] ?? 'Unknown Subject',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    if (firstData['markedBy'] == 'HOD')
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          "HOD",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ),
                  ],
                ),
                subtitle: Text(
                  "Period ${firstData['period']} • Marked by ${firstData['markedBy']} • $presentCount/${recordDocs.length} Present",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                children: [
                  const Divider(height: 1),
                  ...recordDocs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final bool isPresent = d['isPresent'] == true;
                    return ListTile(
                      dense: true,
                      title: Text(
                        d['name'] ?? d['studentId'] ?? 'Unknown',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      subtitle: Text(
                        d['studentId'] ?? '',
                        style: GoogleFonts.inter(fontSize: 11),
                      ),
                      trailing: Switch(
                        value: isPresent,
                        activeColor: const Color(0xFF10B981),
                        onChanged: (val) async {
                          final batchUpdate = _db.batch();

                          // 1. Update central record in 'attendance'
                          batchUpdate.update(
                            _db.collection('attendance').doc(doc.id),
                            {
                              'isPresent': val,
                              'lastEditedBy': 'HOD',
                              'editTimestamp': FieldValue.serverTimestamp(),
                            },
                          );

                          // 2. If it's an HOD-marked record, sync back to batch-specific collection
                          if (doc.id.startsWith('HOD_')) {
                            // Find matching batch by subject
                            for (var b in _batches) {
                              if (b['subject'] == d['subject']) {
                                final batchCol = b['collection'];
                                final dateKey = DateFormat(
                                  'yyyy-MM-dd',
                                ).format((d['date'] as Timestamp).toDate());
                                final localRef = _db
                                    .collection(batchCol)
                                    .doc('${dateKey}_${d['studentId']}');
                                batchUpdate.update(localRef, {
                                  'isPresent': val,
                                });
                                break;
                              }
                            }
                          }

                          await batchUpdate.commit();
                        },
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── HELPERS ─────────────────────────────────────────────
  Widget _statCard(
    String title,
    String value,
    IconData icon,
    Color bg,
    Color fg,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
              child: Icon(icon, color: fg, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _markAllBtn(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 17, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _th(String text, {int flex = 1}) => Expanded(
    flex: flex,
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF64748B),
        letterSpacing: 0.3,
      ),
    ),
  );

  Widget _bc(String label, {bool isLast = false}) => Text(
    label,
    style: GoogleFonts.inter(
      color: isLast ? Colors.white : Colors.white70,
      fontSize: 12,
      fontWeight: isLast ? FontWeight.w700 : FontWeight.w500,
    ),
  );

  Widget _bcSep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Icon(Icons.chevron_right_rounded, color: Colors.white54, size: 14),
  );
}
