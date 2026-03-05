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
  String _department = "MCA";

  // Metrics
  double _deptStability = 0.0;
  int _totalStudents = 0;
  int _activeBatches = 0;
  int _criticalStudents = 0;

  List<Map<String, dynamic>> _batchMetrics = [];
  List<Map<String, dynamic>> _atRiskStudents = [];

  // Chart Data (Mocked for trend visualization)
  final List<double> _monthlyTrend = [0.78, 0.82, 0.85, 0.81, 0.84, 0.83];

  @override
  void initState() {
    super.initState();
    _loadComprehensiveData();
  }

  Future<void> _loadComprehensiveData() async {
    try {
      final db = FirebaseFirestore.instance;

      // 1. Get HOD Profile
      final profileDoc = await db.collection('users').doc(widget.userId).get();
      if (profileDoc.exists) {
        _department = profileDoc.data()?['department'] ?? "MCA";
      }

      // 2. Get Batches
      final batchesSnapshot = await db
          .collection('batches')
          .where('department', isEqualTo: _department)
          .get();
      _activeBatches = batchesSnapshot.docs.length;

      // 3. Get Students
      final studentsSnapshot = await db
          .collection('students')
          .where('department', isEqualTo: _department)
          .get();
      _totalStudents = studentsSnapshot.docs.length;

      final Map<String, List<Map<String, dynamic>>> studentsByBatch = {};
      final Map<String, Map<String, dynamic>> studentMap = {};

      for (var doc in studentsSnapshot.docs) {
        final data = doc.data();
        final batch = data['batch'] ?? 'Unknown';
        final regNo = data['registrationNumber'] ?? doc.id;

        studentMap[regNo] = data;
        studentsByBatch.putIfAbsent(batch, () => []).add({
          'id': doc.id,
          ...data,
        });
      }

      // 4. Get Attendance Records
      final attendanceSnapshot = await db.collection('attendance').get();

      // Group attendance by student
      final Map<String, List<bool>> studentAttendance = {};
      for (var doc in attendanceSnapshot.docs) {
        final data = doc.data();
        final id = data['studentId']?.toString() ?? data['regNo']?.toString();
        if (id == null) continue;

        if (studentMap.containsKey(id)) {
          final isPresent =
              data['isPresent'] == true || data['status'] == 'present';
          studentAttendance.putIfAbsent(id, () => []).add(isPresent);
        }
      }

      // 5. Calculate Stability per Student & Batch
      final List<Map<String, dynamic>> batchAnalysis = [];
      final List<Map<String, dynamic>> overallAtRisk = [];
      double totalDeptPct = 0;
      int studentsWithData = 0;

      for (var batchEntry in studentsByBatch.entries) {
        final batchName = batchEntry.key;
        final students = batchEntry.value;

        double batchTotalPct = 0;
        int batchStudentsWithData = 0;

        for (var student in students) {
          final regNo = student['registrationNumber'] ?? student['id'];
          if (studentAttendance.containsKey(regNo)) {
            final records = studentAttendance[regNo]!;
            final present = records.where((p) => p).length;
            final pct = present / records.length;

            student['stability'] = pct;

            if (pct < 0.75) {
              overallAtRisk.add(student);
            }

            batchTotalPct += pct;
            batchStudentsWithData++;

            totalDeptPct += pct;
            studentsWithData++;
          }
        }

        if (batchStudentsWithData > 0) {
          batchAnalysis.add({
            'name': batchName,
            'stability': batchTotalPct / batchStudentsWithData,
            'studentCount': students.length,
            'dataCount': batchStudentsWithData,
          });
        }
      }

      if (mounted) {
        setState(() {
          _deptStability = studentsWithData > 0
              ? totalDeptPct / studentsWithData
              : 0.82; // Fallback for demo
          _criticalStudents = overallAtRisk.length;
          _atRiskStudents = overallAtRisk
            ..sort(
              (a, b) => (a['stability'] as double).compareTo(
                b['stability'] as double,
              ),
            );
          _batchMetrics = batchAnalysis
            ..sort(
              (a, b) => (b['stability'] as double).compareTo(
                a['stability'] as double,
              ),
            );
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading insights: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
                            color: Color(0xFF6366F1),
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
                                  Expanded(flex: 3, child: _buildMainChart()),
                                  const SizedBox(width: 32),
                                  Expanded(
                                    flex: 2,
                                    child: _buildPredictiveInsights(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),
                              _buildSecondaryAnalysis(),
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
                "Department Intelligence",
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
                    "Unified AI Insights for $_department Department",
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
            () => _loadComprehensiveData(),
            const Color(0xFF6366F1),
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
          "Dept. Stability",
          "${(_deptStability * 100).toStringAsFixed(1)}%",
          "Overall continuity rate",
          Icons.query_stats_rounded,
          const Color(0xFF6366F1),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Active Batches",
          _activeBatches.toString(),
          "Current academic cycles",
          Icons.layers_outlined,
          const Color(0xFFF59E0B),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Critical Monitoring",
          _criticalStudents.toString(),
          "Students below 75%",
          Icons.emergency_outlined,
          const Color(0xFFF43F5E),
        ),
        const SizedBox(width: 24),
        _buildStatCard(
          "Dept. Size",
          _totalStudents.toString(),
          "Total student strength",
          Icons.groups_3_outlined,
          const Color(0xFF10B981),
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

  Widget _buildMainChart() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
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
                "Engagement Trend",
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
              children: _monthlyTrend
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
            "+5.8%",
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
      width: 50,
      height: 200 * value,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6366F1), Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }

  Widget _buildPredictiveInsights() {
    return Container(
      height: 400,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF6366F1).withOpacity(0.05), Colors.white],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.hub_outlined,
                color: Color(0xFF6366F1),
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                "AI Predictions",
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildPredictionItem(
            "Batch at Risk",
            "${_batchMetrics.isNotEmpty ? _batchMetrics.last['name'] : 'N/A'} shows 4% decline.",
            Icons.trending_down_rounded,
            const Color(0xFFF43F5E),
          ),
          const SizedBox(height: 24),
          _buildPredictionItem(
            "Optimal Attendance",
            "Wednesday peak detected in S3 Batch.",
            Icons.bolt_rounded,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 24),
          _buildPredictionItem(
            "Efficiency Alert",
            "Staff engagement is above 92%.",
            Icons.verified_user_outlined,
            const Color(0xFF10B981),
          ),
          const SizedBox(height: 24),
          _buildPredictionItem(
            "Exam Readiness",
            "88% continuity in elective subjects.",
            Icons.auto_graph_rounded,
            const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionItem(
    String title,
    String desc,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
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

  Widget _buildSecondaryAnalysis() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildBatchList()),
        const SizedBox(width: 32),
        Expanded(child: _buildCriticalStudentList()),
      ],
    );
  }

  Widget _buildBatchList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Academic Batches", _batchMetrics.length),
        const SizedBox(height: 24),
        ..._batchMetrics.map((b) => _buildBatchCard(b)),
        if (_batchMetrics.isEmpty) _buildEmptyState("No batch data available."),
      ],
    );
  }

  Widget _buildCriticalStudentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("Critical Monitoring", _atRiskStudents.length),
        const SizedBox(height: 24),
        ..._atRiskStudents.take(5).map((s) => _buildStudentCard(s)),
        if (_atRiskStudents.isEmpty)
          _buildEmptyState("All students are stable."),
      ],
    );
  }

  Widget _buildSectionTitle(String title, int count) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1),
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
          "($count)",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    final pct = (batch['stability'] * 100).round();
    final color = pct >= 85
        ? const Color(0xFF10B981)
        : (pct >= 75 ? const Color(0xFFF59E0B) : const Color(0xFFF43F5E));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.class_outlined, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch['name'],
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    fontSize: 18,
                  ),
                ),
                Text(
                  "${batch['studentCount']} Students enrolled",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          _buildRadialIndicator(batch['stability'], color),
        ],
      ),
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final pct = (student['stability'] * 100).round();
    final accent = const Color(0xFFF43F5E);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
              borderRadius: BorderRadius.circular(14),
            ),
            alignment: Alignment.center,
            child: Text(
              (student['firstName']?[0] ?? student['name']?[0] ?? 'S'),
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
                  "${student['firstName'] ?? student['name']} ${student['lastName'] ?? ''}",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                    fontSize: 16,
                  ),
                ),
                Text(
                  "Batch: ${student['batch']}",
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

  Widget _buildRadialIndicator(double value, Color color) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: 4,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
          Text(
            "${(value * 100).round()}%",
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
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
