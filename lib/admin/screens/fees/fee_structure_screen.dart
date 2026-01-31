import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class FeeStructureScreen extends StatelessWidget {
  const FeeStructureScreen({super.key});

  void _addFeeType(BuildContext context) {
    TextEditingController titleCtrl = TextEditingController();
    TextEditingController amountCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Fee Structure"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Fee Title (e.g., Tuition)")),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: "Amount"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if(titleCtrl.text.isNotEmpty) {
                FirebaseFirestore.instance.collection('fee_structures').add({
                  'title': titleCtrl.text,
                  'amount': double.tryParse(amountCtrl.text) ?? 0.0,
                  'createdAt': FieldValue.serverTimestamp(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          )
        ],
      ),
    );
  }

  void _deleteFee(String id) {
    FirebaseFirestore.instance.collection('fee_structures').doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fee Structure"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addFeeType(context),
        label: const Text("Add New Fee"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fee_structures').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: ListTile(
                  leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.receipt_long, color: Colors.orange)),
                  title: Text(data['title'] ?? "Unknown", style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                  subtitle: Text("₹${data['amount']}", style: GoogleFonts.inter(color: Colors.green, fontWeight: FontWeight.bold)),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteFee(docs[index].id)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}