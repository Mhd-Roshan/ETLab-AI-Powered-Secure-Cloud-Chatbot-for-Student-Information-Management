import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  bool _isProcessing = false;

  // --- HELPER: SHOW MESSAGES ---
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

  // --- DIALOG: CREATE NEW LEDGER ---
  void _showAddAccountDialog() {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController(text: "0");
    String accountType = 'Asset';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Create Ledger Account", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Account Name", hintText: "e.g., Tuition Fee Ledger", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: accountType,
                    decoration: const InputDecoration(labelText: "Account Type", border: OutlineInputBorder()),
                    items: ['Asset', 'Income', 'Expense'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => setDialogState(() => accountType = v!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: balanceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Opening Balance (₹)", border: OutlineInputBorder(), prefixText: "₹ "),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: _isProcessing ? null : () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  String name = nameCtrl.text.trim();
                  if (name.isEmpty) {
                    _showMsg("Account name is required", isError: true);
                    return;
                  }

                  setDialogState(() => _isProcessing = true);
                  final db = FirebaseFirestore.instance.collection('accounts');

                  try {
                    // --- DUPLICATION CHECK ---
                    final duplicate = await db.where('name', isEqualTo: name).get();
                    if (duplicate.docs.isNotEmpty) {
                      _showMsg("Account '$name' already exists!", isError: true);
                      setDialogState(() => _isProcessing = false);
                      return;
                    }

                    // --- SAVE TO FIREBASE ---
                    await db.add({
                      'name': name,
                      'type': accountType,
                      'balance': double.tryParse(balanceCtrl.text) ?? 0.0,
                      'createdAt': FieldValue.serverTimestamp(),
                      'status': 'Active',
                    });

                    if (mounted) Navigator.pop(context);
                    _showMsg("Ledger account created successfully");
                  } catch (e) {
                    _showMsg("Database Error: $e", isError: true);
                  } finally {
                    setDialogState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5C51E1), foregroundColor: Colors.white),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Create Account"),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SIDEBAR (Full Height)
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 3)),

          // 2. MAIN CONTENT (Full screen from top)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(), // Custom top header
                  const SizedBox(height: 32),

                  // Breadcrumb / Back Navigation
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
                          Text("Accounts & Ledgers",
                              style: GoogleFonts.plusJakartaSans(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          Text("Spring 2026 • Institutional Funds", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showAddAccountDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add Ledger"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C51E1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Live Stats Cards
                  _buildLiveStatsRow(),
                  const SizedBox(height: 40),

                  Text("Active Ledger Accounts", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),

                  // Ledgers Grid
                  _buildLedgerGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
      builder: (context, snapshot) {
        double total = 0;
        int activeCount = 0;
        if (snapshot.hasData) {
          activeCount = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            total += (doc['balance'] ?? 0.0);
          }
        }
        return Row(
          children: [
            _statCard("Total Assets", "₹${NumberFormat('#,##,###').format(total)}", Colors.green, Icons.account_balance_wallet),
            const SizedBox(width: 24),
            _statCard("Active Ledgers", "$activeCount Accounts", Colors.blue, Icons.list_alt_rounded),
            const SizedBox(width: 24),
            _statCard("Audit Status", "Cleared", Colors.orange, Icons.fact_check_outlined),
          ],
        );
      },
    );
  }

  Widget _buildLedgerGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        var docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 400,
            mainAxisExtent: 180,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            var data = docs[index].data() as Map<String, dynamic>;
            return _ledgerCard(docs[index].id, data);
          },
        );
      },
    );
  }

  Widget _ledgerCard(String id, Map<String, dynamic> data) {
    Color typeColor = data['type'] == 'Expense' ? Colors.red : Colors.green;
    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text(data['type'] ?? "Asset", style: TextStyle(color: typeColor, fontWeight: FontWeight.bold, fontSize: 10)),
              ),
              IconButton(onPressed: () => _confirmDelete(id, data['name']), icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20)),
            ],
          ),
          const SizedBox(height: 12),
          Text(data['name'] ?? "Untitled Ledger", style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Balance", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                  Text("₹${NumberFormat('#,##,###').format(data['balance'])}", style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                ],
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Ledger?"),
        content: Text("Warning: Deleting '$name' will remove all financial references to this account."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(onPressed: () {
            FirebaseFirestore.instance.collection('accounts').doc(id).delete();
            Navigator.pop(context);
            _showMsg("Account deleted", isError: true);
          }, child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
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
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: color, size: 24)),
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
          Icon(Icons.account_balance_rounded, size: 60, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          const Text("No Ledger Accounts Found", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}