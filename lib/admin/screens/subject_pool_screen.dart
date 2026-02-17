import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class SubjectPoolScreen extends StatefulWidget {
  const SubjectPoolScreen({super.key});

  @override
  State<SubjectPoolScreen> createState() => _SubjectPoolScreenState();
}

class _SubjectPoolScreenState extends State<SubjectPoolScreen> {
  String _selectedDept = 'MCA';
  final List<String> _departments = ['MCA', 'MBA'];
  bool _isProcessing = false; // Loading state to prevent duplicate clicks

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

  // --- DIALOG: Add Subject ---
  void _showAddSubjectDialog() {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final creditsCtrl = TextEditingController(text: "3");
    final instructorCtrl = TextEditingController();
    String dept = _selectedDept;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text("Add New Subject"),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: codeCtrl,
                            decoration: const InputDecoration(
                              labelText: "Course Code",
                              hintText: "e.g. CS301",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: creditsCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Credits",
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) => v!.isEmpty ? "Required" : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Subject Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: dept,
                      decoration: const InputDecoration(
                        labelText: "Department",
                        border: OutlineInputBorder(),
                      ),
                      items: _departments
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) => dept = v!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: instructorCtrl,
                      decoration: const InputDecoration(
                        labelText: "Instructor (Optional)",
                        border: OutlineInputBorder(),
                      ),
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
              ElevatedButton(
                onPressed: _isProcessing
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => _isProcessing = true);

                          String code = codeCtrl.text.trim().toUpperCase();
                          String name = nameCtrl.text.trim();
                          final db = FirebaseFirestore.instance.collection(
                            'courses',
                          );

                          try {
                            // --- DUPLICATION CHECK: Course Code ---
                            final duplicateCode = await db.doc(code).get();
                            if (duplicateCode.exists) {
                              _showMsg(
                                "Course code '$code' already exists!",
                                isError: true,
                              );
                              setDialogState(() => _isProcessing = false);
                              return;
                            }

                            // --- DUPLICATION CHECK: Course Name ---
                            final duplicateName = await db
                                .where('courseName', isEqualTo: name)
                                .where('department', isEqualTo: dept)
                                .get();
                            if (duplicateName.docs.isNotEmpty) {
                              _showMsg(
                                "Subject name '$name' already exists in $dept!",
                                isError: true,
                              );
                              setDialogState(() => _isProcessing = false);
                              return;
                            }

                            // --- CREATE DOC ---
                            await db.doc(code).set({
                              'courseCode': code,
                              'courseName': name,
                              'credits': int.tryParse(creditsCtrl.text) ?? 3,
                              'department': dept,
                              'instructor': instructorCtrl.text.isEmpty
                                  ? "TBA"
                                  : instructorCtrl.text.trim(),
                              'totalStudents': 0,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (mounted) Navigator.pop(context);
                            _showMsg("Course added successfully");
                          } catch (e) {
                            _showMsg("Error: $e", isError: true);
                          } finally {
                            setDialogState(() => _isProcessing = false);
                          }
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
                    : const Text("Add Course"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOG: Edit Subject ---
  void _showEditSubjectDialog(DocumentSnapshot doc) {
    final formKey = GlobalKey<FormState>();
    var data = doc.data() as Map<String, dynamic>;
    final nameCtrl = TextEditingController(text: data['courseName']);
    final creditsCtrl = TextEditingController(text: data['credits'].toString());
    final instructorCtrl = TextEditingController(text: data['instructor']);
    String dept = data['department'] ?? _selectedDept;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Subject"),
            content: SizedBox(
              width: 400,
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      initialValue: data['courseCode'],
                      enabled: false, // ID shouldn't change
                      decoration: const InputDecoration(
                        labelText: "Course Code",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "Subject Name",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: creditsCtrl,
                      decoration: const InputDecoration(
                        labelText: "Credits",
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? "Required" : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: dept,
                      decoration: const InputDecoration(
                        labelText: "Department",
                        border: OutlineInputBorder(),
                      ),
                      items: _departments
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
                          .toList(),
                      onChanged: (v) => dept = v!,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: instructorCtrl,
                      decoration: const InputDecoration(
                        labelText: "Instructor",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
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
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => _isProcessing = true);

                          String newName = nameCtrl.text.trim();
                          String currentName = data['courseName'];

                          try {
                            // --- DUPLICATION CHECK: Course Name (only if name changed) ---
                            if (newName != currentName) {
                              final duplicateName = await FirebaseFirestore
                                  .instance
                                  .collection('courses')
                                  .where('courseName', isEqualTo: newName)
                                  .where('department', isEqualTo: dept)
                                  .get();

                              if (duplicateName.docs.isNotEmpty) {
                                _showMsg(
                                  "Subject name '$newName' already exists in $dept!",
                                  isError: true,
                                );
                                setDialogState(() => _isProcessing = false);
                                return;
                              }
                            }

                            await FirebaseFirestore.instance
                                .collection('courses')
                                .doc(doc.id)
                                .update({
                                  'courseName': newName,
                                  'credits':
                                      int.tryParse(creditsCtrl.text) ?? 3,
                                  'department': dept,
                                  'instructor': instructorCtrl.text.trim(),
                                });
                            if (mounted) Navigator.pop(context);
                            _showMsg("Course updated");
                          } catch (e) {
                            _showMsg("Error: $e", isError: true);
                          } finally {
                            setDialogState(() => _isProcessing = false);
                          }
                        }
                      },
                child: const Text("Save Changes"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- ACTION: Delete Subject ---
  void _deleteSubject(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Subject?"),
        content: const Text("This action cannot be undone."),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 2)),
          Expanded(
            child: Column(
              children: [
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
                                  "Subject Pool",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Manage curriculum and electives",
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: _showAddSubjectDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text("Add Subject"),
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
                        const SizedBox(height: 24),
                        Row(
                          children: _departments
                              .map((dept) => _buildFilterTab(dept))
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('courses')
                              .orderBy('createdAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting)
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            var docs = snapshot.data?.docs ?? [];
                            var filteredDocs = docs
                                .where(
                                  (doc) =>
                                      (doc.data() as Map)['department'] ==
                                      _selectedDept,
                                )
                                .toList();
                            if (filteredDocs.isEmpty) return _buildEmptyState();

                            return Wrap(
                              spacing: 20,
                              runSpacing: 20,
                              children: filteredDocs
                                  .map((doc) => _buildSubjectCard(doc))
                                  .toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String title) {
    bool isSelected = _selectedDept == title;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedDept = title),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFE2E8F0),
            ),
          ),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectCard(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return Container(
      width: 250,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['courseCode'] ?? "CODE",
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: Colors.grey,
                ),
                onSelected: (val) {
                  if (val == 'edit') _showEditSubjectDialog(doc);
                  if (val == 'delete') _deleteSubject(doc.id);
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
          const SizedBox(height: 12),
          Text(
            data['courseName'] ?? "Untitled",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.school_outlined, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                "${data['credits'] ?? 0} Credits",
                style: GoogleFonts.inter(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              const CircleAvatar(
                radius: 10,
                backgroundColor: Color(0xFFF1F5F9),
                child: Icon(Icons.person, size: 12, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['instructor'] ?? "TBA",
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
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
          Icon(
            Icons.library_books_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "No subjects found for $_selectedDept",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
