import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class StaffScreen extends StatefulWidget {
  const StaffScreen({super.key});

  @override
  State<StaffScreen> createState() => _StaffScreenState();
}

class _StaffScreenState extends State<StaffScreen> {
  String _selectedDept = 'All'; // Filter
  bool _isProcessing = false; // Loading state for form

  // --- FORM: ADD / EDIT STAFF ---
  void _showStaffForm({String? docId, Map<String, dynamic>? data}) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(
        text: data != null ? "${data['firstName']} ${data['lastName']}" : '');
    final emailCtrl = TextEditingController(text: data?['email'] ?? '');
    final idCtrl = TextEditingController(text: data?['staffId'] ?? '');
    
    String role = data?['designation'] ?? 'Professor';
    String dept = data?['department'] ?? 'CSE';
    String status = data?['status'] ?? 'Active';

    bool isEdit = docId != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(isEdit ? "Edit Staff Member" : "Add New Staff"),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildInput("Full Name", nameCtrl, Icons.person_outline),
                      const SizedBox(height: 12),
                      _buildInput("Email Address", emailCtrl, Icons.email_outlined, isEmail: true),
                      const SizedBox(height: 12),
                      _buildInput("Employee ID", idCtrl, Icons.badge_outlined, isEnabled: !isEdit),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(labelText: "Designation", border: OutlineInputBorder()),
                        items: ['Professor', 'Asst. Professor', 'Lab Assistant', 'Admin Staff']
                            .map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (v) => setDialogState(() => role = v!),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: dept,
                        decoration: const InputDecoration(labelText: "Department", border: OutlineInputBorder()),
                        items: ['CSE', 'ECE', 'ME', 'CE', 'MCA', 'MBA', 'Admin']
                            .map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                        onChanged: (v) => setDialogState(() => dept = v!),
                      ),
                      if (isEdit) ...[
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(labelText: "Status", border: OutlineInputBorder()),
                          items: ['Active', 'On Leave']
                              .map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => setDialogState(() => status = v!),
                        ),
                      ]
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
                    String staffId = idCtrl.text.trim().toUpperCase();
                    String email = emailCtrl.text.trim().toLowerCase();
                    
                    setDialogState(() => _isProcessing = true);

                    try {
                      final db = FirebaseFirestore.instance.collection('staff');

                      // --- DUPLICATION CHECK ---
                      // 1. Check ID
                      final idQuery = await db.where('staffId', isEqualTo: staffId).get();
                      if (idQuery.docs.isNotEmpty && (!isEdit || idQuery.docs.first.id != docId)) {
                        _showMsg("Employee ID '$staffId' is already in use!", isError: true);
                        setDialogState(() => _isProcessing = false);
                        return;
                      }

                      // 2. Check Email
                      final emailQuery = await db.where('email', isEqualTo: email).get();
                      if (emailQuery.docs.isNotEmpty && (!isEdit || emailQuery.docs.first.id != docId)) {
                        _showMsg("Email '$email' is already registered!", isError: true);
                        setDialogState(() => _isProcessing = false);
                        return;
                      }

                      // --- PREPARE DATA ---
                      List<String> nameParts = nameCtrl.text.trim().split(' ');
                      Map<String, dynamic> staffData = {
                        'firstName': nameParts.first,
                        'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
                        'email': email,
                        'staffId': staffId,
                        'designation': role,
                        'department': dept,
                        'status': status,
                      };

                      if (isEdit) {
                        await db.doc(docId).update(staffData);
                        _showMsg("Staff details updated");
                      } else {
                        staffData['joinDate'] = FieldValue.serverTimestamp();
                        // Use staffId as document ID to enforce DB-level uniqueness
                        await db.doc(staffId).set(staffData);
                        _showMsg("Staff member added successfully");
                      }

                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      _showMsg("Error: $e", isError: true);
                    } finally {
                      setDialogState(() => _isProcessing = false);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(100, 45),
                ),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(isEdit ? "Update" : "Add Staff"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DELETE STAFF ---
  void _deleteStaff(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Staff?"),
        content: const Text("Are you sure you want to remove this staff member? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('staff').doc(docId).delete();
              Navigator.pop(context);
              _showMsg("Staff record deleted");
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating),
    );
  }

  Widget _buildInput(String label, TextEditingController ctrl, IconData icon, {bool isEmail = false, bool isEnabled = true}) {
    return TextFormField(
      controller: ctrl,
      enabled: isEnabled,
      validator: (v) {
        if (v == null || v.isEmpty) return "Required";
        if (isEmail && !v.contains('@')) return "Invalid email";
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
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
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Staff Directory",
                              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text("Manage faculty and administrative staff", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showStaffForm(),
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text("Add Staff"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('staff').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                      
                      var allDocs = snapshot.data?.docs ?? [];
                      var filteredDocs = allDocs.where((doc) {
                        if (_selectedDept == 'All') return true;
                        return (doc.data() as Map)['department'] == _selectedDept;
                      }).toList();

                      // Stats
                      int professors = allDocs.where((d) => (d.data() as Map)['designation'].toString().contains('Professor')).length;

                      return Column(
                        children: [
                          Row(
                            children: [
                              _buildStatCard("Total Staff", "${allDocs.length}", Colors.blue, Icons.badge_outlined),
                              const SizedBox(width: 20),
                              _buildStatCard("Teaching Faculty", "$professors", Colors.green, Icons.school_outlined),
                              const SizedBox(width: 20),
                              _buildStatCard("Support Staff", "${allDocs.length - professors}", Colors.orange, Icons.engineering_outlined),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: ['All', 'CSE', 'ECE', 'ME', 'CE', 'MCA', 'MBA']
                                  .map((dept) => _buildFilterTab(dept)).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white, borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 5))],
                            ),
                            child: filteredDocs.isEmpty
                                ? _buildEmptyState()
                                : DataTable(
                                    columnSpacing: 20, horizontalMargin: 32, headingRowHeight: 60,
                                    columns: const [
                                      DataColumn(label: Text("Staff Member", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("ID", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Designation", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Department", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                      DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                                    ],
                                    rows: filteredDocs.map((doc) {
                                      var data = doc.data() as Map<String, dynamic>;
                                      String name = "${data['firstName']} ${data['lastName']}";
                                      bool isActive = (data['status'] ?? 'Active') == 'Active';

                                      return DataRow(
                                        cells: [
                                          DataCell(Row(children: [
                                            CircleAvatar(radius: 18, backgroundColor: Colors.purple.shade50, child: Text(name[0], style: TextStyle(color: Colors.purple.shade700, fontWeight: FontWeight.bold))),
                                            const SizedBox(width: 12),
                                            Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                              Text(data['email'] ?? "", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                            ]),
                                          ])),
                                          DataCell(Text(data['staffId'] ?? "--", style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataCell(Text(data['designation'] ?? "")),
                                          DataCell(Text(data['department'] ?? "--")),
                                          DataCell(_buildStatusBadge(isActive)),
                                          DataCell(Row(children: [
                                            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.grey), onPressed: () => _showStaffForm(docId: doc.id, data: data)),
                                            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), onPressed: () => _deleteStaff(doc.id)),
                                          ])),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    Color color = isActive ? Colors.green : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(isActive ? "Active" : "On Leave", style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String title) {
    bool isSelected = _selectedDept == title;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedDept = title),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.purpleAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? Colors.purpleAccent : const Color(0xFFE2E8F0)),
          ),
          child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B))),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      child: Column(children: [
        Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text("No staff members found", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
      ]),
    );
  }
}