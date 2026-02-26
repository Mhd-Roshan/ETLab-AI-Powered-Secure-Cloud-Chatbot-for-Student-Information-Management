import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'timetable_screen.dart';
import '../services/student_service.dart';

class AttendanceScreen extends StatefulWidget {
  final String? studentRegNo;
  final String? overallAttendance;

  const AttendanceScreen({
    super.key,
    this.studentRegNo,
    this.overallAttendance,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final StudentService _studentService = StudentService();
  String selectedSemester = "Semester 1 (Current)";
  final List<String> semesters = ["Semester 1 (Current)"];
  String searchQuery = "";

  // Helper to assign consistent colors to subjects based on name
  Color _getColorForSubject(String subject) {
    if (subject.isEmpty) return Colors.grey;
    final int hash = subject.codeUnits.fold(0, (a, b) => a + b);
    final List<Color> colors = [
      const Color(0xFF001FF4),
      Colors.orange,
      Colors.green,
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.blue,
      Colors.indigo,
    ];
    return colors[hash % colors.length];
  }

  // Helper to assign consistent icons to subjects
  IconData _getIconForSubject(String subject) {
    subject = subject.toLowerCase();
    if (subject.contains('math')) return Icons.calculate;
    if (subject.contains('programming') ||
        subject.contains('code') ||
        subject.contains('python') ||
        subject.contains('java')) {
      return Icons.code;
    }
    if (subject.contains('computer') || subject.contains('web')) {
      return Icons.computer;
    }
    if (subject.contains('digital') || subject.contains('electronics')) {
      return Icons.memory;
    }
    if (subject.contains('english') || subject.contains('literature')) {
      return Icons.book;
    }
    if (subject.contains('android') || subject.contains('mobile')) {
      return Icons.phone_android;
    }
    if (subject.contains('network')) return Icons.wifi;
    if (subject.contains('database')) return Icons.storage;
    return Icons.subject;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Attendance",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _studentService.getAttendance(widget.studentRegNo ?? ""),
        builder: (context, snapshot) {
          List<Map<String, dynamic>> displaySubjects = [];
          int overallPresent = 0;
          int overallTotal = 0;

          // Define the static baseline subjects first
          final List<Map<String, dynamic>> baselineSubjects = [
            {
              'subject': 'ADVANCED DATA STRUCTURES',
              'code': 'MCA101',
              'present': 6,
              'total': 8,
            },
            {
              'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
              'code': 'MCA105',
              'present': 6,
              'total': 8,
            },
            {
              'subject': 'WEB PROGRAMMING LAB',
              'code': 'MCA106',
              'present': 6,
              'total': 8,
            },
          ];

          final Map<String, Map<String, dynamic>> aggregated = {};

          // 1. Initialize with baseline if no real records exist or for certain student IDs
          if (widget.studentRegNo != null) {
            for (var base in baselineSubjects) {
              aggregated[base['subject']] = {...base, 'isBaseline': true};
            }
          }

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            bool hasRealRecords = snapshot.data!.docs.any(
              (doc) =>
                  (doc.data() as Map<String, dynamic>).containsKey('isPresent'),
            );

            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final subjectName =
                  (data['subjectName'] ?? data['subject'] ?? 'Unknown')
                      .toString()
                      .toUpperCase();
              final isRealRecord = data.containsKey('isPresent');

              if (hasRealRecords && !isRealRecord) continue;

              if (isRealRecord) {
                if (!aggregated.containsKey(subjectName)) {
                  aggregated[subjectName] = {
                    'subject': subjectName,
                    'code': data['subjectCode'] ?? data['code'] ?? '-',
                    'present': 0,
                    'total': 0,
                  };
                }
                aggregated[subjectName]!['total'] += 1;
                if (data['isPresent'] == true) {
                  aggregated[subjectName]!['present'] += 1;
                }
              } else if (data.containsKey('present') &&
                  data.containsKey('total')) {
                // For summary records
                if (!aggregated.containsKey(subjectName)) {
                  aggregated[subjectName] = {
                    'subject': subjectName,
                    'code': data['subjectCode'] ?? data['code'] ?? '-',
                    'present': data['present'] ?? 0,
                    'total': data['total'] ?? 0,
                  };
                } else if (!(aggregated[subjectName]!['isBaseline'] ?? false)) {
                  // Only add summary records if not already populated by baseline
                  aggregated[subjectName]!['present'] += data['present'] ?? 0;
                  aggregated[subjectName]!['total'] += data['total'] ?? 0;
                }
              }
            }
          }

          displaySubjects = aggregated.values.map((data) {
            overallPresent += (data['present'] as int);
            overallTotal += (data['total'] as int);
            return {
              ...data,
              'icon': _getIconForSubject(data['subject']),
              'color': _getColorForSubject(data['subject']),
            };
          }).toList();

          double overallPercentage = overallTotal > 0
              ? (overallPresent / overallTotal) * 100
              : 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOverallAttendanceCard(
                  overallPercentage,
                  overallPresent,
                  overallTotal,
                ),
                const SizedBox(height: 20),

                // Semester Dropdown
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedSemester,
                      icon: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      isExpanded: true,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      items: semesters.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.school_outlined,
                                size: 20,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 12),
                              Text(value),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedSemester = newValue!;
                        });
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Daily Log Shortcut
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TimetableScreen(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF001FF4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.calendar_month_rounded,
                            color: Color(0xFF001FF4),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Daily Attendance Log",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "View attendance status per day",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: Color(0xFF001FF4),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Subject-wise Attendance Header
                const Text(
                  "Subject-wise Attendance",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                // Subject Cards List - Already computed from Stream
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displaySubjects.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    return _buildSubjectCard(displaySubjects[index]);
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOverallAttendanceCard(
    double percentage,
    int present,
    int total,
  ) {
    Color cardColor;
    String status;
    IconData statusIcon;

    if (percentage >= 90) {
      cardColor = const Color(0xFF2E7D32); // Dark Green
      status = "Excellent";
      statusIcon = Icons.stars;
    } else if (percentage >= 75) {
      cardColor = const Color(0xFF8DC63F); // Apple Green
      status = "Good Standing";
      statusIcon = Icons.check_circle;
    } else {
      cardColor = const Color(0xFFEF5350); // Red
      status = "Critical";
      statusIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Progress
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 90,
                height: 90,
                child: CircularProgressIndicator(
                  value: percentage / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              Column(
                children: [
                  Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "$present/$total",
                    style: const TextStyle(color: Colors.white, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(width: 20),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Overall Attendance",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(statusIcon, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      status,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  percentage >= 75
                      ? "Keep up the good work!"
                      : "Attend more classes to reach 75%",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectCard(Map<String, dynamic> subject) {
    int present = subject['present'];
    int total = subject['total'];
    double percentage = total > 0 ? (present / total) * 100 : 0.0;
    Color subjectColor = subject['color'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Subject Icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(subject['icon'], color: subjectColor, size: 24),
                ),

                const SizedBox(width: 12),

                // Subject Name & Code
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject['subject'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        subject['code'],
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Percentage Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (percentage >= 90
                                ? const Color(0xFF2E7D32)
                                : (percentage >= 75
                                      ? const Color(0xFF8DC63F)
                                      : const Color(0xFFEF5350)))
                            .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: percentage >= 90
                          ? const Color(0xFF2E7D32)
                          : (percentage >= 75
                                ? const Color(0xFF8DC63F)
                                : const Color(0xFFEF5350)),
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 8,
                backgroundColor: Colors.grey[100],
                valueColor: AlwaysStoppedAnimation(
                  percentage >= 90
                      ? const Color(0xFF2E7D32)
                      : (percentage >= 75
                            ? const Color(0xFF8DC63F)
                            : const Color(0xFFEF5350)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Present/Total Pills
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (percentage >= 90
                                ? const Color(0xFF2E7D32)
                                : (percentage >= 75
                                      ? const Color(0xFF8DC63F)
                                      : const Color(0xFFEF5350)))
                            .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "$present / $total classes",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: percentage >= 90
                          ? const Color(0xFF2E7D32)
                          : (percentage >= 75
                                ? const Color(0xFF8DC63F)
                                : const Color(0xFFEF5350)),
                    ),
                  ),
                ),
                Text(
                  "${total - present} Absent",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
