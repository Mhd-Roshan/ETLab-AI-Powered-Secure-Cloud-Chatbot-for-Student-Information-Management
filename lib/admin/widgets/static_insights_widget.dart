import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:ui';

class StaticInsightsWidget extends StatefulWidget {
  final Function(String)? onInsightTap;
  
  const StaticInsightsWidget({super.key, this.onInsightTap});

  @override
  State<StaticInsightsWidget> createState() => _StaticInsightsWidgetState();
}

class _StaticInsightsWidgetState extends State<StaticInsightsWidget> with TickerProviderStateMixin {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  Map<String, dynamic> _metrics = {};
  bool _isLoading = true;
  bool _isHovered = false;
  Timer? _updateTimer;
  Timer? _hoverTimer;
  AnimationController? _animationController;
  AnimationController? _pulseController;
  Animation<double>? _fadeAnimation;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadData();
    _startPeriodicUpdates();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _pulseController!,
      curve: Curves.easeInOut,
    ));
  }

  void _startPeriodicUpdates() {
    _updateTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _onHoverEnter() {
    setState(() {
      _isHovered = true;
    });
    
    _pulseController?.repeat(reverse: true);
    
    // Start hover timer for auto-refresh
    _hoverTimer?.cancel();
    _hoverTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isHovered && mounted) {
        _loadData(); // Refresh data immediately on hover
      }
    });
  }

  void _onHoverExit() {
    setState(() {
      _isHovered = false;
    });
    
    _pulseController?.stop();
    _pulseController?.reset();
    _hoverTimer?.cancel();
  }

  Future<void> _loadData() async {
    try {
      final studentsSnap = await _db.collection('students').get();
      final staffSnap = await _db.collection('staff').get();
      final feesSnap = await _db.collection('fee_collections').get();
      
      int studentCount = studentsSnap.docs.length;
      int staffCount = staffSnap.docs.length;
      
      double totalFees = 0;
      double totalAttendance = 0;
      int lowAttendanceCount = 0;
      
      for (var doc in studentsSnap.docs) {
        final data = doc.data();
        double attendance = (data['attendancePercentage'] ?? 0).toDouble();
        totalAttendance += attendance;
        if (attendance < 75) lowAttendanceCount++;
      }
      
      for (var doc in feesSnap.docs) {
        totalFees += (doc.data()['amount'] ?? 0).toDouble();
      }
      
      double avgAttendance = studentCount > 0 ? totalAttendance / studentCount : 0;
      
      if (mounted) {
        setState(() {
          _metrics = {
            'students': studentCount,
            'staff': staffCount,
            'attendance': avgAttendance,
            'fees': totalFees,
            'lowAttendance': lowAttendanceCount,
          };
          _isLoading = false;
        });
        _animationController?.forward();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 32,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.8),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Column(
            children: [
              // Modern Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.9),
                      Colors.white.withValues(alpha: 0.7),
                    ],
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade200.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF667EEA),
                            Color(0xFF764BA2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_graph,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      "Analytics",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F2937),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        if (widget.onInsightTap != null) {
                          widget.onInsightTap!("Analyze current university performance with ${_metrics['students'] ?? 0} students, ${_metrics['attendance']?.toStringAsFixed(1) ?? '0'}% attendance");
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF667EEA).withValues(alpha: 0.1),
                              const Color(0xFF764BA2).withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "View Details",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF667EEA),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: Color(0xFF667EEA),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Modern Content - 3 Cards
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667EEA)),
                            ),
                          ),
                        ),
                      )
                    : FadeTransition(
                        opacity: _fadeAnimation ?? const AlwaysStoppedAnimation(1.0),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: [
                              // Card 1: Students
                              Expanded(
                                child: _buildModernCard(
                                  "Students",
                                  _metrics['students']?.toString() ?? "0",
                                  Icons.groups_rounded,
                                  const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                  ),
                                  _getStudentStatus(),
                                  0,
                                ),
                              ),
                              const SizedBox(width: 4),
                              
                              // Card 2: Attendance
                              Expanded(
                                child: _buildModernCard(
                                  "Attendance",
                                  "${_metrics['attendance']?.toStringAsFixed(1) ?? '0'}%",
                                  Icons.verified_rounded,
                                  _getAttendanceGradient(),
                                  _getAttendanceStatus(),
                                  1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              
                              // Card 3: Fees
                              Expanded(
                                child: _buildModernCard(
                                  "Revenue",
                                  "₹${_formatAmount(_metrics['fees'] ?? 0)}",
                                  Icons.trending_up_rounded,
                                  const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [Color(0xFF059669), Color(0xFF10B981)],
                                  ),
                                  "Collected",
                                  2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernCard(String title, String value, IconData icon, LinearGradient gradient, String status, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.elasticOut,
      builder: (context, animationValue, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * animationValue),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: gradient.colors.first.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(height: 2),
                
                // Value
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                
                // Title
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 1),
                
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        gradient.colors.first.withValues(alpha: 0.1),
                        gradient.colors.last.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: gradient.colors.first.withValues(alpha: 0.2),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    status,
                    style: GoogleFonts.inter(
                      fontSize: 5.5,
                      fontWeight: FontWeight.w700,
                      color: gradient.colors.first,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStudentStatus() {
    int count = _metrics['students'] ?? 0;
    if (count > 100) return "EXCELLENT";
    if (count > 50) return "GOOD";
    return "GROWING";
  }

  LinearGradient _getAttendanceGradient() {
    double attendance = _metrics['attendance'] ?? 0;
    if (attendance >= 85) {
      return const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)],
      );
    } else if (attendance >= 75) {
      return const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
      );
    }
    return const LinearGradient(
      colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
    );
  }

  String _getAttendanceStatus() {
    double attendance = _metrics['attendance'] ?? 0;
    if (attendance >= 85) return "EXCELLENT";
    if (attendance >= 75) return "GOOD";
    return "CRITICAL";
  }

  String _formatAmount(double amount) {
    if (amount >= 10000000) {
      return "${(amount / 10000000).toStringAsFixed(1)}Cr";
    } else if (amount >= 100000) {
      return "${(amount / 100000).toStringAsFixed(1)}L";
    } else if (amount >= 1000) {
      return "${(amount / 1000).toStringAsFixed(1)}K";
    }
    return amount.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }
}