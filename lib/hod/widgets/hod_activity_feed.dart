import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:edlab/services/staff_service.dart';

class HodActivityFeed extends StatelessWidget {
  final String department;
  const HodActivityFeed({super.key, this.department = 'MCA'});

  @override
  Widget build(BuildContext context) {
    final StaffService service = StaffService();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "DEPARTMENTAL FEED",
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
            _buildLiveStatus(),
          ],
        ),
        const SizedBox(height: 16),
        _buildDepartmentSummary(),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot>(
          stream: service.getHodActivities(department: department),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoading();
            }

            final now = DateTime.now();
            final startOfToday = DateTime(now.year, now.month, now.day);

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            // Filter for today's activities
            final todayDocs = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final ts = data['timestamp'] as Timestamp?;
              return ts != null && ts.toDate().isAfter(startOfToday);
            }).toList();

            if (todayDocs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(40),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 48,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No activities for today yet",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      "New activities will appear here as they happen.",
                      style: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: todayDocs.length,
              itemBuilder: (context, index) {
                final doc = todayDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildActivityCard(context, data);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveStatus() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "LIVE UPDATES",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF16A34A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentSummary() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildMiniStat(
            'Active Assignments',
            '12',
            const Color(0xFF6366F1),
            Icons.assignment_rounded,
          ),
          const SizedBox(width: 16),
          _buildMiniStat(
            'Staff Active',
            '85%',
            const Color(0xFF10B981),
            Icons.people_rounded,
          ),
          const SizedBox(width: 16),
          _buildMiniStat(
            'Exam Progress',
            'Mid-Term',
            const Color(0xFFF59E0B),
            Icons.school_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return Column(
      children: List.generate(
        3,
        (index) => Container(
          height: 80,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(Icons.feed_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No recent activities found",
            style: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context, Map<String, dynamic> data) {
    final title = data['title'] ?? 'Update';
    final subtitle = data['subtitle'] ?? '';
    final timestamp = data['timestamp'] as Timestamp?;
    final iconName = data['icon'] ?? 'circle';

    String timeStr = 'Recently';
    if (timestamp != null) {
      final dt = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours}h ago';
      } else {
        timeStr = DateFormat('MMM d').format(dt);
      }
    }

    final Color accentColor = _getAccentColor(iconName);
    final IconData icon = _getIcon(iconName);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 6, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: accentColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(icon, color: accentColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getCategoryLabel(iconName),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: accentColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  timeStr,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                            if (subtitle.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                subtitle,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
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
      ),
    );
  }

  Color _getAccentColor(String iconName) {
    switch (iconName) {
      case 'assignment':
        return const Color(0xFF6366F1);
      case 'people':
        return const Color(0xFF10B981);
      case 'check_circle':
        return const Color(0xFF8B5CF6);
      case 'school':
        return const Color(0xFFF59E0B);
      case 'announcement':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFF64748B);
    }
  }

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'assignment':
        return Icons.assignment_outlined;
      case 'people':
        return Icons.people_outline_rounded;
      case 'check_circle':
        return Icons.check_circle_outline_rounded;
      case 'school':
        return Icons.school_outlined;
      case 'announcement':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _getCategoryLabel(String iconName) {
    switch (iconName) {
      case 'assignment':
        return 'ACADEMIC UPDATE';
      case 'people':
        return 'STAFF ACTIVITY';
      case 'check_circle':
        return 'COMPLETED';
      case 'school':
        return 'STAFF NEWS';
      case 'announcement':
        return 'URGENT';
      default:
        return 'GENERAL';
    }
  }
}
