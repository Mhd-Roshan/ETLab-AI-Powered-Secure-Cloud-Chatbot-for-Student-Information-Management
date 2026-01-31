import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({super.key});

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  // Navigation State
  String? _selectedDept;
  String? _selectedBatch;

  // Data Lists
  final List<String> _departments = [
    'MCA',
    'MBA',
    'CSE',
    'ECE',
    'ME',
    'CE',
    'EEE',
  ];

  // Generate Batches (e.g., 2021-2023 to 2026-2028)
  final List<String> _batches = List.generate(6, (index) {
    int startYear = 2021 + index;
    return "$startYear-${startYear + 2}"; // Assuming 2-year courses like MCA/MBA. Change logic for B.Tech (4 years)
  });

  // --- CRUD: ADD / EDIT STUDENT ---
  void _showStudentForm({String? docId, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final fNameCtrl = TextEditingController(text: data?['firstName'] ?? '');
    final lNameCtrl = TextEditingController(text: data?['lastName'] ?? '');
    final regCtrl = TextEditingController(
      text: data?['registrationNumber'] ?? '',
    );
    final emailCtrl = TextEditingController(text: data?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: data?['phone'] ?? '');

    // Status defaults to active
    String status = data?['status'] ?? 'active';

    bool isEdit = docId != null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(
              isEdit ? "Edit Student" : "Add New Student",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Breadcrumb Context
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Adding to $_selectedDept • $_selectedBatch",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildInput("First Name", fNameCtrl)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildInput("Last Name", lNameCtrl)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInput("Registration No.", regCtrl),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildInput("Email", emailCtrl)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildInput("Phone", phoneCtrl)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: status,
                        decoration: const InputDecoration(
                          labelText: "Status",
                          border: OutlineInputBorder(),
                        ),
                        items: ['active', 'inactive', 'suspended']
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.toUpperCase()),
                              ),
                            )
                            .toList(),
                        onChanged: (val) => setState(() => status = val!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (formKey.currentState!.validate()) {
                    Map<String, dynamic> studentData = {
                      'firstName': fNameCtrl.text,
                      'lastName': lNameCtrl.text,
                      'registrationNumber': regCtrl.text,
                      'email': emailCtrl.text,
                      'phone': phoneCtrl.text,
                      'department': _selectedDept, // Auto-assigned from context
                      'batch': _selectedBatch, // Auto-assigned from context
                      'status': status,
                    };

                    if (!isEdit) {
                      studentData['createdAt'] = FieldValue.serverTimestamp();
                    }

                    if (isEdit) {
                      await FirebaseFirestore.instance
                          .collection('students')
                          .doc(docId)
                          .update(studentData);
                    } else {
                      await FirebaseFirestore.instance
                          .collection('students')
                          .add(studentData);
                    }
                    if (mounted) Navigator.pop(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: Text(isEdit ? "Update" : "Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl) {
    return TextFormField(
      controller: ctrl,
      validator: (v) => v!.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  // --- CRUD: DELETE ---
  Future<void> _deleteStudent(String docId) async {
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Student?"),
            content: const Text("This cannot be undone."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(docId)
          .delete();
    }
  }

  // --- NAVIGATION HELPERS ---
  void _resetSelection() {
    setState(() {
      if (_selectedBatch != null) {
        _selectedBatch = null;
      } else {
        _selectedDept = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 1)),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),

                  // BREADCRUMBS & HEADER
                  Row(
                    children: [
                      if (_selectedDept != null)
                        IconButton(
                          onPressed: _resetSelection,
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.black87,
                          ),
                        ),
                      Text(
                        _selectedBatch != null
                            ? "$_selectedDept > Batch $_selectedBatch"
                            : _selectedDept != null
                            ? "$_selectedDept Departments"
                            : "Select Department",
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      // Only show Add Button if we are in the Student List view
                      if (_selectedBatch != null)
                        ElevatedButton.icon(
                          onPressed: () => _showStudentForm(),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Student"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- CONDITIONAL RENDERING ---
                  if (_selectedDept == null)
                    _buildDepartmentGrid()
                  else if (_selectedBatch == null)
                    _buildBatchGrid()
                  else
                    _buildStudentList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- VIEW 1: DEPARTMENTS ---
  Widget _buildDepartmentGrid() {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: _departments.map((dept) {
        return _buildSelectionCard(
          title: dept,
          subtitle: "Department",
          icon: Icons.business,
          color: Colors.blueAccent,
          onTap: () => setState(() => _selectedDept = dept),
        );
      }).toList(),
    );
  }

  // --- VIEW 2: BATCHES ---
  Widget _buildBatchGrid() {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: _batches.map((batch) {
        return _buildSelectionCard(
          title: batch,
          subtitle: "Academic Year",
          icon: Icons.calendar_today_rounded,
          color: Colors.orangeAccent,
          onTap: () => setState(() => _selectedBatch = batch),
        );
      }).toList(),
    );
  }

  // --- VIEW 3: STUDENT LIST (FIREBASE) ---
  Widget _buildStudentList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .where('department', isEqualTo: _selectedDept)
            .where('batch', isEqualTo: _selectedBatch)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );

          final students = snapshot.data?.docs ?? [];

          if (students.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(60),
                child: Column(
                  children: [
                    Icon(
                      Icons.person_off_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No students found in $_selectedDept ($_selectedBatch)",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Click 'Add Student' to create records.",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return DataTable(
            columnSpacing: 20,
            horizontalMargin: 32,
            headingRowHeight: 60,
            dataRowMinHeight: 60,
            dataRowMaxHeight: 60,
            columns: const [
              DataColumn(
                label: Text(
                  "Name",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Reg No",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Contact",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Status",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Actions",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: students.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.blue.shade50,
                          child: Text(
                            (data['firstName']?[0] ?? "U"),
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "${data['firstName']} ${data['lastName']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              data['email'] ?? "",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(data['registrationNumber'] ?? "--")),
                  DataCell(Text(data['phone'] ?? "--")),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (data['status'] == 'active')
                            ? Colors.green.shade50
                            : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        (data['status'] ?? "Active").toString().toUpperCase(),
                        style: TextStyle(
                          color: (data['status'] == 'active')
                              ? Colors.green.shade700
                              : Colors.red.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onPressed: () =>
                              _showStudentForm(docId: doc.id, data: data),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteStudent(doc.id),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // --- COMMON CARD WIDGET ---
  Widget _buildSelectionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 200,
        height: 180,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
