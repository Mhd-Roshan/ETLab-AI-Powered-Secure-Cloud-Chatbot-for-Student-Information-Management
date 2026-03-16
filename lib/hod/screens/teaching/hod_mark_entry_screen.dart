import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class HodMarkEntryScreen extends StatefulWidget {
  final String userId;
  final String evaluationId;
  final String examName;
  final String examType;
  final String subjectCode;
  final String subjectName;
  final String batchName;
  final List<String> cosMapped;
  final String maxMark;
  final bool isPublished;

  const HodMarkEntryScreen({
    super.key,
    required this.userId,
    required this.evaluationId,
    required this.examName,
    required this.examType,
    required this.subjectCode,
    required this.subjectName,
    required this.batchName,
    required this.cosMapped,
    this.maxMark = '40',
    this.isPublished = false,
  });

  @override
  State<HodMarkEntryScreen> createState() => _HodMarkEntryScreenState();
}

class _HodMarkEntryScreenState extends State<HodMarkEntryScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  late List<_Question> _questions;
  final List<_StudentEntry> _students = [];
  bool _loading = true;
  bool _saving = false;
  late TabController _bottomTab;

  @override
  void initState() {
    super.initState();
    _bottomTab = TabController(length: 2, vsync: this);
    _buildQuestions();
    _loadData();
  }

  void _buildQuestions() {
    final cos = widget.cosMapped.isNotEmpty
        ? widget.cosMapped
        : ['CO1', 'CO2', 'CO3', 'CO4', 'CO5'];

    final isSeriesExam = widget.examType.toLowerCase().contains('series');
    if (isSeriesExam) {
      _questions = [
        _Question('Q1', 'A', cos.length > 1 ? cos[1] : 'CO2', 3.0),
        _Question('Q2', 'A', cos.length > 1 ? cos[1] : 'CO2', 3.0),
        _Question('Q3', 'A', cos.length > 2 ? cos[2] : 'CO3', 3.0),
        _Question('Q4', 'A', cos.length > 2 ? cos[2] : 'CO3', 3.0),
        _Question('Q5', 'A', cos.length > 2 ? cos[2] : 'CO3', 3.0),
        _Question('Q6', 'A', cos.length > 3 ? cos[3] : 'CO4', 3.0),
        _Question('Q7', 'B', cos.length > 1 ? cos[1] : 'CO2', 5.5),
        _Question('Q8', 'B', cos.length > 1 ? cos[1] : 'CO2', 5.5),
        _Question('Q9', 'B', cos.length > 2 ? cos[2] : 'CO3', 5.5),
        _Question('Q10', 'B', cos.length > 2 ? cos[2] : 'CO3', 5.5),
        _Question('Q11', 'B', cos.length > 3 ? cos[3] : 'CO4', 5.5),
      ];
    } else {
      _questions = [
        _Question('Q1', 'A', cos.isNotEmpty ? cos[0] : 'CO1', 5.0),
        _Question('Q2', 'A', cos.length > 1 ? cos[1] : 'CO2', 5.0),
        _Question('Q3', 'A', cos.length > 2 ? cos[2] : 'CO3', 5.0),
        _Question('Q4', 'B', cos.length > 1 ? cos[1] : 'CO2', 10.0),
        _Question('Q5', 'B', cos.length > 2 ? cos[2] : 'CO3', 10.0),
      ];
    }
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);

    try {
      // Step 1: Load existing saved marks for this evaluation
      final marksSnap = await _db
          .collection('obe_marks')
          .where('evaluationId', isEqualTo: widget.evaluationId)
          .get();

      final marksMap = <String, Map<String, String>>{};
      final absentMap = <String, bool>{};
      for (final doc in marksSnap.docs) {
        final data = doc.data();
        final roll = data['rollNo']?.toString() ?? '';
        if (roll.isNotEmpty) {
          marksMap[roll] = Map<String, String>.from(
            (data['marks'] as Map<String, dynamic>? ?? {}).map(
              (k, v) => MapEntry(k, v.toString()),
            ),
          );
          absentMap[roll] = data['absent'] == true;
        }
      }

      // Step 2: Fetch real students from 'users' collection (role = student)
      List<Map<String, dynamic>> studentList = [];

      final usersSnap = await _db
          .collection('users')
          .where('role', isEqualTo: 'student')
          .get();

      if (usersSnap.docs.isNotEmpty) {
        int rollCounter = 1;
        for (var doc in usersSnap.docs) {
          final data = doc.data();
          final firstName = data['firstname']?.toString() ??
              data['firstName']?.toString() ?? '';
          final lastName = data['lastname']?.toString() ??
              data['lastName']?.toString() ?? '';
          final fullName = data['fullName']?.toString() ??
              data['name']?.toString() ??
              '$firstName $lastName'.trim();
          final username = data['username']?.toString() ?? doc.id;
          final rollNo = data['rollNo']?.toString() ??
              data['roll_no']?.toString() ??
              '${rollCounter}';

          if (fullName.isNotEmpty) {
            studentList.add({
              'rollNo': rollNo,
              'name': fullName.toUpperCase(),
              'studentId': username,
            });
            rollCounter++;
          }
        }

        // Sort by rollNo
        studentList.sort((a, b) {
          final aR = int.tryParse(a['rollNo']?.toString() ?? '') ?? 999;
          final bR = int.tryParse(b['rollNo']?.toString() ?? '') ?? 999;
          return aR.compareTo(bR);
        });
      }

      if (mounted) {
        setState(() {
          _students.clear();
          for (int i = 0; i < studentList.length; i++) {
            final s = studentList[i];
            final roll = s['rollNo']?.toString() ?? '${i + 1}';
            final name = s['name']?.toString() ?? 'Student ${i + 1}';
            _students.add(
              _StudentEntry(
                rollNo: roll,
                name: name,
                studentId: s['studentId']?.toString() ?? '',
                absent: absentMap[roll] ?? false,
                marks: {
                  for (final q in _questions)
                    q.id: TextEditingController(
                      text: marksMap[roll]?[q.id] ?? '',
                    ),
                },
              ),
            );
          }
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading students: $e');
      if (mounted) {
        setState(() {
          _students.clear();
          _loading = false;
        });
      }
    }
  }

  void _fillRandomMarks() {
    final rng = Random();
    setState(() {
      for (final s in _students) {
        if (!s.absent) {
          for (final q in _questions) {
            final max = q.maxMark;
            final min = max * 0.4;
            final raw = min + rng.nextDouble() * (max - min);
            final rounded = (raw * 2).round() / 2;
            s.marks[q.id]?.text = rounded.toStringAsFixed(
              rounded % 1 == 0 ? 0 : 1,
            );
          }
        }
      }
    });
  }

  Future<void> _saveMarks() async {
    setState(() => _saving = true);
    try {
      final batch = _db.batch();
      for (final s in _students) {
        final marks = <String, String>{};
        for (final q in _questions) {
          marks[q.id] = s.marks[q.id]?.text.trim() ?? '';
        }
        final total = _calcTotal(s);
        final ref = _db
            .collection('obe_marks')
            .doc('${widget.evaluationId}_${s.rollNo}');
        batch.set(ref, {
          'evaluationId': widget.evaluationId,
          'rollNo': s.rollNo,
          'name': s.name,
          'studentId': s.studentId,
          'absent': s.absent,
          'marks': marks,
          'total': total,
          'subjectCode': widget.subjectCode,
          'batchName': widget.batchName,
          'timestamp': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
      await batch.commit();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 10),
                Text('Marks saved successfully!', style: GoogleFonts.inter()),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _calcTotal(_StudentEntry s) {
    if (s.absent) return 0;
    double t = 0;
    for (final q in _questions) {
      t += double.tryParse(s.marks[q.id]?.text.trim() ?? '') ?? 0;
    }
    return t;
  }

  @override
  void dispose() {
    _bottomTab.dispose();
    for (final s in _students) {
      for (final c in s.marks.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final present = _students.where((s) => !s.absent).length;
    final absent = _students.length - present;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Published warning banner
          if (widget.isPublished) _publishedBanner(),

          // Info bar
          _infoBar(present, absent),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Tab bar (Marks Entry | CO Attainment)
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _bottomTab,
              labelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              labelColor: const Color(0xFF4F46E5),
              unselectedLabelColor: const Color(0xFF64748B),
              indicatorColor: const Color(0xFF4F46E5),
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Marks Entry'),
                Tab(text: 'CO Attainment'),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Content
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
                  )
                : TabBarView(
                    controller: _bottomTab,
                    children: [_marksEntryTab(), _coAttainmentTab()],
                  ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Color(0xFF0F172A),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Mark',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            widget.examName,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: [
        // Refresh
        IconButton(
          onPressed: _loadData,
          icon: const Icon(
            Icons.refresh_rounded,
            size: 18,
            color: Color(0xFF64748B),
          ),
          tooltip: 'Reload',
        ),
        // Fill Sample
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: OutlinedButton.icon(
            onPressed: _fillRandomMarks,
            icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
            label: Text(
              'Fill Sample',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF10B981),
              side: const BorderSide(color: Color(0xFF10B981)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        // Save
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: ElevatedButton.icon(
            onPressed: widget.isPublished || _saving ? null : _saveMarks,
            icon: _saving
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 16),
            label: Text(
              _saving ? 'Saving...' : 'Save',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: const Color(0xFFE2E8F0), height: 1),
      ),
    );
  }

  Widget _publishedBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    color: const Color(0xFFFFF7ED),
    child: Row(
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 15,
          color: Color(0xFFB45309),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '"Marks cannot be modified as the results for this examination have already been published."',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFFB45309),
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _infoBar(int present, int absent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFFF8FAFC),
      child: Row(
        children: [
          _pill(
            widget.examName,
            Icons.fact_check_outlined,
            const Color(0xFF4F46E5),
          ),
          const SizedBox(width: 8),
          _pill(
            widget.subjectCode,
            Icons.menu_book_outlined,
            const Color(0xFF0EA5E9),
          ),
          const SizedBox(width: 8),
          _pill(
            widget.batchName,
            Icons.school_outlined,
            const Color(0xFF10B981),
          ),
          const SizedBox(width: 8),
          _pill(
            widget.examType,
            Icons.category_outlined,
            const Color(0xFFF59E0B),
          ),
          const Spacer(),
          _statBox('$present', 'Present', const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _statBox('$absent', 'Absent', const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _statBox('${_students.length}', 'Total', const Color(0xFF4F46E5)),
        ],
      ),
    );
  }

  Widget _pill(String label, IconData icon, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );

  Widget _statBox(String val, String lbl, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.2)),
    ),
    child: Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          lbl,
          style: GoogleFonts.inter(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  // ─── TAB 1: MARKS ENTRY ──────────────────────────────────────────────────
  Widget _marksEntryTab() {
    if (_students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            const SizedBox(height: 12),
            Text(
              'No students found',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No registered students found.\nEnsure students are added with role "student".',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Reload',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    final parts = <String, List<_Question>>{};
    for (final q in _questions) parts.putIfAbsent(q.part, () => []).add(q);
    final partNames = parts.keys.toList()..sort();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Row 1: Part banners + fixed cols ────────────────────────
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _hCell('Roll\nNo', w: 52),
                  _hCell('Name', w: 180),
                  _hCell('Absent', w: 64),
                  ...partNames.map((part) {
                    final qs = parts[part]!;
                    return Container(
                      width: qs.length * 72.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: part == 'A'
                            ? const Color(0xFFEEF2FF)
                            : const Color(0xFFF0FDF4),
                        border: const Border(
                          right: BorderSide(color: Color(0xFFCBD5E1)),
                          bottom: BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Text(
                        'PART $part',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: part == 'A'
                              ? const Color(0xFF4338CA)
                              : const Color(0xFF166634),
                        ),
                      ),
                    );
                  }),
                  _hCell('Total', w: 72),
                ],
              ),
            ),
            // ── Row 2: Question sub-headers ──────────────────────────────
            Row(
              children: [
                const SizedBox(width: 296), // 52+180+64
                ...partNames.expand((p) => parts[p]!.map((q) => _qHeader(q))),
                const SizedBox(width: 72),
              ],
            ),
            // ── Student rows ─────────────────────────────────────────────
            ..._students.asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final total = _calcTotal(s);
              return Container(
                color: i % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC),
                child: Row(
                  children: [
                    _dataCell(s.rollNo, w: 52),
                    Container(
                      width: 180,
                      height: 40,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE2E8F0)),
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                      ),
                      child: Text(
                        s.name,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Absent checkbox
                    Container(
                      width: 64,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Color(0xFFE2E8F0)),
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                      ),
                      child: Checkbox(
                        value: s.absent,
                        activeColor: const Color(0xFFEF4444),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        onChanged: widget.isPublished
                            ? null
                            : (v) => setState(() => s.absent = v ?? false),
                      ),
                    ),
                    // Mark inputs
                    ...partNames.expand(
                      (p) => parts[p]!.map((q) => _markCell(s, q)),
                    ),
                    // Total
                    Container(
                      width: 72,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(
                          right: BorderSide(color: Color(0xFFE2E8F0)),
                          bottom: BorderSide(color: Color(0xFFF1F5F9)),
                        ),
                      ),
                      child: Text(
                        s.absent
                            ? 'AB'
                            : total.toStringAsFixed(
                                total == total.truncateToDouble() ? 0 : 1,
                              ),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: s.absent
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            // ── Summary footer row ───────────────────────────────────────
            Container(
              color: const Color(0xFFEEF2FF),
              child: Row(
                children: [
                  Container(
                    width: 244,
                    height: 36,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 10),
                    decoration: const BoxDecoration(
                      border: Border(
                        right: BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                    child: Text(
                      'CLASS AVERAGE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF4338CA),
                      ),
                    ),
                  ),
                  const SizedBox(width: 52),
                  // Per question average
                  ...partNames.expand(
                    (p) => parts[p]!.map((q) {
                      final vals = _students
                          .where((s) => !s.absent)
                          .map(
                            (s) =>
                                double.tryParse(
                                  s.marks[q.id]?.text.trim() ?? '',
                                ) ??
                                0,
                          )
                          .toList();
                      final avg = vals.isEmpty
                          ? 0.0
                          : vals.reduce((a, b) => a + b) / vals.length;
                      return Container(
                        width: 72,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        child: Text(
                          avg.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF4338CA),
                          ),
                        ),
                      );
                    }),
                  ),
                  // Total average
                  Container(
                    width: 72,
                    height: 36,
                    alignment: Alignment.center,
                    color: const Color(0xFFDDE1FF),
                    child: Builder(
                      builder: (_) {
                        final totals = _students
                            .where((s) => !s.absent)
                            .map((s) => _calcTotal(s))
                            .toList();
                        final avg = totals.isEmpty
                            ? 0.0
                            : totals.reduce((a, b) => a + b) / totals.length;
                        return Text(
                          avg.toStringAsFixed(1),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4338CA),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _markCell(_StudentEntry s, _Question q) {
    return Container(
      width: 72,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: const BoxDecoration(
        border: Border(
          right: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFF1F5F9)),
        ),
      ),
      child: IgnorePointer(
        ignoring: s.absent || widget.isPublished,
        child: AnimatedOpacity(
          opacity: s.absent ? 0.35 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: TextField(
            controller: s.marks[q.id],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF1E293B),
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 6,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Color(0xFF4F46E5),
                  width: 1.5,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(color: Color(0xFFF1F5F9)),
              ),
              filled: true,
              fillColor: s.absent ? const Color(0xFFFFF1F2) : Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // ─── TAB 2: CO ATTAINMENT ────────────────────────────────────────────────
  Widget _coAttainmentTab() {
    final coList = widget.cosMapped.isNotEmpty
        ? widget.cosMapped
        : ['CO1', 'CO2', 'CO3', 'CO4', 'CO5'];

    // Group questions by CO
    final coQuestions = <String, List<_Question>>{};
    for (final q in _questions) {
      coQuestions.putIfAbsent(q.co, () => []).add(q);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CO Attainment Summary',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            'Based on ${_students.where((s) => !s.absent).length} present students · ${widget.examName}',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 20),
          // CO cards
          ...coList.map((co) {
            final qs = coQuestions[co] ?? [];
            if (qs.isEmpty) return const SizedBox.shrink();

            double totalMax = qs.fold(0, (sum, q) => sum + q.maxMark);
            double totalAvg = 0;
            for (final s in _students.where((s) => !s.absent)) {
              for (final q in qs) {
                totalAvg +=
                    double.tryParse(s.marks[q.id]?.text.trim() ?? '') ?? 0;
              }
            }
            final presentCount = _students.where((s) => !s.absent).length;
            final avgPerStudent = presentCount > 0
                ? totalAvg / presentCount
                : 0.0;
            final attainmentPct = totalMax > 0
                ? (avgPerStudent / totalMax) * 100
                : 0.0;
            final level = attainmentPct >= 70
                ? 3
                : attainmentPct >= 60
                ? 2
                : attainmentPct >= 50
                ? 1
                : 0;
            final levelColor = level == 3
                ? const Color(0xFF10B981)
                : level == 2
                ? const Color(0xFFF59E0B)
                : level == 1
                ? const Color(0xFFEF4444)
                : const Color(0xFF94A3B8);

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          co,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${qs.map((q) => q.id).join(', ')} (Max: ${totalMax.toStringAsFixed(1)})',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: levelColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Level $level',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: levelColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: (attainmentPct / 100).clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              levelColor,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        '${attainmentPct.toStringAsFixed(1)}%',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: levelColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _attStat(
                        'Avg Score',
                        avgPerStudent.toStringAsFixed(2),
                        const Color(0xFF4F46E5),
                      ),
                      const SizedBox(width: 12),
                      _attStat(
                        'Max Score',
                        totalMax.toStringAsFixed(1),
                        const Color(0xFF0EA5E9),
                      ),
                      const SizedBox(width: 12),
                      _attStat(
                        'Questions',
                        '${qs.length}',
                        const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 12),
                      _attStat('Target', '≥ 60%', const Color(0xFFF59E0B)),
                    ],
                  ),
                ],
              ),
            );
          }),

          // Attainment table
          const SizedBox(height: 8),
          Text(
            'Attainment Levels',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          _levelTable(),
        ],
      ),
    );
  }

  Widget _attStat(String label, String val, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: color.withValues(alpha: 0.15)),
    ),
    child: Column(
      children: [
        Text(
          val,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );

  Widget _levelTable() {
    final rows = [
      ['Level 3', '≥ 70%', 'High Attainment', const Color(0xFF10B981)],
      ['Level 2', '60–70%', 'Moderate Attainment', const Color(0xFFF59E0B)],
      ['Level 1', '50–60%', 'Low Attainment', const Color(0xFFEF4444)],
      ['Level 0', '< 50%', 'Not Attained', const Color(0xFF94A3B8)],
    ];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final i = e.key;
          final r = e.value;
          final color = r[3] as Color;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: i % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
              borderRadius: i == 0
                  ? const BorderRadius.vertical(top: Radius.circular(10))
                  : i == rows.length - 1
                  ? const BorderRadius.vertical(bottom: Radius.circular(10))
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: 72,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    r[0] as String,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  r[1] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                  ),
                  softWrap: false,
                ),
                const SizedBox(width: 16),
                Text(
                  r[2] as String,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── HELPER WIDGETS ────────────────────────────────────────────────────
  Widget _hCell(String text, {required double w}) => Container(
    width: w,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
    decoration: const BoxDecoration(
      color: Color(0xFFF1F5F9),
      border: Border(
        right: BorderSide(color: Color(0xFFCBD5E1)),
        bottom: BorderSide(color: Color(0xFFCBD5E1)),
      ),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF475569),
      ),
    ),
  );

  Widget _qHeader(_Question q) => Container(
    width: 72,
    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
    decoration: const BoxDecoration(
      color: Color(0xFFF8FAFC),
      border: Border(
        right: BorderSide(color: Color(0xFFCBD5E1)),
        bottom: BorderSide(color: Color(0xFFCBD5E1)),
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          q.id,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E293B),
          ),
        ),
        Text(
          '(${q.maxMark % 1 == 0 ? q.maxMark.toInt() : q.maxMark}).${q.co}',
          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF64748B)),
        ),
      ],
    ),
  );

  Widget _dataCell(String text, {required double w}) => Container(
    width: w,
    height: 40,
    alignment: Alignment.center,
    decoration: const BoxDecoration(
      border: Border(
        right: BorderSide(color: Color(0xFFE2E8F0)),
        bottom: BorderSide(color: Color(0xFFF1F5F9)),
      ),
    ),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        color: const Color(0xFF64748B),
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

class _Question {
  final String id, part, co;
  final double maxMark;
  _Question(this.id, this.part, this.co, this.maxMark);
}

class _StudentEntry {
  final String rollNo, name;
  final String studentId;
  bool absent;
  final Map<String, TextEditingController> marks;
  _StudentEntry({
    required this.rollNo,
    required this.name,
    this.studentId = '',
    required this.absent,
    required this.marks,
  });
}
