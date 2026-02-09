import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:ui';

class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> with SingleTickerProviderStateMixin {
  final List<String> _semesterOptions = ["Semester I", "Semester II", "Semester III", "Semester IV"];
  late String _selectedSemester;
  final Set<String> _uploadedAssignments = {};
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _selectedSemester = _semesterOptions[0];
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            _buildModernAppBar(),
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _animationController,
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStatsCards(),
                    const SizedBox(height: 24),
                    _buildSummaryTable(_getMockData()),
                    const SizedBox(height: 32),
                    _buildAssignmentsSection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      stretch: true,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        child: FlexibleSpaceBar(
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 70, bottom: 16),
          title: const Text(
            "Assignments",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          background: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(70, 40, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGlassSemesterSelector(),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildGlassSemesterSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSemester,
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 20),
              dropdownColor: const Color(0xFF667EEA),
              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
              items: _semesterOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(color: Colors.white)))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedSemester = val);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    final allDocs = _getMockData();
    final pending = allDocs.where((d) => d['status'] != 'submitted' && !_uploadedAssignments.contains('${d['subject']}_${d['type']}')).length;
    final submitted = allDocs.where((d) => d['status'] == 'submitted' || _uploadedAssignments.contains('${d['subject']}_${d['type']}')).length;
    final overdue = allDocs.where((d) => d['status'] == 'overdue').length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildStatCard("Pending", pending.toString(), const Color(0xFFFF6B6B), Icons.pending_actions)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard("Submitted", submitted.toString(), const Color(0xFF51CF66), Icons.check_circle)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard("Overdue", overdue.toString(), const Color(0xFFFF922B), Icons.warning_amber_rounded)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildSummaryTable(List<dynamic> docs) {
    Map<String, Map<int, dynamic>> subjectMap = {};
    for (var doc in docs) {
      String subject = doc['subject'];
      int type = doc['type'] ?? 1;
      String id = '${subject}_$type';
      if (_uploadedAssignments.contains(id)) {
        var newDoc = Map<String, dynamic>.from(doc);
        newDoc['status'] = 'submitted';
        subjectMap.putIfAbsent(subject, () => {})[type] = newDoc;
      } else {
        subjectMap.putIfAbsent(subject, () => {})[type] = doc;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Text("Assignment Overview", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [const Color(0xFF667EEA).withValues(alpha: 0.1), const Color(0xFF764BA2).withValues(alpha: 0.1)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Expanded(child: Text("SUBJECT", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF667EEA)))),
                SizedBox(width: 50, child: Center(child: Text("I", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA))))),
                SizedBox(width: 50, child: Center(child: Text("II", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA))))),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ...subjectMap.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  Expanded(child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  _buildModernStatusIcon(entry.value[1]),
                  _buildModernStatusIcon(entry.value[2]),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModernStatusIcon(dynamic doc) {
    if (doc == null) return const SizedBox(width: 50, child: Center(child: Text("—", style: TextStyle(color: Colors.grey, fontSize: 18))));
    String status = doc['status'];
    if (status == 'submitted') {
      return SizedBox(
        width: 50,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF51CF66), Color(0xFF37B24D)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFF51CF66).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.check, size: 16, color: Colors.white),
          ),
        ),
      );
    } else if (status == 'overdue') {
      return SizedBox(
        width: 50,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFA5252)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ),
      );
    } else {
      return const SizedBox(width: 50, child: Center(child: Icon(Icons.upload_file, size: 22, color: Color(0xFF667EEA))));
    }
  }

  Widget _buildAssignmentsSection() {
    final allDocs = _getMockData();
    final pendingAssignments = allDocs.where((d) {
      String id = '${d['subject']}_${d['type']}';
      return d['status'] != 'submitted' && !_uploadedAssignments.contains(id);
    }).toList();
    final submittedAssignments = allDocs.where((d) {
      String id = '${d['subject']}_${d['type']}';
      return d['status'] == 'submitted' || _uploadedAssignments.contains(id);
    }).toList();

    return Column(
      children: [
        _buildModernSectionHeader("Pending", const Color(0xFFFF6B6B), Icons.pending_actions, pendingAssignments.length),
        const SizedBox(height: 16),
        _buildHorizontalList(pendingAssignments, isPending: true),
        const SizedBox(height: 32),
        _buildModernSectionHeader("Submitted", const Color(0xFF51CF66), Icons.check_circle_outline, submittedAssignments.length),
        const SizedBox(height: 16),
        _buildHorizontalList(submittedAssignments, isPending: false),
      ],
    );
  }

  Widget _buildModernSectionHeader(String title, Color color, IconData icon, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Text(count.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(List<dynamic> assignments, {required bool isPending}) {
    if (assignments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(isPending ? Icons.check_circle_outline : Icons.celebration, size: 48, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(isPending ? "No pending assignments" : "No submitted assignments yet", style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
              ],
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: assignments.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 16),
        itemBuilder: (ctx, i) => _buildModernAssignmentCard(assignments[i], isPending),
      ),
    );
  }

  Widget _buildModernAssignmentCard(dynamic data, bool isPending) {
    final DateFormat formatter = DateFormat('dd MMM yy');
    DateTime? safeDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    String issued = safeDate(data['issueDate']) != null ? formatter.format(safeDate(data['issueDate'])!) : "N/A";
    String deadlineOrSub;
    String dateLabel;
    
    if (isPending) {
      dateLabel = "DEADLINE";
      deadlineOrSub = safeDate(data['dueDate']) != null ? formatter.format(safeDate(data['dueDate'])!) : "N/A";
    } else {
      dateLabel = "SUBMITTED";
      String id = '${data['subject']}_${data['type']}';
      deadlineOrSub = _uploadedAssignments.contains(id) ? formatter.format(DateTime.now()) : (safeDate(data['submittedDate']) != null ? formatter.format(safeDate(data['submittedDate'])!) : "N/A");
    }

    bool isOverdue = isPending && data['status'] == 'overdue';
    String assignmentId = '${data['subject']}_${data['type']}';
    Color cardColor = isPending ? (isOverdue ? const Color(0xFFFFF5F5) : const Color(0xFFF0F4FF)) : Colors.white;
    Color accentColor = isPending ? (isOverdue ? const Color(0xFFFF6B6B) : const Color(0xFF667EEA)) : const Color(0xFF51CF66);

    return Container(
      width: 300,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(color: accentColor.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accentColor, accentColor.withValues(alpha: 0.7)]),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Text("Assignment ${data['type'] == 1 ? 'I' : 'II'}", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              if (isOverdue)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFFF6B6B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.warning_amber_rounded, size: 12, color: Color(0xFFFF6B6B)), SizedBox(width: 4), Text("OVERDUE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFFF6B6B)))],
                  ),
                )
              else if (!isPending)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF51CF66).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.check_circle, size: 12, color: Color(0xFF51CF66)), SizedBox(width: 4), Text("DONE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF51CF66)))],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(data['subject'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Container(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.calendar_today, size: 11, color: Colors.grey.shade600), const SizedBox(width: 4), Text("ISSUED", style: TextStyle(fontSize: 9, color: Colors.grey.shade600, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 4),
                    Text(issued, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(mainAxisAlignment: MainAxisAlignment.end, children: [Icon(isPending ? Icons.alarm : Icons.check, size: 11, color: isOverdue ? const Color(0xFFFF6B6B) : Colors.grey.shade600), const SizedBox(width: 4), Text(dateLabel, style: TextStyle(fontSize: 9, color: isOverdue ? const Color(0xFFFF6B6B) : Colors.grey.shade600, fontWeight: FontWeight.bold))]),
                    const SizedBox(height: 4),
                    Text(deadlineOrSub, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOverdue ? const Color(0xFFFF6B6B) : Colors.black87)),
                  ],
                ),
              ),
            ],
          ),
          if (isPending) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: ElevatedButton(
                onPressed: () => _handleUpload(context, assignmentId, data['subject']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  shadowColor: accentColor.withValues(alpha: 0.4),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(Icons.cloud_upload_outlined, size: 18), SizedBox(width: 8), Text("Upload Assignment", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleUpload(BuildContext context, String assignmentId, String subject) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null) {
        if (!context.mounted) return;
        
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text("Uploading...", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );

        await Future.delayed(const Duration(seconds: 2));

        setState(() {
          _uploadedAssignments.add(assignmentId);
        });

        if (!context.mounted) return;
        Navigator.pop(context);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text("$subject uploaded successfully!")),
              ],
            ),
            backgroundColor: const Color(0xFF51CF66),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Upload failed. Please try again."),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  List<dynamic> _getMockData() {
    final now = DateTime.now();
    final past = now.subtract(const Duration(days: 5));
    final future = now.add(const Duration(days: 5));

    return [
      {'subject': 'Mathematics I', 'type': 1, 'status': 'overdue', 'issueDate': past, 'dueDate': past, 'semester': 1},
      {'subject': 'Mathematics I', 'type': 2, 'status': 'pending', 'issueDate': now, 'dueDate': future, 'semester': 1},
      {'subject': 'Physics', 'type': 1, 'status': 'submitted', 'issueDate': past, 'dueDate': past, 'submittedDate': past, 'semester': 1},
      {'subject': 'Chemistry', 'type': 1, 'status': 'submitted', 'issueDate': past, 'dueDate': past, 'submittedDate': past, 'semester': 1},
      {'subject': 'Engineering Graphics', 'type': 1, 'status': 'pending', 'issueDate': now, 'dueDate': future, 'semester': 1},
      {'subject': 'Programming in C', 'type': 2, 'status': 'pending', 'issueDate': now, 'dueDate': future, 'semester': 1}
    ];
  }
}
