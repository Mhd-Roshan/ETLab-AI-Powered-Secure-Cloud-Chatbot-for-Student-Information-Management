import 'package:flutter/material.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String _selectedExam = "Series Exam 1";
  final List<String> _examTypes = [
    "Series Exam 1",
    "Series Exam 2",
    "Assignment 1",
    "Assignment 2",
  ];

  // Series exam results - out of 40 marks each
  final Map<String, List<Map<String, dynamic>>> _examResults = {
    "Series Exam 1": [
      {
        'subject': 'ADVANCED DATA STRUCTURES',
        'code': 'MCA101',
        'marks': 35,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': const Color(0xFF001FF4),
      },
      {
        'subject': 'ADVANCED SOFTWARE ENGINEERING',
        'code': 'MCA102',
        'marks': 32,
        'maxMarks': 40,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.orange,
      },
      {
        'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
        'code': 'MCA103',
        'marks': 38,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.green,
      },
      {
        'subject': 'MATHEMATICAL FOUNDATIONS FOR COMPUTING',
        'code': 'MCA104',
        'marks': 28,
        'maxMarks': 40,
        'grade': 'B+',
        'gradePoint': 8,
        'color': Colors.red,
      },
      {
        'subject': 'DATA STRUCTURES LAB',
        'code': 'MCA105',
        'marks': 33,
        'maxMarks': 40,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.purple,
      },
      {
        'subject': 'PROGRAMMING LAB',
        'code': 'MCA106',
        'marks': 37,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.teal,
      },
      {
        'subject': 'WEB PROGRAMMING LAB',
        'code': 'MCA107',
        'marks': 34,
        'maxMarks': 40,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.blue,
      },
    ],
    "Series Exam 2": [
      {
        'subject': 'ADVANCED DATA STRUCTURES',
        'code': 'MCA101',
        'marks': 36,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': const Color(0xFF001FF4),
      },
      {
        'subject': 'ADVANCED SOFTWARE ENGINEERING',
        'code': 'MCA102',
        'marks': 30,
        'maxMarks': 40,
        'grade': 'B+',
        'gradePoint': 8,
        'color': Colors.orange,
      },
      {
        'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
        'code': 'MCA103',
        'marks': 39,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.green,
      },
      {
        'subject': 'MATHEMATICAL FOUNDATIONS FOR COMPUTING',
        'code': 'MCA104',
        'marks': 29,
        'maxMarks': 40,
        'grade': 'B+',
        'gradePoint': 8,
        'color': Colors.red,
      },
      {
        'subject': 'DATA STRUCTURES LAB',
        'code': 'MCA105',
        'marks': 34,
        'maxMarks': 40,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.purple,
      },
      {
        'subject': 'PROGRAMMING LAB',
        'code': 'MCA106',
        'marks': 38,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.teal,
      },
      {
        'subject': 'WEB PROGRAMMING LAB',
        'code': 'MCA107',
        'marks': 32,
        'maxMarks': 40,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.blue,
      },
    ],
    "Assignment 1": [
      {
        'subject': 'ADVANCED DATA STRUCTURES',
        'code': 'MCA101',
        'marks': 9,
        'maxMarks': 10,
        'grade': 'A+',
        'gradePoint': 10,
        'color': const Color(0xFF001FF4),
      },
      {
        'subject': 'ADVANCED SOFTWARE ENGINEERING',
        'code': 'MCA102',
        'marks': 8,
        'maxMarks': 10,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.orange,
      },
      {
        'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
        'code': 'MCA103',
        'marks': 10,
        'maxMarks': 10,
        'grade': 'O',
        'gradePoint': 10,
        'color': Colors.green,
      },
      {
        'subject': 'MATHEMATICAL FOUNDATIONS FOR COMPUTING',
        'code': 'MCA104',
        'marks': 7,
        'maxMarks': 10,
        'grade': 'B+',
        'gradePoint': 8,
        'color': Colors.red,
      },
    ],
    "Assignment 2": [
      {
        'subject': 'ADVANCED DATA STRUCTURES',
        'code': 'MCA101',
        'marks': 10,
        'maxMarks': 10,
        'grade': 'O',
        'gradePoint': 10,
        'color': const Color(0xFF001FF4),
      },
      {
        'subject': 'ADVANCED SOFTWARE ENGINEERING',
        'code': 'MCA102',
        'marks': 9,
        'maxMarks': 10,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.orange,
      },
      {
        'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
        'code': 'MCA103',
        'marks': 10,
        'maxMarks': 10,
        'grade': 'O',
        'gradePoint': 10,
        'color': Colors.green,
      },
      {
        'subject': 'MATHEMATICAL FOUNDATIONS FOR COMPUTING',
        'code': 'MCA104',
        'marks': 8,
        'maxMarks': 10,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.red,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final subjectResults = _examResults[_selectedExam] ?? [];

    // Calculate GLOBAL overall marks across all exams
    double globalTotalMarks = 0.0;
    int globalTotalMaxMarks = 0;

    _examResults.forEach((key, results) {
      for (var res in results) {
        globalTotalMarks += ((res['marks'] ?? 0) as num).toDouble();
        globalTotalMaxMarks += ((res['maxMarks'] ?? 0) as num).toInt();
      }
    });

    double globalPercentage = globalTotalMaxMarks > 0
        ? (globalTotalMarks / globalTotalMaxMarks) * 100
        : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
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
        title: const Text(
          "Academic Results",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Results Card (Static)
            _buildOverallPerformanceCard(
              globalPercentage,
              globalTotalMarks,
              globalTotalMaxMarks,
            ),
            const SizedBox(height: 24),
            _buildDropdownSelector(),
            const SizedBox(height: 20),
            Text(
              "Subject-wise Marks - $_selectedExam",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildResultsTable(subjectResults),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildOverallPerformanceCard(
    double percentage,
    double marks,
    int max,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF001FF4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001FF4).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "OVERALL SMESTER PERFORMANCE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${percentage.toStringAsFixed(1)}%",
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${marks.toInt()} / $max Total Marks Obtained",
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector() {
    return Container(
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
          value: _selectedExam,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Colors.grey,
          ),
          isExpanded: true,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          borderRadius: BorderRadius.circular(16),
          items: _examTypes.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                children: [
                  const Icon(Icons.assignment, size: 20, color: Colors.grey),
                  const SizedBox(width: 12),
                  Text(value),
                ],
              ),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedExam = newValue!;
            });
          },
        ),
      ),
    );
  }

  Widget _buildResultsTable(List<Map<String, dynamic>> results) {
    return Container(
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF001FF4).withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                const Expanded(
                  flex: 3,
                  child: Text(
                    'Subject',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF001FF4),
                    ),
                  ),
                ),
                _buildHeaderCell('Marks', 2),
                _buildHeaderCell('Grade', 1),
                _buildHeaderCell('GP', 1),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Colors.grey[200]),
            itemBuilder: (context, index) {
              return _buildResultRow(results[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF001FF4),
        ),
      ),
    );
  }

  Widget _buildResultRow(Map<String, dynamic> subject) {
    final marks = (subject['marks'] ?? 0) as num;
    final maxMarks = (subject['maxMarks'] ?? 40) as num;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject['subject']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subject['code']?.toString() ?? '',
                  style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              "$marks / $maxMarks",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildGradeCell(
            subject['grade']?.toString() ?? '-',
            subject['color'] as Color? ?? Colors.grey,
            1,
          ),
          _buildDataCell((subject['gradePoint'] ?? 0).toString(), 1),
        ],
      ),
    );
  }

  Widget _buildDataCell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildGradeCell(String grade, Color color, int flex) {
    return Expanded(
      flex: flex,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            grade,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}
