import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../widgets/hod_sidebar.dart';
import '../../widgets/hod_header.dart';
import 'hod_mark_entry_screen.dart';

class HodEvaluationScreen extends StatefulWidget {
  final String userId;
  final String subjectCode;
  final String subjectName;
  final String batchName;

  const HodEvaluationScreen({
    super.key,
    required this.userId,
    this.subjectCode = '20MCA205',
    this.subjectName = 'Advanced Data Structure',
    this.batchName = 'MCA 2023-25',
  });

  @override
  State<HodEvaluationScreen> createState() => _HodEvaluationScreenState();
}

class _HodEvaluationScreenState extends State<HodEvaluationScreen>
    with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  late TabController _tabController;

  final List<_TabDef> _tabs = [
    _TabDef('Evaluations', Icons.fact_check_outlined),
    _TabDef('Course Outcome', Icons.track_changes_outlined),
    _TabDef('Questions', Icons.quiz_outlined),
    _TabDef('Question Papers', Icons.description_outlined),
    _TabDef('Templates', Icons.article_outlined),
  ];

  // Evaluations filters
  final _nameFilter = TextEditingController();
  String? _typeFilter;
  String _hodName = 'HOD';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadHodName();
  }

  Future<void> _loadHodName() async {
    try {
      final doc = await _db.collection('users').doc(widget.userId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final name = data['fullName'] ?? data['name'] ?? data['displayName'];
        if (name != null && name.toString().isNotEmpty) {
          if (mounted) setState(() => _hodName = name.toString());
          return;
        }
      }
      if (mounted) setState(() => _hodName = widget.userId.split('@')[0]);
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameFilter.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSidebar(activeIndex: 2, userId: widget.userId),
          Expanded(
            child: Stack(
              children: [
                // Indigo gradient (same as Course Plan)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 380,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4F46E5),
                          Color(0xFF4338CA),
                          Color(0xFF3730A3),
                        ],
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                      child: HodHeader(
                        title: 'OBE',
                        userId: widget.userId,
                        showBackButton: true,
                        isWhite: true,
                        showDate: false,
                      ),
                    ),
                    _buildBreadcrumbs(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(40, 12, 40, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTabBar(),
                            const SizedBox(height: 20),
                            _buildTabContent(),
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

  // ── Breadcrumbs ────────────────────────────────────────────────────────────
  Widget _buildBreadcrumbs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        children: [
          _bc('Home'),
          _bcSep(),
          _bc('My Classes'),
          _bcSep(),
          _bc(widget.batchName),
          _bcSep(),
          _bc('${widget.subjectCode} - ${widget.subjectName}'),
          _bcSep(),
          _bc('OBE', isLast: true),
        ],
      ),
    );
  }

  Widget _bc(String t, {bool isLast = false}) => Text(
    t,
    style: GoogleFonts.inter(
      fontSize: 11,
      fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
      color: isLast ? Colors.white : Colors.white.withValues(alpha: 0.7),
    ),
  );

  Widget _bcSep() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Icon(
      Icons.chevron_right_rounded,
      size: 14,
      color: Colors.white.withValues(alpha: 0.4),
    ),
  );

  // ── Glassmorphic Tab Bar ───────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: _tabs
                  .asMap()
                  .entries
                  .map((e) => _tabItem(e.value, e.key))
                  .toList(),
            ),
          ),
          const Spacer(),
          _chip(
            Icons.download_outlined,
            'Export',
            const Color(0xFF10B981),
            const Color(0xFFF0FDF4),
            onTap: () {},
          ),
          const SizedBox(width: 10),
          _chip(
            Icons.add_rounded,
            'Add',
            const Color(0xFF4F46E5),
            const Color(0xFFEEF2FF),
            onTap: _addAction,
          ),
        ],
      ),
    );
  }

  Widget _tabItem(_TabDef tab, int i) {
    final sel = _tabController.index == i;
    return GestureDetector(
      onTap: () => setState(() => _tabController.index = i),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: sel ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: sel
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              tab.icon,
              size: 17,
              color: sel
                  ? const Color(0xFF4F46E5)
                  : Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 7),
            Text(
              tab.label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel
                    ? const Color(0xFF4F46E5)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
    IconData icon,
    String label,
    Color color,
    Color bg, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 7),
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

  void _addAction() {
    switch (_tabController.index) {
      case 0:
        _showEvalDialog();
        break;
      case 1:
        _showCODialog();
        break;
      case 2:
        _showQuestionDialog();
        break;
      case 3:
        _showQPDialog();
        break;
      case 4:
        _showTemplateDialog();
        break;
    }
  }

  // ── Tab Router ─────────────────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _evaluationsTab();
      case 1:
        return _courseOutcomeTab();
      case 2:
        return _questionsTab();
      case 3:
        return _questionPapersTab();
      case 4:
        return _templatesTab();
      default:
        return const SizedBox.shrink();
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 0 — EVALUATIONS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _evaluationsTab() {
    return _card(
      header: _cardHeader(
        'CO Based Evaluations',
        Icons.fact_check_outlined,
        '${widget.subjectCode} · ${widget.subjectName} · ${widget.batchName}',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('obe_evaluations')
            .where('subjectCode', isEqualTo: widget.subjectCode)
            .where('hodId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return _loader();
          final all = snap.data?.docs ?? [];
          final docs = all.where((d) {
            final data = d.data() as Map<String, dynamic>;
            if (_nameFilter.text.isNotEmpty &&
                !(data['name'] ?? '').toString().toLowerCase().contains(
                  _nameFilter.text.toLowerCase(),
                ))
              return false;
            if (_typeFilter != null && (data['type'] ?? '') != _typeFilter)
              return false;
            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _filterRow(),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _resultBadge(docs.length),
              if (docs.isEmpty)
                _empty('No evaluations yet', 'Use "Add" to create one.')
              else
                _evalTable(docs),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _filterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 10),
      child: Row(
        children: [
          SizedBox(
            width: 210,
            height: 36,
            child: TextField(
              controller: _nameFilter,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 13),
              decoration: _searchDeco('Search exam name...'),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 160,
            height: 36,
            child: DropdownButtonFormField<String>(
              value: _typeFilter,
              isDense: true,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF1E293B),
              ),
              hint: Text(
                'All Types',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFFADB5BD),
                ),
              ),
              decoration: _inputDeco(),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Types', style: TextStyle(fontSize: 12)),
                ),
                ...[
                  'Series Exam',
                  'Assignment',
                  'Quiz',
                  'Module Test',
                  'Seminar',
                  'Viva',
                  'CAD',
                ].map(
                  (t) => DropdownMenuItem(
                    value: t,
                    child: Text(t, style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _typeFilter = v),
            ),
          ),
          if (_nameFilter.text.isNotEmpty || _typeFilter != null) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => setState(() {
                _nameFilter.clear();
                _typeFilter = null;
              }),
              icon: const Icon(Icons.close_rounded, size: 13),
              label: Text('Clear', style: GoogleFonts.inter(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _evalTable(List<QueryDocumentSnapshot> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = [
          _C('Exam Name', 3),
          _C('Type', 2),
          _C('Batch', 1),
          _C('Max Mark', 1),
          _C('Duration', 1),
          _C('COs Mapped', 2),
          _C('Created By', 2),
          _C('', 2),
        ];
        return Column(
          children: [
            _tableHeader(cols, padH: 24),
            ...docs.asMap().entries.map((e) {
              final d = e.value.data() as Map<String, dynamic>;
              final creator = d['createdByName']?.toString().isNotEmpty == true
                  ? d['createdByName'].toString()
                  : _hodName;
              final cos = (d['cosMapped'] as List? ?? []).join(', ');
              return _tableRow(
                e.key,
                cols,
                padH: 24,
                cells: [
                  _linkCell(d['name'] ?? 'Untitled'),
                  _badgeCell(d['type'] ?? 'Series Exam'),
                  _textCell(d['batch'] ?? widget.batchName),
                  _textCell('${d['maxMark'] ?? '40'}', bold: true),
                  _textCell(d['duration'] ?? '2 Hrs'),
                  _textCell(cos.isEmpty ? '—' : cos),
                  _avatarNameCell(creator),
                  _actionsCell(
                    onView: () => _showEvalDetail(d, e.value.id),
                    onEdit: () => _showEvalDialog(doc: e.value),
                    onDelete: () => _deleteDoc(
                      'obe_evaluations',
                      e.value.id,
                      d['name'] ?? '',
                    ),
                  ),
                ],
              );
            }),
          ],
        );
      },
    );
  }

  void _showEvalDetail(Map<String, dynamic> d, String docId) {
    final cos = List<String>.from(d['cosMapped'] ?? []);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HodMarkEntryScreen(
          userId: widget.userId,
          evaluationId: docId,
          examName: d['name'] ?? 'Untitled',
          examType: d['type'] ?? 'Series Exam',
          subjectCode: d['subjectCode'] ?? widget.subjectCode,
          subjectName: d['subjectName'] ?? widget.subjectName,
          batchName: d['batch'] ?? widget.batchName,
          cosMapped: cos,
          maxMark: '${d['maxMark'] ?? '40'}',
          isPublished: d['status'] == 'Published',
        ),
      ),
    );
  }

  void _showEvalDialog({QueryDocumentSnapshot? doc}) {
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final n = TextEditingController(text: d['name']);
    final b = TextEditingController(text: d['batch'] ?? widget.batchName);
    final mk = TextEditingController(text: '${d['maxMark'] ?? '40'}');
    final du = TextEditingController(text: d['duration'] ?? '2 Hrs');
    final cr = TextEditingController(text: d['createdByName'] ?? _hodName);
    String type = d['type'] ?? 'Series Exam';
    List<String> selectedCOs = List<String>.from(d['cosMapped'] ?? []);

    _showFormDialog(
      title: doc == null ? 'Add Evaluation' : 'Edit Evaluation',
      icon: Icons.fact_check_outlined,
      builder: (ctx, setS) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _ff('Exam Name', n)),
              const SizedBox(width: 12),
              Expanded(child: _ff('Batch', b)),
            ],
          ),
          const SizedBox(height: 12),
          _dropField(
            'Evaluation Type',
            type,
            [
              'Series Exam',
              'Assignment',
              'Quiz',
              'Module Test',
              'Seminar',
              'Viva',
              'CAD',
            ],
            (v) {
              setS(() => type = v);
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ff('Max Mark', mk, keyboard: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(child: _ff('Duration', du)),
            ],
          ),
          const SizedBox(height: 12),
          // CO mapping checkboxes
          FutureBuilder<QuerySnapshot>(
            future: _db
                .collection('obe_course_outcomes')
                .where('subjectCode', isEqualTo: widget.subjectCode)
                .get(),
            builder: (ctx, snap) {
              final coList =
                  snap.data?.docs
                      .map((d) => (d.data() as Map)['code']?.toString() ?? '')
                      .where((s) => s.isNotEmpty)
                      .toList() ??
                  ['CO1', 'CO2', 'CO3', 'CO4', 'CO5', 'CO6'];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Map Course Outcomes',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: coList.map((co) {
                      final sel = selectedCOs.contains(co);
                      return GestureDetector(
                        onTap: () => setS(() {
                          if (sel)
                            selectedCOs.remove(co);
                          else
                            selectedCOs.add(co);
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: sel
                                ? const Color(0xFF4F46E5)
                                : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: sel
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Text(
                            co,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _ff('Created By', cr),
        ],
      ),
      onSave: () async {
        final payload = {
          'name': n.text.trim(),
          'type': type,
          'batch': b.text.trim(),
          'maxMark': mk.text.trim(),
          'duration': du.text.trim(),
          'cosMapped': selectedCOs,
          'createdByName': cr.text.trim().isEmpty ? _hodName : cr.text.trim(),
          'subjectCode': widget.subjectCode,
          'subjectName': widget.subjectName,
          'hodId': widget.userId,
          'timestamp': FieldValue.serverTimestamp(),
        };
        if (doc == null)
          await _db.collection('obe_evaluations').add(payload);
        else
          await _db.collection('obe_evaluations').doc(doc.id).update(payload);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 1 — COURSE OUTCOMES
  // ════════════════════════════════════════════════════════════════════════════
  Widget _courseOutcomeTab() {
    return _card(
      header: _cardHeader(
        'Course Outcomes',
        Icons.track_changes_outlined,
        '${widget.subjectCode} · ${widget.subjectName}',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('obe_course_outcomes')
            .where('subjectCode', isEqualTo: widget.subjectCode)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return _loader();
          final docs = snap.data?.docs ?? [];
          docs.sort((a, b) {
            final aCode = (a.data() as Map)['code']?.toString() ?? '';
            final bCode = (b.data() as Map)['code']?.toString() ?? '';
            return aCode.compareTo(bCode);
          });

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultBadge(docs.length),
              if (docs.isEmpty)
                _empty(
                  'No course outcomes defined',
                  'Add COs for ${widget.subjectName}.',
                )
              else
                _coTable(docs),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _coTable(List<QueryDocumentSnapshot> docs) {
    final cols = [
      _C('CO Code', 1),
      _C('Description', 4),
      _C('Bloom\'s Level', 2),
      _C('POs Mapped', 2),
      _C('', 1),
    ];
    return Column(
      children: [
        _tableHeader(cols, padH: 24),
        ...docs.asMap().entries.map((e) {
          final d = e.value.data() as Map<String, dynamic>;
          final pos = (d['posMapped'] as List? ?? []).join(', ');
          return _tableRow(
            e.key,
            cols,
            padH: 24,
            cells: [
              _badgeCell(d['code'] ?? 'CO1', color: const Color(0xFF4F46E5)),
              _textCell(d['description'] ?? '—'),
              _bloomBadge(d['bloomLevel'] ?? 'Remember'),
              _textCell(pos.isEmpty ? '—' : pos),
              _actionsCell(
                onEdit: () => _showCODialog(doc: e.value),
                onDelete: () => _deleteDoc(
                  'obe_course_outcomes',
                  e.value.id,
                  d['code'] ?? '',
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  void _showCODialog({QueryDocumentSnapshot? doc}) {
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final code = TextEditingController(text: d['code']);
    final desc = TextEditingController(text: d['description']);
    String bloom = d['bloomLevel'] ?? 'Remember';
    List<String> pos = List<String>.from(d['posMapped'] ?? []);
    final allPOs = [
      'PO1',
      'PO2',
      'PO3',
      'PO4',
      'PO5',
      'PO6',
      'PO7',
      'PO8',
      'PO9',
      'PO10',
      'PO11',
      'PO12',
    ];

    _showFormDialog(
      title: doc == null ? 'Add Course Outcome' : 'Edit Course Outcome',
      icon: Icons.track_changes_outlined,
      builder: (ctx, setS) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _ff('CO Code (e.g. CO1)', code)),
              const SizedBox(width: 12),
              Expanded(
                child: _dropField('Bloom\'s Level', bloom, [
                  'Remember',
                  'Understand',
                  'Apply',
                  'Analyze',
                  'Evaluate',
                  'Create',
                ], (v) => setS(() => bloom = v)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ff('Description', desc, maxLines: 3),
          const SizedBox(height: 12),
          Text(
            "Map Program Outcomes",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: allPOs.map((po) {
              final sel = pos.contains(po);
              return GestureDetector(
                onTap: () => setS(() {
                  if (sel)
                    pos.remove(po);
                  else
                    pos.add(po);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    po,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      onSave: () async {
        final payload = {
          'code': code.text.trim(),
          'description': desc.text.trim(),
          'bloomLevel': bloom,
          'posMapped': pos,
          'subjectCode': widget.subjectCode,
          'subjectName': widget.subjectName,
          'hodId': widget.userId,
          'timestamp': FieldValue.serverTimestamp(),
        };
        if (doc == null)
          await _db.collection('obe_course_outcomes').add(payload);
        else
          await _db
              .collection('obe_course_outcomes')
              .doc(doc.id)
              .update(payload);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 2 — QUESTIONS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _questionsTab() {
    return _card(
      header: _cardHeader(
        'Question Bank',
        Icons.quiz_outlined,
        '${widget.subjectCode} · ${widget.subjectName}',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('obe_questions')
            .where('subjectCode', isEqualTo: widget.subjectCode)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return _loader();
          final docs = snap.data?.docs ?? [];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _resultBadge(docs.length),
              if (docs.isEmpty)
                _empty('No questions added', 'Build your question bank.')
              else
                _questionList(docs),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _questionList(List<QueryDocumentSnapshot> docs) {
    final cols = [
      _C('Q.No', 1),
      _C('Question', 5),
      _C('CO', 1),
      _C('Marks', 1),
      _C('Difficulty', 2),
      _C('', 1),
    ];
    return Column(
      children: [
        _tableHeader(cols, padH: 24),
        ...docs.asMap().entries.map((e) {
          final d = e.value.data() as Map<String, dynamic>;
          return _tableRow(
            e.key,
            cols,
            padH: 24,
            cells: [
              _textCell('${e.key + 1}', bold: true),
              _textCell(d['question'] ?? '—'),
              _badgeCell(d['coCode'] ?? 'CO1', color: const Color(0xFF059669)),
              _textCell('${d['marks'] ?? '2'}', bold: true),
              _diffBadge(d['difficulty'] ?? 'Medium'),
              _actionsCell(
                onEdit: () => _showQuestionDialog(doc: e.value),
                onDelete: () => _deleteDoc(
                  'obe_questions',
                  e.value.id,
                  'Question ${e.key + 1}',
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  void _showQuestionDialog({QueryDocumentSnapshot? doc}) {
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final q = TextEditingController(text: d['question']);
    final mk = TextEditingController(text: '${d['marks'] ?? '2'}');
    String co = d['coCode'] ?? 'CO1';
    String diff = d['difficulty'] ?? 'Medium';

    _showFormDialog(
      title: doc == null ? 'Add Question' : 'Edit Question',
      icon: Icons.quiz_outlined,
      builder: (ctx, setS) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ff('Question', q, maxLines: 4),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _dropField('CO Code', co, [
                  'CO1',
                  'CO2',
                  'CO3',
                  'CO4',
                  'CO5',
                  'CO6',
                ], (v) => setS(() => co = v)),
              ),
              const SizedBox(width: 12),
              Expanded(child: _ff('Marks', mk, keyboard: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(
                child: _dropField('Difficulty', diff, [
                  'Easy',
                  'Medium',
                  'Hard',
                ], (v) => setS(() => diff = v)),
              ),
            ],
          ),
        ],
      ),
      onSave: () async {
        final payload = {
          'question': q.text.trim(),
          'coCode': co,
          'marks': mk.text.trim(),
          'difficulty': diff,
          'subjectCode': widget.subjectCode,
          'hodId': widget.userId,
          'timestamp': FieldValue.serverTimestamp(),
        };
        if (doc == null)
          await _db.collection('obe_questions').add(payload);
        else
          await _db.collection('obe_questions').doc(doc.id).update(payload);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 3 — QUESTION PAPERS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _questionPapersTab() {
    return _card(
      header: _cardHeader(
        'Question Papers',
        Icons.description_outlined,
        '${widget.subjectCode} · ${widget.subjectName}',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('obe_question_papers')
            .where('subjectCode', isEqualTo: widget.subjectCode)
            .where('hodId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return _loader();
          final docs = snap.data?.docs ?? [];
          return Column(
            children: [
              _resultBadge(docs.length),
              if (docs.isEmpty)
                _empty(
                  'No question papers yet',
                  'Create a question paper for this subject.',
                )
              else
                _qpList(docs),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _qpList(List<QueryDocumentSnapshot> docs) {
    final cols = [
      _C('Title', 3),
      _C('Exam Type', 2),
      _C('Total Marks', 1),
      _C('Duration', 1),
      _C('Date', 2),
      _C('Status', 2),
      _C('', 1),
    ];
    return Column(
      children: [
        _tableHeader(cols, padH: 24),
        ...docs.asMap().entries.map((e) {
          final d = e.value.data() as Map<String, dynamic>;
          final ts = d['date'] as String? ?? '—';
          return _tableRow(
            e.key,
            cols,
            padH: 24,
            cells: [
              _linkCell(d['title'] ?? 'Untitled'),
              _textCell(d['examType'] ?? '—'),
              _textCell('${d['totalMarks'] ?? '100'}', bold: true),
              _textCell(d['duration'] ?? '3 Hrs'),
              _textCell(ts),
              _statusBadge(d['status'] ?? 'Draft'),
              _actionsCell(
                onEdit: () => _showQPDialog(doc: e.value),
                onDelete: () => _deleteDoc(
                  'obe_question_papers',
                  e.value.id,
                  d['title'] ?? '',
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  void _showQPDialog({QueryDocumentSnapshot? doc}) {
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final title = TextEditingController(text: d['title']);
    final tm = TextEditingController(text: '${d['totalMarks'] ?? '100'}');
    final dur = TextEditingController(text: d['duration'] ?? '3 Hrs');
    String examType = d['examType'] ?? 'Series Exam 1';
    String status = d['status'] ?? 'Draft';

    _showFormDialog(
      title: doc == null ? 'Create Question Paper' : 'Edit Question Paper',
      icon: Icons.description_outlined,
      builder: (ctx, setS) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ff('Paper Title', title),
          const SizedBox(height: 12),
          _dropField('Exam Type', examType, [
            'Series Exam 1',
            'Series Exam 2',
            'Series Exam 3',
            'Assignment',
            'End Semester',
          ], (v) => setS(() => examType = v)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ff('Total Marks', tm, keyboard: TextInputType.number),
              ),
              const SizedBox(width: 12),
              Expanded(child: _ff('Duration', dur)),
              const SizedBox(width: 12),
              Expanded(
                child: _dropField('Status', status, [
                  'Draft',
                  'Published',
                  'Approved',
                ], (v) => setS(() => status = v)),
              ),
            ],
          ),
        ],
      ),
      onSave: () async {
        final now = DateFormat('dd MMM yyyy').format(DateTime.now());
        final payload = {
          'title': title.text.trim(),
          'examType': examType,
          'totalMarks': tm.text.trim(),
          'duration': dur.text.trim(),
          'status': status,
          'date': now,
          'subjectCode': widget.subjectCode,
          'hodId': widget.userId,
          'timestamp': FieldValue.serverTimestamp(),
        };
        if (doc == null)
          await _db.collection('obe_question_papers').add(payload);
        else
          await _db
              .collection('obe_question_papers')
              .doc(doc.id)
              .update(payload);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 4 — TEMPLATES
  // ════════════════════════════════════════════════════════════════════════════
  Widget _templatesTab() {
    return _card(
      header: _cardHeader(
        'Mark Templates',
        Icons.article_outlined,
        '${widget.subjectCode} · ${widget.subjectName}',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('obe_templates')
            .where('subjectCode', isEqualTo: widget.subjectCode)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return _loader();
          final docs = snap.data?.docs ?? [];
          return Column(
            children: [
              _resultBadge(docs.length),
              if (docs.isEmpty)
                _empty('No templates found', 'Create a mark entry template.')
              else
                _templateList(docs),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
    );
  }

  Widget _templateList(List<QueryDocumentSnapshot> docs) {
    final cols = [
      _C('Template Name', 3),
      _C('Exam Type', 2),
      _C('Max Mark', 1),
      _C('Components', 3),
      _C('', 1),
    ];
    return Column(
      children: [
        _tableHeader(cols, padH: 24),
        ...docs.asMap().entries.map((e) {
          final d = e.value.data() as Map<String, dynamic>;
          final comps = (d['components'] as List? ?? []).join(', ');
          return _tableRow(
            e.key,
            cols,
            padH: 24,
            cells: [
              _linkCell(d['name'] ?? 'Template'),
              _textCell(d['examType'] ?? '—'),
              _textCell('${d['maxMark'] ?? '100'}', bold: true),
              _textCell(comps.isEmpty ? '—' : comps),
              _actionsCell(
                onEdit: () => _showTemplateDialog(doc: e.value),
                onDelete: () =>
                    _deleteDoc('obe_templates', e.value.id, d['name'] ?? ''),
              ),
            ],
          );
        }),
      ],
    );
  }

  void _showTemplateDialog({QueryDocumentSnapshot? doc}) {
    final d = doc?.data() as Map<String, dynamic>? ?? {};
    final name = TextEditingController(text: d['name']);
    final mk = TextEditingController(text: '${d['maxMark'] ?? '100'}');
    String examType = d['examType'] ?? 'Series Exam';
    List<String> comps = List<String>.from(d['components'] ?? []);
    final allComps = [
      'Part A (2 Marks)',
      'Part B (5 Marks)',
      'Part C (10 Marks)',
      'Part D (16 Marks)',
      'Viva',
      'Record',
    ];

    _showFormDialog(
      title: doc == null ? 'Add Template' : 'Edit Template',
      icon: Icons.article_outlined,
      builder: (ctx, setS) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(child: _ff('Template Name', name)),
              const SizedBox(width: 12),
              Expanded(
                child: _ff('Max Mark', mk, keyboard: TextInputType.number),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _dropField('Exam Type', examType, [
            'Series Exam',
            'Assignment',
            'Quiz',
            'End Semester',
          ], (v) => setS(() => examType = v)),
          const SizedBox(height: 12),
          Text(
            'Mark Components',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: allComps.map((c) {
              final sel = comps.contains(c);
              return GestureDetector(
                onTap: () => setS(() {
                  if (sel)
                    comps.remove(c);
                  else
                    comps.add(c);
                }),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: sel
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: sel
                          ? const Color(0xFF4F46E5)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    c,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sel ? Colors.white : const Color(0xFF475569),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
      onSave: () async {
        final payload = {
          'name': name.text.trim(),
          'maxMark': mk.text.trim(),
          'examType': examType,
          'components': comps,
          'subjectCode': widget.subjectCode,
          'hodId': widget.userId,
          'timestamp': FieldValue.serverTimestamp(),
        };
        if (doc == null)
          await _db.collection('obe_templates').add(payload);
        else
          await _db.collection('obe_templates').doc(doc.id).update(payload);
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SHARED WIDGETS
  // ════════════════════════════════════════════════════════════════════════════

  Widget _card({required Widget header, required Widget body}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [header, body],
      ),
    );
  }

  Widget _cardHeader(String title, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4F46E5), size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC7D2FE)),
            ),
            child: Text(
              'KMCT MCA Dept',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF4F46E5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _resultBadge(int count) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 10, 24, 6),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count record${count != 1 ? 's' : ''}',
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF4F46E5),
        ),
      ),
    ),
  );

  Widget _loader() => const Padding(
    padding: EdgeInsets.all(60),
    child: Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
  );

  Widget _empty(String title, String sub) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 56),
    child: Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inbox_outlined,
              size: 40,
              color: Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    ),
  );

  // Table helpers
  Widget _tableHeader(List<_C> cols, {double padH = 16}) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: EdgeInsets.symmetric(horizontal: padH),
      child: Row(
        children: cols
            .map(
              (c) => Expanded(
                flex: c.flex,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    c.label,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.label.isEmpty
                          ? Colors.transparent
                          : const Color(0xFF1565C0),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _tableRow(
    int idx,
    List<_C> cols, {
    required List<Widget> cells,
    double padH = 16,
  }) {
    return Container(
      color: idx % 2 == 0 ? Colors.white : const Color(0xFFFAFAFC),
      padding: EdgeInsets.symmetric(horizontal: padH),
      child: Row(
        children: cells
            .asMap()
            .entries
            .map((e) => Expanded(flex: cols[e.key].flex, child: e.value))
            .toList(),
      ),
    );
  }

  Widget _linkCell(String t) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Text(
      t,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF1565C0),
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.underline,
      ),
    ),
  );

  Widget _textCell(String t, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Text(
      t,
      overflow: TextOverflow.ellipsis,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: bold ? const Color(0xFF1E293B) : const Color(0xFF475569),
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );

  Widget _badgeCell(String t, {Color color = const Color(0xFF4338CA)}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            t,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
      );

  Widget _avatarNameCell(String name) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : 'H',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4F46E5),
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: const Color(0xFF475569),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _actionsCell({
    VoidCallback? onView,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (onView != null) ...[
          _ibtn(Icons.remove_red_eye_outlined, const Color(0xFF64748B), onView),
          const SizedBox(width: 6),
        ],
        _ibtn(Icons.edit_outlined, const Color(0xFF4F46E5), onEdit),
        const SizedBox(width: 6),
        _ibtn(Icons.delete_outline_rounded, const Color(0xFFEF4444), onDelete),
      ],
    ),
  );

  Widget _ibtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 13, color: color),
    ),
  );

  Widget _bloomBadge(String level) {
    const colors = {
      'Remember': Color(0xFF0EA5E9),
      'Understand': Color(0xFF8B5CF6),
      'Apply': Color(0xFF10B981),
      'Analyze': Color(0xFFF59E0B),
      'Evaluate': Color(0xFFEF4444),
      'Create': Color(0xFFEC4899),
    };
    final c = colors[level] ?? const Color(0xFF64748B);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          level,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
      ),
    );
  }

  Widget _diffBadge(String diff) {
    final c = diff == 'Easy'
        ? const Color(0xFF10B981)
        : diff == 'Hard'
        ? const Color(0xFFEF4444)
        : const Color(0xFFF59E0B);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          diff,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final c = status == 'Published'
        ? const Color(0xFF10B981)
        : status == 'Approved'
        ? const Color(0xFF4F46E5)
        : const Color(0xFFF59E0B);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          status,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: c,
          ),
        ),
      ),
    );
  }

  // Form dialog
  void _showFormDialog({
    required String title,
    required IconData icon,
    required Widget Function(BuildContext, StateSetter) builder,
    required Future<void> Function() onSave,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: const Color(0xFF4F46E5), size: 17),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    builder(ctx, setS),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
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
                  await onSave();
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteDoc(String collection, String id, String label) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'Delete "$label"?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF475569),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: const Color(0xFF64748B)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) await _db.collection(collection).doc(id).delete();
  }

  // Form field helpers
  Widget _ff(
    String label,
    TextEditingController ctrl, {
    TextInputType keyboard = TextInputType.text,
    int maxLines = 1,
  }) => TextField(
    controller: ctrl,
    keyboardType: keyboard,
    maxLines: maxLines,
    style: GoogleFonts.inter(fontSize: 13),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF64748B),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFF4F46E5)),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );

  Widget _dropField(
    String label,
    String value,
    List<String> items,
    ValueChanged<String> onChanged,
  ) => DropdownButtonFormField<String>(
    value: value,
    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E293B)),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        color: const Color(0xFF64748B),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(9),
        borderSide: const BorderSide(color: Color(0xFF4F46E5)),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    items: items
        .map(
          (t) => DropdownMenuItem(
            value: t,
            child: Text(t, style: GoogleFonts.inter(fontSize: 13)),
          ),
        )
        .toList(),
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );

  InputDecoration _searchDeco(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFADB5BD)),
    prefixIcon: const Icon(
      Icons.search_rounded,
      size: 16,
      color: Color(0xFF94A3B8),
    ),
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFF4F46E5)),
    ),
  );

  InputDecoration _inputDeco() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  );
}

class _TabDef {
  final String label;
  final IconData icon;
  const _TabDef(this.label, this.icon);
}

class _C {
  final String label;
  final int flex;
  const _C(this.label, this.flex);
}
