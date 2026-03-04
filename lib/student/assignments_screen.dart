import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/student_service.dart';
import 'widgets/liquid_glass_button.dart';

class AssignmentsScreen extends StatefulWidget {
  final String? studentId;
  const AssignmentsScreen({super.key, this.studentId});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final StudentService _studentService = StudentService();
  int _selectedFilterIndex = 0; // 0: All, 1: Pending, 2: Submitted

  String? _studentDept;
  String? _studentSem;
  String? _studentName;
  String? _studentEmail;
  String? _studentCollegeCode;
  String? _profileRegNo; // Prefer this over widget.studentId if available
  bool _isLoadingProfile = true;

  String get _effectiveStudentId => (widget.studentId ?? 'unknown').trim();

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  void _loadStudentProfile() {
    if (widget.studentId != null) {
      debugPrint('[Assignments] Loading profile for: ${widget.studentId}');
      _studentService.getStudentProfile(widget.studentId!).listen((doc) async {
        if (doc.exists && mounted) {
          debugPrint('[Assignments] Found in students collection');
          final data = doc.data() as Map<String, dynamic>;
          _applyStudentData(data);
        } else if (mounted) {
          debugPrint(
            '[Assignments] Not in students, trying users collection...',
          );
          // Fallback 1: Check users collection by username/email
          final userDoc = await _studentService.getUserByIdentifier(
            widget.studentId!,
          );
          if (userDoc != null && userDoc.exists && mounted) {
            debugPrint('[Assignments] Found in users by identifier');
            final data = userDoc.data() as Map<String, dynamic>;
            _applyStudentData(data);
          } else if (mounted) {
            debugPrint(
              '[Assignments] Not found by identifier, trying direct doc ID...',
            );
            // Fallback 2: Try users collection by doc ID directly
            try {
              final directDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.studentId!)
                  .get();
              if (directDoc.exists && mounted) {
                debugPrint('[Assignments] Found in users by doc ID');
                final data = directDoc.data() as Map<String, dynamic>;
                _applyStudentData(data);
                return;
              }
            } catch (e) {
              debugPrint('[Assignments] Error fetching by doc ID: $e');
            }

            // Last resort: Set defaults so assignments still load
            debugPrint('[Assignments] No profile found. Using defaults.');
            if (mounted) {
              setState(() {
                _studentDept = 'MCA';
                _studentSem = '1';
                _studentName = widget.studentId;
                _profileRegNo = widget.studentId;
                _isLoadingProfile = false;
              });
            }
          }
        }
      });
    } else {
      setState(() {
        _studentDept = 'MCA';
        _studentSem = '1';
        _profileRegNo = widget.studentId;
        _isLoadingProfile = false;
      });
    }
  }

  void _applyStudentData(Map<String, dynamic> data) {
    setState(() {
      _studentDept = data['department'] ?? 'MCA';
      _studentSem = (data['semester'] ?? '1').toString();
      _studentCollegeCode = data['collegeCode'];
      _studentName =
          "${data['firstName'] ?? data['firstname'] ?? ''} ${data['lastName'] ?? data['lastname'] ?? ''}"
              .trim();
      _studentEmail = data['email'];
      _profileRegNo =
          data['regNo'] ??
          data['studentId'] ??
          data['username'] ??
          widget.studentId;
      _isLoadingProfile = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildSimpleAppBar(),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildAssignmentList()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildSimpleAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: Colors.black,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Assignments",
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            "Semester I",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          _filterChip("All", 0),
          const SizedBox(width: 8),
          _filterChip("Pending", 1),
          const SizedBox(width: 8),
          _filterChip("Submitted", 2),
        ],
      ),
    );
  }

  Widget _filterChip(String label, int index) {
    bool isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Liquid glass: frosted clear background on selection
          gradient: isSelected
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.80),
                    Colors.white.withOpacity(0.40),
                  ],
                )
              : null,
          color: isSelected ? null : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.white.withOpacity(0.8)
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.40),
                    blurRadius: 6,
                    spreadRadius: -2,
                    offset: const Offset(0, -1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.grey.shade800 : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildAssignmentList() {
    if (_isLoadingProfile) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<DocumentSnapshot<Map<String, dynamic>>>>(
      stream: _studentService.getAssignmentsByClass(
        _studentDept!,
        _studentSem!,
        collegeCode: _studentCollegeCode,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          debugPrint(
            "No assignments found for Dept: $_studentDept, Sem: $_studentSem, College: $_studentCollegeCode",
          );
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 60,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 16),
                Text(
                  "No assignments for $_studentDept Sem $_studentSem",
                  style: TextStyle(color: Colors.grey[500], fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  "Check if your profile matches the assignment's target department and semester.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          );
        }

        final items = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final doc = items[index];
            final assignmentData = doc.data() as Map<String, dynamic>;
            final assignmentId = doc.id;

            return StreamBuilder<QuerySnapshot>(
              stream: _studentService.getStudentSubmission(
                _effectiveStudentId,
                assignmentId,
              ),
              builder: (context, subSnapshot) {
                // If the stream is active, check the docs
                bool isSubmitted = false;
                Map<String, dynamic>? submissionData;

                if (subSnapshot.hasData && subSnapshot.data!.docs.isNotEmpty) {
                  isSubmitted = true;
                  submissionData =
                      subSnapshot.data!.docs.first.data()
                          as Map<String, dynamic>;
                }

                // Filter logic
                if (_selectedFilterIndex == 1 && isSubmitted) {
                  return const SizedBox.shrink();
                }
                if (_selectedFilterIndex == 2 && !isSubmitted) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildSimpleAssignmentCard(
                    assignmentId,
                    assignmentData,
                    !isSubmitted,
                    submissionData: submissionData,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Renaming _buildModernAssignmentCard to _buildSimpleAssignmentCard for consistency with call above
  // Note: Previous step I said I'd replace _buildModernAssignmentCard in next step.
  // I will introduce _buildSimpleAssignmentCard here and remove the old one in next step.
  // Actually, I can't call a method I strictly haven't defined yet if I rely on type checking, but Dart is lenient if I define it in same file.
  // Wait, I am removing _buildModernAssignmentCard in this step?
  // The instruction says "Range lines 65 to 602". _buildModernAssignmentCard starts at 603.
  // So I am NOT removing it yet. I should call `_buildModernAssignmentCard` for now, or rename it in next step.
  // I'll call `_buildSimpleAssignmentCard` and define it in the next step.
  // BUT if `_buildModernAssignmentCard` exists and I call `_buildSimpleAssignmentCard`, it will error until I add it.
  // I should call `_buildSimpleAssignmentCard` here and update the method name below in next step.
  // Or I can just continue calling `_buildModernAssignmentCard` here and rename it later. I will call `_buildModernAssignmentCard` here to avoid temporary error if I can't do simultaneous edits.
  // Wait, I can't easily sync "call name" and "def name" across steps without temporary breakage unless I use one consistent name.
  // I'll use `_buildModernAssignmentCard` name for now in the call, and in the next step I'll replace the method body but keep the name to avoid ripple effects, OR I'll rename validly.
  // I'll stick to `_buildModernAssignmentCard` name in the call.

  Widget _buildSimpleAssignmentCard(
    String assignmentId,
    Map<String, dynamic> data,
    bool isPending, {
    Map<String, dynamic>? submissionData,
  }) {
    final DateFormat formatter = DateFormat('dd MMM yy');
    DateTime? safeDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    String dateLabel;
    String dateStr;

    if (isPending) {
      dateLabel = "Due";
      dateStr = safeDate(data['dueDate']) != null
          ? formatter.format(safeDate(data['dueDate'])!)
          : "N/A";
    } else {
      dateLabel = "Submitted";
      dateStr = safeDate(submissionData?['submittedAt']) != null
          ? formatter.format(safeDate(submissionData!['submittedAt'])!)
          : "N/A";
    }

    bool isOverdue =
        isPending &&
        safeDate(data['dueDate']) != null &&
        safeDate(data['dueDate'])!.isBefore(DateTime.now());
    // Use the document ID from Firestore instead of the synthesized one

    return GestureDetector(
      onTap: () {
        if (!isPending) {
          _showFeedbackDialog(data, submissionData);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Type Chip + Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (data['type'] == 1)
                        ? Colors.orange.shade50
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['type'] == 1 ? "OFFLINE" : "ONLINE",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: (data['type'] == 1)
                          ? Colors.orange.shade700
                          : Colors.blue.shade700,
                    ),
                  ),
                ),
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "OVERDUE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                  )
                else if (!isPending)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF51CF66),
                    size: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Subject Title
            Text(
              data['subject'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            // Date Row
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 6),
                Text(
                  "$dateLabel: $dateStr",
                  style: TextStyle(
                    fontSize: 13,
                    color: isOverdue
                        ? Colors.red.shade400
                        : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Staff/Feedback Prompt
            if (!isPending && submissionData?['feedback'] != null) ...[
              const SizedBox(height: 8),
              Text(
                "Tap to view feedback",
                style: TextStyle(
                  fontSize: 12,
                  color: const Color(0xFF001FF4),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            // Upload Button for Pending
            if (isPending) ...[
              const SizedBox(height: 16),
              if (data['type'] == 1)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: Colors.orange.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Physical submission required. You can also upload a digital copy here.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              LiquidGlassButton(
                isFullWidth: true,
                onPressed: () => _handleUpload(
                  context,
                  assignmentId,
                  data['subject'],
                  data['staffId'],
                ),
                icon: const Icon(Icons.upload_file_outlined, size: 18),
                label: Text(
                  data['type'] == 1
                      ? "Upload Digital Copy"
                      : "Upload Submission",
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleUpload(
    BuildContext context,
    String assignmentId,
    String subject,
    String? staffId,
  ) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
      );

      if (result != null) {
        if (!context.mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    "Uploading to Cloudinary...",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        );

        if (!context.mounted) return;
        final platformFile = result.files.single;
        final String fileName =
            "${DateTime.now().millisecondsSinceEpoch}_${platformFile.name}";
        String downloadUrl = '';

        try {
          if (kIsWeb) {
            if (platformFile.bytes != null) {
              downloadUrl = await _studentService.uploadBytes(
                platformFile.bytes!,
                fileName,
              );
            }
          } else {
            if (platformFile.path != null) {
              downloadUrl = await _studentService.uploadFile(
                platformFile.path!,
                fileName,
              );
            } else if (platformFile.bytes != null) {
              downloadUrl = await _studentService.uploadBytes(
                platformFile.bytes!,
                fileName,
              );
            }
          }
        } catch (e) {
          debugPrint("Upload process failed: $e");
          if (context.mounted) Navigator.pop(context);
          throw Exception("Cloudinary Upload Error");
        }

        if (downloadUrl.isEmpty) {
          if (context.mounted) Navigator.pop(context);
          throw Exception("Could not generate Cloudinary URL");
        }

        await _studentService.submitAssignment({
          'assignmentId': assignmentId,
          'staffId': staffId,
          'studentId': _effectiveStudentId,
          'email': _studentEmail ?? _effectiveStudentId,
          'studentName': _studentName ?? 'Student',
          'semester': _studentSem ?? '1',
          'regNo': _profileRegNo ?? widget.studentId,
          'subject': subject,
          'fileName': platformFile.name,
          'fileUrl': downloadUrl,
          'status': 'submitted',
        });

        if (!context.mounted) return;
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text("$subject uploaded to Cloudinary!")),
              ],
            ),
            backgroundColor: const Color(0xFF51CF66),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Upload failed. Please try again."),
          backgroundColor: const Color(0xFFFF6B6B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showFeedbackDialog(
    Map<String, dynamic> assignment,
    Map<String, dynamic>? submission,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Feedback",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF667EEA),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        assignment['staffName'] ?? "Staff",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Staff",
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50], // Very light grey background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Review:",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      submission?['feedback'] ??
                          "Your submission is under review.",
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (submission?['grade'] != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text(
                      "Grade: ",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF51CF66).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF51CF66)),
                      ),
                      child: Text(
                        submission!['grade'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF51CF66),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

