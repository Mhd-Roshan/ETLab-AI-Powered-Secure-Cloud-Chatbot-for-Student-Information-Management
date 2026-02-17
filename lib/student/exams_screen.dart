import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../services/student_service.dart';

class ExamsScreen extends StatefulWidget {
  final String? studentId;
  const ExamsScreen({super.key, this.studentId});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  final StudentService _studentService = StudentService();
  late TabController _tabController;

  List<Map<String, dynamic>> _dummySeries = [];
  List<Map<String, dynamic>> _dummyUniversity = [];

  // Assuming we get the student's department and semester from their profile
  // or passed in. For now, we'll fetch profile or use defaults.
  String _department = 'MCA'; // Default
  String _semester = 'Semester 1'; // Default
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeDummyData();
    _fetchStudentProfile();
  }

  Future<void> _fetchStudentProfile() async {
    if (widget.studentId == null) {
      setState(() => _isLoadingProfile = false);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _department = doc['department'] ?? 'MCA';
          _semester = doc['semester'] ?? 'Semester 1';
          _isLoadingProfile = false;
        });
      } else {
        setState(() => _isLoadingProfile = false);
      }
    } catch (e) {
      debugPrint("Error fetching profile for exams: $e");
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _initializeDummyData() {
    _dummySeries = [
      {
        'title': 'First Series Exam',
        'subject': 'ADVANCED DATA STRUCTURES',
        'date': DateTime.now().add(const Duration(days: 5)),
        'time': '10:00 AM - 12:00 PM',
        'venue': 'Exam Hall A',
        'status': 'Scheduled',
        'type': 'Series',
      },
      {
        'title': 'First Series Exam',
        'subject': 'ADVANCED SOFTWARE ENGINEERING',
        'date': DateTime.now().add(const Duration(days: 7)),
        'time': '10:00 AM - 12:00 PM',
        'venue': 'Exam Hall B',
        'status': 'Scheduled',
        'type': 'Series',
      },
      {
        'title': 'First Series Exam',
        'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
        'date': DateTime.now().subtract(const Duration(days: 2)),
        'time': '10:00 AM - 12:00 PM',
        'venue': 'Exam Hall A',
        'status': 'Completed',
        'type': 'Series',
      },
    ];

    _dummyUniversity = [
      {
        'title': 'University Semester Exam',
        'subject': 'MATHEMATICAL FOUNDATIONS FOR COMPUTING',
        'date': DateTime.now().add(const Duration(days: 45)),
        'time': '9:30 AM - 12:30 PM',
        'venue': 'Main Block, 301',
        'status': 'Scheduled',
        'type': 'University',
      },
      {
        'title': 'University Semester Exam',
        'subject': 'ADVANCED DATA STRUCTURES',
        'date': DateTime.now().add(const Duration(days: 48)),
        'time': '9:30 AM - 12:30 PM',
        'venue': 'Main Block, 302',
        'status': 'Scheduled',
        'type': 'University',
      },
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          "Exams",
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF001FF4),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF001FF4),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          tabs: const [
            Tab(text: "Series Exams"),
            Tab(text: "University Exams"),
          ],
        ),
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<QuerySnapshot>(
              stream: _studentService.getExams(_department, _semester),
              builder: (context, snapshot) {
                // If error or no data, default to dummy views
                // We also check if connection state is active, but if we have no data, fallback
                if (snapshot.hasError) {
                  debugPrint("Firestore error: ${snapshot.error}");
                  return _buildDummyDataView();
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildDummyDataView();
                }

                final docs = snapshot.data!.docs;

                final seriesExams = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>?;
                  return data != null && data['type'] == 'Series';
                }).toList();

                final universityExams = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>?;
                  return data != null && data['type'] == 'University';
                }).toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildExamList(
                      seriesExams,
                      isRealData: true,
                      type: 'Series',
                    ),
                    _buildExamList(
                      universityExams,
                      isRealData: true,
                      type: 'University',
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildDummyDataView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildExamList(_dummySeries, isRealData: false, type: 'Series'),
        _buildExamList(_dummyUniversity, isRealData: false, type: 'University'),
      ],
    );
  }

  Widget _buildExamList(
    List<dynamic>? exams, {
    required bool isRealData,
    required String type,
  }) {
    if (exams == null || exams.isEmpty) {
      return _buildEmptyState("No $type exams scheduled!", Icons.event_busy);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: exams.length,
      separatorBuilder: (ctx, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final rawExam = exams[index];
        if (rawExam == null) return const SizedBox.shrink();

        final Map<String, dynamic> exam;
        if (isRealData) {
          final data = rawExam.data() as Map<String, dynamic>?;
          if (data == null) return const SizedBox.shrink();
          exam = data;
        } else {
          exam = rawExam as Map<String, dynamic>;
        }

        final title = exam['title'] ?? 'Exam';
        final subject = exam['subject'] ?? 'Unknown Subject';
        final date = isRealData
            ? (exam['date'] as Timestamp).toDate()
            : (exam['date'] as DateTime);
        final time = exam['time'] ?? 'TBD';
        final venue = exam['venue'] ?? 'TBD';
        final status =
            exam['status'] ?? 'Scheduled'; // Scheduled, Completed, Cancelled

        final isCompleted =
            status == 'Completed' ||
            date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

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
            border: Border(
              left: BorderSide(
                color: isCompleted ? Colors.grey : const Color(0xFF001FF4),
                width: 5,
              ),
            ),
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
                        subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isCompleted ? "Completed" : status,
                        style: TextStyle(
                          color: isCompleted ? Colors.grey : Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('EEEE, MMM d, yyyy').format(date),
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      time,
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      venue,
                      style: TextStyle(color: Colors.grey[800], fontSize: 13),
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
}
