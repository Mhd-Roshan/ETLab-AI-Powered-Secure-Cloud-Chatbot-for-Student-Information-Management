import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';
import 'package:edlab/hod/widgets/hod_header.dart';
import 'package:intl/intl.dart';

class HodTimetableScreen extends StatelessWidget {
  final String userId;
  const HodTimetableScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSidebar(activeIndex: 3, userId: userId),
          Expanded(
            child: Stack(
              children: [
                // --- Premium Aurora Background ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 300,
                  child: Container(
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
                ),

                // --- Main Content ---
                SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HodHeader(title: "My Timetable", userId: userId),
                      const SizedBox(height: 60),

                      // Timetable Content
                      _buildTimetableGrid(),
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

  Widget _buildTimetableGrid() {
    final String currentDay = DateFormat('EEEE').format(DateTime.now());

    return Column(
      children: [
        _buildDaySection(
          "Monday",
          [
            _TimetableEntry(
              "10:00 AM",
              "11:00 AM",
              "Data Structure",
              "Room 502",
              const Color(0xFF001FF4),
            ),
            _TimetableEntry(
              "02:00 PM",
              "03:00 PM",
              "Data Structure",
              "Room 502",
              const Color(0xFF6366F1),
            ),
          ],
          isOnHeader: true,
          isToday: currentDay == "Monday",
        ),
        _buildDaySection("Tuesday", [
          _TimetableEntry(
            "11:00 AM",
            "12:30 PM",
            "Data Structure",
            "Room 502",
            const Color(0xFF8B5CF6),
          ),
        ], isToday: currentDay == "Tuesday"),
        _buildDaySection("Wednesday", [
          _TimetableEntry(
            "10:00 AM",
            "11:00 AM",
            "Data Structure",
            "Room 502",
            const Color(0xFFEC4899),
          ),
        ], isToday: currentDay == "Wednesday"),
        _buildDaySection("Thursday", [
          _TimetableEntry(
            "02:00 PM",
            "03:30 PM",
            "Data Structure",
            "Room 502",
            const Color(0xFFF59E0B),
          ),
        ], isToday: currentDay == "Thursday"),
        _buildDaySection("Friday", [
          _TimetableEntry(
            "09:30 AM",
            "10:30 AM",
            "Data Structure",
            "Room 502",
            const Color(0xFF10B981),
          ),
        ], isToday: currentDay == "Friday"),
      ],
    );
  }

  Widget _buildDaySection(
    String day,
    List<_TimetableEntry> entries, {
    bool isOnHeader = false,
    bool isToday = false,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Indicator Column
          SizedBox(
            width: 16,
            child: Column(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isToday
                        ? const Color(0xFF001FF4)
                        : const Color(0xFFE2E8F0),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      if (isToday)
                        BoxShadow(
                          color: const Color(0xFF001FF4).withOpacity(0.3),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                    ],
                  ),
                  child: isToday
                      ? Center(
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        )
                      : null,
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: const Color(0xFFE2E8F0).withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Content Column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: isOnHeader ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 8),
                ...entries.map((e) => _buildPremiumEntryCard(e)).toList(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumEntryCard(_TimetableEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 226, 228, 233).withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 6,
              height: 100,
              decoration: BoxDecoration(color: entry.color),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: entry.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            entry.startTime,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: entry.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "to ${entry.endTime}",
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 32),
                    Container(
                      width: 1,
                      height: 40,
                      color: const Color(0xFFF1F5F9),
                    ),
                    const SizedBox(width: 32),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.subject,
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E293B),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: entry.color.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                entry.location,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
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

class _TimetableEntry {
  final String startTime;
  final String endTime;
  final String subject;
  final String location;
  final Color color;

  _TimetableEntry(
    this.startTime,
    this.endTime,
    this.subject,
    this.location,
    this.color,
  );
}
