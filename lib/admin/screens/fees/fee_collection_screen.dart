import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';

class FeeCollectionScreen extends StatefulWidget {
  const FeeCollectionScreen({super.key});

  @override
  State<FeeCollectionScreen> createState() => _FeeCollectionScreenState();
}

class _FeeCollectionScreenState extends State<FeeCollectionScreen> {
  bool _isProcessing = false;

  // --- HELPER: SHOW SNACKBAR ---
  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // --- DIALOG: RECORD NEW PAYMENT ---
  void _showCollectFeeDialog() {
    final studentCtrl = TextEditingController();
    final regNoCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String feeType = 'Tuition Fee';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("New Transaction", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: studentCtrl,
                    decoration: const InputDecoration(labelText: "Student Name", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: regNoCtrl,
                    decoration: const InputDecoration(labelText: "Registration No.", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: feeType,
                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                    items: ['Tuition Fee', 'Bus Fee', 'Exam Fee', 'Hostel Fee', 'Fine']
                        .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => feeType = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Amount (₹)", prefixText: "₹ ", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: _isProcessing ? null : () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  String name = studentCtrl.text.trim();
                  String reg = regNoCtrl.text.trim().toUpperCase();
                  double amt = double.tryParse(amountCtrl.text) ?? 0.0;

                  if (name.isEmpty || reg.isEmpty || amt <= 0) {
                    _showMsg("Please enter valid details", isError: true);
                    return;
                  }

                  setDialogState(() => _isProcessing = true);
                  final db = FirebaseFirestore.instance.collection('fee_collections');

                  try {
                    // --- DUPLICATION PREVENTION ---
                    // Check if the same student paid the same amount for same type in last 5 minutes
                    DateTime bufferTime = DateTime.now().subtract(const Duration(minutes: 5));
                    final duplicate = await db
                        .where('regNo', isEqualTo: reg)
                        .where('amount', isEqualTo: amt)
                        .where('type', isEqualTo: feeType)
                        .where('date', isGreaterThan: Timestamp.fromDate(bufferTime))
                        .get();

                    if (duplicate.docs.isNotEmpty) {
                      _showMsg("Error: Potential duplicate transaction detected!", isError: true);
                      setDialogState(() => _isProcessing = false);
                      return;
                    }

                    // --- GENERATE RECEIPT & SAVE ---
                    String rId = "TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
                    
                    await db.add({
                      'receiptId': rId,
                      'studentName': name,
                      'regNo': reg,
                      'type': feeType,
                      'amount': amt,
                      'date': FieldValue.serverTimestamp(),
                      'status': 'Success'
                    });

                    if (mounted) Navigator.pop(context);
                    _showMsg("Payment Recorded! Receipt: $rId");
                  } catch (e) {
                    _showMsg("Error: $e", isError: true);
                  } finally {
                    setDialogState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C51E1), foregroundColor: Colors.white),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Confirm Payment"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fee Collection"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
          tooltip: "Back to Fees Dashboard",
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton.icon(
              onPressed: _showCollectFeeDialog,
              icon: const Icon(Icons.add_card_rounded, size: 18),
              label: const Text("New Payment"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5C51E1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar Integration
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 3)),

          // 2. Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Real-time Total Stats
                  _buildStatsRow(),
                  const SizedBox(height: 40),

                  Text("Recent Transactions", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Main Transaction Table
                  _buildTransactionTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('fee_collections').snapshots(),
      builder: (context, snapshot) {
        double total = 0;
        int count = 0;
        if (snapshot.hasData) {
          count = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            total += (doc['amount'] ?? 0.0);
          }
        }
        return Row(
          children: [
            _statCard("Total Collected", "₹${NumberFormat('#,##,###').format(total)}", Colors.green, Icons.account_balance_wallet_rounded),
            const SizedBox(width: 24),
            _statCard("Total Transactions", "$count Payments", Colors.blue, Icons.receipt_long_rounded),
            const SizedBox(width: 24),
            _statCard("Daily Target", "₹2,50,000", Colors.orange, Icons.track_changes_rounded),
          ],
        );
      },
    );
  }

  Widget _buildTransactionTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fee_collections').orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return _buildEmptyState();

          return DataTable(
            horizontalMargin: 32,
            headingRowHeight: 60,
            dataRowMaxHeight: 80,
            columns: const [
              DataColumn(label: Text("RECEIPT ID", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
              DataColumn(label: Text("STUDENT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
              DataColumn(label: Text("CATEGORY", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
              DataColumn(label: Text("AMOUNT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
              DataColumn(label: Text("DATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
              DataColumn(label: Text("ACTIONS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey))),
            ],
            rows: docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              DateTime? date = data['date'] != null ? (data['date'] as Timestamp).toDate() : null;
              
              return DataRow(cells: [
                DataCell(Text(data['receiptId'] ?? "--", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                DataCell(Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(data['studentName'] ?? "--", style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(data['regNo'] ?? "--", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                )),
                DataCell(Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(6)),
                  child: Text(data['type'] ?? "--", style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                )),
                DataCell(Text("₹${NumberFormat('#,##,###').format(data['amount'])}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold))),
                DataCell(Text(date != null ? DateFormat('MMM dd, yyyy').format(date) : "Pending")),
                DataCell(Row(
                  children: [
                    IconButton(icon: const Icon(Icons.print_outlined, size: 20), onPressed: () => _showMsg("Generating PDF...")),
                    IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20), onPressed: () => doc.reference.delete()),
                  ],
                )),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _statCard(String title, String val, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9))),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                Text(val, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(80),
      child: Column(
        children: [
          Icon(Icons.history_edu_rounded, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          const Text("No transactions found in this period.", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}