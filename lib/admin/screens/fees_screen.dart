import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';
import 'fees/accounts_screen.dart';
import 'fees/fee_collection_screen.dart';
import 'fees/fee_reports_screen.dart';
import 'fees/fee_structure_screen.dart';

class FeesScreen extends StatelessWidget {
  const FeesScreen({super.key});

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
                  const AdminHeader(
                    title: "Fee Management",
                    showBackButton: true,
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(height: 16),
                  const SizedBox(height: 40),

                  // --- MENU GRID ---
                  // We use Wrap for responsive layout (similar to your image but flexible)
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _buildFeeMenuCard(
                        context,
                        "Fee Structure",
                        "Define semester fees & breakdowns",
                        Icons.layers_rounded,
                        Colors.amber,
                        const FeeStructureScreen(),
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Fee Collection",
                        "Collect payments & issue receipts",
                        Icons.payments_rounded,
                        Colors.orange,
                        const FeeCollectionScreen(),
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Fee Reports",
                        "Daily collection & due reports",
                        Icons.description_rounded,
                        Colors.blueGrey,
                        const FeeReportsScreen(),
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Manage",
                        "Fine settings & late fee rules",
                        Icons.tune_rounded,
                        Colors.pinkAccent,
                        null,
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Concession Groups",
                        "Scholarships & discounts",
                        Icons.diversity_3_rounded,
                        Colors.yellow.shade800,
                        null,
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Accounts",
                        "Bank accounts & transactions",
                        Icons.account_balance_rounded,
                        Colors.green,
                        const AccountsScreen(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // --- Quick Stats Overview (Bonus Feature) ---
                  const Text(
                    "Today's Overview",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildMiniStat(
                        "Collected Today",
                        "₹ 1,25,000",
                        Colors.green,
                      ),
                      const SizedBox(width: 24),
                      _buildMiniStat(
                        "Pending Dues",
                        "₹ 45,000",
                        Colors.redAccent,
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

  // --- WIDGET HELPERS ---

  Widget _buildFeeMenuCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget? page,
  ) {
    return Container(
      width: 300,
      height: 160,
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (page != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.grey.shade300,
                      size: 20,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
              ),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
