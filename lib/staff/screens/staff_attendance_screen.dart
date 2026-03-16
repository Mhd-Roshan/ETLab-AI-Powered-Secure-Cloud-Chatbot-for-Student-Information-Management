import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:edlab/staff/widgets/staff_sidebar.dart';
import 'package:edlab/staff/widgets/staff_header.dart';

class StaffAttendanceScreen extends StatefulWidget {
  final String userId;
  const StaffAttendanceScreen({super.key, required this.userId});

  @override
  State<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends State<StaffAttendanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();

  static const String _subject = 'DIGITAL FUNDAMENTALS & COMP. ARCH.';



  // MCA Timetable: weekday -> list of subjects per period (7 periods)
  // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
  static const Map<int, List<String>> _mcaTimetable = {
    1: ['DIGITAL FUNDAMENTALS & COMP. ARCH.'],
    2: ['DIGITAL FUNDAMENTALS & COMP. ARCH.'],
    3: ['DIGITAL FUNDAMENTALS & COMP. ARCH.'],
    4: ['DIGITAL FUNDAMENTALS & COMP. ARCH.'],
    5: ['DIGITAL FUNDAMENTALS & COMP. ARCH.'],
    6: ['DIGITAL FUNDAMENTALS & COMP. ARCH.'],
    7: ['-'],
  };

  /// Returns the list of periods (1-indexed) where DIGITAL FUNDAMENTALS is scheduled for a given date
  List<int> _getDigitalFundamentalsPeriods(DateTime date) {
    final subjects = _mcaTimetable[date.weekday] ?? [];
    List<int> periods = [];
    for (int i = 0; i < subjects.length; i++) {
      if (subjects[i].contains('DIGITAL FUNDAMENTALS')) {
        periods.add(i + 1); // 1-indexed
      }
    }
    return periods;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StaffSidebar(activeIndex: -1, userId: widget.userId),
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: StaffHeader(
                    title: "Attendance",
                    showBackButton: false,
                    userId: widget.userId,
                  ),
                ),
                _buildTabs(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAddAttendanceTab(),
                      _buildViewAttendanceTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      color: const Color(0xFFF8FAFC),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
          ),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: const Color(0xFF001FF4),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          indicatorColor: const Color(0xFF001FF4),
          tabs: const [
            Tab(
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 18),
                  SizedBox(width: 8),
                  Text("Add Attendance"),
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 18),
                  SizedBox(width: 8),
                  Text("View Attendance"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ADD ATTENDANCE TAB ─────────────────────────────
  Widget _buildAddAttendanceTab() {
    final scheduledPeriods = _getDigitalFundamentalsPeriods(_selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date controls
          _buildDateAndControls(),
          const SizedBox(height: 24),

          // Subject info badge
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEFF6FF), Color(0xFFF0EDFF)],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF001FF4),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _subject,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E293B),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "MCA • ${DateFormat('EEEE').format(_selectedDate)} • ${scheduledPeriods.isEmpty ? 'No class today' : '${scheduledPeriods.length} period(s) scheduled'}",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Show a single Daily Attendance card OR "no class" message
          if (scheduledPeriods.isEmpty)
            _buildNoClassMessage()
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildPeriodCard(
                scheduledPeriods.first,
              ), // Just show one card
            ),

          // Existing attendance records for this date
          const SizedBox(height: 8),
          _buildExistingAttendanceForDate(),
        ],
      ),
    );
  }

  Widget _buildNoClassMessage() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event_busy_rounded, size: 56, color: Colors.grey[300]),
            const SizedBox(height: 14),
            Text(
              "No ${_subject.split(' ').take(2).join(' ')} class on ${DateFormat('EEEE').format(_selectedDate)}",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Try Monday (Period 1) or Tuesday (Period 5)",
              style: GoogleFonts.inter(
                color: const Color(0xFFCBD5E1),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodCard(int period) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Period number badge
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF001FF4), Color(0xFF4338CA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF001FF4).withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "DAILY",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Daily Attendance",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    fontSize: 16,
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      size: 14,
                      color: Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Full Day Session",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dynamic button based on whether attendance is already taken
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('attendance')
                .where('subject', isEqualTo: _subject)
                .snapshots(),
            builder: (context, snapshot) {
              // Filter by date client-side to avoid composite index requirement
              final startOfDay = DateTime(
                _selectedDate.year,
                _selectedDate.month,
                _selectedDate.day,
              );
              final endOfDay = startOfDay.add(const Duration(days: 1));

              bool alreadyTaken = false;
              if (snapshot.hasData) {
                alreadyTaken = snapshot.data!.docs.any((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (data['date'] == null) return false;
                  final docDate = (data['date'] as Timestamp).toDate();
                  return !docDate.isBefore(startOfDay) &&
                      docDate.isBefore(endOfDay);
                });
              }

              if (alreadyTaken) {
                return OutlinedButton.icon(
                  onPressed: () => _showStudentListDialog(
                    context,
                    _subject,
                    _selectedDate,
                    1, // Fixed period
                  ),
                  icon: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF166534),
                    size: 16,
                  ),
                  label: Text(
                    "Submitted",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF166534),
                      fontSize: 12,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFDCFCE7),
                    side: const BorderSide(color: Color(0xFF86EFAC)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                );
              }

              return ElevatedButton.icon(
                onPressed: () => _showStudentListDialog(
                  context,
                  _subject,
                  _selectedDate,
                  1, // Fixed period
                ),
                icon: const Icon(Icons.edit_note_rounded, size: 18),
                label: Text(
                  "Take Attendance",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF001FF4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateAndControls() {
    final isToday = DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date display
          GestureDetector(
            onTap: () => _pickDate(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF001FF4), Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF001FF4).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE').format(_selectedDate),
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat('dd MMM yyyy').format(_selectedDate),
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Quick date buttons
          _buildQuickDateButton(
            "Today",
            isToday,
            () => setState(() => _selectedDate = DateTime.now()),
          ),
          const SizedBox(width: 8),
          _buildQuickDateButton(
            "Yesterday",
            DateUtils.isSameDay(
              _selectedDate,
              DateTime.now().subtract(const Duration(days: 1)),
            ),
            () => setState(
              () => _selectedDate = DateTime.now().subtract(
                const Duration(days: 1),
              ),
            ),
          ),

          const Spacer(),

          // Navigation arrows
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => setState(
                    () => _selectedDate = _selectedDate.subtract(
                      const Duration(days: 1),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: const Color(0xFF64748B),
                  tooltip: "Previous Day",
                ),
                Container(width: 1, height: 24, color: const Color(0xFFE2E8F0)),
                IconButton(
                  onPressed: () => setState(
                    () => _selectedDate = _selectedDate.add(
                      const Duration(days: 1),
                    ),
                  ),
                  icon: const Icon(Icons.chevron_right_rounded),
                  color: const Color(0xFF64748B),
                  tooltip: "Next Day",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickDateButton(
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? const Color(0xFF001FF4).withValues(alpha: 0.3)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: isActive ? const Color(0xFF001FF4) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildExistingAttendanceForDate() {
    final startOfDay = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('attendance').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  "No attendance recorded for ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Click \"Take Attendance\" to start marking",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter by date and exclude HOD records client-side
        final filteredDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['date'] == null) return false;

          // Exclude HOD records from staff view
          if (data['markedBy'] == 'HOD') return false;

          final docDate = (data['date'] as Timestamp).toDate();
          return !docDate.isBefore(startOfDay) && docDate.isBefore(endOfDay);
        }).toList();

        if (filteredDocs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: Colors.grey[300],
                ),
                const SizedBox(height: 12),
                Text(
                  "No attendance recorded for ${DateFormat('dd MMM yyyy').format(_selectedDate)}",
                  style: GoogleFonts.inter(
                    color: const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Click \"Take Attendance\" to start marking",
                  style: GoogleFonts.inter(
                    color: const Color(0xFFCBD5E1),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        }

        // Group attendance by period & subject
        final Map<String, Map<String, dynamic>> periodGroups = {};
        for (var doc in filteredDocs) {
          final data = doc.data() as Map<String, dynamic>;
          final subject = data['subject']?.toString() ?? 'Unknown';
          final key = subject; // Group by subject only for daily view

          if (!periodGroups.containsKey(key)) {
            periodGroups[key] = {
              'period': 'Daily',
              'subject': subject,
              'total': 0,
              'present': 0,
            };
          }
          periodGroups[key]!['total'] =
              (periodGroups[key]!['total'] as int) + 1;
          if (data['isPresent'] == true) {
            periodGroups[key]!['present'] =
                (periodGroups[key]!['present'] as int) + 1;
          }
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: periodGroups.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final key = periodGroups.keys.elementAt(index);
            final group = periodGroups[key]!;
            final total = group['total'] as int;
            final present = group['present'] as int;
            final absent = total - present;
            final percentage = total > 0 ? (present / total * 100) : 0.0;

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  // Period badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        "Daily",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF001FF4),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group['subject'] as String,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E293B),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildSmallBadge(
                              "$present",
                              const Color(0xFF10B981),
                              "Present",
                            ),
                            const SizedBox(width: 8),
                            _buildSmallBadge(
                              "$absent",
                              const Color(0xFFEF4444),
                              "Absent",
                            ),
                            const SizedBox(width: 8),
                            _buildSmallBadge(
                              "$total",
                              const Color(0xFF64748B),
                              "Total",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Percentage
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${percentage.toStringAsFixed(0)}%",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          color: percentage >= 75
                              ? const Color(0xFF10B981)
                              : percentage >= 60
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFEF4444),
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        "attendance",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Edit button - only enabled for today
                  Builder(
                    builder: (context) {
                      final isToday = DateUtils.isSameDay(
                        _selectedDate,
                        DateTime.now(),
                      );
                      final periodNum =
                          int.tryParse(group['period'].toString()) ?? 1;

                      if (isToday) {
                        return GestureDetector(
                          onTap: () => _showStudentListDialog(
                            context,
                            group['subject'] as String,
                            _selectedDate,
                            periodNum,
                          ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: const Color(
                                  0xFF001FF4,
                                ).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.edit_rounded,
                                  color: Color(0xFF001FF4),
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Edit",
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF001FF4),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      } else {
                        return Tooltip(
                          message:
                              "Attendance can only be edited on the same day",
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lock_rounded,
                              color: Color(0xFF94A3B8),
                              size: 16,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSmallBadge(String value, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          "$value $label",
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF001FF4),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  // ─── VIEW ATTENDANCE TAB ────────────────────────────
  String _searchQuery = "";

  Widget _buildViewAttendanceTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                ),
              ],
            ),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                icon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF64748B),
                ),
                hintText: "Search MCA Students by name or register number...",
                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('role', isEqualTo: 'student')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No students found in MCA",
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final allStudents = snapshot.data!.docs;
              final filteredStudents = allStudents.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                String name = (data['name'] ?? "").toString();
                if (name.isEmpty) {
                  final fName = (data['firstName'] ?? data['firstname'] ?? "")
                      .toString();
                  final lName = (data['lastName'] ?? data['lastname'] ?? "")
                      .toString();
                  name = "$fName $lName".trim();
                }
                final lowerName = name.toLowerCase();
                final regNo = (data['regNo'] ?? doc.id)
                    .toString()
                    .toLowerCase();
                return lowerName.contains(_searchQuery.toLowerCase()) ||
                    regNo.contains(_searchQuery.toLowerCase());
              }).toList();

              List<Map<String, dynamic>> finalDisplayList = filteredStudents
                  .map(
                    (doc) => <String, dynamic>{
                      'id': (doc.data() as Map<String, dynamic>)['username']?.toString() ?? doc.id,
                      'data': doc.data() as Map<String, dynamic>,
                    },
                  )
                  .toList();

              // Sort by name for better arrangement
              finalDisplayList.sort((a, b) {
                final nameA = (a['data'] as Map<String, dynamic>)['name']?.toString() ?? 
                            (a['data'] as Map<String, dynamic>)['fullName']?.toString() ?? '';
                final nameB = (b['data'] as Map<String, dynamic>)['name']?.toString() ?? 
                            (b['data'] as Map<String, dynamic>)['fullName']?.toString() ?? '';
                return nameA.toLowerCase().compareTo(nameB.toLowerCase());
              });

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                itemCount: finalDisplayList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = finalDisplayList[index];
                  final student = item['data'] as Map<String, dynamic>;
                  final docId = item['id'] as String;

                  final firstName = student['firstname']?.toString() ??
                      student['firstName']?.toString() ?? '';
                  final lName = student['lastname']?.toString() ??
                      student['lastName']?.toString() ?? '';
                  String name = student['fullName']?.toString() ??
                      student['name']?.toString() ??
                      '$firstName $lName'.trim();
                  if (name.isEmpty) name = 'Unknown';

                  final regNo = student['username']?.toString() ?? docId;

                  return _buildStudentAttendanceCard(docId, name, regNo);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStudentAttendanceCard(String docId, String name, String regNo) {
    const int targetClasses = 50;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('attendance')
          .where('studentId', isEqualTo: regNo)
          .where('subject', isEqualTo: _subject)
          .snapshots(),
      builder: (context, snapshot) {
        int presentCount = 0;
        int totalConducted = 0;

        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalConducted = docs.length;
          presentCount = docs
              .where((d) =>
                  (d.data() as Map<String, dynamic>)['isPresent'] == true)
              .length;
        }

        final double attendancePct =
            totalConducted > 0 ? (presentCount / totalConducted) * 100 : 0;

        final Color pctColor = attendancePct >= 85
            ? const Color(0xFF10B981)
            : attendancePct >= 75
                ? const Color(0xFFF59E0B)
                : const Color(0xFFEF4444);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: pctColor.withValues(alpha: 0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w800,
                        color: pctColor,
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
                          name,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E293B),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                regNo,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF64748B),
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "${attendancePct.toStringAsFixed(1)}%",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w900,
                          color: pctColor,
                          fontSize: 22,
                        ),
                      ),
                      Text(
                        "$presentCount / $totalConducted sessions",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Progress bars
              Row(
                children: [
                  Expanded(
                    flex: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Attendance",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              "${attendancePct.toStringAsFixed(0)}%",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: pctColor,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: attendancePct / 100,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Course Progress",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF64748B),
                                fontSize: 11,
                              ),
                            ),
                            Text(
                              "$totalConducted / $targetClasses",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalConducted / targetClasses,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF001FF4),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildPercentageData(double percentage, int total, [int? present]) {
    Color color;
    if (percentage >= 75) {
      color = const Color(0xFF10B981);
    } else if (percentage >= 65) {
      color = const Color(0xFFF59E0B);
    } else {
      color = const Color(0xFFEF4444);
    }

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${percentage.toStringAsFixed(1)}%",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                color: color,
                fontSize: 18,
              ),
            ),
            Text(
              present != null ? "$present/$total Classes" : "$total Classes",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(
            value: total == 0 ? 0 : percentage / 100,
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeWidth: 4,
            strokeCap: StrokeCap.round,
          ),
        ),
      ],
    );
  }

  // ─── ATTENDANCE MARKING DIALOG ──────────────────────
  void _showStudentListDialog(
    BuildContext context,
    String subject,
    DateTime date,
    int period,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return _AttendanceMarkingDialog(
          subject: subject,
          date: date,
          period: period,
          department: "MCA",
        );
      },
    );
  }
}

class _AttendanceMarkingDialog extends StatefulWidget {
  final String subject;
  final DateTime date;
  final int period;
  final String department;

  const _AttendanceMarkingDialog({
    required this.subject,
    required this.date,
    required this.period,
    required this.department,
  });

  @override
  State<_AttendanceMarkingDialog> createState() =>
      _AttendanceMarkingDialogState();
}

class _AttendanceMarkingDialogState extends State<_AttendanceMarkingDialog> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Map<String, bool> _attendance = {};
  bool _isLoading = false;
  String _filter = "All";

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.subject,
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "${DateFormat('dd MMM yyyy').format(widget.date)} • Period ${widget.period} • ${widget.department}",
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildFilterChip("All", "All"),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "P: ${_attendance.values.where((v) => v).length}",
                        "Present",
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        "A: ${_attendance.values.where((v) => !v).length}",
                        "Absent",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Student List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No students found",
                            style: TextStyle(color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    );
                  }

                  final allStudents = snapshot.data!.docs;

                  // Use username as the key for attendance tracking
                  if (_attendance.isEmpty) {
                    for (var s in allStudents) {
                      final data = s.data() as Map<String, dynamic>;
                      final username = data['username']?.toString() ?? s.id;
                      _attendance[username] = true;
                    }
                  }

                  List<Map<String, dynamic>> finalDisplayList = [];

                  for (var doc in allStudents) {
                    final data = doc.data() as Map<String, dynamic>;
                    final username = data['username']?.toString() ?? doc.id;
                    final isPresent = _attendance[username] ?? true;
                    if (_filter == "Present" && !isPresent) continue;
                    if (_filter == "Absent" && isPresent) continue;

                    finalDisplayList.add(<String, dynamic>{
                      'id': username,
                      'data': data,
                    });
                  }

                  if (finalDisplayList.isEmpty) {
                    return Center(
                      child: Text(
                        "No students $_filter",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: finalDisplayList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = finalDisplayList[index];
                      final student = item['data'] as Map<String, dynamic>;
                      final docId = item['id'] as String;
                      final firstName = student['firstname']?.toString() ??
                          student['firstName']?.toString() ?? '';
                      final lastName = student['lastname']?.toString() ??
                          student['lastName']?.toString() ?? '';
                      String name = student['fullName']?.toString() ??
                          student['name']?.toString() ??
                          '$firstName $lastName'.trim();
                      if (name.isEmpty) name = 'Unknown';

                      final regNo = student['username']?.toString() ?? docId;
                      final isPresent = _attendance[docId] ?? true;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFFF1F5F9),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : "?",
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF64748B),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1E293B),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    regNo,
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF94A3B8),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _attendance[docId] = false,
                                  ),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: !isPresent
                                          ? const Color(0xFFFEE2E2)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: !isPresent
                                            ? const Color(0xFFFECACA)
                                            : const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: !isPresent
                                          ? const Color(0xFFEF4444)
                                          : const Color(0xFF94A3B8),
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () =>
                                      setState(() => _attendance[docId] = true),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isPresent
                                          ? const Color(0xFFDCFCE7)
                                          : Colors.transparent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isPresent
                                            ? const Color(0xFF86EFAC)
                                            : const Color(0xFFF1F5F9),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: isPresent
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF94A3B8),
                                      size: 20,
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
                },
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(24),
              color: const Color(0xFFF8FAFC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () =>
                        setState(() => _attendance.updateAll((_, __) => true)),
                    child: Text(
                      "Mark All Present",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveAttendance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF001FF4),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Save Attendance",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterValue) {
    final isActive = _filter == filterValue;
    Color bgColor;
    Color borderColor;
    Color textColor;

    switch (filterValue) {
      case "Present":
        bgColor = isActive ? const Color(0xFFDCFCE7) : Colors.transparent;
        borderColor = isActive
            ? const Color(0xFF166534)
            : const Color(0xFFE2E8F0);
        textColor = isActive
            ? const Color(0xFF14532D)
            : const Color(0xFF64748B);
        break;
      case "Absent":
        bgColor = isActive ? const Color(0xFFFEE2E2) : Colors.transparent;
        borderColor = isActive
            ? const Color(0xFFEF4444)
            : const Color(0xFFE2E8F0);
        textColor = isActive
            ? const Color(0xFF7F1D1D)
            : const Color(0xFF64748B);
        break;
      default:
        bgColor = isActive ? const Color(0xFFEFF6FF) : Colors.transparent;
        borderColor = isActive
            ? const Color(0xFF3B82F6)
            : const Color(0xFFE2E8F0);
        textColor = isActive
            ? const Color(0xFF1E40AF)
            : const Color(0xFF64748B);
    }

    return GestureDetector(
      onTap: () => setState(() => _filter = filterValue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: textColor,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAttendance() async {
    setState(() => _isLoading = true);

    try {
      final existingQuery = await _db
          .collection('attendance')
          .where('subject', isEqualTo: widget.subject)
          .get();

      // Filter by date client-side to avoid composite index requirement
      final startOfDay = DateTime(
        widget.date.year,
        widget.date.month,
        widget.date.day,
      );
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final existingRecords = existingQuery.docs.where((doc) {
        final data = doc.data();
        if (data['date'] == null) return false;
        final docDate = (data['date'] as Timestamp).toDate();
        return docDate.isAfter(
              startOfDay.subtract(const Duration(seconds: 1)),
            ) &&
            docDate.isBefore(endOfDay);
      }).toList();

      final batch = _db.batch();

      // 2. Delete existing records to prevent duplication
      for (var doc in existingRecords) {
        batch.delete(doc.reference);
      }

      // 3. Save new attendance data
      _attendance.forEach((studentId, isPresent) {
        final docRef = _db.collection('attendance').doc();
        batch.set(docRef, {
          'date': widget.date,
          'period': 1, // Store as period 1 for daily consistency
          'subject': widget.subject,
          'subjectName': widget.subject,
          'department': widget.department,
          'studentId': studentId,
          'isPresent': isPresent,
          'markedBy': 'Staff',
          'timestamp': FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "✅ Attendance saved for ${widget.subject} - ${DateFormat('dd MMM yyyy').format(widget.date)}",
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
