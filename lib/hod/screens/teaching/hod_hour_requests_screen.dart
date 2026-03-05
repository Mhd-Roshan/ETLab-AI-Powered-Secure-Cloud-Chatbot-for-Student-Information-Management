import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';

class HodHourRequestsScreen extends StatefulWidget {
  final String userId;
  const HodHourRequestsScreen({super.key, required this.userId});

  @override
  State<HodHourRequestsScreen> createState() => _HodHourRequestsScreenState();
}

class _HodHourRequestsScreenState extends State<HodHourRequestsScreen> {
  final TextEditingController _subFromController = TextEditingController();
  final TextEditingController _hourController = TextEditingController();
  String _statusFilter = 'select';
  String _batchFilter = 'select';
  DateTime _fromDate = DateTime(2026, 3, 2);
  DateTime _toDate = DateTime(2026, 3, 5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // --- Dynamic Aurora Background ---
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFEEF2FF),
                    Color(0xFFF1F5F9),
                    Color(0xFFE0E7FF),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _AuroraPainter())),

          Row(
            children: [
              HodSidebar(activeIndex: 5, userId: widget.userId),
              Expanded(
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(48),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- Modern Header ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.home_outlined,
                                        size: 16,
                                        color: Color(0xFF6366F1),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        size: 16,
                                        color: Color(0xFFCBD5E1),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "HOUR REQUESTS",
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: const Color(0xFF6366F1),
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Schedule & Hour Management",
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              _actionButton(
                                Icons.add_rounded,
                                "New Request",
                                const Color(0xFF6366F1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),

                          // --- Stats Row (Modern touch) ---
                          Row(
                            children: [
                              _statCard(
                                "Pending",
                                "12",
                                const Color(0xFFF59E0B),
                                Icons.pending_actions_rounded,
                              ),
                              const SizedBox(width: 24),
                              _statCard(
                                "Approved",
                                "45",
                                const Color(0xFF10B981),
                                Icons.check_circle_outline_rounded,
                              ),
                              const SizedBox(width: 24),
                              _statCard(
                                "Substitute",
                                "03",
                                const Color(0xFF6366F1),
                                Icons.swap_horiz_rounded,
                              ),
                            ],
                          ),
                          const SizedBox(height: 56),

                          // --- Section 1: Requests From Other Staff ---
                          _buildModernRequestSection(
                            title: "Staff Substitution Requests",
                            isByMe: false,
                          ),

                          const SizedBox(height: 48),

                          // --- Section 2: Requests By You ---
                          _buildModernRequestSection(
                            title: "Requests Initiated by You",
                            isByMe: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF64748B),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModernRequestSection({
    required String title,
    required bool isByMe,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.table_chart_rounded,
                    size: 20,
                    color: Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),

          // Filters Modern Panels
          Padding(
            padding: const EdgeInsets.all(32),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 5,
              crossAxisSpacing: 32,
              mainAxisSpacing: 20,
              children: [
                _buildModernFilterItem(
                  "Status",
                  _buildModernDropdown(
                    _statusFilter,
                    (v) => setState(() => _statusFilter = v!),
                  ),
                ),
                _buildModernFilterItem(
                  "Batch",
                  _buildModernDropdown(
                    _batchFilter,
                    (v) => setState(() => _batchFilter = v!),
                  ),
                ),
                _buildModernFilterItem(
                  "Substitution",
                  _buildModernTextField(_subFromController, "Search staff..."),
                ),
                _buildModernFilterItem(
                  "Hour Unit",
                  _buildModernTextField(_hourController, "e.g. 2 hrs"),
                ),
                _buildModernFilterItem(
                  "From Date",
                  _buildModernDateField(
                    _fromDate,
                    (d) => setState(() => _fromDate = d),
                  ),
                ),
                _buildModernFilterItem(
                  "To Date",
                  _buildModernDateField(
                    _toDate,
                    (d) => setState(() => _toDate = d),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 32,
            ),
            child: Row(
              children: [
                _actionButton(
                  Icons.search_rounded,
                  "Search Requests",
                  const Color(0xFF1E293B),
                ),
                const SizedBox(width: 16),
                _outlineButton(Icons.refresh_rounded, "Clear Filters"),
              ],
            ),
          ),

          // Modern Table
          _buildModernTable(),
        ],
      ),
    );
  }

  Widget _buildModernTable() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: 0.05),
            border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              _modernHeaderCell("DATE", flex: 2),
              _modernHeaderCell("PERIOD", flex: 2),
              _modernHeaderCell("BATCH", flex: 2),
              _modernHeaderCell("SUBJECT", flex: 3),
              _modernHeaderCell("FROM", flex: 2),
              _modernHeaderCell("STATUS", flex: 2),
            ],
          ),
        ),
        Container(
          height: 150,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: const Color(0xFFCBD5E1).withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                "No processing hour requests found",
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modernHeaderCell(String label, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: const Color(0xFF6366F1),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildModernFilterItem(String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildModernDropdown(String value, void Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: const [
            DropdownMenuItem(value: 'select', child: Text("All Statuses")),
            DropdownMenuItem(value: 'Approved', child: Text("Approved")),
            DropdownMenuItem(value: 'Pending', child: Text("Pending")),
          ],
          onChanged: onChanged,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Color(0xFF6366F1),
          ),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String hint) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1E293B),
        ),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
          hintText: hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildModernDateField(
    DateTime date,
    void Function(DateTime) onSelected,
  ) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (d != null) onSelected(d);
      },
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              DateFormat('MMM dd, yyyy').format(date),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: Color(0xFF6366F1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(IconData icon, String label, Color color) {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
    );
  }

  Widget _outlineButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF64748B),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class _AuroraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    paint.color = const Color(0xFF6366F1).withValues(alpha: 0.1);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.2), 200, paint);

    paint.color = const Color(0xFFA5B4FC).withValues(alpha: 0.1);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.8), 300, paint);

    paint.color = const Color(0xFF818CF8).withValues(alpha: 0.05);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), 250, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
