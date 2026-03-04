import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/hod/screens/hod_batches_screen.dart';
import 'package:edlab/hod/screens/hod_staff_screen.dart';

class HodWorkspaceGrid extends StatelessWidget {
  final String userId;
  const HodWorkspaceGrid({super.key, this.userId = 'hod@gmail.com'});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> items = [
      {
        'icon': Icons.groups_rounded,
        'label': 'Batches',
        'color': const Color(0xFF6366F1),
        'route': HodBatchesScreen(userId: userId),
      },
      {
        'icon': Icons.grid_view_rounded,
        'label': 'Subject Pool',
        'color': const Color(0xFFA855F7),
        'route': null,
      },
      {
        'icon': Icons.view_list_rounded,
        'label': 'My Subjects',
        'color': const Color(0xFFFCD34D),
        'route': null,
      },
      {
        'icon': Icons.forum_rounded,
        'label': 'Chat Room',
        'color': const Color(0xFF10B981),
        'route': null,
      },
      {
        'icon': Icons.badge_rounded,
        'label': 'Staff',
        'color': const Color(0xFFEC4899),
        'route': HodStaffScreen(userId: userId),
      },
      {
        'icon': Icons.public_rounded,
        'label': 'Website',
        'color': const Color(0xFF3B82F6),
        'route': null,
      },
      {
        'icon': Icons.folder_rounded,
        'label': 'Class Material',
        'color': const Color(0xFF84CC16),
        'route': null,
      },
      {
        'icon': Icons.school_rounded,
        'label': 'Faculty',
        'color': const Color(0xFFF59E0B),
        'route': null,
      },
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: items
          .map((item) => _buildModernGridItem(context, item))
          .toList(),
    );
  }

  Widget _buildModernGridItem(BuildContext context, Map<String, dynamic> item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (item['route'] != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => item['route']),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("${item['label']} screen coming soon!"),
                behavior: SnackBarBehavior.floating,
                margin: const EdgeInsets.all(20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        },
        borderRadius: BorderRadius.circular(32),
        child: Container(
          width: 175,
          height: 150,
          decoration: const BoxDecoration(color: Colors.transparent),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: (item['color'] as Color).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'], color: item['color'], size: 36),
              ),
              const SizedBox(height: 16),
              Text(
                item['label'],
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
