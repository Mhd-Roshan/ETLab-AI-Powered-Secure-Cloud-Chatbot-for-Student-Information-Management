import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/student_service.dart';

class FeesScreen extends StatefulWidget {
  final String? studentId;
  const FeesScreen({super.key, this.studentId});

  @override
  State<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends State<FeesScreen>
    with SingleTickerProviderStateMixin {
  final StudentService _studentService = StudentService();

  List<Map<String, dynamic>> _dummySemester = [];
  List<Map<String, dynamic>> _dummyExam = [];

  @override
  void initState() {
    super.initState();
    _initializeDummyData();
  }

  void _initializeDummyData() {
    _dummySemester = [
      {
        'title': 'Library Fine',
        'amount': 250,
        'dueDate': DateTime.now().subtract(const Duration(days: 2)),
        'status': 'Overdue',
        'type': 'Semester',
        'id': '3',
      },
    ];

    _dummyExam = [
      {
        'title': 'Exam Fee (Regular)',
        'amount': 1500,
        'dueDate': DateTime.now().add(const Duration(days: 5)),
        'status': 'Pending',
        'type': 'Exam',
        'id': '2',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Fees & Payments",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: widget.studentId == null
          ? _buildPendingList(
              [..._dummySemester, ..._dummyExam],
              isRealData: false,
              type: 'Pending',
            )
          : StreamBuilder<QuerySnapshot>(
              stream: _studentService.getFees(widget.studentId!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // If no real data, show dummy data for demonstration
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildPendingList(
                    [..._dummySemester, ..._dummyExam],
                    isRealData: false,
                    type: 'Pending',
                  );
                }

                // Process real data safely
                final docs = snapshot.data!.docs;
                final pendingFees = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>?;
                  return data != null && data['status'] == 'Pending';
                }).toList();

                return _buildPendingList(
                  pendingFees,
                  isRealData: true,
                  type: 'Pending',
                );
              },
            ),
    );
  }

  Widget _buildPendingList(
    List<dynamic>? fees, {
    required bool isRealData,
    required String type,
  }) {
    if (fees == null || fees.isEmpty) {
      return _buildEmptyState(
        "No pending $type fees!",
        Icons.check_circle_outline,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: fees.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final rawFee = fees[index];
        if (rawFee == null) return const SizedBox.shrink();

        final Map<String, dynamic> fee;
        if (isRealData) {
          final data = rawFee.data() as Map<String, dynamic>?;
          if (data == null) return const SizedBox.shrink();
          fee = data;
        } else {
          fee = rawFee as Map<String, dynamic>;
        }

        final title = fee['title'] ?? 'Fee Payment';
        final amount = fee['amount'] ?? 0;
        final dueDate = isRealData
            ? (fee['dueDate'] as Timestamp).toDate()
            : (fee['dueDate'] as DateTime);
        final status = fee['status'] ?? 'Pending';
        final isOverdue =
            status == 'Overdue' || dueDate.isBefore(DateTime.now());

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: isOverdue
                ? Border.all(color: Colors.red.withOpacity(0.5))
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOverdue
                            ? Colors.red.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOverdue ? "Overdue" : "Due Soon",
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "Due Date: ${DateFormat('dd MMM yyyy').format(dueDate)}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹$amount",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        final docId = isRealData ? fees[index].id : fee['id'];
                        _processPayment((isRealData ? fee : fee), docId);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001FF4),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 10,
                        ),
                      ),
                      child: const Text("Pay Now"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(Map<String, dynamic> fee, String docId) async {
    // 1. Show processing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await Future.delayed(const Duration(seconds: 2)); // Simulate gateway delay

    // 2. Mock Data Handling (Local State Update)
    if (widget.studentId == null || !docId.startsWith('doc_')) {
      // Assume non-firestore ID usage or explicit Mock mode if ID is simple
      // Logic: Real firestore IDs are usually long alphanumeric. Mock IDs are '1', '2', etc.
      // Or simply check if we are in dummy view logic.

      // However, better check:
      bool isMock = ['1', '2', '3', '4'].contains(docId);

      if (isMock) {
        final transactionId = "TXN${DateTime.now().millisecondsSinceEpoch}";
        final paymentDate = DateTime.now();

        if (mounted) {
          setState(() {
            // Try finding in Semester
            var semIndex = _dummySemester.indexWhere(
              (element) => element['id'] == docId,
            );
            if (semIndex != -1) {
              var paidFee = _dummySemester.removeAt(semIndex);
              paidFee['status'] = 'Paid';
              paidFee['paymentDate'] = paymentDate;
              paidFee['transactionId'] = transactionId;
              // No history list to insert into anymore
            } else {
              // Try Exam
              var examIndex = _dummyExam.indexWhere(
                (element) => element['id'] == docId,
              );
              if (examIndex != -1) {
                var paidFee = _dummyExam.removeAt(examIndex);
                paidFee['status'] = 'Paid';
                paidFee['paymentDate'] = paymentDate;
                paidFee['transactionId'] = transactionId;
                // No history list to insert into anymore
              }
            }
          });

          Navigator.pop(context); // Close loader

          // Show Success Dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("Payment Successful"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 60),
                  const SizedBox(height: 16),
                  Text("Transaction ID: $transactionId"),
                  const SizedBox(height: 8),
                  Text("Amount: ₹${fee['amount']}"),
                  const SizedBox(height: 8),
                  const Text(
                    "(Mock Payment)",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("OK"),
                ),
              ],
            ),
          );
        }
        return;
      }
    }

    try {
      // 3. Real Firestore Update
      if (docId.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close loader
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Error: Cannot process payment without a document ID.",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final transactionId = "TXN${DateTime.now().millisecondsSinceEpoch}";
      final paymentDate = DateTime.now();

      final feeRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .collection('fees')
          .doc(docId);

      await feeRef.update({
        'status': 'Paid',
        'paymentDate': paymentDate,
        'transactionId': transactionId,
      });

      if (mounted) {
        Navigator.pop(context); // Close loader
        // Show Success Dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Payment Successful"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text("Transaction ID: $transactionId"),
                const SizedBox(height: 8),
                Text("Amount: ₹${fee['amount']}"),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loader
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Payment Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
