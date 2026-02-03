import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Department and Division selection
  String _selectedDept = 'MCA';
  String _selectedDivision = 'S1';
  
  // Available Departments
  List<String> get _departments => ['MCA', 'MBA'];
  
  // Available Divisions (same for both departments)
  List<String> get _divisions => ['S1', 'S2'];

  // --- DATABASE ACTIONS ---

  // Delete Student Logic
  Future<void> _deleteStudent(String docId, String name) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Confirm Delete"),
            content: Text("Are you sure you want to delete student $name?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Cancel")),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Delete", style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      try {
        await FirebaseFirestore.instance.collection('students').doc(docId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Student deleted successfully")),
          );
        }
      } catch (e) {
        debugPrint("Error deleting: $e");
      }
    }
  }

  // Edit Student Logic
  void _showEditDialog(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    final fNameController = TextEditingController(text: data['firstName']);
    final lNameController = TextEditingController(text: data['lastName']);
    final attendanceController = TextEditingController(
        text: (data['attendancePercentage'] ?? 85).toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Student Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: fNameController,
                decoration: const InputDecoration(labelText: "First Name")),
            TextField(
                controller: lNameController,
                decoration: const InputDecoration(labelText: "Last Name")),
            TextField(
                controller: attendanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Attendance %")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('students')
                  .doc(doc.id)
                  .update({
                'firstName': fNameController.text,
                'lastName': lNameController.text,
                'attendancePercentage':
                    double.tryParse(attendanceController.text) ?? 85.0,
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save Changes"),
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
          // Sidebar
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: -1)),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),

                  // --- Header ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Department Attendance",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Track performance and engagement",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Department Tabs ---
                  Row(
                    children: [
                      Text(
                        "Department",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _departments
                                .map((dept) => _buildDeptTab(dept))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // --- Division Tabs ---
                  Row(
                    children: [
                      Text(
                        "Division",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _divisions
                                .map((division) => _buildDivisionTab(division))
                                .toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- DATA STREAM ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      var allDocs = snapshot.data?.docs ?? [];
                      // Filter by department and division
                      var students = allDocs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String docDept = (data['department'] ?? "")
                            .toString()
                            .toUpperCase();
                        String docDivision = (data['division'] ?? data['semester'] ?? "")
                            .toString()
                            .toUpperCase();

                        // Check department match
                        bool deptMatch = false;
                        if (_selectedDept == 'MCA') {
                          deptMatch = docDept.contains('MCA') || 
                                     docDept.contains('COMPUTER APPLICATION');
                        } else if (_selectedDept == 'MBA') {
                          deptMatch = docDept.contains('MBA') || 
                                     docDept.contains('BUSINESS');
                        }

                        // Check division match
                        bool divisionMatch = docDivision.contains(_selectedDivision);

                        return deptMatch && divisionMatch;
                      }).toList();

                      if (students.isEmpty) return _buildEmptyState();

                      return Column(
                        children: [
                          _buildSummaryRow(students),
                          const SizedBox(height: 24),

                          // --- STUDENT TABLE ---
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: const Color(0xFFF1F5F9)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: DataTable(
                              columnSpacing: 20,
                              horizontalMargin: 32,
                              headingRowHeight: 60,
                              dataRowMinHeight: 70,
                              dataRowMaxHeight: 70,
                              columns: const [
                                DataColumn(label: Text("Student Name", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Reg Number", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Attendance %", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Performance", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text("Actions", style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: students.map((doc) {
                                var data = doc.data() as Map<String, dynamic>;
                                String name = "${data['firstName']} ${data['lastName']}";
                                String reg = data['registrationNumber'] ?? "---";
                                double percentage = (data['attendancePercentage'] is num)
                                    ? (data['attendancePercentage'] as num).toDouble()
                                    : 85.0;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(reg)),
                                    DataCell(_buildAttendanceBar(percentage)),
                                    DataCell(_buildPerformanceTag(percentage)),
                                    DataCell(_buildStatusChip(data['status'] ?? 'active')),
                                    DataCell(
                                      PopupMenuButton<String>(
                                        onSelected: (value) {
                                          if (value == 'edit') {
                                            _showEditDialog(doc);
                                          } else if (value == 'delete') {
                                            _deleteStudent(doc.id, name);
                                          }
                                        },
                                        itemBuilder: (context) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: ListTile(
                                              leading: Icon(Icons.edit, size: 20),
                                              title: Text("Edit"),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: ListTile(
                                              leading: Icon(Icons.delete, color: Colors.red, size: 20),
                                              title: Text("Delete", style: TextStyle(color: Colors.red)),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                          ),
                                        ],
                                        icon: const Icon(Icons.more_vert, color: Colors.grey),
                                      ),
                                    ),
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

  // --- UI COMPONENTS ---

  Widget _buildSummaryRow(List<DocumentSnapshot> students) {
    double totalPerc = 0;
    for (var s in students) {
      var d = s.data() as Map<String, dynamic>;
      totalPerc += (d['attendancePercentage'] ?? 75.0);
    }
    double deptAvg = totalPerc / students.length;

    return Row(
      children: [
        _buildSummaryCard("Total Students", students.length.toString(), Colors.blueAccent, Icons.people_alt_outlined),
        const SizedBox(width: 20),
        _buildSummaryCard("Avg. Attendance", "${deptAvg.toStringAsFixed(1)}%", deptAvg > 75 ? Colors.green : Colors.orange, Icons.bar_chart_rounded),
        const SizedBox(width: 20),
        _buildSummaryCard(
          "Critical Risk",
          students.where((s) => ((s.data() as Map)['attendancePercentage'] ?? 0) < 65).length.toString(),
          Colors.redAccent,
          Icons.warning_amber_rounded,
        ),
      ],
    );
  }

  Widget _buildAttendanceBar(double percentage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${percentage.toStringAsFixed(0)}%", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          width: 100,
          height: 6,
          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(3)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: _getColorForPercentage(percentage),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    bool isActive = status == 'active';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isActive ? Colors.green.shade100 : Colors.red.shade100),
      ),
      child: Text(
        isActive ? "Active" : "Inactive",
        style: TextStyle(color: isActive ? Colors.green.shade700 : Colors.red.shade700, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDeptTab(String title) {
    bool isSelected = _selectedDept == title;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedDept = title),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blueAccent : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blueAccent : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivisionTab(String division) {
    bool isSelected = _selectedDivision == division;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedDivision = division),
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.indigoAccent : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.indigoAccent : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            division,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(24), 
        border: Border.all(color: const Color(0xFFF1F5F9))
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No students found in $_selectedDept ($_selectedDivision)",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try selecting a different department or division.",
            style: GoogleFonts.inter(
              fontSize: 13, 
              color: Colors.grey.shade500
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForPercentage(double p) {
    if (p >= 85) return const Color(0xFF10B981);
    if (p >= 75) return const Color(0xFF3B82F6);
    if (p >= 65) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  Widget _buildPerformanceTag(double p) {
    String text = p >= 85 ? "Excellent" : p >= 75 ? "Good" : p >= 65 ? "Average" : "Poor";
    Color color = _getColorForPercentage(p);
    return Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12));
  }
}