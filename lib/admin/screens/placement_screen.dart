import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  String _currentView = 'Students';
  bool _isProcessing = false;

  // --- ADD DRIVE DIALOG ---
  void _showAddDriveDialog() {
    final companyCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final pkgCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Add Recruitment Drive"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: "Company Name", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: "Job Role", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: pkgCtrl, decoration: const InputDecoration(labelText: "Package (LPA)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text("Drive Date"),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  if (companyCtrl.text.isEmpty) return;
                  setDialogState(() => _isProcessing = true);
                  
                  String dateStr = DateFormat('MMM dd, yyyy').format(selectedDate);
                  String company = companyCtrl.text.trim();

                  try {
                    // --- DUPLICATION CHECK ---
                    final duplicate = await FirebaseFirestore.instance
                        .collection('placement_drives')
                        .where('company', isEqualTo: company)
                        .where('date', isEqualTo: dateStr)
                        .get();

                    if (duplicate.docs.isNotEmpty) {
                      _showMsg("A drive for $company is already scheduled for $dateStr!", isError: true);
                      setDialogState(() => _isProcessing = false);
                      return;
                    }

                    await FirebaseFirestore.instance.collection('placement_drives').add({
                      'company': company,
                      'role': roleCtrl.text.trim(),
                      'pkg': "${pkgCtrl.text.trim()} LPA",
                      'date': dateStr,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) Navigator.pop(context);
                    _showMsg("Drive added successfully");
                  } catch (e) {
                    _showMsg("Error: $e", isError: true);
                  } finally {
                    setDialogState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white),
                child: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Create Drive"),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating));
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
                          Text("Placement Cell", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text("Track recruitment drives and student offers", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.file_download_outlined, size: 18), label: const Text("Export Data"), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(onPressed: _showAddDriveDialog, icon: const Icon(Icons.add_business_rounded, size: 18), label: const Text("Add Drive"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('students').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      var docs = snapshot.data!.docs;
                      var placed = docs.where((doc) => (doc.data() as Map)['placementStatus'] == 'Placed').toList();
                      return Row(
                        children: [
                          _buildStatCard("Total Offers", "${placed.length}", Colors.green, Icons.verified_rounded),
                          const SizedBox(width: 20),
                          _buildStatCard("Highest Pkg", "₹42 LPA", Colors.purple, Icons.trending_up_rounded),
                          const SizedBox(width: 20),
                          _buildStatCard("Average Pkg", "₹8.5 LPA", Colors.blue, Icons.pie_chart_rounded),
                          const SizedBox(width: 20),
                          _buildStatCard("Unplaced", "${docs.length - placed.length}", Colors.orange, Icons.pending_actions_rounded),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(mainAxisSize: MainAxisSize.min, children: [_buildTab("Students Records", 'Students'), Container(width: 1, height: 20, color: Colors.grey.shade300), _buildTab("Upcoming Drives", 'Drives')])),
                  const SizedBox(height: 24),
                  _currentView == 'Students' ? _buildStudentTable() : _buildDrivesGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 5))]),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          var students = snapshot.data!.docs;
          if (students.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No student records found")));
          return DataTable(
            columnSpacing: 20, horizontalMargin: 32, headingRowHeight: 60, dataRowMinHeight: 70, dataRowMaxHeight: 70,
            columns: const [
              DataColumn(label: Text("Candidate", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Dept", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("CGPA", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Company", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Package", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: students.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String name = "${data['firstName']} ${data['lastName']}";
              return DataRow(cells: [
                DataCell(Row(children: [CircleAvatar(radius: 16, backgroundColor: Colors.indigo.shade50, child: Text(name[0], style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold))), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text(data['registrationNumber'] ?? "", style: TextStyle(fontSize: 11, color: Colors.grey.shade500))])])),
                DataCell(Text(data['department'] ?? "--")),
                DataCell(Text(data['cgpa']?.toString() ?? "8.5", style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(data['placedCompany'] ?? "--")),
                DataCell(Text(data['package'] ?? "--")),
                DataCell(_buildStatusBadge(data['placementStatus'] ?? "Pending")),
                DataCell(IconButton(icon: const Icon(Icons.edit_note, color: Colors.grey), onPressed: () {})),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDrivesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('placement_drives').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var drives = snapshot.data!.docs;
        if (drives.isEmpty) return _buildEmptyDrives();
        return Wrap(spacing: 24, runSpacing: 24, children: drives.map((doc) {
          var d = doc.data() as Map<String, dynamic>;
          return _buildDriveCard(d);
        }).toList());
      }
    );
  }

  Widget _buildEmptyDrives() => const Center(child: Padding(padding: EdgeInsets.all(60), child: Text("No upcoming drives scheduled.")));

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)), const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey)]), const SizedBox(height: 20), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))), const SizedBox(height: 4), Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500))])));
  }

  Widget _buildTab(String title, String viewName) {
    bool isActive = _currentView == viewName;
    return InkWell(onTap: () => setState(() => _currentView = viewName), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: isActive ? BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)) : null, child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isActive ? Colors.black : Colors.grey))));
  }

  Widget _buildStatusBadge(String status) {
    Color color = status.toLowerCase() == 'placed' ? Colors.green.shade700 : Colors.orange.shade700;
    Color bg = status.toLowerCase() == 'placed' ? Colors.green.shade50 : Colors.orange.shade50;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildDriveCard(Map<String, dynamic> drive) {
    return Container(width: 300, padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(drive['company'], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold))), const Icon(Icons.more_horiz, color: Colors.grey)]), const SizedBox(height: 20), Text(drive['role'], style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text("Package: ${drive['pkg']}", style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)), const SizedBox(height: 24), const Divider(height: 1), const SizedBox(height: 16), Row(children: [const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey), const SizedBox(width: 6), Text("Date: ${drive['date']}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700)), const Spacer(), Text("Apply Now", style: GoogleFonts.inter(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.bold))])]));
  }
}