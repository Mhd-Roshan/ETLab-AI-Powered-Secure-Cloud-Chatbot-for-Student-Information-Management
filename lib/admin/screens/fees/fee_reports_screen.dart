import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class FeeReportsScreen extends StatelessWidget {
  const FeeReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SIDEBAR INTEGRATION (Active Index 3 for Finance)
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 3)),

          // 2. MAIN CONTENT (Full screen from the very top)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(), // Standard Top Header
                  const SizedBox(height: 32),

                  // Breadcrumb / Title Row
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                        style: IconButton.styleFrom(backgroundColor: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Financial Reports",
                              style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text("Real-time revenue analytics and collection insights", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        onPressed: () {}, // Future PDF Export
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text("Export PDF"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- DATA AGGREGATION STREAM ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('fee_collections').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      var docs = snapshot.data?.docs ?? [];
                      double totalCollected = 0;
                      double todayCollected = 0;
                      double monthlyCollected = 0;
                      Map<String, double> categoryBreakdown = {};

                      DateTime now = DateTime.now();
                      
                      for (var doc in docs) {
                        var data = doc.data() as Map<String, dynamic>;
                        double amount = (data['amount'] ?? 0).toDouble();
                        String type = data['type'] ?? "General";
                        totalCollected += amount;

                        // Category Logic
                        categoryBreakdown[type] = (categoryBreakdown[type] ?? 0) + amount;

                        if (data['date'] != null) {
                          DateTime d = (data['date'] as Timestamp).toDate();
                          // Today's Logic
                          if (d.year == now.year && d.month == now.month && d.day == now.day) {
                            todayCollected += amount;
                          }
                          // This Month's Logic
                          if (d.year == now.year && d.month == now.month) {
                            monthlyCollected += amount;
                          }
                        }
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top Stats Row
                          Row(
                            children: [
                              _buildReportCard("Life-time Collection", "₹${NumberFormat('#,##,###').format(totalCollected)}", Colors.green, Icons.account_balance_wallet_rounded),
                              const SizedBox(width: 24),
                              _buildReportCard("Collected Today", "₹${NumberFormat('#,##,###').format(todayCollected)}", Colors.blue, Icons.today_rounded),
                              const SizedBox(width: 24),
                              _buildReportCard("This Month", "₹${NumberFormat('#,##,###').format(monthlyCollected)}", Colors.purple, Icons.calendar_month_rounded),
                            ],
                          ),
                          const SizedBox(height: 40),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Wise Breakdown
                              Expanded(
                                flex: 2,
                                child: _buildCategoryBreakdown(categoryBreakdown),
                              ),
                              const SizedBox(width: 24),
                              // Dues Estimation (Logic based on Students with unpaid fees)
                              Expanded(
                                flex: 1,
                                child: _buildDuesEstimation(),
                              ),
                            ],
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

  Widget _buildReportCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 20),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
            Text(title, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(Map<String, double> breakdown) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Collection by Category", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          if (breakdown.isEmpty) const Text("No data available", style: TextStyle(color: Colors.grey)),
          ...breakdown.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(e.key, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.blueGrey.shade700)),
                    Text("₹${NumberFormat('#,##,###').format(e.value)}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.7, // In a real app: (e.value / totalCollected)
                  backgroundColor: Colors.grey.shade100,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                  borderRadius: BorderRadius.circular(10),
                  minHeight: 6,
                )
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDuesEstimation() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('students').where('feesPaid', isEqualTo: false).snapshots(),
      builder: (context, snapshot) {
        int studentCount = snapshot.data?.docs.length ?? 0;
        return Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.red.shade400, Colors.red.shade600], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30),
              const SizedBox(height: 20),
              Text("$studentCount", style: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
              Text("Students with pending dues", style: GoogleFonts.inter(color: Colors.white.withOpacity(0.8), fontSize: 14)),
              const SizedBox(height: 24),
              const Divider(color: Colors.white24),
              TextButton(
                onPressed: () {},
                child: const Row(
                  children: [
                    Text("View List", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}