import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/hod/screens/ai_chat_screen.dart';
import 'package:edlab/hod/screens/ai_insight_screen.dart';
import 'package:edlab/services/hod_service.dart';
import 'package:edlab/services/staff_service.dart';
import 'package:edlab/services/voice_service.dart';

// Ensure these widget files exist in your project
import 'widgets/hod_sidebar.dart';
import 'widgets/hod_header.dart';
import 'widgets/hod_grid.dart';
import 'widgets/hod_calendar.dart';

class HodDashboard extends StatefulWidget {
  final dynamic user;
  const HodDashboard({super.key, this.user});

  @override
  State<HodDashboard> createState() => _HodDashboardState();
}

class _HodDashboardState extends State<HodDashboard> {
  final StaffService service = StaffService();
  final HodService _hodService = HodService();

  @override
  void initState() {
    super.initState();
    _seedDatabaseIfNeeded();
  }

  /// Seeds Firestore with batch and student data if not already present.
  Future<void> _seedDatabaseIfNeeded() async {
    try {
      final existing = await FirebaseFirestore.instance
          .collection('batches')
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        await _hodService.seedBatches();
        await _hodService.seedBatchStudents();
        await _hodService.seedStaff();
      }
    } catch (_) {
      // Silently ignore seed errors — data may already exist
    }
  }

  // ✅ Navigation Helper
  void _navigateToAi(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiChatScreen(
          initialPrompt: prompt,
          userId: widget.user?.toString() ?? 'hod@gmail.com',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Sidebar
          HodSidebar(
            activeIndex: 0,
            userId: widget.user?.toString() ?? 'hod@gmail.com',
          ),

          // 2. Main Content Area
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HodHeader(userId: widget.user?.toString() ?? 'hod@gmail.com'),
                  const SizedBox(height: 32),

                  // --- SECTION 1: LIVE DEPARTMENT METRICS ---
                  StreamBuilder<DocumentSnapshot>(
                    stream: _hodService.getProfile(
                      widget.user?.toString() ?? 'hod@gmail.com',
                    ),
                    builder: (context, profileSnapshot) {
                      String department = "MCA"; // Fallback
                      if (profileSnapshot.hasData &&
                          profileSnapshot.data!.exists) {
                        final data =
                            profileSnapshot.data!.data()
                                as Map<String, dynamic>;
                        department = data['department'] ?? "MCA";
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: _buildLiveCard(
                              title: 'Total Batches',
                              stream: _hodService
                                  .getDepartmentBatches(department)
                                  .map((s) => s.docs.length),
                              color: const Color(0xFF6366F1),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildLiveCard(
                              title: 'Total Coordinators',
                              stream: _hodService
                                  .getDepartmentBatches(department)
                                  .map(
                                    (s) => s.docs
                                        .map((d) {
                                          final data =
                                              d.data() as Map<String, dynamic>;
                                          return data['coordinator'] as String?;
                                        })
                                        .where((c) => c != null)
                                        .cast<String>()
                                        .toSet()
                                        .length,
                                  ),
                              color: const Color(0xFF10B981),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildLiveCard(
                              title: 'Exams Scheduled',
                              stream: _hodService
                                  .getDepartmentExams(department)
                                  .map((s) => s.docs.length),
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // --- SECTION 2: AI INTELLIGENCE HUB ---
                  Row(
                    children: [
                      // ✅ INTERACTIVE AI CHAT (Main Assistant)
                      Expanded(
                        flex: 3,
                        child: AiChatAssistantCard(
                          onSubmitted: (text) => _navigateToAi(text),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // ✅ AI PREDICTIVE INSIGHT CARD
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AiInsightScreen(
                                userId:
                                    widget.user?.toString() ?? 'hod@gmail.com',
                              ),
                            ),
                          ),
                          child: const AiInsightCard(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- SECTION 3: WORKSPACE ---
                  Text(
                    "WORKSPACE",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SECTION 4: INTERACTIVE SERVICE GRID ---
                  HodWorkspaceGrid(
                    userId: widget.user?.toString() ?? 'hod@gmail.com',
                  ),
                ],
              ),
            ),
          ),

          // 3. Right Sidebar
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: const HodRightPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveCard({
    required String title,
    required Stream<int> stream,
    required Color color,
  }) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data.toString() : "...";
        return LiveMetricCarousel(
          baseColor: color,
          dataPoints: [
            {'title': title, 'count': count, 'percent': 'Live', 'isUp': true},
            {
              'title': 'Department View',
              'count': count,
              'percent': '100%',
              'isUp': true,
            },
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------
// ✅ AI CHAT CARD (From StaffDashboard)
// ------------------------------------------------------------------
class AiChatAssistantCard extends StatefulWidget {
  final Function(String) onSubmitted;

  const AiChatAssistantCard({super.key, required this.onSubmitted});

  @override
  State<AiChatAssistantCard> createState() => _AiChatAssistantCardState();
}

class _AiChatAssistantCardState extends State<AiChatAssistantCard> {
  final TextEditingController _controller = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isVoiceInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    if (mounted) {
      setState(() {
        _isVoiceInitialized = initialized;
      });
    }

    _voiceService.onSpeechResult = (result) {
      if (mounted) {
        _controller.text = result;
        if (result.isNotEmpty) {
          widget.onSubmitted(result);
        }
      }
    };

    _voiceService.onListeningStateChanged = (isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
        });
      }
    };

    _voiceService.onSpeechError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }

  Future<void> _toggleVoiceListening() async {
    if (!_isVoiceInitialized) return;
    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening();
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001FF4).withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF001FF4),
                    Color(0xFF4F46E5),
                    Color(0xFF7C3AED),
                  ],
                ),
              ),
            ),
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: 10,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                      blurRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EdLab AI Assistant",
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Powered by Gemini 2.0 Pro",
                              style: GoogleFonts.inter(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: _isListening
                                    ? "Listening..."
                                    : "Ask anything about your department...",
                                hintStyle: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              onSubmitted: (val) {
                                if (val.isNotEmpty) widget.onSubmitted(val);
                                _controller.clear();
                              },
                            ),
                          ),
                          GestureDetector(
                            onTap: _isVoiceInitialized
                                ? _toggleVoiceListening
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Colors.redAccent
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (_controller.text.isNotEmpty) {
                                widget.onSubmitted(_controller.text);
                                _controller.clear();
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF001FF4),
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------
// ✅ AI INSIGHT CARD (From StaffDashboard)
// ------------------------------------------------------------------
class AiInsightCard extends StatefulWidget {
  const AiInsightCard({super.key});

  @override
  State<AiInsightCard> createState() => _AiInsightCardState();
}

class _AiInsightCardState extends State<AiInsightCard> {
  double _stability = 0.0;
  int _atRisk = 0;
  int _improving = 0;
  bool _loading = true;
  String _riskLabel = "Calculating...";
  Color _riskColor = const Color(0xFF15803D);
  IconData _riskIcon = Icons.shield_outlined;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    try {
      final db = FirebaseFirestore.instance;
      final snapshot = await db.collection('attendance').get();

      if (snapshot.docs.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final Map<String, List<bool>> studentRecords = {};
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final studentId =
            data['studentId']?.toString() ?? data['regNo']?.toString();
        if (studentId == null) continue;
        final isPresent =
            data['isPresent'] == true || data['status'] == 'present';
        studentRecords.putIfAbsent(studentId, () => []).add(isPresent);
      }

      if (studentRecords.isEmpty) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final List<double> percentages = studentRecords.values.map((records) {
        final present = records.where((p) => p).length;
        return present / records.length;
      }).toList();

      final overall = percentages.reduce((a, b) => a + b) / percentages.length;
      final atRisk = percentages.where((p) => p < 0.75).length;
      final improving = percentages.where((p) => p >= 0.85).length;

      String label;
      Color color;
      IconData icon;
      if (overall >= 0.85) {
        label = "Low Risk";
        color = const Color(0xFF15803D);
        icon = Icons.shield_outlined;
      } else if (overall >= 0.70) {
        label = "Moderate Risk";
        color = const Color(0xFFD97706);
        icon = Icons.warning_amber_rounded;
      } else {
        label = "High Risk";
        color = const Color(0xFFDC2626);
        icon = Icons.crisis_alert_rounded;
      }

      if (mounted) {
        setState(() {
          _stability = overall;
          _atRisk = atRisk;
          _improving = improving;
          _riskLabel = label;
          _riskColor = color;
          _riskIcon = icon;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (_stability * 100).round();
    final gaugeColor = _stability >= 0.85
        ? const Color(0xFF10B981)
        : _stability >= 0.70
        ? const Color(0xFFF59E0B)
        : const Color(0xFFEF4444);

    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: gaugeColor.withOpacity(0.06),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          children: [
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [gaugeColor.withOpacity(0.08), Colors.transparent],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: gaugeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: gaugeColor.withOpacity(0.4),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "AI PREDICTIVE INSIGHTS",
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF94A3B8),
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      _buildRefreshButton(),
                    ],
                  ),
                  const Spacer(),
                  _loading
                      ? const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Row(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 94,
                                  height: 94,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFF1F5F9),
                                      width: 8,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 94,
                                  height: 94,
                                  child: CircularProgressIndicator(
                                    value: _stability,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.transparent,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      gaugeColor,
                                    ),
                                    strokeCap: StrokeCap.round,
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      "$pct%",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF0F172A),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                      ),
                                    ),
                                    Text(
                                      "Stability",
                                      style: GoogleFonts.inter(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _riskColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(100),
                                      border: Border.all(
                                        color: _riskColor.withOpacity(0.1),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          _riskIcon,
                                          color: _riskColor,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _riskLabel,
                                          style: GoogleFonts.inter(
                                            color: _riskColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInsightRow(
                                    Icons.analytics_outlined,
                                    "$_atRisk At-risk detected",
                                    const Color(0xFFF43F5E),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInsightRow(
                                    Icons.show_chart_rounded,
                                    "$_improving Performance up",
                                    const Color(0xFF10B981),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                  const Spacer(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRefreshButton() {
    return InkWell(
      onTap: _loadInsights,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(
          Icons.refresh_rounded,
          color: Color(0xFF94A3B8),
          size: 16,
        ),
      ),
    );
  }

  Widget _buildInsightRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFF64748B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// ✅ LIVE METRIC CAROUSEL (From AdminDashboard)
// ------------------------------------------------------------------
class LiveMetricCarousel extends StatefulWidget {
  final Color baseColor;
  final List<Map<String, dynamic>> dataPoints;

  const LiveMetricCarousel({
    super.key,
    required this.baseColor,
    required this.dataPoints,
  });

  @override
  State<LiveMetricCarousel> createState() => _LiveMetricCarouselState();
}

class _LiveMetricCarouselState extends State<LiveMetricCarousel> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.dataPoints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentData = widget.dataPoints[_currentIndex];
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.baseColor.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: WaveFlowPainter(
                  color: widget.baseColor.withOpacity(0.1),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          (currentData['title'] as String).toUpperCase(),
                          style: GoogleFonts.inter(
                            color: const Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: (currentData['isUp'] as bool)
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              (currentData['isUp'] as bool)
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 12,
                              color: (currentData['isUp'] as bool)
                                  ? const Color(0xFF16A34A)
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentData['percent'],
                              style: GoogleFonts.inter(
                                color: (currentData['isUp'] as bool)
                                    ? const Color(0xFF16A34A)
                                    : Colors.redAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    currentData['count'],
                    style: GoogleFonts.inter(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -1,
                    ),
                  ),
                  Row(
                    children: List.generate(widget.dataPoints.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 4),
                        height: 4,
                        width: _currentIndex == index ? 16 : 6,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? widget.baseColor
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WaveFlowPainter extends CustomPainter {
  final Color color;
  WaveFlowPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.60,
      size.width * 0.5,
      size.height * 0.8,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.95,
      size.width,
      size.height * 0.65,
    );
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
