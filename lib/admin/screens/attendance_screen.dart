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
  // Default selected department
  String _selectedDept = 'MCA';

  // Available Departments
  List<String> get _departments => ['MCA', 'MBA', 'CSE', 'ECE', 'ME', 'CE'];

  // Level Selection for MCA
  String _selectedLevel = 'S1';
  List<String> get _levels => ['S1', 'S2', 'S3', 'S4'];

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

                  // --- Header & Department Selector ---
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
                      // Export Button
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text("Export Report"),
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
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- Department Tabs ---
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _departments
                          .map((dept) => _buildDeptTab(dept))
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Level Selector (Visible only for MCA) ---
                  if (_selectedDept == 'MCA') ...[
                    Text(
                      "Semester / Level",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: (_levels)
                            .map((level) => _buildLevelTab(level))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // --- DATA STREAM ---
                  StreamBuilder<QuerySnapshot>(
                    // Query students based on the selected Department
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        // Note: In a real app, ensure your Firestore has 'department' field matching these values
                        // If strict matching fails, remove the .where clause to see all data for testing
                        // .where('department', isEqualTo: _selectedDept)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      // Filter manually if Firestore index is missing, or use the .where above
                      var allDocs = snapshot.data?.docs ?? [];
                      // Simple client-side filter for prototype robustness
                      var students = allDocs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        // Flexible matching (e.g., "Computer Science" matches "CSE" logic if needed)
                        // Here we assume simple matching or show all if department field is missing/messy
                        String docDept = (data['department'] ?? "")
                            .toString()
                            .toUpperCase();
                        String docLevel =
                            (data['level'] ?? data['semester'] ?? "")
                                .toString()
                                .toUpperCase();

                        if (_selectedDept == 'MCA') {
                          bool matchesDept =
                              docDept.contains('MCA') ||
                              docDept.contains('COMPUTER APPLICATION');
                          bool matchesLevel = docLevel.contains(_selectedLevel);
                          return matchesDept && matchesLevel;
                        }
                        if (_selectedDept == 'MBA')
                          return docDept.contains('MBA') ||
                              docDept.contains('BUSINESS');
                        if (_selectedDept == 'CSE')
                          return docDept.contains('CSE') ||
                              docDept.contains('COMPUTER SCIENCE');
                        return docDept.contains(_selectedDept);
                      }).toList();

                      if (students.isEmpty) {
                        return _buildEmptyState();
                      }

                      // Calculate Department Average
                      double totalPerc = 0;
                      for (var s in students) {
                        var d = s.data() as Map<String, dynamic>;
                        totalPerc +=
                            (d['attendancePercentage'] ??
                            75.0); // Fallback to 75 if missing
                      }
                      double deptAvg = totalPerc / students.length;

                      return Column(
                        children: [
                          // Summary Cards for this Dept
                          Row(
                            children: [
                              _buildSummaryCard(
                                "Total Students",
                                students.length.toString(),
                                Colors.blueAccent,
                                Icons.people_alt_outlined,
                              ),
                              const SizedBox(width: 20),
                              _buildSummaryCard(
                                "Avg. Attendance",
                                "${deptAvg.toStringAsFixed(1)}%",
                                deptAvg > 75 ? Colors.green : Colors.orange,
                                Icons.bar_chart_rounded,
                              ),
                              const SizedBox(width: 20),
                              _buildSummaryCard(
                                "Critical Risk",
                                students
                                    .where(
                                      (s) =>
                                          ((s.data()
                                                  as Map)['attendancePercentage'] ??
                                              0) <
                                          65,
                                    )
                                    .length
                                    .toString(),
                                Colors.redAccent,
                                Icons.warning_amber_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // --- STUDENT TABLE ---
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
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
                                DataColumn(
                                  label: Text(
                                    "Student Name",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Reg Number",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Attendance %",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Performance",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Status",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    "Actions",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                              rows: students.map((doc) {
                                var data = doc.data() as Map<String, dynamic>;

                                // Data Extraction with Fallbacks
                                String name =
                                    "${data['firstName']} ${data['lastName']}";
                                String reg =
                                    data['registrationNumber'] ?? "---";
                                // If 'attendancePercentage' doesn't exist in DB, mock it for UI demo based on GPA or random
                                double percentage =
                                    (data['attendancePercentage'] is num)
                                    ? (data['attendancePercentage'] as num)
                                          .toDouble()
                                    : 85.0;

                                bool isActive =
                                    (data['status'] ?? 'active') == 'active';

                                return DataRow(
                                  cells: [
                                    // 1. Name
                                    DataCell(
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor:
                                                Colors.indigo.shade50,
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
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                data['email'] ?? "",
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

                                    // 2. Reg No
                                    DataCell(
                                      Text(
                                        reg,
                                        style: GoogleFonts.inter(fontSize: 13),
                                      ),
                                    ),

                                    // 3. Percentage Bar
                                    DataCell(
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                "${percentage.toStringAsFixed(0)}%",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Container(
                                            width: 100,
                                            height: 6,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: FractionallySizedBox(
                                              alignment: Alignment.centerLeft,
                                              widthFactor: percentage / 100,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: _getColorForPercentage(
                                                    percentage,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(3),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 4. Performance (Visual)
                                    DataCell(_buildPerformanceTag(percentage)),

                                    // 5. Active Status
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isActive
                                              ? Colors.green.shade50
                                              : Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: isActive
                                                ? Colors.green.shade100
                                                : Colors.red.shade100,
                                          ),
                                        ),
                                        child: Text(
                                          isActive ? "Active" : "Inactive",
                                          style: TextStyle(
                                            color: isActive
                                                ? Colors.green.shade700
                                                : Colors.red.shade700,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),

                                    // 6. Actions
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(
                                          Icons.more_vert,
                                          color: Colors.grey,
                                          size: 20,
                                        ),
                                        onPressed: () {},
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

  // --- WIDGET HELPERS ---

  Widget _buildLevelTab(String level) {
    bool isSelected = _selectedLevel == level;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedLevel = level),
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
            level,
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
                      color: Colors.blueAccent.withOpacity(0.3),
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

  Widget _buildSummaryCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
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
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No students found in $_selectedDept${_selectedDept == 'MCA' ? ' ($_selectedLevel)' : ''}",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try selecting a different department or add students.",
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Color _getColorForPercentage(double p) {
    if (p >= 85) return const Color(0xFF10B981); // Emerald
    if (p >= 75) return const Color(0xFF3B82F6); // Blue
    if (p >= 65) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  Widget _buildPerformanceTag(double p) {
    String text;
    Color color;
    if (p >= 85) {
      text = "Excellent";
      color = const Color(0xFF10B981);
    } else if (p >= 75) {
      text = "Good";
      color = const Color(0xFF3B82F6);
    } else if (p >= 65) {
      text = "Average";
      color = const Color(0xFFF59E0B);
    } else {
      text = "Poor";
      color = const Color(0xFFEF4444);
    }

    return Text(
      text,
      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
    );
  }
}
