import 'package:flutter/material.dart';
import '../services/student_service.dart';

class ResultsScreen extends StatefulWidget {
  final String? studentId;
  final String? initialExam;
  const ResultsScreen({super.key, this.studentId, this.initialExam});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final StudentService _studentService = StudentService();
  bool _isLoading = true;
  late String _selectedExam;
  List<String> _examTypes = [];
  Map<String, List<Map<String, dynamic>>> _examResults = {};

  // Subject color mapping
  static const Map<String, Color> _subjectColors = {
    'DATA STRUCTURES': Color(0xFF001FF4),
    'SOFTWARE ENGINEERING': Colors.orange,
    'COMPUTER ARCHITECTURE': Colors.green,
    'DIGITAL FUNDAMENTALS': Colors.green,
    'PROGRAMMING LAB': Colors.teal,
    'WEB PROGRAMMING': Colors.cyan,
  };

  @override
  void initState() {
    super.initState();
    _selectedExam = widget.initialExam ?? "";
    _loadResults();
  }

  Future<void> _loadResults() async {
    if (widget.studentId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dbResults = await _studentService.getStudentExamResults(
        widget.studentId!,
      );
      _applyResults(dbResults);
    } catch (e) {
      debugPrint("Error loading results: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyResults(Map<String, List<Map<String, dynamic>>> dbResults) {
    final Map<String, List<Map<String, dynamic>>> processed = {};
    dbResults.forEach((exam, subjects) {
      processed[exam] = subjects.map((s) {
        return {
          ...s,
          'color': _getSubjectColor(s['subject']?.toString() ?? ''),
        };
      }).toList();
    });

    setState(() {
      _examResults = processed;
      _examTypes = processed.keys.toList();
      
      // Select the initial exam if provided and exists, otherwise pick the first one
      if (widget.initialExam != null && processed.containsKey(widget.initialExam)) {
        _selectedExam = widget.initialExam!;
      } else if (_examTypes.isNotEmpty && (!_examTypes.contains(_selectedExam) || _selectedExam.isEmpty)) {
        _selectedExam = _examTypes.first;
      }
    });
  }

  Color _getSubjectColor(String subject) {
    final upper = subject.toUpperCase();
    for (final entry in _subjectColors.entries) {
      if (upper.contains(entry.key)) {
        return entry.value;
      }
    }
    return Colors.blue;
  }

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
        actions: const [
          SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _examResults.isEmpty
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            "No results available yet",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Results will appear here once your\nteachers publish exam marks",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _loadResults,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text("Refresh"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.80),
            Colors.white.withOpacity(0.40),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.85), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.40),
            blurRadius: 6,
            spreadRadius: -2,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "OVERALL SEMESTER PERFORMANCE",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${percentage.toStringAsFixed(1)}%",
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: Colors.grey.shade900,
              height: 1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "${marks.toInt()} / $max Total Marks Obtained",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSelector() {
    if (_examTypes.isEmpty) return const SizedBox.shrink();

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
    if (results.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            "No results for this exam",
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ),
      );
    }

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
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.90),
                  Colors.white.withOpacity(0.60),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade100, width: 1.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Subject',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
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
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade800,
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
