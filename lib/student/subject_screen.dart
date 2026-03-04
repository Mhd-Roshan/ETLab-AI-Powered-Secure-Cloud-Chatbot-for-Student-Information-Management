import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_service.dart';

class SyllabusScreen extends StatefulWidget {
  final String studentRegNo;
  const SyllabusScreen({super.key, required this.studentRegNo});

  @override
  State<SyllabusScreen> createState() => _SyllabusScreenState();
}

class _SyllabusScreenState extends State<SyllabusScreen> {
  final StudentService _studentService = StudentService();
  String selectedScheme = "2020 Scheme";
  String selectedCourse = "MCA";
  int selectedSemester = 1;
  bool _isProfileLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadStudentProfile();
  }

  Future<void> _loadStudentProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentRegNo)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          selectedCourse = data['department'] ?? "MCA";
          selectedSemester =
              int.tryParse(data['semester']?.toString() ?? "1") ?? 1;
          _isProfileLoaded = true;
        });
      } else {
        setState(() => _isProfileLoaded = true);
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
      setState(() => _isProfileLoaded = true);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubjects() async {
    try {
      String schemeKey = selectedScheme.split(' ')[0]; // "2020"
      String docId = "${selectedCourse}_${schemeKey}_S$selectedSemester";

      final doc = await FirebaseFirestore.instance
          .collection('syllabus')
          .doc(docId)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data['subjects'] != null) {
          return List<Map<String, dynamic>>.from(data['subjects']);
        }
      }
      return [];
    } catch (e) {
      debugPrint("Error fetching subjects: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isProfileLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          "SUBJECTS",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            letterSpacing: 1.2,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 18,
            color: Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject List Section
            _buildSubjectsList(),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsList() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _fetchSubjects(),
        _studentService.getDetailedAttendance(widget.studentRegNo),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF001FF4)),
              ),
            ),
          );
        }

        final List<Map<String, dynamic>> subjects =
            List<Map<String, dynamic>>.from(snapshot.data?[0] ?? []);
        final List<Map<String, dynamic>> attendanceStats =
            List<Map<String, dynamic>>.from(snapshot.data?[1] ?? []);

        if (subjects.isEmpty) {
          return Center(
            child: Column(
              children: [
                const SizedBox(height: 60),
                Icon(
                  Icons.auto_stories_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 20),
                Text(
                  "No subjects found in database for S1",
                  style: GoogleFonts.inter(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Enrolled Subjects",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  "${subjects.length} Total",
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final stat = attendanceStats.firstWhere((s) {
                  final String sName = (s['subjectName'] ?? s['subject'] ?? "")
                      .toString()
                      .toUpperCase();
                  final String subjName = (subject['name'] ?? "")
                      .toString()
                      .toUpperCase();
                  return sName != "" && sName == subjName;
                }, orElse: () => {});

                return _buildSubjectCard(subject, stat);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildSubjectCard(
    Map<String, dynamic> subject,
    Map<String, dynamic> stat,
  ) {
    // Coverage data from syllabus
    final int coverage = (subject['subjectCoverage'] as num? ?? 0).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF001FF4).withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.menu_book_rounded,
                color: Color(0xFF001FF4),
                size: 24,
              ),
            ),
          ),

          title: Text(
            subject['name'],
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              height: 1.2,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "${subject['teacherName'] ?? 'Faculty'}",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 20),

                  // Course Outcomes
                  _buildSectionTitle("Learning Objectives"),
                  const SizedBox(height: 10),
                  ...(subject['courseOutcomes'] as List<dynamic>? ?? [])
                      .map(
                        (co) => _buildListItem(
                          co.toString(),
                          Icons.check_circle_rounded,
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 20),

                  // Syllabus (Modules)
                  _buildSectionTitle("Syllabus Modules"),
                  const SizedBox(height: 10),
                  ...(subject['modules'] as List<dynamic>? ?? [])
                      .map(
                        (module) => _buildListItem(
                          module.toString(),
                          Icons.circle_outlined,
                        ),
                      )
                      .toList(),
                  const SizedBox(height: 24),

                  // Subject Coverage Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: coverage / 100,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF001FF4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w800,
        fontSize: 10,
        letterSpacing: 1.2,
        color: Colors.grey.shade500,
      ),
    );
  }

  Widget _buildListItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF001FF4).withOpacity(0.6)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.black87,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
