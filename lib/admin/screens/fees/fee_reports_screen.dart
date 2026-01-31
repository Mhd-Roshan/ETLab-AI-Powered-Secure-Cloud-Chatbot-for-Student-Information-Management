import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

class FeeReportsScreen extends StatelessWidget {
  const FeeReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fee Reports"), backgroundColor: Colors.white, foregroundColor: Colors.black, elevation: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('fee_collections').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          
          var docs = snapshot.data!.docs;
          double totalCollected = 0;
          double todayCollected = 0;
          
          DateTime now = DateTime.now();
          for(var doc in docs) {
            var data = doc.data() as Map<String, dynamic>;
            double amount = (data['amount'] ?? 0).toDouble();
            totalCollected += amount;
            
            if(data['date'] != null) {
              DateTime d = (data['date'] as Timestamp).toDate();
              if(d.year == now.year && d.month == now.month && d.day == now.day) {
                todayCollected += amount;
              }
            }
          }

          return Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildReportCard("Total Collected", "₹${totalCollected.toStringAsFixed(0)}", Colors.green, Icons.savings),
                    const SizedBox(width: 24),
                    _buildReportCard("Collected Today", "₹${todayCollected.toStringAsFixed(0)}", Colors.blue, Icons.today),
                    const SizedBox(width: 24),
                    _buildReportCard("Pending Dues", "₹45,000", Colors.red, Icons.warning), // Static for now, requires student mapping
                  ],
                ),
                // Add graphs or more lists here later
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 16),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.bold)),
            Text(title, style: GoogleFonts.inter(color: Colors.grey, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}