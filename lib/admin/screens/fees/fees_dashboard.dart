import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';
import 'fee_structure_screen.dart';
import 'fee_collection_screen.dart';
import 'fee_reports_screen.dart';
import 'accounts_screen.dart';

class FeesDashboard extends StatelessWidget {
  const FeesDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar - Index 3 is typically used for Finance/Fees in ERPs
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 3)),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),

                  // Back Button and Title
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        tooltip: "Back to Admin Dashboard",
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Fees Management",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Overview of institutional revenue and ledger accounts",
                            style: GoogleFonts.inter(
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- 1. FINANCIAL SUMMARY SECTION (REAL DATA) ---
                  _buildFinancialSummary(),
                  const SizedBox(height: 40),

                  // --- 2. GRID MENU ---
                  Text(
                    "Operations",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildMenuCard(
                        context,
                        "Fee Structure",
                        "Define types & amounts",
                        Icons.account_balance_wallet_rounded,
                        Colors.orange,
                        const FeeStructureScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        "Fee Collection",
                        "Record new payments",
                        Icons.currency_exchange_rounded,
                        Colors.blue,
                        const FeeCollectionScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        "Accounts",
                        "Ledgers & Balances",
                        Icons.account_balance_rounded,
                        Colors.teal,
                        const AccountsScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        "Reports",
                        "Invoices & Analytics",
                        Icons.analytics_rounded,
                        Colors.purple,
                        const FeeReportsScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        "Concessions",
                        "Manage discounts",
                        Icons.discount_rounded,
                        Colors.pink,
                        const SizedBox(),
                      ),
                      _buildMenuCard(
                        context,
                        "Settings",
                        "Configuration",
                        Icons.settings_applications_rounded,
                        Colors.blueGrey,
                        const SizedBox(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER: REAL-TIME SUMMARY ---
  Widget _buildFinancialSummary() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('fee_collections')
          .snapshots(),
      builder: (context, snapshot) {
        double totalRevenue = 0;
        int transactionCount = 0;

        if (snapshot.hasData) {
          transactionCount = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            totalRevenue += (doc['amount'] ?? 0.0);
          }
        }

        return Row(
          children: [
            _statTile(
              "Total Revenue",
              "₹${totalRevenue.toStringAsFixed(0)}",
              Icons.trending_up_rounded,
              Colors.green,
            ),
            const SizedBox(width: 20),
            _statTile(
              "Transactions",
              transactionCount.toString(),
              Icons.receipt_long_rounded,
              Colors.blue,
            ),
            const SizedBox(width: 20),
            _statTile(
              "Due Amount",
              "₹4.2L", // Example static value or calculated from a 'dues' collection
              Icons.pending_actions_rounded,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _statTile(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
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

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget page,
  ) {
    return InkWell(
      onTap: () {
        if (page is! SizedBox) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        }
      },
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Text(
                  "Manage",
                  style: TextStyle(
                    color: Color(0xFF001FF4),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: Color(0xFF001FF4),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
