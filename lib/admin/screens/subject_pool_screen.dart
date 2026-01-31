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
  // Changed default from 'All' to 'MCA'
  String _selectedDept = 'MCA';

  // Removed 'All' from the list
  final List<String> _departments = ['MCA', 'MBA', 'CSE', 'ECE', 'ME', 'CE'];

  // --- DIALOG: Add Subject ---
  void _showAddSubjectDialog() {
    final _formKey = GlobalKey<FormState>();
    String code = '';
    String name = '';
    String credits = '3';
    String dept = _selectedDept; // Default to currently selected tab
    String instructor = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Subject"),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Course Code",
                          hintText: "e.g. CS301",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                        onSaved: (v) => code = v!,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        decoration: const InputDecoration(
                          labelText: "Credits",
                          hintText: "e.g. 4",
                          border: OutlineInputBorder(),
                        ),
                        initialValue: "3",
                        onSaved: (v) => credits = v!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Subject Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  onSaved: (v) => name = v!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: dept,
                  decoration: const InputDecoration(
                    labelText: "Department",
                    border: OutlineInputBorder(),
                  ),
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => dept = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Instructor (Optional)",
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => instructor = v ?? "TBA",
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(code)
                    .set({
                      'courseCode': code,
                      'courseName': name,
                      'credits': int.tryParse(credits) ?? 3,
                      'department': dept,
                      'instructor': instructor.isEmpty ? "TBA" : instructor,
                      'totalStudents': 0,
                    });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Add Course"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG: Edit Subject ---
  void _showEditSubjectDialog(DocumentSnapshot doc) {
    final _formKey = GlobalKey<FormState>();
    var data = doc.data() as Map<String, dynamic>;

    String code = data['courseCode'] ?? '';
    String name = data['courseName'] ?? '';
    String credits = (data['credits'] ?? 3).toString();
    String dept = data['department'] ?? _selectedDept;
    String instructor = data['instructor'] ?? '';

    // If department from data isn't in our list (e.g. legacy data), fallback to first or selected
    if (!_departments.contains(dept)) {
      dept = _departments.contains(_selectedDept)
          ? _selectedDept
          : _departments.first;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Subject"),
        content: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        // Enabled false because typically ID/Code shouldn't change or it messes up references
                        // If you want to allow changing code, you'd need to handle deleting old doc and creating new one
                        enabled: false,
                        initialValue: code,
                        decoration: const InputDecoration(
                          labelText: "Course Code",
                          hintText: "e.g. CS301",
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                        onSaved: (v) => code = v!,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: credits,
                        decoration: const InputDecoration(
                          labelText: "Credits",
                          hintText: "e.g. 4",
                          border: OutlineInputBorder(),
                        ),
                        onSaved: (v) => credits = v!,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(
                    labelText: "Subject Name",
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v!.isEmpty ? "Required" : null,
                  onSaved: (v) => name = v!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: dept,
                  decoration: const InputDecoration(
                    labelText: "Department",
                    border: OutlineInputBorder(),
                  ),
                  items: _departments
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => dept = v!,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: instructor,
                  decoration: const InputDecoration(
                    labelText: "Instructor (Optional)",
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => instructor = v ?? "TBA",
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
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                await FirebaseFirestore.instance
                    .collection('courses')
                    .doc(doc.id) // Update existing doc
                    .update({
                      // 'courseCode': code, // Don't update code if it's the doc ID/key
                      'courseName': name,
                      'credits': int.tryParse(credits) ?? 3,
                      'department': dept,
                      'instructor': instructor.isEmpty ? "TBA" : instructor,
                    });
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text("Save Changes"),
          ),
        ],
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AdminHeader(),
                        const SizedBox(height: 32),

                        // Title Row
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
                                backgroundColor: Colors.blueAccent,
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

                        // Department Tabs
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _departments
                                .map((dept) => _buildFilterTab(dept))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Courses Grid
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('courses')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            var docs = snapshot.data?.docs ?? [];
                            // Exact match filtering
                            var filteredDocs = docs.where((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              return (data['department'] ?? '') ==
                                  _selectedDept;
                            }).toList();

                            if (filteredDocs.isEmpty) {
                              return _buildEmptyState();
                            }

                            return Wrap(
                              spacing: 20, // Reduced spacing
                              runSpacing: 20,
                              children: filteredDocs.map((doc) {
                                return _buildSubjectCard(doc);
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
    Color accentColor = _getDeptColor(data['department']);

    return Container(
      width: 250, // Reduced from 280 for more compact fit
      padding: const EdgeInsets.all(20), // Reduced padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Slightly rounder
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  data['courseCode'] ?? "CODE",
                  style: TextStyle(
                    color: accentColor,
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
            data['courseName'] ?? "Untitled Course",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.bold,
              fontSize: 15, // Slightly smaller font
              color: const Color(0xFF0F172A),
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              Icon(
                Icons.school_outlined,
                size: 14,
                color: Colors.grey.shade500,
              ),
              const SizedBox(width: 4),
              Text(
                "${data['credits'] ?? 0} Credits",
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 12,
                ),
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
          const SizedBox(height: 8),
          Text(
            "Add a new subject to get started.",
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Color _getDeptColor(String? dept) {
    switch (dept) {
      case 'CSE':
        return Colors.blue;
      case 'MCA':
        return Colors.indigo;
      case 'MBA':
        return Colors.purple;
      case 'ECE':
        return Colors.orange;
      case 'ME':
        return Colors.red;
      default:
        return Colors.green;
    }
  }
}
