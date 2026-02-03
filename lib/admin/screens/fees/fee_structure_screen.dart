import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';

class FeeStructureScreen extends StatefulWidget {
  const FeeStructureScreen({super.key});

  @override
  State<FeeStructureScreen> createState() => _FeeStructureScreenState();
}

class _FeeStructureScreenState extends State<FeeStructureScreen> {
  bool _isProcessing = false;

  // --- HELPER: SHOW SNACKBAR MESSAGES ---
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

  // --- DIALOG: ADD FEE TYPE WITH DUPLICATION CHECK ---
  void _showAddFeeTypeDialog() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text("Add Fee Category", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Fee Title",
                    hintText: "e.g. Tuition Fee",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  decoration: const InputDecoration(
                    labelText: "Amount (₹)",
                    prefixText: "₹ ",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: _isProcessing ? null : () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  String title = titleCtrl.text.trim();
                  String amountStr = amountCtrl.text.trim();

                  if (title.isEmpty || amountStr.isEmpty) {
                    _showMsg("All fields are required", isError: true);
                    return;
                  }

                  setDialogState(() => _isProcessing = true);

                  try {
                    // --- DUPLICATION LOGIC ---
                    // Query Firestore to see if this title already exists
                    final duplicateCheck = await FirebaseFirestore.instance
                        .collection('fee_structures')
                        .where('title', isEqualTo: title)
                        .get();

                    if (duplicateCheck.docs.isNotEmpty) {
                      _showMsg("Fee structure '$title' already exists!", isError: true);
                      setDialogState(() => _isProcessing = false);
                      return;
                    }

                    // --- SAVE TO FIREBASE ---
                    await FirebaseFirestore.instance.collection('fee_structures').add({
                      'title': title,
                      'amount': double.tryParse(amountStr) ?? 0.0,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) Navigator.pop(context);
                    _showMsg("Fee category added successfully");
                  } catch (e) {
                    _showMsg("Error: $e", isError: true);
                  } finally {
                    setDialogState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text("Save Category"),
              )
            ],
          );
        },
      ),
    );
  }

  // --- ACTION: DELETE WITH CONFIRMATION ---
  void _deleteFee(String id, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Fee Type?"),
        content: Text("Are you sure you want to remove '$title' from the structure?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('fee_structures').doc(id).delete();
              Navigator.pop(context);
              _showMsg("Deleted $title", isError: true);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Fee Structure"),
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
              onPressed: _showAddFeeTypeDialog,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Add New Fee"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepOrangeAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
          // 1. Sidebar (Using your custom Sidebar)
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 3)),

          // 2. Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Data Grid / List
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('fee_structures').orderBy('createdAt', descending: true).snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
                      }
                      var docs = snapshot.data?.docs ?? [];

                      if (docs.isEmpty) {
                        return _buildEmptyState();
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 350,
                          mainAxisExtent: 100,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;
                          return _buildFeeCard(docs[index].id, data);
                        },
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

  Widget _buildFeeCard(String id, Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.orange, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['title'] ?? "Unknown", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15)),
                Text("₹${data['amount']}", style: GoogleFonts.inter(color: Colors.green.shade700, fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteFee(id, data['title'] ?? "this fee"),
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(Icons.list_alt_rounded, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text("No Fee Structures Found", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Text("Start by adding a new fee category above.", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}