import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  final String? studentRegNo;
  
  const AttendanceScreen({super.key, this.studentRegNo});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  String selectedSemester = "Semester 4 (Current)";
  final List<String> semesters = [
    "Semester 4 (Current)",
    "Semester 3",
    "Semester 2",
    "Semester 1"
  ];

  String searchQuery = "";

  // Dummy subject-wise attendance data (replace with Firebase later)
  final List<Map<String, dynamic>> subjectAttendance = [
    {
      'subject': 'Data Structures',
      'code': 'CS401',
      'present': 28,
      'total': 35,
      'color': const Color(0xFF5C51E1),
      'icon': Icons.code,
    },
    {
      'subject': 'Mathematics',
      'code': 'MA402',
      'present': 30,
      'total': 38,
      'color': Colors.orange,
      'icon': Icons.calculate,
    },
    {
      'subject': 'Python Programming',
      'code': 'CS403',
      'present': 32,
      'total': 36,
      'color': Colors.green,
      'icon': Icons.computer,
    },
    {
      'subject': 'Digital Fundamentals',
      'code': 'EC404',
      'present': 25,
      'total': 35,
      'color': Colors.red,
      'icon': Icons.memory,
    },
    {
      'subject': 'English Literature',
      'code': 'EN405',
      'present': 33,
      'total': 37,
      'color': Colors.purple,
      'icon': Icons.book,
    },
    {
      'subject': 'Android Development',
      'code': 'CS406',
      'present': 27,
      'total': 33,
      'color': Colors.teal,
      'icon': Icons.phone_android,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Calculate overall attendance
    int totalPresent = subjectAttendance.fold(0, (sum, item) => sum + (item['present'] as int));
    int totalClasses = subjectAttendance.fold(0, (sum, item) => sum + (item['total'] as int));
    double overallPercentage = (totalPresent / totalClasses) * 100;

    // Filter subjects based on search
    final filteredSubjects = subjectAttendance.where((subject) {
      return subject['subject'].toString().toLowerCase().contains(searchQuery.toLowerCase()) ||
             subject['code'].toString().toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Attendance Card
            _buildOverallAttendanceCard(overallPercentage, totalPresent, totalClasses),
            
            const SizedBox(height: 20),

            // Semester Dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedSemester,
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
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
                          const Icon(Icons.school_outlined, size: 20, color: Colors.grey),
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

            // Search Bar
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  hintText: "Search subjects...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
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

            // Subject Cards List
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredSubjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _buildSubjectCard(filteredSubjects[index]);
              },
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallAttendanceCard(double percentage, int present, int total) {
    Color cardColor;
    String status;
    IconData statusIcon;

    if (percentage >= 75) {
      cardColor = const Color(0xFF4CAF50); // Green
      status = "Good Standing";
      statusIcon = Icons.check_circle;
    } else if (percentage >= 65) {
      cardColor = const Color(0xFFFFA726); // Orange
      status = "Need Improvement";
      statusIcon = Icons.warning;
    } else {
      cardColor = const Color(0xFFEF5350); // Red
      status = "Critical";
      statusIcon = Icons.error;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
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
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
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
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  percentage >= 75 
                      ? "Keep up the good work!" 
                      : "Attend more classes to reach 75%",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
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
    double percentage = (present / total) * 100;
    Color subjectColor = subject['color'];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
                    color: subjectColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    subject['icon'],
                    color: subjectColor,
                    size: 24,
                  ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Percentage Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: percentage >= 75 
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${percentage.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: percentage >= 75 ? Colors.green : Colors.red,
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
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(subjectColor),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Present/Total Text
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "$present Present / $total Total",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  "${total - present} Absent",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
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