import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../widgets/hod_sidebar.dart';
import '../../widgets/hod_header.dart';

class HodCoursePlanScreen extends StatefulWidget {
  final String userId;
  final String subjectCode;
  final String subjectName;
  final String batchName;

  const HodCoursePlanScreen({
    super.key,
    required this.userId,
    this.subjectCode = '20MCA105',
    this.subjectName = 'Data Structures',
    this.batchName = 'MCA 2023-25',
  });

  @override
  State<HodCoursePlanScreen> createState() => _HodCoursePlanScreenState();
}

class _HodCoursePlanScreenState extends State<HodCoursePlanScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _searchQuery = "";
  String _selectedSemester = "IVth";
  final Map<String, List<String>> _primaryAssignments = {};
  final Map<String, List<String>> _scrutinyAssignments = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 1);

    // Initial default assignments for IVth Semester
    _primaryAssignments['20MCA202'] = ["HADI K P"];
    _primaryAssignments['20MCA204'] = ["REMMYA C B"];
    _primaryAssignments['20MCA272'] = ["SHARAFUNNISSA O"];
    _primaryAssignments['20MCA288'] = ["ATHULYA PRABHAKARAN"];
    _primaryAssignments['20MCA232'] = ["HADI K P"];
    _primaryAssignments['20MCA234'] = ["REMMYA C B"];
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
          HodSidebar(activeIndex: 2, userId: widget.userId),
          Expanded(
            child: Stack(
              children: [
                // --- Premium Indigo Aurora Background ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 400,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF4F46E5), // Indigo 600
                          Color(0xFF4338CA), // Indigo 700
                          Color(0xFF3730A3), // Indigo 800
                        ],
                      ),
                    ),
                    child: Opacity(
                      opacity: 0.1,
                      child: CustomPaint(painter: _AuroraPainter()),
                    ),
                  ),
                ),

                // --- Main Content ---
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                      child: HodHeader(
                        title: "Course Plan",
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
                            _buildActionBar(),
                            const SizedBox(height: 12),
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

  Widget _buildBreadcrumbs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        children: [
          _breadcrumbItem("Home"),
          _breadcrumbSep(),
          _breadcrumbItem("My Classes"),
          _breadcrumbSep(),
          _breadcrumbItem(widget.batchName),
          _breadcrumbSep(),
          _breadcrumbItem("${widget.subjectCode} - ${widget.subjectName}"),
          _breadcrumbSep(),
          _breadcrumbItem("Course Plan", isLast: true),
        ],
      ),
    );
  }

  Widget _breadcrumbItem(String text, {bool isLast = false}) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: isLast ? FontWeight.w800 : FontWeight.w600,
        color: isLast ? Colors.white : Colors.white.withValues(alpha: 0.7),
        letterSpacing: 0.2,
      ),
    );
  }

  Widget _breadcrumbSep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Icon(
        Icons.chevron_right_rounded,
        size: 14,
        color: Colors.white.withValues(alpha: 0.4),
      ),
    );
  }

  Widget _buildActionBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        children: [
          // Glassmorphic TabBar
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                _tabItem("Syllabus", Icons.description_outlined, 0),
                _tabItem("Subject Plan", Icons.grid_view_rounded, 1),
                _tabItem("Coverage", Icons.assignment_turned_in_outlined, 2),
                _tabItem("Source Books", Icons.menu_book_outlined, 3),
                _tabItem("Assign Teacher", Icons.person_add_alt_1_outlined, 4),
              ],
            ),
          ),
          const Spacer(),
          _actionButton(
            Icons.info_outline,
            "Instructions",
            const Color(0xFFF59E0B),
            const Color(0xFFFFF7ED),
          ),
        ],
      ),
    );
  }

  Widget _tabItem(String text, IconData icon, int index) {
    bool isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => setState(() => _tabController.index = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
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
              icon,
              size: 20,
              color: isSelected
                  ? const Color(0xFF4F46E5)
                  : Colors.white.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF4F46E5)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_tabController.index) {
      case 0:
        return _buildSyllabusTab();
      case 1:
        return _buildSubjectPlanTab();
      case 2:
        return _buildSubjectCoverageTab();
      case 3:
        return _buildEmptyState("Source Books coming soon");
      case 4:
        return _buildAssignTeacherTab();
      default:
        return _buildEmptyState("Tab content coming soon");
    }
  }

  // --- Assign Teacher Tab (Match Reference Image) ---
  Widget _buildAssignTeacherTab() {
    final Map<String, List<Map<String, String>>> semesterSubjects = {
      "Ist": [
        {"code": "20MCA101", "name": "DISCRETE MATHEMATICS"},
        {"code": "20MCA103", "name": "DIGITAL FUNDAMENTALS & ARCHITECTURE"},
        {"code": "20MCA105", "name": "DATA STRUCTURES"},
        {"code": "20MCA107", "name": "COMPUTER NETWORKS"},
      ],
      "IInd": [
        {"code": "20MCA102", "name": "ADVANCED DBMS"},
        {"code": "20MCA104", "name": "ADVANCED COMPUTER NETWORKS"},
        {"code": "20MCA172", "name": "ADVANCED OS"},
        {"code": "20MCA188", "name": "ARTIFICIAL INTELLIGENCE"},
      ],
      "IIIrd": [
        {"code": "20MCA201", "name": "DATA SCIENCE"},
        {"code": "20MCA203", "name": "ALGORITHM DESIGN"},
        {"code": "20MCA205", "name": "JAVA TECHNOLOGY"},
        {"code": "20MCA241", "name": "DATA SCIENCE LAB"},
      ],
      "IVth": [
        {"code": "20MCA202", "name": "MACHINE LEARNING"},
        {"code": "20MCA204", "name": "CLOUD COMPUTING"},
        {"code": "20MCA272", "name": "DATA ANALYTICS"},
        {"code": "20MCA288", "name": "INTERNET OF THINGS"},
        {"code": "20MCA232", "name": "MACHINE LEARNING LAB"},
        {"code": "20MCA234", "name": "INTERNSHIP & MINI PROJECT"},
      ],
    };

    final subjects = semesterSubjects[_selectedSemester] ?? [];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.list_alt_rounded,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (val) => setState(() => _selectedSemester = val),
                  itemBuilder: (context) => ["Ist", "IInd", "IIIrd", "IVth"]
                      .map(
                        (s) =>
                            PopupMenuItem(value: s, child: Text("$s semester")),
                      )
                      .toList(),
                  child: Row(
                    children: [
                      Text(
                        "Assign Teachers ($_selectedSemester semester)",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: Color(0xFF64748B),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _refExportBtn(),
              ],
            ),
          ),

          // Column Headers
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 40, 40, 0),
            child: Row(
              children: [
                const Expanded(flex: 3, child: SizedBox()),
                Expanded(
                  flex: 4,
                  child: Text(
                    "Assign Teachers to Subject",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(width: 40),
                Expanded(
                  flex: 3,
                  child: Text(
                    "Scrutiny Faculties",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Subject Rows
          Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: subjects
                  .map((s) => _buildReferenceRow(s['code']!, s['name']!))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferenceRow(String code, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Code & Name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$code - $name",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Assign Teachers
          Expanded(
            flex: 4,
            child: _refInputBox(
              chips: _primaryAssignments[code] ?? [],
              placeholder: "Choose faculty",
              onTap: () => _showFacultySelectionDialog(code, true),
              onRemove: (name) {
                setState(() {
                  _primaryAssignments[code]?.remove(name);
                });
              },
            ),
          ),

          const SizedBox(width: 40),

          // Scrutiny
          Expanded(
            flex: 3,
            child: _refInputBox(
              chips: _scrutinyAssignments[code] ?? [],
              placeholder: "Choose faculty",
              onTap: () => _showFacultySelectionDialog(code, false),
              onRemove: (name) {
                setState(() {
                  _scrutinyAssignments[code]?.remove(name);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _refInputBox({
    required List<String> chips,
    required String placeholder,
    required VoidCallback onTap,
    required Function(String) onRemove,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (chips.isEmpty)
              Text(
                placeholder,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ...chips.map(
              (c) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      c,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => onRemove(c),
                      child: const Icon(
                        Icons.close,
                        size: 10,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFacultySelectionDialog(String subjectCode, bool isPrimary) {
    final List<String> facultyNames = [
      "HADI K P",
      "REMMYA C B",
      "SHARAFUNNISSA O",
      "ATHULYA PRABHAKARAN",
      "DR. SARAH JOHNSON",
      "PROF. MICHAEL CHEN",
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isPrimary ? "Assign Teacher" : "Assign Scrutiny Faculty",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Select faculty for $subjectCode",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: facultyNames.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) => ListTile(
                    dense: true,
                    title: Text(
                      facultyNames[index],
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                    onTap: () {
                      setState(() {
                        if (isPrimary) {
                          if (!_primaryAssignments.containsKey(subjectCode)) {
                            _primaryAssignments[subjectCode] = [];
                          }
                          if (!_primaryAssignments[subjectCode]!.contains(
                            facultyNames[index],
                          )) {
                            _primaryAssignments[subjectCode]!.add(
                              facultyNames[index],
                            );
                          }
                        } else {
                          if (!_scrutinyAssignments.containsKey(subjectCode)) {
                            _scrutinyAssignments[subjectCode] = [];
                          }
                          if (!_scrutinyAssignments[subjectCode]!.contains(
                            facultyNames[index],
                          )) {
                            _scrutinyAssignments[subjectCode]!.add(
                              facultyNames[index],
                            );
                          }
                        }
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  Widget _refExportBtn() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.settings_outlined,
            size: 12,
            color: Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Text(
            "Export",
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusTab() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
        children: [
          Row(
            children: [
              const Icon(
                Icons.description_outlined,
                color: Color(0xFF4F46E5),
                size: 30,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Official Syllabus",
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    "Curriculum structure and learning objectives",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download),
                label: const Text("Download PDF"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          _syllabusModule("Module 1: Introduction to Data Structures", [
            "Arrays and Strings",
            "Singly and Doubly Linked Lists",
            "Circular Linked Lists",
          ]),
          const SizedBox(height: 24),
          _syllabusModule("Module 2: Stacks and Queues", [
            "Stack Implementation using Arrays & Lists",
            "Queue Implementation and Variants",
            "Applications of Stacks & Queues",
          ]),
        ],
      ),
    );
  }

  Widget _syllabusModule(String title, List<String> topics) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF4F46E5),
            ),
          ),
          const SizedBox(height: 16),
          ...topics.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    size: 16,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    t,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Subject Plan Tab (Working Drag & Drop) ---
  Widget _buildSubjectPlanTab() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column: Deliveries (DragTarget)
        Expanded(flex: 4, child: _buildDeliveriesSection()),
        const SizedBox(width: 40),
        // Right Column: Outline (Draggable)
        Expanded(flex: 3, child: _buildOutlineSection()),
      ],
    );
  }

  Widget _buildDeliveriesSection() {
    return Column(
      children: [
        // Header Actions
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              _legendItem(const Color(0xFF10B981), "Lecture"),
              const SizedBox(width: 24),
              _legendItem(const Color(0xFF3B82F6), "Special"),
              const Spacer(),
              _outlineBtn(Icons.visibility_outlined, "View Status", () {}),
              const SizedBox(width: 12),
              _outlineBtn(Icons.file_download_outlined, "Export", _exportToPdf),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Deliveries List as DragTarget
        DragTarget<Map<String, dynamic>>(
          onAcceptWithDetails: (details) {
            _showAddDeliveryDialog(prefillTopic: details.data['title']);
          },
          builder: (context, candidateData, rejectedData) {
            bool isHovering = candidateData.isNotEmpty;
            return Container(
              padding: isHovering ? const EdgeInsets.all(12) : EdgeInsets.zero,
              decoration: isHovering
                  ? BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFF4F46E5),
                        width: 2,
                      ),
                    )
                  : null,
              child: StreamBuilder<QuerySnapshot>(
                stream: _db
                    .collection('course_deliveries')
                    .where('subjectCode', isEqualTo: widget.subjectCode)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty && !isHovering) {
                    return _buildNoContent(
                      "No Deliveries Recorded",
                      "Teaching logs for your subjects will appear here.",
                      Icons.history_edu_rounded,
                      action: _buildSlotCreationTip(),
                    );
                  }

                  // Sort by date descending
                  docs.sort((a, b) {
                    final aDate = (a.data() as Map)['date'] as Timestamp;
                    final bDate = (b.data() as Map)['date'] as Timestamp;
                    return bDate.compareTo(aDate);
                  });

                  return Column(
                    children: [
                      if (isHovering)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            "Drop topic here to create slot",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF4F46E5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Wrap(
                        spacing: 24,
                        runSpacing: 24,
                        children: [
                          ...docs.map((doc) => _buildDeliveryCard(doc)),
                          _buildAddSlotCard(),
                        ],
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDeliveryCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final date = (data['date'] as Timestamp).toDate();
    final isCovered = data['isCovered'] ?? false;
    final color = isCovered ? const Color(0xFF10B981) : const Color(0xFF4F46E5);

    return Container(
      width: 260,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('EEE, MMM d yyyy').format(date).toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      "Slot ${data['slot']}",
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCovered ? "DONE" : "PENDING",
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    data['topic'] ?? 'No Topic',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _miniInfo("Hrs", data['hour']?.toString() ?? '1'),
                    const Spacer(),
                    _miniInfo("Type", data['type'] ?? 'Lecture'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      doc.reference.update({'isCovered': !isCovered});
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: color.withValues(alpha: 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isCovered ? "Mark Uncovered" : "Mark Covered",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
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

  Widget _miniInfo(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 9, color: const Color(0xFF94A3B8)),
        ),
        Text(
          val,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildAddSlotCard() {
    return GestureDetector(
      onTap: _showAddDeliveryDialog,
      child: Container(
        width: 260,
        height: 280,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_circle_outline_rounded,
              size: 40,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              "Add Slot",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlineSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                const Icon(
                  Icons.auto_awesome_mosaic_rounded,
                  color: Color(0xFF4F46E5),
                ),
                const SizedBox(width: 16),
                Text(
                  "Course Outline",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _countBadge("Live"),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: "Search topics...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                StreamBuilder<QuerySnapshot>(
                  stream: _db
                      .collection('course_outlines')
                      .where('subjectCode', isEqualTo: widget.subjectCode)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return _buildNoContent(
                        "No syllabus topics",
                        "Add modules to the outline",
                        Icons.library_books_rounded,
                      );
                    }

                    final filtered = docs.where((d) {
                      final title = (d.data() as Map)['title'] ?? '';
                      return title.toString().toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                    }).toList();

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, idx) =>
                          const SizedBox(height: 12),
                      itemBuilder: (ctx, i) =>
                          _buildDraggableTopic(filtered[i]),
                    );
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showAddTopicDialog,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 20,
                    ),
                    label: const Text("Add Custom Topic"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF1E293B),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
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

  Widget _buildDraggableTopic(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isCovered = data['isCovered'] ?? false;

    return Draggable<Map<String, dynamic>>(
      data: {'title': data['title'], 'id': doc.id},
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4338CA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            data['title'],
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _topicCard(data, isCovered),
      ),
      child: _topicCard(data, isCovered),
    );
  }

  Widget _topicCard(Map<String, dynamic> data, bool isCovered) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCovered ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCovered
              ? const Color(0xFF10B981).withValues(alpha: 0.2)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.drag_indicator, color: Color(0xFFCBD5E1)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['title'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    decoration: isCovered ? TextDecoration.lineThrough : null,
                  ),
                ),
                Text(
                  data['desc'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (isCovered)
            const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
        ],
      ),
    );
  }

  // --- Subject Coverage Tab (Reference UI) ---
  Widget _buildSubjectCoverageTab() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(28),
            child: Row(
              children: [
                const Icon(Icons.analytics_outlined, color: Color(0xFF4F46E5)),
                const SizedBox(width: 16),
                Text(
                  "Coverage Analysis",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                _legendItem(Colors.green, "Covered"),
                const SizedBox(width: 16),
                _legendItem(const Color(0xFF3B82F6), "Planned"),
              ],
            ),
          ),
          const Divider(height: 1),
          StreamBuilder<QuerySnapshot>(
            stream: _db
                .collection('course_outlines')
                .where('subjectCode', isEqualTo: widget.subjectCode)
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

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return _buildNoContent(
                  "Analysis Unavailable",
                  "No syllabus data found to analyze",
                  Icons.analytics_outlined,
                );
              }

              return Padding(
                padding: const EdgeInsets.all(32),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    bool covered = data['isCovered'] ?? false;
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: covered
                            ? const Color(0xFF10B981)
                            : const Color(0xFF3B82F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_right_alt,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              data['title'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- UI Helpers ---
  Widget _buildSlotCreationTip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.yellow, size: 18),
          const SizedBox(width: 12),
          Text(
            "Tip: Drag a syllabus topic here to auto-fill",
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoContent(
    String title,
    String subtitle,
    IconData icon, {
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 80),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 50,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          if (action != null) ...[const SizedBox(height: 32), action],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 100),
        child: Text(
          title,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _outlineBtn(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF1E293B)),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF4F46E5),
        ),
      ),
    );
  }

  void _showAddDeliveryDialog({String? prefillTopic}) {
    final topicCtrl = TextEditingController(text: prefillTopic ?? '');
    final slotCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Create Teaching Slot"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: slotCtrl,
              decoration: const InputDecoration(
                labelText: "Slot Number (e.g. 5)",
              ),
            ),
            TextField(
              controller: topicCtrl,
              decoration: const InputDecoration(labelText: "Topic"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (slotCtrl.text.isNotEmpty && topicCtrl.text.isNotEmpty) {
                await _db.collection('course_deliveries').add({
                  'subjectCode': widget.subjectCode,
                  'slot': int.tryParse(slotCtrl.text) ?? 1,
                  'topic': topicCtrl.text,
                  'date': Timestamp.now(),
                  'hour': 1,
                  'type': 'Lecture',
                  'isCovered': false,
                  'markedBy': widget.userId,
                });
                if (!mounted) return;
                Navigator.pop(ctx);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void _showAddTopicDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Add Custom Topic",
          style: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Topic Title",
                hintText: "e.g. Introduction to NoSQL",
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description",
                hintText: "Brief overview of the topic",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                await _db.collection('course_outlines').add({
                  'subjectCode': widget.subjectCode,
                  'id': 'CUS-${DateTime.now().millisecond}',
                  'title': titleController.text.trim(),
                  'desc': descController.text.trim(),
                  'duration': 'N/A',
                  'isCovered': false,
                  'order': 99,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                if (!mounted) return;
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  Future<void> _exportToPdf() async {
    // Basic export implementation
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (ctx) => pw.Center(
          child: pw.Text("Course Plan Report - ${widget.subjectName}"),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (_) => pdf.save());
  }
}

class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.3), 150, paint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.7), 200, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
