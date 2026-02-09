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
  bool _isProcessing = false; // Loading state for form submission

  // Data Lists
  final List<String> _departments = ['MCA', 'MBA'];

  final List<String> _batches = List.generate(6, (index) {
    int startYear = 2021 + index;
    return "$startYear-${startYear + 2}";
  });

  // --- CRUD: ADD / EDIT STUDENT ---
  void _showStudentForm({String? docId, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final fNameCtrl = TextEditingController(text: data?['firstName'] ?? '');
    final lNameCtrl = TextEditingController(text: data?['lastName'] ?? '');
    final regCtrl = TextEditingController(text: data?['registrationNumber'] ?? '');
    final emailCtrl = TextEditingController(text: data?['email'] ?? '');
    final phoneCtrl = TextEditingController(text: data?['phone'] ?? '');

    String status = data?['status'] ?? 'active';
    String department = data?['department'] ?? _selectedDept ?? 'MCA';
    String batch = data?['batch'] ?? _selectedBatch ?? '2024-2026';
    bool isEdit = docId != null;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing during duplicate check
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                            const SizedBox(width: 8),
                            Text(
                              isEdit 
                                ? "Editing: $department • $batch"
                                : "Target: $_selectedDept • $_selectedBatch",
                              style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildInput("First Name", fNameCtrl)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildInput("Last Name", lNameCtrl, isRequired: false)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInput("Registration No.", regCtrl, isEnabled: !isEdit), // Usually RegNo shouldn't change
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildInput("Email", emailCtrl)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildInput("Phone", phoneCtrl)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: department,
                              decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder()),
                              items: _departments
                                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => department = val!),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: batch,
                              decoration: const InputDecoration(labelText: "Batch", border: OutlineInputBorder()),
                              items: _batches
                                  .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                                  .toList(),
                              onChanged: (val) => setDialogState(() => batch = val!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: status,
                        decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                        items: ['active', 'inactive', 'suspended']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase())))
                            .toList(),
                        onChanged: (val) => setDialogState(() => status = val!),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  if (formKey.currentState!.validate()) {
                    String regNo = regCtrl.text.trim().toUpperCase();
                    String email = emailCtrl.text.trim().toLowerCase();

                    setDialogState(() => _isProcessing = true);

                    try {
                      // --- DUPLICATION CHECK ---
                      final db = FirebaseFirestore.instance.collection('students');

                      // 1. Check Reg No Duplicate
                      final regQuery = await db.where('registrationNumber', isEqualTo: regNo).get();
                      if (regQuery.docs.isNotEmpty && (!isEdit || regQuery.docs.first.id != docId)) {
                        _showMsg("Registration Number '$regNo' already exists!", isError: true);
                        setDialogState(() => _isProcessing = false);
                        return;
                      }

                      // 2. Check Email Duplicate
                      final emailQuery = await db.where('email', isEqualTo: email).get();
                      if (emailQuery.docs.isNotEmpty && (!isEdit || emailQuery.docs.first.id != docId)) {
                        _showMsg("Email '$email' is already assigned to another student!", isError: true);
                        setDialogState(() => _isProcessing = false);
                        return;
                      }

                      // --- PROCESS DATA ---
                      Map<String, dynamic> studentData = {
                        'firstName': fNameCtrl.text.trim(),
                        'lastName': lNameCtrl.text.trim(),
                        'registrationNumber': regNo,
                        'email': email,
                        'phone': phoneCtrl.text.trim(),
                        'department': department,
                        'batch': batch,
                        'status': status,
                      };

                      if (isEdit) {
                        await db.doc(docId).update(studentData);
                        _showMsg("Student updated successfully");
                      } else {
                        studentData['createdAt'] = FieldValue.serverTimestamp();
                        await db.add(studentData);
                        _showMsg("Student added successfully");
                      }

                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      _showMsg("Error: $e", isError: true);
                    } finally {
                      setDialogState(() => _isProcessing = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(100, 45)),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? "Update" : "Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, {bool isEnabled = true, bool isRequired = true}) {
    return TextFormField(
      controller: ctrl,
      enabled: isEnabled,
      validator: isRequired ? (v) => v!.isEmpty ? "Required" : null : null,
      decoration: InputDecoration(
        labelText: isRequired ? label : "$label (Optional)", 
        border: const OutlineInputBorder()
      ),
    );
  }

  // --- CRUD: DELETE ---
  Future<void> _deleteStudent(String docId) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Student?"),
        content: const Text("This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (confirm) {
      await FirebaseFirestore.instance.collection('students').doc(docId).delete();
      _showMsg("Student deleted");
    }
  }

  // --- NAVIGATION HELPERS ---
  void _resetSelection() {
    setState(() {
      if (_selectedBatch != null) { _selectedBatch = null; } 
      else { _selectedDept = null; }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 1)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      if (_selectedDept != null)
                        IconButton(onPressed: _resetSelection, icon: const Icon(Icons.arrow_back, color: Colors.black87)),
                      Text(
                        _selectedBatch != null
                            ? "$_selectedDept > Batch $_selectedBatch"
                            : _selectedDept != null ? "$_selectedDept Batches" : "Select Department",
                        style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                      ),
                      const Spacer(),
                      if (_selectedBatch != null)
                        ElevatedButton.icon(
                          onPressed: () => _showStudentForm(),
                          icon: const Icon(Icons.add),
                          label: const Text("Add Student"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (_selectedDept == null) _buildDepartmentGrid()
                  else if (_selectedBatch == null) _buildBatchGrid()
                  else _buildStudentList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentGrid() {
    return Wrap(
      spacing: 24, runSpacing: 24,
      children: _departments.map((dept) => _buildSelectionCard(
        title: dept, subtitle: "Department", icon: Icons.business, color: Colors.blueAccent,
        onTap: () => setState(() => _selectedDept = dept),
      )).toList(),
    );
  }

  Widget _buildBatchGrid() {
    return Wrap(
      spacing: 24, runSpacing: 24,
      children: _batches.map((batch) => _buildSelectionCard(
        title: batch, subtitle: "Academic Year", icon: Icons.calendar_today_rounded, color: Colors.orangeAccent,
        onTap: () => setState(() => _selectedBatch = batch),
      )).toList(),
    );
  }

  Widget _buildStudentList() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students')
            .where('department', isEqualTo: _selectedDept)
            .where('batch', isEqualTo: _selectedBatch)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          final students = snapshot.data?.docs ?? [];
          if (students.isEmpty) return _buildEmptyState();

          return DataTable(
            columnSpacing: 20, horizontalMargin: 32, headingRowHeight: 60,
            columns: const [
              DataColumn(label: Text("Name", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Reg No", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Contact", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: students.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return DataRow(cells: [
                DataCell(Row(children: [
                  CircleAvatar(radius: 16, backgroundColor: Colors.blue.shade50, child: Text((data['firstName']?[0] ?? "U"), style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold))),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(
                      "${data['firstName']}${data['lastName']?.toString().isNotEmpty == true ? ' ${data['lastName']}' : ''}", 
                      style: const TextStyle(fontWeight: FontWeight.w600)
                    ),
                    Text(data['email'] ?? "", style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ]),
                ])),
                DataCell(Text(data['registrationNumber'] ?? "--")),
                DataCell(Text(data['phone'] ?? "--")),
                DataCell(_buildStatusBadge(data['status'] ?? 'active')),
                DataCell(Row(children: [
                  IconButton(icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.grey), onPressed: () => _showStudentForm(docId: doc.id, data: data)),
                  IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent), onPressed: () => _deleteStudent(doc.id)),
                ])),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'active' ? Colors.green : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Padding(padding: const EdgeInsets.all(60), child: Column(children: [
      Icon(Icons.person_off_outlined, size: 48, color: Colors.grey.shade300),
      const SizedBox(height: 16),
      Text("No students found in $_selectedDept ($_selectedBatch)", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
    ])));
  }

  Widget _buildSelectionCard({required String title, required String subtitle, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 200, height: 180, padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
          const Spacer(),
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }
}