import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class SemesterRegistrationScreen extends StatefulWidget {
  const SemesterRegistrationScreen({super.key});

  @override
  State<SemesterRegistrationScreen> createState() =>
      _SemesterRegistrationScreenState();
}

class _SemesterRegistrationScreenState
    extends State<SemesterRegistrationScreen> {
  String _selectedStatus = 'All';
  final List<String> _filterOptions = ['All', 'Pending', 'Approved', 'Rejected'];
  
  // Track IDs currently being updated to prevent double-clicks
  final Set<String> _processingIds = {};

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

  // --- FUNCTION: Update Status with Business Logic ---
  Future<void> _updateStatus(String docId, String newStatus, bool isFeePaid) async {
    // 1. Business Logic Check: Cannot approve without fee payment
    if (newStatus == 'Approved' && !isFeePaid) {
      _showMsg("Cannot Approve: Student fees are still due.", isError: true);
      return;
    }

    // 2. Prevent Duplicate Requests
    if (_processingIds.contains(docId)) return;

    setState(() => _processingIds.add(docId));

    try {
      await FirebaseFirestore.instance.collection('students').doc(docId).update({
        'semesterRegistrationStatus': newStatus,
        'registrationActionDate': FieldValue.serverTimestamp(),
        'actionBy': 'Admin', // In real app: FirebaseAuth.instance.currentUser
      });

      _showMsg("Registration $newStatus");
    } catch (e) {
      _showMsg("Update failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _processingIds.remove(docId));
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
                  _buildHeaderAndFilters(),
                  const SizedBox(height: 24),
                  _buildRegistrationStream(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAndFilters() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Semester Registration",
                style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            const SizedBox(height: 4),
            Text("Spring 2026 • Approval Workflow",
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
          child: Row(
            children: _filterOptions.map((opt) => _buildFilterTab(opt)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        }

        var docs = snapshot.data?.docs ?? [];
        var filteredDocs = docs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String status = data['semesterRegistrationStatus'] ?? 'Pending';
          return _selectedStatus == 'All' || status == _selectedStatus;
        }).toList();

        if (filteredDocs.isEmpty) return _buildEmptyState();

        return Column(
          children: [
            _buildStatsRow(docs),
            const SizedBox(height: 32),
            _buildDataTable(filteredDocs),
          ],
        );
      },
    );
  }

  Widget _buildDataTable(List<QueryDocumentSnapshot> docs) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 5))]),
      child: DataTable(
        columnSpacing: 20, horizontalMargin: 32, headingRowHeight: 60, dataRowMaxHeight: 80,
        columns: const [
          DataColumn(label: Text("Student", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Dept/Sem", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Fee Status", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Approval", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String name = "${data['firstName']} ${data['lastName']}";
          String regStatus = data['semesterRegistrationStatus'] ?? "Pending";
          bool isFeePaid = data['feesPaid'] ?? false;
          bool isBeingProcessed = _processingIds.contains(doc.id);

          return DataRow(cells: [
            DataCell(Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(data['registrationNumber'] ?? "--", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            )),
            DataCell(Text("${data['department']} • S${data['semester']}")),
            DataCell(Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: isFeePaid ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
              child: Text(isFeePaid ? "PAID" : "DUE", style: TextStyle(color: isFeePaid ? Colors.green.shade700 : Colors.red.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
            )),
            DataCell(_buildStatusBadge(regStatus)),
            DataCell(
              isBeingProcessed 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : regStatus == 'Approved' 
                ? const Icon(Icons.verified, color: Colors.green, size: 22)
                : Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                      onPressed: () => _updateStatus(doc.id, "Approved", isFeePaid),
                    ),
                    IconButton(
                      icon: const Icon(Icons.highlight_off, color: Colors.red),
                      onPressed: () => _updateStatus(doc.id, "Rejected", isFeePaid),
                    ),
                  ],
                )
            ),
          ]);
        }).toList(),
      ),
    );
  }

  // --- STATS ROW HELPER ---
  Widget _buildStatsRow(List<QueryDocumentSnapshot> allDocs) {
    int total = allDocs.length;
    int approved = allDocs.where((d) => (d.data() as Map)['semesterRegistrationStatus'] == 'Approved').length;
    int pending = allDocs.where((d) => (d.data() as Map)['semesterRegistrationStatus'] != 'Approved' && (d.data() as Map)['semesterRegistrationStatus'] != 'Rejected').length;

    return Row(
      children: [
        _statCard("Total Candidates", "$total", Colors.blueAccent, Icons.groups_outlined),
        const SizedBox(width: 20),
        _statCard("Pending Review", "$pending", Colors.orangeAccent, Icons.hourglass_empty_rounded),
        const SizedBox(width: 20),
        _statCard("Successfully Registered", "$approved", Colors.green, Icons.task_alt_rounded),
      ],
    );
  }

  Widget _buildFilterTab(String title) {
    bool isActive = _selectedStatus == title;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(color: isActive ? const Color(0xFFF1F5F9) : Colors.transparent),
        child: Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Colors.black : Colors.grey)),
      ),
    );
  }

  Widget _statCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 16),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
              Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = status == 'Approved' ? Colors.green : status == 'Rejected' ? Colors.red : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEmptyState() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(60), child: Column(children: [Icon(Icons.assignment_turned_in_outlined, size: 48, color: Colors.grey.shade300), const SizedBox(height: 16), Text("No registrations to show", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600))]));
  }
}