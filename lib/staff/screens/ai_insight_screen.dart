import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class AiInsightScreen extends StatefulWidget {
  final String userId;
  const AiInsightScreen({super.key, required this.userId});

  @override
  State<AiInsightScreen> createState() => _AiInsightScreenState();
}

class _AiInsightScreenState extends State<AiInsightScreen> {
  bool _loading = true;
  double _overallAttendance = 0.0;
  int _atRiskCount = 0;
  int _improvingCount = 0;
  int _totalStudents = 0;
  List<Map<String, dynamic>> _atRiskStudents = [];
  List<Map<String, dynamic>> _topPerformers = [];

  // Weekly trend data (mocked for visualization but could be calculated)
  final List<double> _weeklyStability = [0.82, 0.85, 0.88, 0.84, 0.86, 0.85];

  @override
  void initState() {
    super.initState();
    _loadDetailedInsights();
  }

  Future<void> _loadDetailedInsights() async {
    try {
      final db = FirebaseFirestore.instance;
      final attendanceSnapshot = await db.collection('attendance').get();
      final studentsSnapshot = await db.collection('students').get();

      if (attendanceSnapshot.docs.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      // Group attendance by student
      final Map<String, List<bool>> studentRecordMap = {};
      final Map<String, String> studentNames = {};

      // Get student names first
      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final id = doc.id;
        final name = data['name'] ?? 'Unknown Student';
        studentNames[id] = name;
      }

      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data();
        final studentId =
            data['studentId']?.toString() ?? data['regNo']?.toString();
        if (studentId == null) continue;

        // Try to get name if not in map
        if (!studentNames.containsKey(studentId)) {
          studentNames[studentId] = data['studentName'] ?? 'Student $studentId';
        }

        final isPresent =
            data['isPresent'] == true || data['status'] == 'present';
        studentRecordMap.putIfAbsent(studentId, () => []).add(isPresent);
      }

      final List<Map<String, dynamic>> analysis = [];
      studentNames.forEach((id, name) {
        if (studentRecordMap.containsKey(id)) {
          final records = studentRecordMap[id]!;
          final presentCount = records.where((p) => p).length;
          final pct = presentCount / records.length;

          analysis.add({
            'id': id,
            'name': name,
            'pct': pct,
            'totalClasses': records.length,
            'presentClasses': presentCount,
          });
        }
      });

      // Sort analysis
      analysis.sort((a, b) => b['pct'].compareTo(a['pct']));

      final overall = analysis.isEmpty
          ? 0.0
          : analysis.map((e) => e['pct'] as double).reduce((a, b) => a + b) /
                analysis.length;
      final atRisk = analysis
          .where((e) => (e['pct'] as double) < 0.75)
          .toList();
      final top = analysis.where((e) => (e['pct'] as double) >= 0.85).toList();

      if (mounted) {
        setState(() {
          _overallAttendance = overall;
          _atRiskCount = atRisk.length;
          _improvingCount = top.length;
          _totalStudents = analysis.length;
          _atRiskStudents = atRisk;
          _topPerformers = top;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF001FF4),
                            strokeWidth: 3,
                          ),
                        )
                      : SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTopStats(),
                              const SizedBox(height: 32),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _buildStabilityChart(),
                                  ),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    flex: 2,
                                    child: _buildAIPredictionsLight(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),
                              _buildStudentAnalysis(),
                            ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 56, 40, 28),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildActionButton(
            Icons.arrow_back_ios_new_rounded,
            () => Navigator.pop(context),
            const Color(0xFF0F172A),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Student Intelligence",
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -1,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Real-time Class Stability Analytics",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          _buildActionButton(
            Icons.file_download_outlined,
            () {},
            const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          _buildActionButton(
            Icons.refresh_rounded,
            () => _loadDetailedInsights(),
            const Color(0xFF001FF4),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _buildTopStats() {
    return Row(
      children: [
        _buildStatCard(
          "Stability Rate",
          "${(_overallAttendance * 100).toStringAsFixed(1)}%",
          "Overall benchmark",
          Icons.auto_awesome_rounded,
          const Color(0xFF001FF4),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "At Risk",
          _atRiskCount.toString(),
          "Below critical line",
          Icons.emergency_outlined,
          const Color(0xFFF43F5E),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Peak Engagement",
          _improvingCount.toString(),
          "High stability tier",
          Icons.verified_outlined,
          const Color(0xFF10B981),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Total Class",
          _totalStudents.toString(),
          "Enrolled students",
          Icons.fingerprint_rounded,
          const Color(0xFF64748B),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    String sub,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.04),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Icon(icon, color: color.withOpacity(0.4), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF0F172A),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStabilityChart() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.02),
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Engagement Continuity",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              _buildTrendBadge(),
            ],
          ),
          const SizedBox(height: 48),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _weeklyStability
                  .map((val) => _buildModernBar(val))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN'].map((w) {
              return Text(
                w,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: const Color(0xFF94A3B8),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.north_east_rounded,
            color: Color(0xFF10B981),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            "+4.2%",
            style: GoogleFonts.inter(
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBar(double value) {
    return Container(
      width: 44,
      height: 200 * value,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF001FF4), Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildAIPredictionsLight() {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF001FF4).withOpacity(0.05), Colors.white],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF001FF4).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                color: Color(0xFF001FF4),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "Predictions",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildPredictionItemLight(
            "Continuity Alert",
            "Stability dipped by 2% in S1 batch.",
            Icons.query_stats_rounded,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 24),
          _buildPredictionItemLight(
            "Optimal Performance",
            "Class capacity is at peak for exams.",
            Icons.auto_graph_rounded,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 24),
          _buildPredictionItemLight(
            "Focus Required",
            "High variation in elective attendance.",
            Icons.adjust_rounded,
            const Color(0xFF001FF4),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionItemLight(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              Text(
                desc,
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudentAnalysis() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildStudentSection(
            "Critical Monitoring",
            _atRiskStudents,
            const Color(0xFFF43F5E),
          ),
        ),
        const SizedBox(width: 32),
        Expanded(
          child: _buildStudentSection(
            "High Performers",
            _topPerformers,
            const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentSection(
    String title,
    List<Map<String, dynamic>> students,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              title.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              "(${students.length})",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ...students.take(5).map((s) => _buildModernStudentCard(s, color)),
        if (students.isEmpty) _buildEmptyStateLight("No data monitored."),
      ],
    );
  }

  Widget _buildModernStudentCard(Map<String, dynamic> student, Color accent) {
    final pct = (student['pct'] * 100).round();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.01),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Text(
              student['name'][0],
              style: GoogleFonts.inter(
                color: accent,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    fontSize: 16,
                  ),
                ),
                Text(
                  "ID: ${student['id']}",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$pct%",
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w900,
                  color: accent,
                  fontSize: 22,
                ),
              ),
              Text(
                "STABILITY",
                style: GoogleFonts.inter(
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateLight(String msg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Text(
        msg,
        style: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

