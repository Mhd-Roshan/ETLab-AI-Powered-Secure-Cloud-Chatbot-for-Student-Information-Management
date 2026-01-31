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
  String _selectedStatus = 'All'; // Filter: All, Pending, Approved

  // Function to Update Status in Firebase
  Future<void> _updateStatus(String docId, String newStatus) async {
    await FirebaseFirestore.instance.collection('students').doc(docId).update({
      'semesterRegistrationStatus': newStatus,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Registration $newStatus"),
          backgroundColor: newStatus == 'Approved' ? Colors.green : Colors.red,
          duration: const Duration(seconds: 1),
        ),
      );
    }
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
                            "Semester Registration",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Spring 2026 • Approval Workflow",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),

                      // Filter Tabs
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            _buildFilterTab("All"),
                            Container(
                              width: 1,
                              height: 20,
                              color: const Color(0xFFF1F5F9),
                            ),
                            _buildFilterTab("Pending"),
                            Container(
                              width: 1,
                              height: 20,
                              color: const Color(0xFFF1F5F9),
                            ),
                            _buildFilterTab("Approved"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- STREAM DATA ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('students')
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

                      var docs = snapshot.data?.docs ?? [];

                      // Filter Logic
                      var filteredDocs = docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        String status =
                            data['semesterRegistrationStatus'] ?? 'Pending';
                        if (_selectedStatus == 'All') return true;
                        return status == _selectedStatus;
                      }).toList();

                      // Stats Logic
                      int total = docs.length;
                      int pending = docs
                          .where(
                            (d) =>
                                (d.data()
                                        as Map)['semesterRegistrationStatus'] ==
                                    'Pending' ||
                                (d.data()
                                        as Map)['semesterRegistrationStatus'] ==
                                    null,
                          )
                          .length;
                      int approved = docs
                          .where(
                            (d) =>
                                (d.data()
                                    as Map)['semesterRegistrationStatus'] ==
                                'Approved',
                          )
                          .length;

                      return Column(
                        children: [
                          // 1. Stats Row
                          Row(
                            children: [
                              _buildStatCard(
                                "Applications",
                                "$total",
                                Colors.blueAccent,
                                Icons.description_outlined,
                              ),
                              const SizedBox(width: 20),
                              _buildStatCard(
                                "Pending Action",
                                "$pending",
                                Colors.orangeAccent,
                                Icons.pending_outlined,
                              ),
                              const SizedBox(width: 20),
                              _buildStatCard(
                                "Approved",
                                "$approved",
                                Colors.green,
                                Icons.check_circle_outline,
                              ),
                              const SizedBox(width: 20),
                              _buildStatCard(
                                "Fees Due",
                                "${total - approved}",
                                Colors.redAccent,
                                Icons.attach_money_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 2. Data Table
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
                            child: filteredDocs.isEmpty
                                ? _buildEmptyState()
                                : DataTable(
                                    columnSpacing: 20,
                                    horizontalMargin: 32,
                                    headingRowHeight: 60,
                                    dataRowMinHeight: 70,
                                    dataRowMaxHeight: 70,
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          "Student Details",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Department",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Sem",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Fee Status",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Reg Status",
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
                                    rows: filteredDocs.map((doc) {
                                      var data =
                                          doc.data() as Map<String, dynamic>;
                                      String name =
                                          "${data['firstName']} ${data['lastName']}";
                                      String regStatus =
                                          data['semesterRegistrationStatus'] ??
                                          "Pending";
                                      bool isFeePaid =
                                          data['feesPaid'] ?? false;

                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor:
                                                      Colors.blue.shade50,
                                                  child: Text(
                                                    name[0],
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade700,
                                                      fontWeight:
                                                          FontWeight.bold,
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
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Text(
                                                      data['registrationNumber'] ??
                                                          "--",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey
                                                            .shade500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              data['department'] ?? "--",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Text(
                                              "S${data['semester'] ?? '1'}",
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: isFeePaid
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                isFeePaid ? "PAID" : "DUE",
                                                style: TextStyle(
                                                  color: isFeePaid
                                                      ? Colors.green.shade700
                                                      : Colors.red.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            _buildStatusBadge(regStatus),
                                          ),
                                          DataCell(
                                            regStatus == 'Approved'
                                                ? const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 20,
                                                  )
                                                : Row(
                                                    children: [
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.check,
                                                          color: Colors.green,
                                                        ),
                                                        tooltip: "Approve",
                                                        onPressed: () =>
                                                            _updateStatus(
                                                              doc.id,
                                                              "Approved",
                                                            ),
                                                      ),
                                                      IconButton(
                                                        icon: const Icon(
                                                          Icons.close,
                                                          color: Colors.red,
                                                        ),
                                                        tooltip: "Reject",
                                                        onPressed: () =>
                                                            _updateStatus(
                                                              doc.id,
                                                              "Rejected",
                                                            ),
                                                      ),
                                                    ],
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

  Widget _buildFilterTab(String title) {
    bool isActive = _selectedStatus == title;
    return InkWell(
      onTap: () => setState(() => _selectedStatus = title),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF1F5F9) : Colors.transparent,
        ),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
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

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.green.shade700;
        bg = Colors.green.shade50;
        break;
      case 'rejected':
        color = Colors.red.shade700;
        bg = Colors.red.shade50;
        break;
      default:
        color = Colors.orange.shade700;
        bg = Colors.orange.shade50;
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(
            Icons.app_registration_rounded,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No registrations found",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
