import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class SuspendedUsersScreen extends StatefulWidget {
  const SuspendedUsersScreen({super.key});

  @override
  State<SuspendedUsersScreen> createState() => _SuspendedUsersScreenState();
}

class _SuspendedUsersScreenState extends State<SuspendedUsersScreen> {
  bool _isProcessing = false;

  // --- HELPER: SHOW SNACKBAR ---
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

  // --- FUNCTION: Reinstate (Activate) a User ---
  Future<void> _reinstateUser(String docId, String name) async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Reinstate User?"),
        content: Text("Are you sure you want to reactivate $name? Access will be restored immediately."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Confirm Reinstate"),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      setState(() => _isProcessing = true);
      try {
        // Real-world: Using a write batch to ensure atomicity
        WriteBatch batch = FirebaseFirestore.instance.batch();
        DocumentReference userRef = FirebaseFirestore.instance.collection('students').doc(docId);

        batch.update(userRef, {
          'status': 'active',
          'lastReinstatedAt': FieldValue.serverTimestamp(),
          'reinstatedBy': 'Admin', // In real app: use FirebaseAuth current user
        });

        await batch.commit();
        _showMsg("$name has been reinstated successfully.");
      } catch (e) {
        _showMsg("Failed to reinstate user: $e", isError: true);
      } finally {
        setState(() => _isProcessing = false);
      }
    }
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
                  _buildHeaderSection(),
                  const SizedBox(height: 32),
                  _buildSuspendedTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Suspended Users",
                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text("Manage restricted access and disciplinary actions",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
        // Live Count Chip
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('students').where('status', isEqualTo: 'suspended').snapshots(),
          builder: (context, snapshot) {
            int count = snapshot.data?.docs.length ?? 0;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: count > 0 ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: count > 0 ? Colors.red.shade100 : Colors.green.shade100),
              ),
              child: Row(
                children: [
                  Icon(count > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
                       color: count > 0 ? Colors.red.shade700 : Colors.green.shade700, size: 20),
                  const SizedBox(width: 8),
                  Text("$count Active Suspensions", 
                       style: TextStyle(color: count > 0 ? Colors.red.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSuspendedTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').where('status', isEqualTo: 'suspended').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          }
          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmptyState();

          return DataTable(
            columnSpacing: 20, horizontalMargin: 32, headingRowHeight: 60, dataRowMinHeight: 80, dataRowMaxHeight: 80,
            columns: const [
              DataColumn(label: Text("User Details", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Department", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Suspension Reason", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String name = "${data['firstName']} ${data['lastName']}";
              return DataRow(cells: [
                DataCell(Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: Colors.red.shade50, 
                                 child: Text(name[0], style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        Text(data['email'] ?? "No Email", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ],
                )),
                DataCell(Text(data['department'] ?? "--")),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                  child: Text(data['suspensionReason'] ?? "Disciplinary Action", 
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 11)),
                )),
                DataCell(
                  ElevatedButton.icon(
                    onPressed: _isProcessing ? null : () => _reinstateUser(doc.id, name),
                    icon: const Icon(Icons.lock_open_rounded, size: 16),
                    label: const Text("Reinstate"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(80),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
            child: Icon(Icons.verified_user_rounded, size: 60, color: Colors.green.shade400),
          ),
          const SizedBox(height: 24),
          Text("No Suspended Users", style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text("All system users currently have active access.", style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}