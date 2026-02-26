import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/staff_service.dart';

class StaffAssignmentsScreen extends StatefulWidget {
  final String staffId; // This is the username/id passed from login

  const StaffAssignmentsScreen({super.key, required this.staffId});

  @override
  State<StaffAssignmentsScreen> createState() => _StaffAssignmentsScreenState();
}

class _StaffAssignmentsScreenState extends State<StaffAssignmentsScreen> {
  final StaffService _service = StaffService();
  String _staffName = "Staff Member";
  String _staffDept = "MCA";
  String _collegeCode = "";
  Stream<List<DocumentSnapshot<Map<String, dynamic>>>>? _assignmentsStream;
  StreamSubscription? _profileSub;

  @override
  void initState() {
    super.initState();
    _assignmentsStream = _service.getStaffAssignments(widget.staffId);
    _loadProfile();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    super.dispose();
  }

  void _loadProfile() {
    _profileSub = _service.getProfile(widget.staffId).listen((doc) {
      if (doc.exists && mounted) {
        setState(() {
          final data = doc.data() as Map<String, dynamic>;

          // Robust name resolution for matching with 'instructor' field in courses
          _staffName =
              data['fullName'] ??
              data['name'] ??
              ((data['firstName'] != null)
                  ? "${data['firstName']} ${data['lastName'] ?? ''}".trim()
                  : null) ??
              data['username'] ??
              widget.staffId;

          _staffDept = data['department'] ?? 'MCA';
          _collegeCode = data['collegeCode'] ?? '';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Manage Assignments",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
        stream: _assignmentsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.redAccent,
                  ),
                  const SizedBox(height: 16),
                  Text("Error loading assignments: ${snapshot.error}"),
                  const SizedBox(height: 8),
                  const Text(
                    "If this is a new filter, a Firestore index may be required.",
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final assignments = snapshot.data!;

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: assignments.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final doc = assignments[index];
              final data = doc
                  .data()!; // Use non-nullable data as doc.exists is checked
              return _buildAssignmentCard(doc.id, data);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateAssignmentDialog(),
        backgroundColor: const Color(0xFF001FF4),
        icon: const Icon(Icons.add_task_rounded, color: Colors.white),
        label: Text(
          "Create Assignment",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF64748B).withValues(alpha: 0.05),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Icon(
              Icons.assignment_add,
              size: 64,
              color: const Color(0xFF001FF4).withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No Assignments Yet",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Create your first assignment to share with students",
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(String id, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled';
    final subject = data['subject'] ?? 'No Subject';
    final dueDate = (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final dept = data['department'] ?? 'General';
    final sem = data['semester'] ?? '1';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SubmissionsListScreen(
            assignmentId: id,
            assignmentTitle: title,
            dept: dept,
            sem: sem.toString(),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (data['type'] == 2)
                        ? Colors.blue[50]
                        : Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (data['type'] == 2) ? "ONLINE" : "OFFLINE",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: (data['type'] == 2)
                          ? Colors.blue[700]
                          : Colors.orange[700],
                    ),
                  ),
                ),
                Text(
                  "Due: ${DateFormat('dd MMM').format(dueDate)}",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: Color(0xFF64748B),
                    size: 20,
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditAssignmentDialog(id, data);
                    } else if (value == 'delete') {
                      _deleteAssignment(id);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(
                            Icons.edit_outlined,
                            size: 18,
                            color: Color(0xFF475569),
                          ),
                          SizedBox(width: 12),
                          Text("Edit"),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Delete",
                            style: TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "$subject | $dept Sem $sem",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildAssignmentStat(
                    Icons.people_outline,
                    "Submissions",
                    "Manage",
                    const Color(0xFF001FF4),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Color(0xFFCBD5E1),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentStat(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            color: const Color(0xFF64748B),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(width: 12),
      ],
    );
  }

  void _showCreateAssignmentDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedSem = "1";
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    const String forcedSubject =
        "DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE";
    int selectedType = 2; // Fixed to Online

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "New Assignment",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Target: $_staffDept Department",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: const Color(0xFF001FF4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. SEMESTER (Fixed to 1)
                _buildFieldLabel("Semester"),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    "Semester 1 (Current)",
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. SUBJECT (Fixed)
                _buildFieldLabel("Subject"),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    forcedSubject,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                _buildFieldLabel("Assignment Title"),
                _buildTextField(titleController, "e.g. Unit 1 Quiz"),
                const SizedBox(height: 16),
                _buildFieldLabel("Due Date"),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 12),
                        Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel("Description (Optional)"),
                _buildTextField(
                  descController,
                  "Enter assignment details...",
                  maxLines: 3,
                ),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please fill title"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }

                        await _service.createAssignment({
                          'title': titleController.text,
                          'subject': forcedSubject,
                          'description': descController.text,
                          'type': selectedType,
                          'department': _staffDept,
                          'semester': selectedSem,
                          'dueDate': Timestamp.fromDate(selectedDate),
                          'staffName': _staffName,
                          'staffId': widget.staffId,
                          'collegeCode': _collegeCode,
                        });

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Assignment created successfully!"),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: ${e.toString()}"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001FF4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Create Assignment",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _deleteAssignment(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "Delete Assignment",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "Are you sure you want to delete this assignment? This action cannot be undone.",
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await _service.deleteAssignment(id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Assignment deleted successfully"),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
            ),
            child: Text(
              "Delete",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditAssignmentDialog(String id, Map<String, dynamic> data) {
    final titleController = TextEditingController(
      text: data['title']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: data['description']?.toString() ?? '',
    );
    const String forcedSubject =
        "DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE";

    DateTime selectedDate;
    final dynamic dueDateData = data['dueDate'];
    if (dueDateData is Timestamp) {
      selectedDate = dueDateData.toDate();
    } else {
      selectedDate = DateTime.now();
    }

    int selectedType = 2; // Fixed to online

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Assignment",
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildFieldLabel("Subject"),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    forcedSubject,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel("Assignment Title"),
                _buildTextField(titleController, "Title"),
                const SizedBox(height: 16),
                _buildFieldLabel("Due Date"),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 30),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setDialogState(() => selectedDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 12),
                        Text(DateFormat('dd MMMM yyyy').format(selectedDate)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFieldLabel("Description (Optional)"),
                _buildTextField(descController, "Description", maxLines: 3),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      try {
                        if (titleController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Title cannot be empty"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                          return;
                        }
                        await _service.updateAssignment(id, {
                          'title': titleController.text,
                          'subject': forcedSubject,
                          'description': descController.text,
                          'type': selectedType,
                          'dueDate': Timestamp.fromDate(selectedDate),
                        });
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Assignment updated successfully"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001FF4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Save Changes",
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// ✅ Submissions List Screen
// ------------------------------------------------------------------
class SubmissionsListScreen extends StatelessWidget {
  final String assignmentId;
  final String assignmentTitle;
  final String dept;
  final String sem;

  const SubmissionsListScreen({
    super.key,
    required this.assignmentId,
    this.assignmentTitle = "Assignment",
    this.dept = "MCA",
    this.sem = "1",
  });

  @override
  Widget build(BuildContext context) {
    final service = StaffService();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Submissions",
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              assignmentTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_forever_rounded,
              color: Colors.redAccent,
            ),
            tooltip: "Delete Assignment & All Submissions",
            onPressed: () => _showDeleteConfirmation(context, service),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<DocumentSnapshot>>(
        future: service.getStudentsForAssignment(dept, sem),
        builder: (context, studentSnapshot) {
          if (studentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allStudents = studentSnapshot.data ?? [];

          return StreamBuilder<QuerySnapshot>(
            stream: service.getSubmissions(assignmentId),
            builder: (context, submissionSnapshot) {
              if (submissionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final onlineSubmissions = <String, Map<String, dynamic>>{};
              for (var doc in (submissionSnapshot.data?.docs ?? [])) {
                final data = doc.data() as Map<String, dynamic>;
                final entry = {'id': doc.id, 'data': data};
                // Index by all possible identifiers (case-insensitive)
                void addKey(String? key) {
                  if (key != null && key.isNotEmpty) {
                    onlineSubmissions[key] = entry;
                    onlineSubmissions[key.toLowerCase()] = entry;
                    onlineSubmissions[key.toUpperCase()] =
                        entry; // Just in case
                  }
                }

                addKey(data['regNo']?.toString());
                addKey(data['studentId']?.toString());
                addKey(data['username']?.toString());
                addKey(data['email']?.toString());
                addKey(data['uid']?.toString());
              }

              final matchedSubDocIds = <String>{};

              return SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- TABLE HEADER ---
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            _tableHeader("STUDENT INFO", flex: 3),
                            _tableHeader("REG NO", flex: 2),
                            _tableHeader("FILE NAME", flex: 2),
                            _tableHeader("SUBMITTED AT", flex: 2),
                            _tableHeader("STATUS", flex: 2),
                            _tableHeader(
                              "MARKS",
                              flex: 1,
                              align: TextAlign.center,
                            ),
                            _tableHeader(
                              "ACTIONS",
                              flex: 2,
                              align: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      // --- SECTION HEADER: CLASS LIST ---
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        color: const Color(0xFFF8FAFC),
                        child: Text(
                          "CLASS ENROLLMENT",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      // --- TABLE ROWS ---
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: allStudents.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final studentDoc = allStudents[index];
                          final studentData =
                              studentDoc.data() as Map<String, dynamic>;

                          // Robust ID Check
                          final regNo =
                              studentData['regNo'] ??
                              studentData['studentId'] ??
                              studentData['username'] ??
                              studentData['id'] ??
                              studentDoc.id;

                          // Robust Name Check
                          final studentName =
                              studentData['name'] ??
                              studentData['fullName'] ??
                              "${studentData['firstName'] ?? ''} ${studentData['lastName'] ?? ''}"
                                  .trim();

                          // Try to find submission by checking all possible IDs
                          // Helper to check multiple forms of an ID
                          Map<String, dynamic>? checkId(String? id) {
                            if (id == null) return null;
                            return onlineSubmissions[id] ??
                                onlineSubmissions[id.toLowerCase()] ??
                                onlineSubmissions[id.toUpperCase()];
                          }

                          // Try to find submission by checking all possible IDs
                          final subInfo =
                              checkId(regNo?.toString()) ??
                              checkId(studentData['studentId']?.toString()) ??
                              checkId(studentData['username']?.toString()) ??
                              checkId(studentData['email']?.toString()) ??
                              onlineSubmissions[studentDoc.id];
                          final bool isOnline = subInfo != null;

                          final Map<String, dynamic> displayData = isOnline
                              ? {
                                  ...(subInfo['data'] as Map<String, dynamic>),
                                  // Force use of current profile data for display
                                  'studentName': studentName.isEmpty
                                      ? 'Unknown Student'
                                      : studentName,
                                  'regNo': regNo,
                                  'semester':
                                      studentData['semester']?.toString() ??
                                      '1',
                                }
                              : {
                                  'studentName': studentName.isEmpty
                                      ? 'Unknown Student'
                                      : studentName,
                                  'regNo': regNo,
                                  'semester':
                                      studentData['semester']?.toString() ??
                                      '1',
                                  'status': 'offline',
                                  'grade': 'Not Marked',
                                  'assignmentId': assignmentId,
                                };

                          final String submissionId = isOnline
                              ? (subInfo['id'] as String)
                              : "offline_$regNo";

                          if (isOnline) {
                            matchedSubDocIds.add(subInfo['id'] as String);
                          }

                          return _buildSubmissionRow(
                            context,
                            submissionId,
                            displayData,
                            isOnline,
                          );
                        },
                      ),
                      // --- SECTION HEADER: OTHER SUBMISSIONS ---
                      Builder(
                        builder: (context) {
                          final otherSubmissions =
                              (submissionSnapshot.data?.docs ?? [])
                                  .where(
                                    (doc) => !matchedSubDocIds.contains(doc.id),
                                  )
                                  .toList();

                          if (otherSubmissions.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(height: 1),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                color: const Color(0xFFF1F5F9),
                                child: Text(
                                  "ONLINE SUBMISSIONS (ABSENT STUDENTS)",
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: otherSubmissions.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final doc = otherSubmissions[index];
                                  final data =
                                      doc.data() as Map<String, dynamic>;

                                  return _buildSubmissionRow(
                                    context,
                                    doc.id,
                                    data,
                                    true,
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, StaffService service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          "Delete Assignment?",
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          "This will permanently delete this assignment AND all student submissions. This action cannot be undone.",
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "Cancel",
              style: GoogleFonts.plusJakartaSans(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () async {
              await service.deleteAssignment(assignmentId);
              if (context.mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back to assignments list
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Assignment and all submissions deleted"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: Text(
              "Delete Everything",
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader(
    String title, {
    int flex = 1,
    TextAlign align = TextAlign.left,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        title,
        textAlign: align,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF64748B),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildSubmissionRow(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
    bool isOnline,
  ) {
    final studentName = data['studentName'] ?? 'Unknown Student';
    final regNo = data['regNo'] ?? 'N/A';
    final status = data['status'] ?? 'pending';
    final grade = data['grade'] ?? 'Not Marked';
    final fileUrl = data['fileUrl'] as String?;
    final fileName = data['fileName'] ?? 'No file';

    String submittedAt = "N/A";
    if (data['submittedAt'] is Timestamp) {
      submittedAt = DateFormat(
        'dd MMM, hh:mm a',
      ).format((data['submittedAt'] as Timestamp).toDate());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        children: [
          // Student Info
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: Text(
                    studentName.isNotEmpty ? studentName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Color(0xFF001FF4),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    studentName,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Reg No
          Expanded(
            flex: 2,
            child: Text(
              regNo,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 13,
              ),
            ),
          ),
          // File Name
          Expanded(
            flex: 2,
            child: Text(
              fileName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
          // Submitted At
          Expanded(
            flex: 2,
            child: Text(
              submittedAt,
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontSize: 12,
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: status == 'marked'
                    ? const Color(0xFFDCFCE7)
                    : (isOnline
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: status == 'marked'
                          ? const Color(0xFF16A34A)
                          : (isOnline
                                ? const Color(0xFF2563EB)
                                : const Color(0xFF64748B)),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    status.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: status == 'marked'
                          ? const Color(0xFF166534)
                          : (isOnline
                                ? const Color(0xFF1E40AF)
                                : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Marks
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                grade,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: grade == 'Not Marked'
                      ? const Color(0xFFCBD5E1)
                      : const Color(0xFF4F46E5),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          // Actions
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (fileUrl != null && fileUrl.isNotEmpty) ...[
                  IconButton(
                    onPressed: () async {
                      final uri = Uri.parse(fileUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    tooltip: "View File",
                  ),
                  const SizedBox(width: 8),
                ],
                IconButton(
                  onPressed: () => _showMarkingSheet(
                    context,
                    id,
                    studentName,
                    data,
                    isOnline,
                  ),
                  tooltip: status == 'marked' ? "Edit Marks" : "Mark",
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: status == 'marked'
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      status == 'marked'
                          ? Icons.edit
                          : Icons.check_circle_outline,
                      size: 16,
                      color: status == 'marked'
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF64748B),
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

  void _showMarkingSheet(
    BuildContext context,
    String id,
    String name,
    Map<String, dynamic> data,
    bool isOnline,
  ) {
    final gradeController = TextEditingController(
      text: data['grade'] == 'Not Marked' ? '' : data['grade'],
    );
    final feedbackController = TextEditingController(
      text: data['feedback'] ?? '',
    );
    final service = StaffService();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.fromLTRB(
          32,
          20,
          32,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Mark Submission",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Student: $name (${isOnline ? 'Online' : 'Offline'})",
              style: GoogleFonts.plusJakartaSans(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Text(
              "GRADE / MARKS",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: gradeController,
              decoration: InputDecoration(
                hintText: "e.g. 8/10, 10/10",
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "FEEDBACK / REPLY",
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: feedbackController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: "Write feedback for the student...",
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () async {
                  if (isOnline) {
                    await service.markSubmission(
                      id,
                      gradeController.text,
                      feedbackController.text,
                    );
                  } else {
                    // For offline, we need to CREATE a submission record with status 'marked'
                    await FirebaseFirestore.instance
                        .collection('submissions')
                        .add({
                          'assignmentId': assignmentId,
                          'studentName': name,
                          'regNo': data['regNo'],
                          'status': 'marked',
                          'grade': gradeController.text,
                          'feedback': feedbackController.text,
                          'type': 'offline', // Distinguish it
                          'timestamp': FieldValue.serverTimestamp(),
                          'markedDate': FieldValue.serverTimestamp(),
                        });
                  }
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Save Marks & Feedback",
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
