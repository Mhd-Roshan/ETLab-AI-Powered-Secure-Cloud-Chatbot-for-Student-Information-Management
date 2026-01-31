import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  // Toggle between 'Drives' and 'Students' view
  String _currentView = 'Students';

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

                  // --- Header & Actions ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Placement Cell",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Track recruitment drives and student offers",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.file_download_outlined,
                              size: 18,
                            ),
                            label: const Text("Export Data"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.add_business_rounded,
                              size: 18,
                            ),
                            label: const Text("Add Drive"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigoAccent,
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- GLOBAL STATS STREAM ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();

                      var docs = snapshot.data!.docs;
                      // Logic: Filter students who have 'placementStatus' == 'Placed'
                      var placedStudents = docs
                          .where(
                            (doc) =>
                                (doc.data() as Map)['placementStatus'] ==
                                'Placed',
                          )
                          .toList();

                      // Mocking financial data from fields if they exist, else calculating dummy averages for UI demo
                      // In real app: double avgPackage = calculateAverage(placedStudents);
                      int totalOffers = placedStudents.length;
                      int unplaced = docs.length - totalOffers;

                      return Row(
                        children: [
                          _buildStatCard(
                            "Total Offers",
                            "$totalOffers",
                            Colors.green,
                            Icons.verified_rounded,
                          ),
                          const SizedBox(width: 20),
                          _buildStatCard(
                            "Highest Pkg",
                            "₹42 LPA",
                            Colors.purple,
                            Icons.trending_up_rounded,
                          ),
                          const SizedBox(width: 20),
                          _buildStatCard(
                            "Average Pkg",
                            "₹8.5 LPA",
                            Colors.blue,
                            Icons.pie_chart_rounded,
                          ),
                          const SizedBox(width: 20),
                          _buildStatCard(
                            "Unplaced",
                            "$unplaced",
                            Colors.orange,
                            Icons.pending_actions_rounded,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // --- TABS ---
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildTab("Students Records", 'Students'),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.grey.shade300,
                        ),
                        _buildTab("Upcoming Drives", 'Drives'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- MAIN VIEW ---
                  _currentView == 'Students'
                      ? _buildStudentTable()
                      : _buildDrivesGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // VIEW: Student Placement Records
  // ---------------------------------------------------------------------------
  Widget _buildStudentTable() {
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
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }

          var students = snapshot.data!.docs;

          if (students.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text("No student records found")),
            );
          }

          return DataTable(
            columnSpacing: 20,
            horizontalMargin: 32,
            headingRowHeight: 60,
            dataRowMinHeight: 70,
            dataRowMaxHeight: 70,
            columns: const [
              DataColumn(
                label: Text(
                  "Candidate",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Dept",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "CGPA",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Company",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  "Package",
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
                  "Action",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: students.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String name = "${data['firstName']} ${data['lastName']}";
              String status =
                  data['placementStatus'] ??
                  "Pending"; // Placed, Shortlisted, Pending
              String company = data['placedCompany'] ?? "--";
              String pkg = data['package'] ?? "--";

              return DataRow(
                cells: [
                  DataCell(
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.indigo.shade50,
                          child: Text(
                            name[0],
                            style: TextStyle(
                              color: Colors.indigo.shade700,
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
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              data['registrationNumber'] ?? "",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  DataCell(Text(data['department'] ?? "--")),
                  DataCell(
                    Text(
                      data['cgpa']?.toString() ?? "8.5",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  DataCell(Text(company)),
                  DataCell(Text(pkg)),
                  DataCell(_buildStatusBadge(status)),
                  DataCell(
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.grey),
                      onPressed: () {},
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

  // ---------------------------------------------------------------------------
  // VIEW: Company Drives
  // ---------------------------------------------------------------------------
  Widget _buildDrivesGrid() {
    // You can connect this to a 'drives' collection in Firebase.
    // Using static data for UI demonstration as requested.
    final List<Map<String, dynamic>> drives = [
      {
        'company': 'Google',
        'role': 'SDE Intern',
        'date': 'Feb 10, 2026',
        'pkg': '42 LPA',
        'color': Colors.red,
      },
      {
        'company': 'Microsoft',
        'role': 'Data Analyst',
        'date': 'Feb 12, 2026',
        'pkg': '45 LPA',
        'color': Colors.blue,
      },
      {
        'company': 'Deloitte',
        'role': 'Consultant',
        'date': 'Feb 15, 2026',
        'pkg': '12 LPA',
        'color': Colors.green,
      },
      {
        'company': 'TCS',
        'role': 'System Engineer',
        'date': 'Feb 20, 2026',
        'pkg': '7 LPA',
        'color': Colors.orange,
      },
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: drives.map((drive) => _buildDriveCard(drive)).toList(),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String title, String viewName) {
    bool isActive = _currentView == viewName;
    return InkWell(
      onTap: () => setState(() => _currentView = viewName),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: isActive
            ? BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;

    switch (status.toLowerCase()) {
      case 'placed':
        color = Colors.green.shade700;
        bg = Colors.green.shade50;
        break;
      case 'shortlisted':
        color = Colors.orange.shade700;
        bg = Colors.orange.shade50;
        break;
      default:
        color = Colors.grey.shade700;
        bg = Colors.grey.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDriveCard(Map<String, dynamic> drive) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: (drive['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  drive['company'],
                  style: TextStyle(
                    color: drive['color'],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Icon(Icons.more_horiz, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            drive['role'],
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Package: ${drive['pkg']}",
            style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                "Date: ${drive['date']}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              Text(
                "Apply Now",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.blueAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
