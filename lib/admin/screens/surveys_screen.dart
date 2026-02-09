import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  bool _isProcessing = false;

  // --- HELPER: SHOW MESSAGES ---
  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // --- ADD SURVEY DIALOG ---
  void _addSurvey(String type) {
    final nameCtrl = TextEditingController();
    String? selectedDept = 'MCA';
    String? selectedBatch = '2024';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Create $type Survey", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Survey Title",
                      hintText: "e.g., Course Feedback 2026",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (type == 'General') ...[
                    DropdownButtonFormField<String>(
                      initialValue: selectedDept,
                      decoration: const InputDecoration(labelText: "Target Department", border: OutlineInputBorder()),
                      items: ['MCA', 'MBA'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                      onChanged: (v) => setDialogState(() => selectedDept = v),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: selectedBatch,
                      decoration: const InputDecoration(labelText: "Target Batch", border: OutlineInputBorder()),
                      items: ['2023', '2024', '2025', '2026'].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (v) => setDialogState(() => selectedBatch = v),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: _isProcessing ? null : () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  String name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    _showMsg("Survey name is required", isError: true);
                    return;
                  }

                  setDialogState(() => _isProcessing = true);
                  final db = FirebaseFirestore.instance.collection('surveys');

                  try {
                    // --- DUPLICATION CHECK ---
                    // Prevent two surveys of the same type having the same name
                    final duplicate = await db.where('type', isEqualTo: type).where('name', isEqualTo: name).get();
                    
                    if (duplicate.docs.isNotEmpty) {
                      _showMsg("A $type survey named '$name' already exists!", isError: true);
                      setDialogState(() => _isProcessing = false);
                      return;
                    }

                    // --- GENERATE UNIQUE ID ---
                    String idPrefix = type == 'Teacher Evaluation' ? "TE" : "GS";
                    String datePart = DateFormat('yyMM').format(DateTime.now());
                    String uniquePart = DateTime.now().millisecond.toString();
                    String generatedId = "$idPrefix-$datePart-$uniquePart";

                    await db.add({
                      'surveyId': generatedId,
                      'name': name,
                      'type': type,
                      'status': 'Active',
                      'department': type == 'General' ? selectedDept : 'All',
                      'batch': type == 'General' ? selectedBatch : 'All',
                      'createdBy': 'Super Admin',
                      'createdAt': FieldValue.serverTimestamp(),
                      'responseCount': 0,
                    });

                    if (mounted) Navigator.pop(context);
                    _showMsg("$type Survey created successfully");
                  } catch (e) {
                    _showMsg("Error: $e", isError: true);
                  } finally {
                    setDialogState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0EA5E9), foregroundColor: Colors.white),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Create Survey"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _deleteSurvey(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Survey?"),
        content: const Text("This will permanently remove the survey and all collected responses."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('surveys').doc(docId).delete();
              Navigator.pop(context);
              _showMsg("Survey deleted", isError: true);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: -1)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),
                  Text("Survey Management",
                      style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                  const SizedBox(height: 8),
                  Text("Publish and monitor institutional feedback forms", style: GoogleFonts.inter(color: Colors.grey)),
                  const SizedBox(height: 32),

                  _buildSectionHeader("Faculty Evaluation", Icons.psychology_outlined, () => _addSurvey("Teacher Evaluation")),
                  const SizedBox(height: 16),
                  _buildSurveyTable("Teacher Evaluation"),

                  const SizedBox(height: 40),

                  _buildSectionHeader("General Feedback", Icons.assignment_outlined, () => _addSurvey("General")),
                  const SizedBox(height: 16),
                  _buildSurveyTable("General"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, VoidCallback onAdd) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF475569), size: 22),
            const SizedBox(width: 10),
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF475569))),
          ],
        ),
        ElevatedButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add, size: 18),
          label: const Text("New Survey"),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0EA5E9),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildSurveyTable(String surveyType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('surveys')
          .where('type', isEqualTo: surveyType)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator();
        var docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
          ),
          child: DataTable(
            horizontalMargin: 24,
            headingRowHeight: 50,
            columns: [
              const DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)))),
              const DataColumn(label: Text("TITLE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)))),
              if (surveyType == 'General') ...[
                const DataColumn(label: Text("TARGET", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)))),
              ],
              const DataColumn(label: Text("RESPONSES", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)))),
              const DataColumn(label: Text("DATE", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)))),
              const DataColumn(label: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0EA5E9)))),
            ],
            rows: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              DateTime? date = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null;

              return DataRow(cells: [
                DataCell(Text(data['surveyId'] ?? "--", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                DataCell(Text(data['name'] ?? "--", style: const TextStyle(fontWeight: FontWeight.w600))),
                if (surveyType == 'General') ...[
                  DataCell(Text("${data['department']} • ${data['batch']}", style: const TextStyle(fontSize: 12))),
                ],
                DataCell(Text(data['responseCount'].toString())),
                DataCell(Text(date != null ? DateFormat('MMM dd, yyyy').format(date) : "Pending")),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.analytics_outlined, size: 18, color: Colors.blueGrey), onPressed: () {}),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: () => _deleteSurvey(doc.id)),
                  ],
                )),
              ]);
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: const Center(child: Text("No active surveys found.", style: TextStyle(color: Colors.grey))),
    );
  }
}