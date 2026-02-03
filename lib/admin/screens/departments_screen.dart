import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class DepartmentsScreen extends StatefulWidget {
  const DepartmentsScreen({super.key});

  @override
  State<DepartmentsScreen> createState() => _DepartmentsScreenState();
}

class _DepartmentsScreenState extends State<DepartmentsScreen> {
  bool _isCreating = false; // To handle loading state during duplication check

  // --- ADD DEPARTMENT DIALOG ---
  void _showAddDeptDialog() {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final hodCtrl = TextEditingController();
    final staffCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing during DB check
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Add New Department"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Dept Name (e.g. Computer Science)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Dept Code (e.g. CSE)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hodCtrl,
                    decoration: const InputDecoration(
                      labelText: "HOD Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: staffCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Total Faculty",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isCreating ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isCreating
                    ? null
                    : () async {
                        String name = nameCtrl.text.trim();
                        String code = codeCtrl.text.trim().toUpperCase();

                        if (name.isEmpty || code.isEmpty) {
                          _showErrorSnackBar("Name and Code are required");
                          return;
                        }

                        setDialogState(() => _isCreating = true);

                        try {
                          // 1. Check for Duplicate Code
                          final codeCheck = await FirebaseFirestore.instance
                              .collection('departments')
                              .where('code', isEqualTo: code)
                              .get();

                          if (codeCheck.docs.isNotEmpty) {
                            _showErrorSnackBar("Department code '$code' already exists!");
                            setDialogState(() => _isCreating = false);
                            return;
                          }

                          // 2. Check for Duplicate Name
                          final nameCheck = await FirebaseFirestore.instance
                              .collection('departments')
                              .where('name', isEqualTo: name)
                              .get();

                          if (nameCheck.docs.isNotEmpty) {
                            _showErrorSnackBar("Department name '$name' already exists!");
                            setDialogState(() => _isCreating = false);
                            return;
                          }

                          // 3. No duplicates found -> Create
                          await FirebaseFirestore.instance.collection('departments').add({
                            'name': name,
                            'code': code,
                            'hodName': hodCtrl.text.trim(),
                            'totalStaff': int.tryParse(staffCtrl.text) ?? 0,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            _showSuccessSnackBar("Department added successfully!");
                          }
                        } catch (e) {
                          _showErrorSnackBar("Database Error: $e");
                        } finally {
                          setDialogState(() => _isCreating = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(100, 45),
                ),
                child: _isCreating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DELETE DEPARTMENT ---
  void _deleteDept(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Department?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('departments').doc(docId).delete();
              Navigator.pop(context);
              _showSuccessSnackBar("Department deleted.");
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating),
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
                          Text("Departments",
                              style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text("Manage faculties and HODs", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showAddDeptDialog,
                        icon: const Icon(Icons.add_business_rounded, size: 18),
                        label: const Text("Add Department"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('departments').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                      }
                      var docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) return _buildEmptyState();

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          mainAxisSpacing: 24,
                          crossAxisSpacing: 24,
                          childAspectRatio: 1.4,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          return _buildDeptCard(docs[index].id, data);
                        },
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

  Widget _buildDeptCard(String docId, Map<String, dynamic> data) {
    String code = data['code'] ?? "DEPT";
    String name = data['name'] ?? "Department";
    String hod = data['hodName'] ?? "TBA";
    int staff = data['totalStaff'] ?? 0;

    Color accentColor = [Colors.blue, Colors.purple, Colors.orange, Colors.teal, Colors.pink][code.length % 5];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: accentColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(code, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.grey),
                  onSelected: (val) { if (val == 'delete') _deleteDept(docId); },
                  itemBuilder: (context) => [const PopupMenuItem(value: 'delete', child: Text("Delete", style: TextStyle(color: Colors.red)))],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text("HOD: $hod", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600)),
                ]),
              ],
            ),
          ),
          const Spacer(),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFF8FAFC)))),
            child: _buildMiniStat(staff.toString(), "Total Faculty", Colors.green),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String val, String label, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.groups_rounded, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(Icons.apartment_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No departments found", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text("Add a department to get started.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}