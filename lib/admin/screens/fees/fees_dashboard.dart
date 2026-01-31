import 'package:flutter/material.dart';
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
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 0)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),
                  Text(
                    "Fees Management",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid Menu
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildMenuCard(
                        context,
                        "Fee Structure",
                        Icons.account_balance_wallet_rounded,
                        Colors.orange,
                        const FeeStructureScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        "Fee Collection",
                        Icons.currency_exchange_rounded,
                        Colors.blue,
                        const FeeCollectionScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        "Fee Reports",
                        Icons.analytics_rounded,
                        Colors.purple,
                        const FeeReportsScreen(),
                      ),
                      _buildMenuCard(
                        context,
                        "Accounts",
                        Icons.account_balance_rounded,
                        Colors.teal,
                        const AccountsScreen(),
                      ),
                      // Extra items from your image reference
                      _buildMenuCard(
                        context,
                        "Concessions",
                        Icons.discount_rounded,
                        Colors.pink,
                        const SizedBox(),
                      ),
                      _buildMenuCard(
                        context,
                        "Manage",
                        Icons.settings_applications_rounded,
                        Colors.grey,
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

  Widget _buildMenuCard(
    BuildContext context,
    String title,
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
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 260,
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
