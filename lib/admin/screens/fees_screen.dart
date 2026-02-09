import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

// Sub-screens
import 'fees/accounts_screen.dart';
import 'fees/fee_collection_screen.dart';
import 'fees/fee_reports_screen.dart';
import 'fees/fee_structure_screen.dart';

class FeesScreen extends StatefulWidget {
  const FeesScreen({super.key});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen> {
  bool _isSeeding = false;

  // --- SEED FEES FUNCTION ---
  Future<void> _seedFees() async {
    if (_isSeeding) return;
    
    setState(() => _isSeeding = true);

    try {
      final db = FirebaseFirestore.instance;
      
      // Fetch some students to assign fees to
      final studentsSnapshot = await db.collection('students').limit(10).get();
      
      if (studentsSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("No students found. Please add students first."),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isSeeding = false);
        return;
      }

      final batch = db.batch();
      final now = DateTime.now();
      
      for (int i = 0; i < studentsSnapshot.docs.length && i < 10; i++) {
        final studentDoc = studentsSnapshot.docs[i];
        final studentData = studentDoc.data();
        final department = studentData['department'] ?? 'MCA';
        final semester = studentData['semester'] ?? 1;
        
        // Fee amounts based on department
        final tuitionFee = department == 'MBA' ? 75000.0 : 65000.0;
        final examFee = 5000.0;
        final libraryFee = 2000.0;
        final totalFee = tuitionFee + examFee + libraryFee;
        
        // Random payment status
        final isPaid = i % 3 != 0; // 2 out of 3 paid
        final amountPaid = isPaid ? totalFee : (totalFee * 0.5); // Half paid if not fully paid
        final balance = totalFee - amountPaid;
        
        // Random payment date within last 30 days
        final daysAgo = i * 3;
        final paymentDate = now.subtract(Duration(days: daysAgo));
        
        // Payment method
        final paymentMethods = ['Cash', 'Online', 'Cheque', 'UPI', 'Card'];
        final paymentMethod = paymentMethods[i % paymentMethods.length];
        
        // Create fee collection record
        final feeRef = db.collection('fee_collections').doc();
        batch.set(feeRef, {
          'studentId': studentDoc.id,
          'studentName': '${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}'.trim(),
          'registrationNumber': studentData['registrationNumber'] ?? 'REG-${1000 + i}',
          'department': department,
          'semester': semester,
          'academicYear': '2024-2025',
          'feeType': 'Semester Fee',
          'tuitionFee': tuitionFee,
          'examFee': examFee,
          'libraryFee': libraryFee,
          'totalAmount': totalFee,
          'amountPaid': amountPaid,
          'balance': balance,
          'paymentMethod': paymentMethod,
          'transactionId': 'TXN${DateTime.now().millisecondsSinceEpoch}${i}',
          'status': isPaid ? 'Paid' : 'Partial',
          'date': Timestamp.fromDate(paymentDate),
          'dueDate': Timestamp.fromDate(now.add(const Duration(days: 30))),
          'remarks': isPaid ? 'Full payment received' : 'Partial payment - balance pending',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Update student's feesPaid status
        batch.update(studentDoc.reference, {
          'feesPaid': isPaid,
          'feesBalance': balance,
        });
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("✓ Successfully seeded 10 fee records!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error seeding fees: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSeeding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar - activeIndex 3 is typically Finance/Fees
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 3)),

          // 2. Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
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
                          Text(
                            "Fees & Accounts",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Monitor revenue streams and ledger balances",
                            style: GoogleFonts.inter(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _isSeeding ? null : _seedFees,
                        icon: _isSeeding 
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.add_circle_outline, size: 18),
                        label: Text(_isSeeding ? "Seeding..." : "Seed 10 Fees"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- LIVE STATS OVERVIEW ---
                  _buildLiveOverview(),
                  const SizedBox(height: 40),

                  // --- NAVIGATION GRID ---
                  Text(
                    "Management Modules",
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
                      _buildFeeMenuCard(
                        context,
                        "Fee Structure",
                        "Define courses and amounts",
                        Icons.layers_rounded,
                        Colors.amber,
                        const FeeStructureScreen(),
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Fee Collection",
                        "Record payments & receipts",
                        Icons.payments_rounded,
                        Colors.orange,
                        const FeeCollectionScreen(),
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Accounts",
                        "Bank ledgers & balances",
                        Icons.account_balance_rounded,
                        Colors.green,
                        const AccountsScreen(),
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Financial Reports",
                        "Analytics and summaries",
                        Icons.description_rounded,
                        Colors.blueGrey,
                        const FeeReportsScreen(),
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Concessions",
                        "Manage discounts & aid",
                        Icons.diversity_3_rounded,
                        Colors.pinkAccent,
                        null,
                      ),
                      _buildFeeMenuCard(
                        context,
                        "Settings",
                        "Late fee & fine rules",
                        Icons.tune_rounded,
                        Colors.indigoAccent,
                        null,
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

  // --- REAL-WORLD DATA LOGIC ---
  Widget _buildLiveOverview() {
    return Row(
      children: [
        // Today's Collection Stream
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('fee_collections').snapshots(),
            builder: (context, snapshot) {
              double todayTotal = 0;
              DateTime now = DateTime.now();

              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['date'] != null) {
                    DateTime d = (data['date'] as Timestamp).toDate();
                    // Filter for today's date
                    if (d.day == now.day && d.month == now.month && d.year == now.year) {
                      todayTotal += (data['amount'] ?? 0.0);
                    }
                  }
                }
              }
              return _buildMiniStat(
                "Collected Today",
                "₹ ${NumberFormat('#,##,###').format(todayTotal)}",
                Colors.green,
                Icons.trending_up,
              );
            },
          ),
        ),
        const SizedBox(width: 24),

        // Pending Dues Stream (Counting students with feesPaid == false)
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .where('feesPaid', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              int pendingCount = snapshot.data?.docs.length ?? 0;
              return _buildMiniStat(
                "Students with Dues",
                "$pendingCount Candidates",
                Colors.redAccent,
                Icons.error_outline_rounded,
              );
            },
          ),
        ),
        const SizedBox(width: 24),

        // Total Ledger Balance
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
            builder: (context, snapshot) {
              double ledgerBalance = 0;
              if (snapshot.hasData) {
                for (var doc in snapshot.data!.docs) {
                  ledgerBalance += (doc['balance'] ?? 0.0);
                }
              }
              return _buildMiniStat(
                "Total Assets",
                "₹ ${NumberFormat('#,##,###').format(ledgerBalance)}",
                Colors.blue,
                Icons.account_balance_wallet,
              );
            },
          ),
        ),
      ],
    );
  }

  // --- UI COMPONENTS ---

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 5)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (page != null) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => page));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Module coming soon...")),
              );
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
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const Icon(Icons.arrow_forward_rounded, color: Colors.grey, size: 18),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}