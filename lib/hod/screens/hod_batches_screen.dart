import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';
import 'package:edlab/hod/widgets/hod_header.dart';
import 'package:edlab/hod/screens/hod_batch_detail_screen.dart';
import 'package:edlab/services/hod_service.dart';

class HodBatchesScreen extends StatefulWidget {
  final String userId;
  const HodBatchesScreen({super.key, required this.userId});

  @override
  State<HodBatchesScreen> createState() => _HodBatchesScreenState();
}

class _HodBatchesScreenState extends State<HodBatchesScreen> {
  final HodService _hodService = HodService();
  bool _seeding = false;

  @override
  void initState() {
    super.initState();
    _seedIfNeeded();
  }

  /// Auto-seeds Firestore with batch data if the collection is empty.
  Future<void> _seedIfNeeded() async {
    try {
      final snap = await _hodService.getDepartmentBatches('MCA').first;
      if (snap.docs.isEmpty) {
        if (mounted) setState(() => _seeding = true);
        await _hodService.seedBatches();
        await _hodService.seedBatchStudents();
        if (mounted) setState(() => _seeding = false);
      }
    } catch (_) {
      if (mounted) setState(() => _seeding = false);
    }
  }

  /// Maps a hex string stored in Firestore to a Flutter Color.
  Color _hexToColor(String hex) {
    final cleaned = hex.replaceAll('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HodSidebar(activeIndex: -1, userId: widget.userId),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _hodService.getDepartmentBatches('MCA'),
              builder: (context, snapshot) {
                final batches = snapshot.hasData
                    ? snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return {
                          ...data,
                          'id': doc.id,
                          'color': _hexToColor(
                            data['colorHex'] as String? ?? '6366F1',
                          ),
                        };
                      }).toList()
                    : <Map<String, dynamic>>[];

                final activeBatches = batches
                    .where((b) => b['status'] == 'Active')
                    .length;
                final totalStudents = batches.fold<int>(
                  0,
                  (sum, b) =>
                      sum + ((b['totalStudents'] as num?)?.toInt() ?? 0),
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(40, 32, 40, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HodHeader(
                        title: "Department Batches",
                        subtitle: "MCA — Master of Computer Applications",
                        userId: widget.userId,
                      ),
                      const SizedBox(height: 32),

                      // --- Stats Row ---
                      Row(
                        children: [
                          _buildStatCard(
                            "Total Batches",
                            batches.isEmpty
                                ? '—'
                                : batches.length.toString().padLeft(2, '0'),
                            Icons.layers_rounded,
                            const Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 24),
                          _buildStatCard(
                            "Total Students",
                            batches.isEmpty ? '—' : totalStudents.toString(),
                            Icons.groups_rounded,
                            const Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 24),
                          _buildStatCard(
                            "Active Batches",
                            batches.isEmpty
                                ? '—'
                                : activeBatches.toString().padLeft(2, '0'),
                            Icons.calendar_today_rounded,
                            const Color(0xFF10B981),
                          ),
                        ],
                      ),

                      const SizedBox(height: 48),

                      Text(
                        "MCA BATCH DIRECTORY",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF94A3B8),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Loading or seeding state
                      if (_seeding ||
                          snapshot.connectionState ==
                              ConnectionState.waiting) ...[
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(48),
                            child: Column(
                              children: [
                                const CircularProgressIndicator(
                                  color: Color(0xFF6366F1),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _seeding
                                      ? 'Setting up batch data…'
                                      : 'Loading batches…',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ] else if (batches.isEmpty) ...[
                        Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.layers_outlined,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No batches found',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF94A3B8),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap the button below to load batch data.',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFFCBD5E1),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() => _seeding = true);
                                  await _hodService.seedBatches();
                                  await _hodService.seedBatchStudents();
                                  if (mounted) setState(() => _seeding = false);
                                },
                                icon: const Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 18,
                                ),
                                label: Text(
                                  'Load Batch Data',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                mainAxisExtent: 220,
                              ),
                          itemCount: batches.length,
                          itemBuilder: (context, index) {
                            final batch = batches[index];
                            return _buildBatchCard(batch);
                          },
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchCard(Map<String, dynamic> batch) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HodBatchDetailScreen(batch: batch, userId: widget.userId),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (batch['color'] as Color).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        batch['semester'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: batch['color'] as Color,
                        ),
                      ),
                    ),
                    Icon(
                      batch['status'] == 'Active'
                          ? Icons.check_circle_rounded
                          : Icons.history_rounded,
                      size: 18,
                      color: batch['status'] == 'Active'
                          ? const Color(0xFF10B981)
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  batch['name'],
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Coordinator: ${batch['coordinator']}",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(
                      Icons.people_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${batch['totalStudents']} Students",
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
