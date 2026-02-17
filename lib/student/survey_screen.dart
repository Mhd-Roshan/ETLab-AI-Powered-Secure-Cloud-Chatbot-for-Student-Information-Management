import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SurveyScreen extends StatefulWidget {
  final String studentId;
  const SurveyScreen({super.key, required this.studentId});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _subjects = [
    "All",
    "General",
    "ADVANCED DATA STRUCTURES",
    "ADVANCED SOFTWARE ENGINEERING",
    "DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE",
    "MATHEMATICAL FOUNDATIONS FOR COMPUTING",
    "DATA STRUCTURES LAB",
    "PROGRAMMING LAB",
    "WEB PROGRAMMING LAB",
  ];

  // Track submitted surveys
  final Set<String> _submittedSurveyIds = {};
  bool _isLoading = true;

  // Mock Data for Surveys - Updated to match correct MCA subjects
  final List<Map<String, dynamic>> _surveys = [
    {
      'id': 's1',
      'title': 'Course Feedback - Semester 1',
      'description':
          'Please provide your honest feedback on the courses taught in Semester 1.',
      'deadline': 'Feb 20, 2026',
      'isActive': true,
      'readTime': '5 min',
      'subject': 'General',
    },
    {
      'id': 's2',
      'title': 'Advanced Data Structures Review',
      'description':
          'Feedback on Algorithm complexity and tree implementations.',
      'deadline': 'Feb 28, 2026',
      'isActive': true,
      'readTime': '4 min',
      'subject': 'ADVANCED DATA STRUCTURES',
    },
    {
      'id': 's3',
      'title': 'Software Engineering Project Management',
      'description': 'Assessment of Agile methodology knowledge gained.',
      'deadline': 'Mar 5, 2026',
      'isActive': true,
      'readTime': '3 min',
      'subject': 'ADVANCED SOFTWARE ENGINEERING',
    },
    {
      'id': 's4',
      'title': 'Architecture Lab Experience',
      'description': 'How was the session on instruction sets and logic gates?',
      'deadline': 'Feb 15, 2026',
      'isActive': false, // Expired
      'readTime': '2 min',
      'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
    },
    {
      'id': 's5',
      'title': 'Campus Facilities Survey',
      'description':
          'Help us improve the campus facilities by rating your experience.',
      'deadline': 'Feb 25, 2026',
      'isActive': true,
      'readTime': '3 min',
      'subject': 'General',
    },
    {
      'id': 's6',
      'title': 'Web Lab Project Status',
      'description': 'Assessment of HTML/CSS/JS final project progress.',
      'deadline': 'Feb 22, 2026',
      'isActive': true,
      'readTime': '2 min',
      'subject': 'WEB PROGRAMMING LAB',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _subjects.length, vsync: this);
    _fetchSubmissions();
  }

  Future<void> _fetchSubmissions() async {
    if (widget.studentId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .collection('survey_submissions')
          .get();

      if (mounted) {
        setState(() {
          _submittedSurveyIds.clear();
          for (var doc in snapshot.docs) {
            _submittedSurveyIds.add(doc.id);
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching survey submissions: $e");
      if (mounted) setState(() => _isLoading = false);
    }
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
          "Surveys",
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
          isScrollable: true,
          labelColor: const Color(0xFF001FF4),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF001FF4),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: _subjects.map((subject) => Tab(text: subject)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _subjects.map((subject) {
                return _buildSurveyList(subject);
              }).toList(),
            ),
    );
  }

  Widget _buildSurveyList(String subject) {
    // Filter surveys based on subject
    final filteredSurveys = subject == "All"
        ? _surveys
        : _surveys.where((s) => s['subject'] == subject).toList();

    if (filteredSurveys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_turned_in_outlined,
              size: 60,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "No surveys available for $subject",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: filteredSurveys.length,
      itemBuilder: (context, index) {
        final survey = filteredSurveys[index];
        final bool isActive = survey['isActive'];
        final bool isSubmitted = _submittedSurveyIds.contains(survey['id']);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Subject Tag and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        survey['subject'].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: isSubmitted
                          ? Colors.blue.withOpacity(0.1) // Submitted
                          : isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      isSubmitted
                          ? "SUBMITTED"
                          : isActive
                          ? "ACTIVE"
                          : "EXPIRED",
                      style: TextStyle(
                        color: isSubmitted
                            ? Colors.blue
                            : isActive
                            ? Colors.green
                            : Colors.grey,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title & Description
              Text(
                survey['title'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                survey['description'],
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Footer (Deadline & Button)
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "DEADLINE",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        survey['deadline'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  if (isSubmitted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.check_circle,
                            size: 16,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 6),
                          Text(
                            "Done",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isActive)
                    ElevatedButton(
                      onPressed: () {
                        _showSurveyDialog(survey);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF001FF4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Start",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        "Closed",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSurveyDialog(Map<String, dynamic> survey) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(survey['title'] ?? 'Survey'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "How would you rate your experience?",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 15),
            _buildRatingOption(
              survey,
              "Excellent",
              Colors.green,
              Icons.sentiment_very_satisfied,
            ),
            _buildRatingOption(
              survey,
              "Good",
              Colors.lightGreen,
              Icons.sentiment_satisfied,
            ),
            _buildRatingOption(
              survey,
              "Average",
              Colors.amber,
              Icons.sentiment_neutral,
            ),
            _buildRatingOption(
              survey,
              "Poor",
              Colors.red,
              Icons.sentiment_dissatisfied,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingOption(
    Map<String, dynamic> survey,
    String label,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _submitSurvey(survey, label, color),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitSurvey(
    Map<String, dynamic> survey,
    String rating,
    Color color,
  ) async {
    final surveyId = survey['id'];
    if (widget.studentId.isEmpty || surveyId == null) return;

    // Close Dialog
    Navigator.pop(context);

    // Show submitting indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Submitting feedback..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .collection('survey_submissions')
          .doc(surveyId)
          .set({
            'surveyTitle': survey['title'],
            'subject': survey['subject'],
            'rating': rating,
            'submittedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() {
          _submittedSurveyIds.add(surveyId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 10),
                Text("Submitted: $rating"),
              ],
            ),
            backgroundColor: color,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
