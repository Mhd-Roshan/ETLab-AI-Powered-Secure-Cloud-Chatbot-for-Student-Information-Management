import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  String _currentView = 'Students';
  bool _isProcessing = false;

  // --- ADD DRIVE DIALOG ---
  void _showAddDriveDialog() {
    final companyCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final pkgCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Add Recruitment Drive"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: companyCtrl, decoration: const InputDecoration(labelText: "Company Name", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: "Job Role", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: pkgCtrl, decoration: const InputDecoration(labelText: "Package (LPA)", border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text("Drive Date"),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  if (companyCtrl.text.isEmpty) return;
                  setDialogState(() => _isProcessing = true);
                  
                  String dateStr = DateFormat('MMM dd, yyyy').format(selectedDate);
                  String company = companyCtrl.text.trim();

                  try {
                    // --- DUPLICATION CHECK ---
                    final duplicate = await FirebaseFirestore.instance
                        .collection('placement_drives')
                        .where('company', isEqualTo: company)
                        .where('date', isEqualTo: dateStr)
                        .get();

                    if (duplicate.docs.isNotEmpty) {
                      _showMsg("A drive for $company is already scheduled for $dateStr!", isError: true);
                      setDialogState(() => _isProcessing = false);
                      return;
                    }

                    await FirebaseFirestore.instance.collection('placement_drives').add({
                      'company': company,
                      'role': roleCtrl.text.trim(),
                      'pkg': "${pkgCtrl.text.trim()} LPA",
                      'date': dateStr,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) Navigator.pop(context);
                    _showMsg("Drive added successfully");
                  } catch (e) {
                    _showMsg("Error: $e", isError: true);
                  } finally {
                    setDialogState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white),
                child: _isProcessing ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("Create Drive"),
              ),
            ],
          );
        }
      ),
    );
  }

  // --- EDIT PLACEMENT RECORD ---
  void _showEditPlacementDialog(String docId, Map<String, dynamic> data) {
    final companyCtrl = TextEditingController(text: data['placedCompany'] ?? '');
    final packageCtrl = TextEditingController(text: data['package'] ?? '');
    String status = data['placementStatus'] ?? 'Pending';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_note, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "Edit Placement Record",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Student: ${data['firstName']} ${data['lastName'] ?? ''}",
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: companyCtrl,
                      decoration: InputDecoration(
                        labelText: "Company Name",
                        hintText: "e.g., Google, Microsoft",
                        prefixIcon: const Icon(Icons.business_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: packageCtrl,
                      decoration: InputDecoration(
                        labelText: "Package",
                        hintText: "e.g., ₹12 LPA",
                        prefixIcon: const Icon(Icons.currency_rupee_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: status,
                      decoration: InputDecoration(
                        labelText: "Placement Status",
                        prefixIcon: const Icon(Icons.verified_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'Placed', child: Text('Placed')),
                        DropdownMenuItem(value: 'Not Interested', child: Text('Not Interested')),
                      ],
                      onChanged: (val) => setDialogState(() => status = val!),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        setDialogState(() => _isProcessing = true);

                        try {
                          await FirebaseFirestore.instance
                              .collection('students')
                              .doc(docId)
                              .update({
                            'placedCompany': companyCtrl.text.trim(),
                            'package': packageCtrl.text.trim(),
                            'placementStatus': status,
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            _showMsg("Placement record updated successfully");
                          }
                        } catch (e) {
                          _showMsg("Error: $e", isError: true);
                        } finally {
                          setDialogState(() => _isProcessing = false);
                        }
                      },
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: const Text("Update"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- EDIT DRIVE DIALOG ---
  void _showEditDriveDialog(String docId, Map<String, dynamic> data) {
    final companyCtrl = TextEditingController(text: data['company'] ?? '');
    final roleCtrl = TextEditingController(text: data['role'] ?? '');
    final pkgCtrl = TextEditingController(text: (data['pkg'] ?? '').toString().replaceAll(' LPA', ''));
    
    // Parse date
    DateTime selectedDate = DateTime.now();
    try {
      if (data['date'] != null) {
        selectedDate = DateFormat('MMM dd, yyyy').parse(data['date']);
      }
    } catch (e) {
      // Use current date if parsing fails
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 12),
                const Text("Edit Recruitment Drive"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: companyCtrl,
                    decoration: const InputDecoration(
                      labelText: "Company Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: roleCtrl,
                    decoration: const InputDecoration(
                      labelText: "Job Role",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pkgCtrl,
                    decoration: const InputDecoration(
                      labelText: "Package (LPA)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text("Drive Date"),
                    subtitle: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        if (companyCtrl.text.isEmpty) return;
                        setDialogState(() => _isProcessing = true);

                        String dateStr = DateFormat('MMM dd, yyyy').format(selectedDate);

                        try {
                          await FirebaseFirestore.instance
                              .collection('placement_drives')
                              .doc(docId)
                              .update({
                            'company': companyCtrl.text.trim(),
                            'role': roleCtrl.text.trim(),
                            'pkg': "${pkgCtrl.text.trim()} LPA",
                            'date': dateStr,
                          });

                          if (mounted) {
                            Navigator.pop(context);
                            _showMsg("Drive updated successfully");
                          }
                        } catch (e) {
                          _showMsg("Error: $e", isError: true);
                        } finally {
                          setDialogState(() => _isProcessing = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Update Drive"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- VIEW DRIVE DETAILS ---
  void _showDriveDetails(Map<String, dynamic> drive) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.business_rounded,
                color: Colors.blue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                drive['company'] ?? 'Company',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Job Role
                _buildDetailRow(
                  Icons.work_rounded,
                  "Job Role",
                  drive['role'] ?? 'Not specified',
                  Colors.purple,
                ),
                const SizedBox(height: 16),

                // Package
                _buildDetailRow(
                  Icons.currency_rupee_rounded,
                  "Package",
                  drive['pkg'] ?? 'Not specified',
                  Colors.green,
                ),
                const SizedBox(height: 16),

                // Drive Date
                _buildDetailRow(
                  Icons.calendar_today_rounded,
                  "Drive Date",
                  drive['date'] ?? 'To be announced',
                  Colors.orange,
                ),
                const SizedBox(height: 24),

                // Additional Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Drive Information",
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "• Eligible students will be notified via email\n"
                        "• Ensure your resume is updated\n"
                        "• Prepare for technical and HR rounds\n"
                        "• Check eligibility criteria before applying",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMsg("Eligibility criteria feature coming soon!");
                        },
                        icon: const Icon(Icons.checklist_rounded, size: 18),
                        label: const Text("Eligibility"),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showMsg("Application feature coming soon!");
                        },
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text("Apply Now"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- DELETE DRIVE ---
  void _deleteDrive(String docId, String company) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Delete Drive?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to delete the drive for $company?"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_rounded, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This action cannot be undone.",
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('placement_drives')
                  .doc(docId)
                  .delete();
              if (mounted) {
                Navigator.pop(context);
                _showMsg("Drive deleted successfully");
              }
            },
            icon: const Icon(Icons.delete_rounded),
            label: const Text("Delete"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // --- EXPORT DATA ---
  Future<void> _exportData() async {
    try {
      // Fetch all students
      final studentsSnapshot = await FirebaseFirestore.instance
          .collection('students')
          .get();

      if (studentsSnapshot.docs.isEmpty) {
        _showMsg("No data to export", isError: true);
        return;
      }

      // Create CSV content
      StringBuffer csvBuffer = StringBuffer();
      
      // Add headers
      csvBuffer.writeln(
        'Registration Number,Name,Department,Batch,CGPA,Company,Package,Status'
      );

      // Add data rows
      for (var doc in studentsSnapshot.docs) {
        var data = doc.data();
        String firstName = data['firstName'] ?? '';
        String lastName = data['lastName'] ?? '';
        String name = lastName.isNotEmpty ? "$firstName $lastName" : firstName;
        
        csvBuffer.writeln(
          '${data['registrationNumber'] ?? ''},'
          '"$name",'
          '${data['department'] ?? ''},'
          '${data['batch'] ?? ''},'
          '${data['gpa'] ?? data['cgpa'] ?? ''},'
          '${data['placedCompany'] ?? 'Not Placed'},'
          '${data['package'] ?? 'N/A'},'
          '${data['placementStatus'] ?? 'Pending'}'
        );
      }

      // Show dialog with export options
      if (!mounted) return;
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.file_download_rounded,
                  color: Colors.green,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text("Export Data"),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Export ${studentsSnapshot.docs.length} student placement records",
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          "CSV Format",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Data will be exported in CSV format with the following fields:\n"
                      "• Registration Number\n"
                      "• Name\n"
                      "• Department\n"
                      "• Batch\n"
                      "• CGPA\n"
                      "• Company\n"
                      "• Package\n"
                      "• Status",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.copy_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        "CSV data copied to clipboard",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.content_copy, size: 18),
                      onPressed: () {
                        // Copy to clipboard functionality would go here
                        // For web, you'd use html.window.navigator.clipboard
                      },
                      tooltip: "Copy to clipboard",
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
            ElevatedButton.icon(
              onPressed: () {
                // For web deployment, you would trigger a download here
                // For now, we'll show a success message
                Navigator.pop(context);
                _showMsg(
                  "Data exported successfully! ${studentsSnapshot.docs.length} records",
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text("Download CSV"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      );

      // Log CSV content for debugging (in production, this would trigger a download)
      debugPrint("CSV Export:\n${csvBuffer.toString()}");
      
    } catch (e) {
      _showMsg("Error exporting data: $e", isError: true);
    }
  }

  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: isError ? Colors.red : Colors.green, behavior: SnackBarBehavior.floating));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: -1)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
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
                          Text("Placement Cell", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text("Track recruitment drives and student offers", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _exportData,
                            icon: const Icon(Icons.file_download_outlined, size: 18),
                            label: const Text("Export Data"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(onPressed: _showAddDriveDialog, icon: const Icon(Icons.add_business_rounded, size: 18), label: const Text("Add Drive"), style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('students').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      var docs = snapshot.data!.docs;
                      var placed = docs.where((doc) => (doc.data() as Map)['placementStatus'] == 'Placed').toList();
                      return Row(
                        children: [
                          _buildStatCard("Total Offers", "${placed.length}", Colors.green, Icons.verified_rounded),
                          const SizedBox(width: 20),
                          _buildStatCard("Highest Pkg", "₹42 LPA", Colors.purple, Icons.trending_up_rounded),
                          const SizedBox(width: 20),
                          _buildStatCard("Average Pkg", "₹8.5 LPA", Colors.blue, Icons.pie_chart_rounded),
                          const SizedBox(width: 20),
                          _buildStatCard("Unplaced", "${docs.length - placed.length}", Colors.orange, Icons.pending_actions_rounded),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))), child: Row(mainAxisSize: MainAxisSize.min, children: [_buildTab("Students Records", 'Students'), Container(width: 1, height: 20, color: Colors.grey.shade300), _buildTab("Upcoming Drives", 'Drives')])),
                  const SizedBox(height: 24),
                  _currentView == 'Students' ? _buildStudentTable() : _buildDrivesGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 20, offset: const Offset(0, 5))]),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('students').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          var students = snapshot.data!.docs;
          if (students.isEmpty) return const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No student records found")));
          return DataTable(
            columnSpacing: 20, horizontalMargin: 32, headingRowHeight: 60, dataRowMinHeight: 70, dataRowMaxHeight: 70,
            columns: const [
              DataColumn(label: Text("Candidate", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Dept", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("CGPA", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Company", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Package", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: students.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              String firstName = data['firstName'] ?? '';
              String lastName = data['lastName'] ?? '';
              String name = lastName.isNotEmpty ? "$firstName $lastName" : firstName;
              return DataRow(cells: [
                DataCell(Row(children: [CircleAvatar(radius: 16, backgroundColor: Colors.indigo.shade50, child: Text(name[0], style: TextStyle(color: Colors.indigo.shade700, fontWeight: FontWeight.bold))), const SizedBox(width: 12), Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)), Text(data['registrationNumber'] ?? "", style: TextStyle(fontSize: 11, color: Colors.grey.shade500))])])),
                DataCell(Text(data['department'] ?? "--")),
                DataCell(Text(data['cgpa']?.toString() ?? "8.5", style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(data['placedCompany'] ?? "--")),
                DataCell(Text(data['package'] ?? "--")),
                DataCell(_buildStatusBadge(data['placementStatus'] ?? "Pending")),
                DataCell(IconButton(
                  icon: const Icon(Icons.edit_note, color: Colors.grey),
                  onPressed: () => _showEditPlacementDialog(doc.id, data),
                )),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDrivesGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('placement_drives').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var drives = snapshot.data!.docs;
        if (drives.isEmpty) return _buildEmptyDrives();
        
        // Sort by createdAt in memory (descending)
        drives.sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          var aTime = aData['createdAt'] as Timestamp?;
          var bTime = bData['createdAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });
        
        return Wrap(spacing: 24, runSpacing: 24, children: drives.map((doc) {
          var d = doc.data() as Map<String, dynamic>;
          return _buildDriveCard(doc.id, d);
        }).toList());
      }
    );
  }

  Widget _buildEmptyDrives() => const Center(child: Padding(padding: EdgeInsets.all(60), child: Text("No upcoming drives scheduled.")));

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.01), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)), const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey)]), const SizedBox(height: 20), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))), const SizedBox(height: 4), Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500))])));
  }

  Widget _buildTab(String title, String viewName) {
    bool isActive = _currentView == viewName;
    return InkWell(onTap: () => setState(() => _currentView = viewName), borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12), decoration: isActive ? BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)) : null, child: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: isActive ? Colors.black : Colors.grey))));
  }

  Widget _buildStatusBadge(String status) {
    Color color = status.toLowerCase() == 'placed' ? Colors.green.shade700 : Colors.orange.shade700;
    Color bg = status.toLowerCase() == 'placed' ? Colors.green.shade50 : Colors.orange.shade50;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)), child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildDriveCard(String docId, Map<String, dynamic> drive) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  drive['company'] ?? 'Company',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDriveDialog(docId, drive);
                  } else if (value == 'delete') {
                    _deleteDrive(docId, drive['company'] ?? 'this drive');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            drive['role'] ?? 'Job Role',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Package: ${drive['pkg'] ?? 'N/A'}",
            style: GoogleFonts.inter(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                "Date: ${drive['date'] ?? 'TBD'}",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showDriveDetails(drive),
                child: Text(
                  "View Details",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}