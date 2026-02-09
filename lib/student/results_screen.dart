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
  ];

  // Series exam results - out of 40 marks each
  final Map<String, List<Map<String, dynamic>>> _examResults = {
    "Series Exam 1": [
      {
        'subject': 'Data Structures',
        'code': 'CS401',
        'marks': 35,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': const Color(0xFF5C51E1),
      },
      {
        'subject': 'Mathematics',
        'code': 'MA402',
        'marks': 32,
        'maxMarks': 40,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.orange,
      },
      {
        'subject': 'Python Programming',
        'code': 'CS403',
        'marks': 38,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.green,
      },
      {
        'subject': 'Digital Fundamentals',
        'code': 'EC404',
        'marks': 28,
        'maxMarks': 40,
        'grade': 'B+',
        'gradePoint': 8,
        'color': Colors.red,
      },
      {
        'subject': 'English Literature',
        'code': 'EN405',
        'marks': 33,
        'maxMarks': 40,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.purple,
      },
      {
        'subject': 'Computer Lab',
        'code': 'CS406',
        'marks': 37,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.teal,
      },
    ],
    "Series Exam 2": [
      {
        'subject': 'Data Structures',
        'code': 'CS401',
        'marks': 36,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': const Color(0xFF5C51E1),
      },
      {
        'subject': 'Mathematics',
        'code': 'MA402',
        'marks': 30,
        'maxMarks': 40,
        'grade': 'B+',
        'gradePoint': 8,
        'color': Colors.orange,
      },
      {
        'subject': 'Python Programming',
        'code': 'CS403',
        'marks': 39,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.green,
      },
      {
        'subject': 'Digital Fundamentals',
        'code': 'EC404',
        'marks': 29,
        'maxMarks': 40,
        'grade': 'B+',
        'gradePoint': 8,
        'color': Colors.red,
      },
      {
        'subject': 'English Literature',
        'code': 'EN405',
        'marks': 34,
        'maxMarks': 40,
        'grade': 'A',
        'gradePoint': 9,
        'color': Colors.purple,
      },
      {
        'subject': 'Computer Lab',
        'code': 'CS406',
        'marks': 38,
        'maxMarks': 40,
        'grade': 'A+',
        'gradePoint': 10,
        'color': Colors.teal,
      },
    ],
  };

  @override
  Widget build(BuildContext context) {
    final subjectResults = _examResults[_selectedExam];
    
    if (subjectResults == null || subjectResults.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FB),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
          ),
          title: const Text("Results"),
        ),
        body: const Center(child: Text("No results available")),
      );
    }
    
    double totalMarks = 0.0;
    int totalMaxMarks = 0;
    double totalGradePoints = 0.0;
    int totalCredits = 0;
    
    try {
      for (var subject in subjectResults) {
        totalMarks += ((subject['marks'] ?? 0) as num).toDouble();
        totalMaxMarks += ((subject['maxMarks'] ?? 40) as num).toInt();
        
        final gradePoint = ((subject['gradePoint'] ?? 0) as num).toDouble();
        final credits = 1; // Each subject counts as 1 credit for series exams
        
        totalGradePoints += gradePoint * credits;
        totalCredits += credits;
      }
    } catch (e) {
      debugPrint("Error calculating results: $e");
    }
    
    double percentage = totalMaxMarks > 0 ? (totalMarks / totalMaxMarks) * 100 : 0.0;
    double avgGradePoint = totalCredits > 0 ? totalGradePoints / totalCredits : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Results",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Text(
              "Series Exam (Out of 40)",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey[400],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5C51E1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.download_rounded, size: 20, color: Color(0xFF5C51E1)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDropdownSelector(),
            const SizedBox(height: 20),
            _buildScoreCard(percentage, avgGradePoint, totalMarks.toInt(), totalMaxMarks),
            const SizedBox(height: 24),
            const Text(
              "Subject-wise Results",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildResultsTable(subjectResults),
            const SizedBox(height: 20),
            _buildSummaryCard(percentage, avgGradePoint, totalMarks.toInt(), totalMaxMarks, subjectResults),
            const SizedBox(height: 20),
          ],
        ),
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
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
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

  Widget _buildScoreCard(double percentage, double avgGP, int totalMarks, int maxMarks) {
    Color cardColor;
    String performance;

    if (percentage >= 90) {
      cardColor = const Color(0xFF4CAF50);
      performance = "Outstanding";
    } else if (percentage >= 80) {
      cardColor = const Color(0xFF5C51E1);
      performance = "Excellent";
    } else if (percentage >= 70) {
      cardColor = const Color(0xFFFFA726);
      performance = "Very Good";
    } else if (percentage >= 60) {
      cardColor = const Color(0xFFFF7043);
      performance = "Good";
    } else {
      cardColor = const Color(0xFFEF5350);
      performance = "Average";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          Text(
            _selectedExam.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${percentage.toStringAsFixed(1)}%",
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              performance,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "$totalMarks / $maxMarks marks",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Avg GP: ${avgGP.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
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
              color: const Color(0xFF5C51E1).withValues(alpha: 0.1),
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
                      color: Color(0xFF5C51E1),
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
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: Colors.grey[200],
            ),
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
          color: Color(0xFF5C51E1),
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
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
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
            1
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

  Widget _buildSummaryCard(double percentage, double avgGP, int totalMarks, int maxMarks, List<Map<String, dynamic>> results) {
    int aPlus = 0, a = 0, bPlus = 0, b = 0, c = 0;
    
    for (var subject in results) {
      String grade = subject['grade']?.toString() ?? '';
      if (grade == 'A+') {
        aPlus++;
      } else if (grade == 'A') {
        a++;
      } else if (grade == 'B+') {
        bPlus++;
      } else if (grade == 'B') {
        b++;
      } else if (grade == 'C') {
        c++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF5C51E1).withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.summarize, color: Color(0xFF5C51E1), size: 20),
              SizedBox(width: 8),
              Text(
                "Summary",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Total Marks', '$totalMarks / $maxMarks'),
          _buildSummaryRow('Percentage', '${percentage.toStringAsFixed(2)}%'),
          _buildSummaryRow('Average Grade Point', avgGP.toStringAsFixed(2)),
          const Divider(height: 24),
          const Text(
            "Grade Distribution",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildGradeDistribution('A+', aPlus, Colors.green),
          _buildGradeDistribution('A', a, const Color(0xFF5C51E1)),
          _buildGradeDistribution('B+', bPlus, Colors.orange),
          _buildGradeDistribution('B', b, Colors.red),
          if (c > 0) _buildGradeDistribution('C', c, Colors.grey),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 8),
                Text(
                  'All Subjects Passed (${results.length}/${results.length})',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradeDistribution(String grade, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    
    double widthFactor = (count / 6).clamp(0.0, 1.0);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
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
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: widthFactor,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
