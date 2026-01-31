import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Add intl to pubspec.yaml
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class SurveyScreen extends StatelessWidget {
  const SurveyScreen({super.key});

  // --- ADD SURVEY DIALOG ---
  void _addSurvey(BuildContext context, String type) {
    final nameCtrl = TextEditingController();
    String? selectedDept = 'MCA';
    String? selectedBatch = '2024';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Add $type Survey"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: "Survey Name",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                if (type == 'General') ...[
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    decoration: const InputDecoration(
                      labelText: "Department",
                      border: OutlineInputBorder(),
                    ),
                    items: ['MCA', 'MBA', 'CSE', 'ECE']
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedDept = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedBatch,
                    decoration: const InputDecoration(
                      labelText: "Batch",
                      border: OutlineInputBorder(),
                    ),
                    items: ['2023', '2024', '2025', '2026']
                        .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                        .toList(),
                    onChanged: (v) => setState(() => selectedBatch = v),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isNotEmpty) {
                    // GENERATE ID (e.g., TE5-Jul-2023)
                    String idPrefix = type == 'Teacher Evaluation'
                        ? "TE"
                        : "GS";
                    String datePart = DateFormat(
                      'MMM-yyyy',
                    ).format(DateTime.now());
                    String randomNum = DateTime.now().millisecond
                        .toString()
                        .substring(0, 1);
                    String generatedId = "$idPrefix$randomNum-$datePart";

                    await FirebaseFirestore.instance.collection('surveys').add({
                      'surveyId': generatedId,
                      'name': nameCtrl.text,
                      'type': type, // 'Teacher Evaluation' or 'General'
                      'status': 'Active',
                      'department': type == 'General' ? selectedDept : 'All',
                      'batch': type == 'General' ? selectedBatch : 'All',
                      'createdBy': 'admin',
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DELETE SURVEY ---
  void _deleteSurvey(String docId) {
    FirebaseFirestore.instance.collection('surveys').doc(docId).delete();
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),
                  Text(
                    "Survey Management",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 1. TEACHER EVALUATION SECTION
                  _buildSectionHeader(
                    "Teacher Evaluation Surveys",
                    () => _addSurvey(context, "Teacher Evaluation"),
                  ),
                  const SizedBox(height: 16),
                  _buildSurveyTable(context, "Teacher Evaluation"),

                  const SizedBox(height: 40),

                  // 2. GENERAL SURVEYS SECTION
                  _buildSectionHeader(
                    "General Surveys",
                    () => _addSurvey(context, "General"),
                  ),
                  const SizedBox(height: 16),
                  _buildSurveyTable(context, "General"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withOpacity(0.5),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.analytics_outlined,
                size: 20,
                color: Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add, size: 16),
            label: const Text("Add a Survey"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0EA5E9), // Light Blue
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSurveyTable(BuildContext context, String surveyType) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('surveys')
          .where('type', isEqualTo: surveyType)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator();
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Text(
              "No surveys found.",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(4),
          ),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
            columns: [
              const DataColumn(
                label: Text(
                  "Survey Id",
                  style: TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const DataColumn(
                label: Text(
                  "Name",
                  style: TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (surveyType == 'General') ...[
                const DataColumn(
                  label: Text(
                    "Department",
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const DataColumn(
                  label: Text(
                    "Batch",
                    style: TextStyle(
                      color: Color(0xFF0EA5E9),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              const DataColumn(
                label: Text(
                  "Status",
                  style: TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const DataColumn(
                label: Text(
                  "Created By",
                  style: TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const DataColumn(
                label: Text(
                  "Create Time",
                  style: TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const DataColumn(
                label: Text(
                  "Action",
                  style: TextStyle(
                    color: Color(0xFF0EA5E9),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            rows: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;

              // Format Timestamp
              String timeStr = "--";
              if (data['createdAt'] != null) {
                timeStr = DateFormat(
                  'yyyy-MM-dd\nHH:mm:ss',
                ).format((data['createdAt'] as Timestamp).toDate());
              }

              return DataRow(
                cells: [
                  DataCell(Text(data['surveyId'] ?? "")),
                  DataCell(
                    Text(
                      data['name'] ?? "",
                      style: const TextStyle(color: Color(0xFF0EA5E9)),
                    ),
                  ), // Blue Link color
                  if (surveyType == 'General') ...[
                    DataCell(Text(data['department'] ?? "")),
                    DataCell(Text(data['batch'] ?? "")),
                  ],
                  DataCell(Text(data['status'] ?? "Active")),
                  DataCell(Text(data['createdBy'] ?? "admin")),
                  DataCell(Text(timeStr, style: const TextStyle(fontSize: 11))),
                  DataCell(
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                        size: 18,
                      ),
                      onPressed: () => _deleteSurvey(doc.id),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
