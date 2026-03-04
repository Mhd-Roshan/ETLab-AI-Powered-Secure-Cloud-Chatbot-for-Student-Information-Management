import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../widgets/staff_sidebar.dart';
import '../widgets/staff_header.dart';

class EvaluationScreen extends StatefulWidget {
  final String userId;
  const EvaluationScreen({super.key, required this.userId});

  @override
  State<EvaluationScreen> createState() => _EvaluationScreenState();
}

class _EvaluationScreenState extends State<EvaluationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    "Series Exam",
    "Assignments",
    "Class Projects",
    "Quizzes",
    "Tutorials",
    "Module Test",
    "Homeworks",
    "Viva",
    "Seminar",
    "CAD",
  ];

  // Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
          StaffSidebar(activeIndex: 2, userId: widget.userId),
          Expanded(
            child: Stack(
              children: [
                // --- Premium Aurora Background ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 320,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF001FF4),
                          Color(0xFF4F46E5),
                          Color(0xFF7C3AED),
                        ],
                      ),
                    ),
                  ),
                ),

                // --- Main Content ---
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(40, 32, 40, 0),
                      child: StaffHeader(
                        title: "Evaluations",
                        userId: widget.userId,
                        showBackButton: true,
                        isWhite: true,
                        showDate: false,
                      ),
                    ),
                    // Breadcrumbs matching the image
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.home_outlined,
                            color: Colors.white.withOpacity(0.8),
                            size: 14,
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withOpacity(0.5),
                            size: 14,
                          ),
                          Text(
                            "My Classes",
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withOpacity(0.5),
                            size: 14,
                          ),
                          Text(
                            "MCA - 1st semester",
                            style: GoogleFonts.inter(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 11,
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.white.withOpacity(0.5),
                            size: 14,
                          ),
                          Text(
                            "Series Exams",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "Analyze and manage student performance data across all assessment types.",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildModernTabBar(),

                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        physics: const BouncingScrollPhysics(),
                        children: _tabs
                            .map((tab) => _buildTabContent(tab))
                            .toList(),
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

  Widget _buildModernTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: const Color(0xFF001FF4),
        unselectedLabelColor: Colors.white,
        dividerColor: Colors.transparent,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: _tabs.map((tab) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('evaluations')
                .where('category', isEqualTo: tab)
                .snapshots(),
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
              return Tab(
                height: 44,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    Text(tab),
                    if (count > 0 || tab == "Series Exam") ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF001FF4).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "$count",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabContent(String tabTitle) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.08),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          children: [
            // Card Header
            Padding(
              padding: const EdgeInsets.all(32),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: Color(0xFF4F46E5),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$tabTitle Management",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        "Configure and track results",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () => _showAddDialog(tabTitle),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text("Create New"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF1F5F9),
                      foregroundColor: const Color(0xFF001FF4),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Dynamic Content: Real-time Database Stream
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('evaluations')
                  .where('category', isEqualTo: tabTitle)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(80),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF001FF4),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return _buildEmptyState(tabTitle);
                }

                return _buildEvaluationList(tabTitle, docs);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String tabTitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 8),
                ),
              ),
              const Icon(
                Icons.collections_bookmark_rounded,
                color: Color(0xFF3B82F6),
                size: 40,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            "No $tabTitle Found",
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Text(
              "Your ${tabTitle.toLowerCase()} list is currently empty for this semester. Click the button below to initialize your first assessment.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF94A3B8),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF001FF4).withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () => _showAddDialog(tabTitle),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
              label: Text("Compute My First $tabTitle"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001FF4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationList(
    String tabTitle,
    List<QueryDocumentSnapshot> docs,
  ) {
    if (tabTitle == "Series Exam") {
      return _buildSeriesExamTable(tabTitle, docs);
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: docs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = docs[index].data() as Map<String, dynamic>;
        final docId = docs[index].id;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: Color(0xFF001FF4),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['name'],
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSeriesExamTable(
    String tabTitle,
    List<QueryDocumentSnapshot> docs,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        children: [
          // Table Headers
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildColHeader("Name")),
                Expanded(child: _buildColHeader("Type")),
                Expanded(child: _buildColHeader("Export")),
                Expanded(child: _buildColHeader("Status")),
                Expanded(child: _buildColHeader("Date")),
                Expanded(
                  child: _buildColHeader("Actions", align: TextAlign.right),
                ),
              ],
            ),
          ),
          // Table Rows
          ...docs.map((doc) {
            final item = doc.data() as Map<String, dynamic>;
            final docId = doc.id;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF8FAFC))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      item['name'] ?? "Untitled",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF001FF4),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['type'] ?? "OFFLINE EXAM",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1E293B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "✅ Downloaded report for ${item['name']}",
                            ),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: const Color(0xFF10B981),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      child: Text(
                        "Download Report",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF3B82F6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['status'] ?? "Results published",
                      style: GoogleFonts.inter(
                        color:
                            (item['status'] == "Unpublished" ||
                                item['status'] == "Draft")
                            ? const Color(0xFF94A3B8)
                            : const Color(0xFF64748B),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item['date'] ?? "N/A",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.remove_red_eye_outlined,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 16),
                        InkWell(
                          onTap: () {
                            final newStatus = item['status'] == "Unpublished"
                                ? "Results published"
                                : "Unpublished";
                            _firestore
                                .collection('evaluations')
                                .doc(docId)
                                .update({'status': newStatus});

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  newStatus == "Unpublished"
                                      ? "Result unpublished successfully"
                                      : "Result published successfully",
                                ),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 1),
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          },
                          child: Text(
                            item['status'] == "Unpublished"
                                ? "Publish result"
                                : "Unpublish result",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF3B82F6),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildColHeader(String title, {TextAlign align = TextAlign.left}) {
    return Text(
      title,
      textAlign: align,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1E293B),
        letterSpacing: 0.5,
      ),
    );
  }

  void _showAddDialog(String tabTitle) {
    final nameController = TextEditingController();
    final dateController = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    String selectedType = "OFFLINE EXAM";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Text(
            "Create New $tabTitle",
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Assessment Name",
                    hintText: "e.g. $tabTitle 1",
                    prefixIcon: const Icon(Icons.edit_note_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: "Assessment Type",
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ["OFFLINE EXAM", "ONLINE EXAM", "VIVA", "PRACTICAL"]
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedType = val);
                  },
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: dateController,
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Assessment Date",
                    prefixIcon: const Icon(Icons.calendar_today_rounded),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (pickedDate != null) {
                      setDialogState(() {
                        dateController.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(pickedDate);
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Cancel",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await _firestore.collection('evaluations').add({
                    'name': nameController.text,
                    'category': tabTitle,
                    'type': selectedType,
                    'max_marks': "100",
                    'date': dateController.text,
                    'status': 'Results published',
                    'timestamp': FieldValue.serverTimestamp(),
                    'staffId': widget.userId,
                  });

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "✅ Successfully created ${nameController.text}",
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: const Color(0xFF10B981),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
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
              ),
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }
}

