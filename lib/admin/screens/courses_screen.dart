import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
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

  // --- CRUD: ADD / EDIT COURSE DIALOG ---
  void _showCourseForm({String? docId, Map<String, dynamic>? data}) {
    final nameCtrl = TextEditingController(text: data?['courseName'] ?? '');
    final codeCtrl = TextEditingController(text: data?['courseCode'] ?? '');
    final creditsCtrl = TextEditingController(
      text: data?['credits']?.toString() ?? '3',
    );
    final instructorCtrl = TextEditingController(
      text: data?['instructor'] ?? '',
    );
    String dept = data?['department'] ?? 'CSE';
    bool isEdit = docId != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              isEdit ? "Edit Course" : "Add New Course",
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: "Course Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeCtrl,
                    enabled:
                        !isEdit, // Course code shouldn't be changed after creation
                    decoration: const InputDecoration(
                      labelText: "Course Code (Unique)",
                      hintText: "e.g. CS101",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: creditsCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: "Credits",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: dept,
                          decoration: const InputDecoration(
                            labelText: "Dept",
                            border: OutlineInputBorder(),
                          ),
                          items: ['MCA', 'MBA']
                              .map(
                                (d) =>
                                    DropdownMenuItem(value: d, child: Text(d)),
                              )
                              .toList(),
                          onChanged: (v) => setDialogState(() => dept = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: instructorCtrl,
                    decoration: const InputDecoration(
                      labelText: "Instructor Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        if (nameCtrl.text.isEmpty || codeCtrl.text.isEmpty) {
                          _showMsg("Name and Code are required", isError: true);
                          return;
                        }

                        setDialogState(() => _isProcessing = true);
                        String code = codeCtrl.text.trim().toUpperCase();
                        final db = FirebaseFirestore.instance.collection(
                          'courses',
                        );

                        try {
                          // --- DUPLICATION CHECK ---
                          if (!isEdit) {
                            final duplicate = await db
                                .where('courseCode', isEqualTo: code)
                                .get();
                            if (duplicate.docs.isNotEmpty) {
                              _showMsg(
                                "Course code '$code' already exists!",
                                isError: true,
                              );
                              setDialogState(() => _isProcessing = false);
                              return;
                            }
                          }

                          Map<String, dynamic> courseData = {
                            'courseName': nameCtrl.text.trim(),
                            'courseCode': code,
                            'credits': int.tryParse(creditsCtrl.text) ?? 3,
                            'department': dept,
                            'instructor': instructorCtrl.text.trim(),
                            'updatedAt': FieldValue.serverTimestamp(),
                          };

                          if (isEdit) {
                            await db.doc(docId).update(courseData);
                          } else {
                            courseData['createdAt'] =
                                FieldValue.serverTimestamp();
                            await db.add(courseData);
                          }

                          if (mounted) Navigator.pop(context);
                          _showMsg(
                            isEdit
                                ? "Course updated"
                                : "Course added successfully",
                          );
                        } catch (e) {
                          _showMsg("Error: $e", isError: true);
                        } finally {
                          setDialogState(() => _isProcessing = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
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
                    : Text(isEdit ? "Update" : "Create"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- CRUD: DELETE ---
  void _deleteCourse(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Course?"),
        content: const Text(
          "This will permanently remove this course from the directory.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('courses')
                  .doc(docId)
                  .delete();
              Navigator.pop(context);
              _showMsg("Course deleted", isError: true);
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            width: 90,
            child: AdminSidebar(activeIndex: 2),
          ), // Active index for Courses
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),

                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Course Directory",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            "Manage institutional curriculum and credits",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showCourseForm(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Add Course"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF001FF4),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Courses Grid
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('courses')
                        .orderBy('courseCode')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      var docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) return _buildEmptyState();

                      return Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: docs.map((doc) {
                          var data = doc.data() as Map<String, dynamic>;
                          return _buildCourseCard(doc.id, data);
                        }).toList(),
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

  Widget _buildCourseCard(String id, Map<String, dynamic> data) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['courseCode'] ?? "CODE",
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, color: Colors.grey),
                onSelected: (val) {
                  if (val == 'edit') _showCourseForm(docId: id, data: data);
                  if (val == 'delete') _deleteCourse(id);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'edit', child: Text("Edit")),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            data['courseName'] ?? "Untitled",
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${data['department']} • ${data['credits']} Credits",
            style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  data['instructor'] ?? "TBA",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
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
          Icon(Icons.book_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "No courses found in the directory.",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
