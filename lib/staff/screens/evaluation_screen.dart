import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/staff_sidebar.dart';

class EvaluationScreen extends StatefulWidget {
  final String userId;
  const EvaluationScreen({super.key, required this.userId});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final List<String> _tabs = [
    'Evaluations',
    'Course Outcome',
    'Questions',
    'Question Papers',
    'Sample Sheets',
    'Templates',
    'Survey',
    'University Exam',
  ];
  int _activeTab = 0;

  final _nameFilter = TextEditingController();
  String? _typeFilter;

  @override
  void dispose() {
    _nameFilter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffSidebar(activeIndex: 2, userId: widget.userId),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle(),
                        const SizedBox(height: 20),
                        _buildTableCard(),
                      ],
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

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 18, 28, 0),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OBE',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Outcome Based Education Management',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                _ghostBtn(Icons.bar_chart_outlined, 'Overall Attainment'),
                const SizedBox(width: 10),
                _ghostBtn(
                  Icons.download_outlined,
                  'Export CSV',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            const Icon(
                              Icons.download_done_rounded,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'CSV exported successfully',
                              style: GoogleFonts.inter(),
                            ),
                          ],
                        ),
                        backgroundColor: const Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _primaryBtn(
                  Icons.add_rounded,
                  'Add Evaluation',
                  onTap: _showAddDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _buildTabBar(),
        ],
      ),
    );
  }

  Widget _ghostBtn(IconData icon, String label, {VoidCallback? onTap}) =>
      InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE2E8F0)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: const Color(0xFF475569)),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _primaryBtn(IconData icon, String label, {VoidCallback? onTap}) =>
      ElevatedButton.icon(
        onPressed: onTap ?? () {},
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4F46E5),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
      );

  Widget _buildTabBar() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        itemCount: _tabs.length,
        itemBuilder: (context, i) {
          final active = i == _activeTab;
          return GestureDetector(
            onTap: () => setState(() => _activeTab = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: active
                        ? const Color(0xFF4F46E5)
                        : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  _tabs[i],
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.table_rows_rounded,
            color: Color(0xFF4F46E5),
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'CO Based Evaluations',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildTableCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('evaluations')
            .where('staffId', isEqualTo: widget.userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(80),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF4F46E5)),
              ),
            );
          }
          final docs = (snapshot.data?.docs ?? []).where((doc) {
            final d = doc.data() as Map<String, dynamic>;
            if (_nameFilter.text.isNotEmpty &&
                !(d['name'] ?? '').toString().toLowerCase().contains(
                  _nameFilter.text.toLowerCase(),
                ))
              return false;
            if (_typeFilter != null &&
                _typeFilter!.isNotEmpty &&
                (d['type'] ?? '') != _typeFilter)
              return false;
            return true;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFilterRow(),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${docs.length} result${docs.length != 1 ? 's' : ''}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                ),
              ),
              docs.isEmpty ? _buildEmptyState() : _buildTable(docs),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          SizedBox(
            width: 220,
            height: 38,
            child: TextField(
              controller: _nameFilter,
              onChanged: (_) => setState(() {}),
              style: GoogleFonts.inter(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Search exam name...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 17,
                  color: Color(0xFF94A3B8),
                ),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 180,
            height: 38,
            child: DropdownButtonFormField<String>(
              value: _typeFilter,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF1E293B),
              ),
              hint: Text(
                'All Types',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFFADB5BD),
                ),
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('All Types', style: TextStyle(fontSize: 13)),
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
                    child: Text(t, style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => _typeFilter = v),
            ),
          ),
          if (_nameFilter.text.isNotEmpty || _typeFilter != null) ...[
            const SizedBox(width: 10),
            TextButton.icon(
              onPressed: () => setState(() {
                _nameFilter.clear();
                _typeFilter = null;
              }),
              icon: const Icon(Icons.close_rounded, size: 14),
              label: Text('Clear', style: GoogleFonts.inter(fontSize: 13)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTable(List<QueryDocumentSnapshot> docs) {
    const cols = [
      'Exam Name',
      'Type',
      'Batch',
      'Subject',
      'Total Mark',
      'Total Time',
      'Created By',
      '',
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF8FAFC),
            child: Row(
              children: cols
                  .map(
                    (c) => Container(
                      width: _colWidth(c),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 13,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE2E8F0)),
                          bottom: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                      child: Text(
                        c,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.isEmpty
                              ? Colors.transparent
                              : const Color(0xFF1565C0),
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          ...docs.asMap().entries.map(
            (e) => _buildRow(
              e.value.id,
              e.value.data() as Map<String, dynamic>,
              e.key,
            ),
          ),
        ],
      ),
    );
  }

  double _colWidth(String col) {
    switch (col) {
      case 'Exam Name':
        return 180;
      case 'Type':
        return 140;
      case 'Batch':
        return 90;
      case 'Subject':
        return 180;
      case 'Total Mark':
        return 110;
      case 'Total Time':
        return 110;
      case 'Created By':
        return 160;
      default:
        return 110;
    }
  }

  Widget _buildRow(String docId, Map<String, dynamic> d, int idx) {
    final isEven = idx % 2 == 0;
    return Container(
      color: isEven ? Colors.white : const Color(0xFFFAFAFC),
      child: Row(
        children: [
          Container(
            width: 180,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: InkWell(
              onTap: () {},
              child: Text(
                d['name'] ?? 'Untitled',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF1565C0),
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
          Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _typeColor(d['type'])[0],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                d['type'] ?? 'Series Exam',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _typeColor(d['type'])[1],
                ),
              ),
            ),
          ),
          _cell(d['batch'] ?? '2025', 90),
          _cell(d['subject'] ?? '—', 180),
          _cell('${d['totalMark'] ?? '40'}', 110, bold: true),
          _cell(d['duration'] ?? '2 Hrs', 110),
          Container(
            width: 160,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(
                    0xFF4F46E5,
                  ).withValues(alpha: 0.1),
                  child: Text(
                    (d['createdByName'] ?? 'F')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF4F46E5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d['createdByName'] ?? 'Faculty',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 110,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _rowIconBtn(
                  Icons.remove_red_eye_outlined,
                  const Color(0xFF64748B),
                  () {},
                ),
                const SizedBox(width: 8),
                _rowIconBtn(
                  Icons.edit_outlined,
                  const Color(0xFF4F46E5),
                  () => _showEditDialog(docId, d),
                ),
                const SizedBox(width: 8),
                _rowIconBtn(
                  Icons.delete_outline_rounded,
                  const Color(0xFFEF4444),
                  () => _showDeleteDialog(docId, d['name'] ?? ''),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List _typeColor(String? type) {
    switch (type) {
      case 'Series Exam':
        return [const Color(0xFFEEF2FF), const Color(0xFF4338CA)];
      case 'Assignment':
        return [const Color(0xFFF0FDF4), const Color(0xFF166534)];
      case 'Quiz':
        return [const Color(0xFFFFF7ED), const Color(0xFF9A3412)];
      case 'Module Test':
        return [const Color(0xFFFFF1F2), const Color(0xFF9F1239)];
      case 'Seminar':
        return [const Color(0xFFF0F9FF), const Color(0xFF075985)];
      case 'Viva':
        return [const Color(0xFFFDF4FF), const Color(0xFF7E22CE)];
      default:
        return [const Color(0xFFF1F5F9), const Color(0xFF334155)];
    }
  }

  Widget _cell(String text, double width, {bool bold = false}) => Container(
    width: width,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: bold ? const Color(0xFF1E293B) : const Color(0xFF475569),
        fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
      ),
    ),
  );

  Widget _rowIconBtn(IconData icon, Color color, VoidCallback onTap) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(6),
    child: Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 14, color: color),
    ),
  );

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      child: Center(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.library_books_outlined,
                size: 48,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No Evaluations Yet',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first evaluation using the button above.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddDialog,
              icon: const Icon(Icons.add_rounded),
              label: Text(
                'Add Evaluation',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog() {
    final nameCtrl = TextEditingController();
    final batchCtrl = TextEditingController(text: '2025');
    final subjectCtrl = TextEditingController();
    final markCtrl = TextEditingController(text: '40');
    final durationCtrl = TextEditingController(text: '2 Hrs');
    final createdByCtrl = TextEditingController();
    String type = 'Series Exam';
    _showFormDialog(
      title: 'Add New Evaluation',
      nameCtrl: nameCtrl,
      batchCtrl: batchCtrl,
      subjectCtrl: subjectCtrl,
      markCtrl: markCtrl,
      durationCtrl: durationCtrl,
      createdByCtrl: createdByCtrl,
      type: type,
      onTypeChanged: (v) => type = v,
      onSave: () async {
        await _db.collection('evaluations').add({
          'name': nameCtrl.text.trim(),
          'type': type,
          'batch': batchCtrl.text.trim(),
          'subject': subjectCtrl.text.trim(),
          'totalMark': markCtrl.text.trim(),
          'duration': durationCtrl.text.trim(),
          'createdByName': createdByCtrl.text.trim().isEmpty
              ? 'Faculty'
              : createdByCtrl.text.trim(),
          'staffId': widget.userId,
          'category': type,
          'status': 'Unpublished',
          'timestamp': FieldValue.serverTimestamp(),
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        });
      },
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> d) {
    final nameCtrl = TextEditingController(text: d['name']);
    final batchCtrl = TextEditingController(text: d['batch'] ?? '2025');
    final subjectCtrl = TextEditingController(text: d['subject']);
    final markCtrl = TextEditingController(text: '${d['totalMark'] ?? '40'}');
    final durationCtrl = TextEditingController(text: d['duration'] ?? '2 Hrs');
    final createdByCtrl = TextEditingController(text: d['createdByName'] ?? '');
    String type = d['type'] ?? 'Series Exam';
    _showFormDialog(
      title: 'Edit Evaluation',
      nameCtrl: nameCtrl,
      batchCtrl: batchCtrl,
      subjectCtrl: subjectCtrl,
      markCtrl: markCtrl,
      durationCtrl: durationCtrl,
      createdByCtrl: createdByCtrl,
      type: type,
      onTypeChanged: (v) => type = v,
      onSave: () async {
        await _db.collection('evaluations').doc(docId).update({
          'name': nameCtrl.text.trim(),
          'type': type,
          'batch': batchCtrl.text.trim(),
          'subject': subjectCtrl.text.trim(),
          'totalMark': markCtrl.text.trim(),
          'duration': durationCtrl.text.trim(),
          'createdByName': createdByCtrl.text.trim().isEmpty
              ? 'Faculty'
              : createdByCtrl.text.trim(),
        });
      },
    );
  }

  void _showFormDialog({
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController batchCtrl,
    required TextEditingController subjectCtrl,
    required TextEditingController markCtrl,
    required TextEditingController durationCtrl,
    required TextEditingController createdByCtrl,
    required String type,
    required ValueChanged<String> onTypeChanged,
    required Future<void> Function() onSave,
  }) {
    String localType = type;
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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_document,
                    color: Color(0xFF4F46E5),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            'Exam Name',
                            nameCtrl,
                            icon: Icons.short_text_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _formField(
                            'Batch',
                            batchCtrl,
                            icon: Icons.school_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _formField(
                      'Subject',
                      subjectCtrl,
                      icon: Icons.menu_book_outlined,
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      value: localType,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF1E293B),
                      ),
                      decoration: InputDecoration(
                        labelText: 'Evaluation Type',
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: const Color(0xFF64748B),
                        ),
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                          size: 18,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                      items:
                          [
                                'Series Exam',
                                'Assignment',
                                'Quiz',
                                'Module Test',
                                'Seminar',
                                'Viva',
                                'CAD',
                              ]
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t,
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setS(() => localType = v);
                          onTypeChanged(v);
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _formField(
                            'Total Mark',
                            markCtrl,
                            icon: Icons.score_outlined,
                            keyboard: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _formField(
                            'Duration',
                            durationCtrl,
                            icon: Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _formField(
                      'Exam Created By',
                      createdByCtrl,
                      icon: Icons.person_outline_rounded,
                    ),
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

  void _showDeleteDialog(String docId, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Delete Evaluation',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$name"? This action cannot be undone.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: const Color(0xFF475569),
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
              await _db.collection('evaluations').doc(docId).delete();
              if (ctx.mounted) Navigator.pop(ctx);
            },
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
  }

  Widget _formField(
    String label,
    TextEditingController ctrl, {
    IconData? icon,
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: GoogleFonts.inter(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          color: const Color(0xFF64748B),
        ),
        prefixIcon: icon != null
            ? Icon(icon, size: 18, color: const Color(0xFF94A3B8))
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4F46E5)),
        ),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}
