import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';

class HodStaffScreen extends StatefulWidget {
  final String userId;
  const HodStaffScreen({super.key, this.userId = 'hod@gmail.com'});

  @override
  State<HodStaffScreen> createState() => _HodStaffScreenState();
}

class _HodStaffScreenState extends State<HodStaffScreen>
    with TickerProviderStateMixin {
  String _searchQuery = "";
  String _selectedStatus = "All";
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  // --- Staff list (mutable so Add Staff works) ---
  final List<Map<String, dynamic>> _allStaff = [
    {
      'name': 'Dr. Sarah Wilson',
      'email': 'sarah.wilson@edlab.com',
      'designation': 'Associate Professor',
      'specialization': 'Machine Learning & AI',
      'status': 'Active',
      'phone': '+91 98765 43210',
      'initials': 'SW',
      'colorHex': 0xFF6366F1,
      'batches': ['MCA 2023-25', 'MCA 2024-26'],
      'subjects': 3,
      'experience': '8 yrs',
    },
    {
      'name': 'Prof. James Bond',
      'email': 'james.bond@edlab.com',
      'designation': 'Assistant Professor',
      'specialization': 'Cyber Security',
      'status': 'In Class',
      'phone': '+91 98765 43211',
      'initials': 'JB',
      'colorHex': 0xFF10B981,
      'batches': ['MCA 2023-25'],
      'subjects': 2,
      'experience': '5 yrs',
    },
    {
      'name': 'Dr. Robert Fox',
      'email': 'robert.fox@edlab.com',
      'designation': 'Professor',
      'specialization': 'Cloud Computing',
      'status': 'On Leave',
      'phone': '+91 98765 43212',
      'initials': 'RF',
      'colorHex': 0xFF8B5CF6,
      'batches': ['MCA 2022-24'],
      'subjects': 4,
      'experience': '14 yrs',
    },
    {
      'name': 'Ms. Emily Blunt',
      'email': 'emily.blunt@edlab.com',
      'designation': 'Assistant Professor',
      'specialization': 'Data Structures & Algorithms',
      'status': 'Active',
      'phone': '+91 98765 43213',
      'initials': 'EB',
      'colorHex': 0xFFF59E0B,
      'batches': ['MCA 2024-26'],
      'subjects': 2,
      'experience': '3 yrs',
    },
    {
      'name': 'Dr. Kavitha Suresh',
      'email': 'kavitha.s@edlab.com',
      'designation': 'Associate Professor',
      'specialization': 'Software Engineering',
      'status': 'Active',
      'phone': '+91 98765 43214',
      'initials': 'KS',
      'colorHex': 0xFFEC4899,
      'batches': ['MCA 2023-25', 'MCA 2024-26'],
      'subjects': 3,
      'experience': '10 yrs',
    },
    {
      'name': 'Mr. Arjun Nair',
      'email': 'arjun.nair@edlab.com',
      'designation': 'Lecturer',
      'specialization': 'Database Systems',
      'status': 'In Class',
      'phone': '+91 98765 43215',
      'initials': 'AN',
      'colorHex': 0xFF0EA5E9,
      'batches': ['MCA 2024-26'],
      'subjects': 2,
      'experience': '2 yrs',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredStaff => _allStaff.where((s) {
    final name = s['name'].toString().toLowerCase();
    final status = s['status'].toString();
    final matchSearch = name.contains(_searchQuery.toLowerCase());
    final matchStatus = _selectedStatus == "All" || status == _selectedStatus;
    return matchSearch && matchStatus;
  }).toList();

  int get _activeCount => _allStaff
      .where((s) => s['status'] == 'Active' || s['status'] == 'In Class')
      .length;
  int get _onLeaveCount =>
      _allStaff.where((s) => s['status'] == 'On Leave').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          HodSidebar(activeIndex: -1, userId: widget.userId),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPageHeader(),
                    const SizedBox(height: 32),
                    _buildStatsRow(),
                    const SizedBox(height: 32),
                    _buildControls(),
                    const SizedBox(height: 28),
                    _buildStaffGrid(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader() {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Staff Directory",
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            Text(
              "MCA Department · ${_allStaff.length} Faculty Members",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const Spacer(),
        _buildAddButton(),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAddStaffDialog(),
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  "Add Staff",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------- ADD STAFF DIALOG ----------------------
  void _showAddStaffDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final designationCtrl = TextEditingController();
    final speciCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    String selectedStatus = 'Active';
    String? duplicateError;

    final colorPalette = [
      0xFF6366F1,
      0xFF10B981,
      0xFF8B5CF6,
      0xFFF59E0B,
      0xFFEC4899,
      0xFF0EA5E9,
      0xFFEF4444,
      0xFF14B8A6,
    ];
    final nextColor = colorPalette[_allStaff.length % colorPalette.length];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 120,
            vertical: 60,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 24, 20, 20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Add New Staff Member",
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),

                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Duplicate error banner
                          if (duplicateError != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFFCA5A5),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline,
                                    color: Color(0xFFEF4444),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      duplicateError!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: const Color(0xFFDC2626),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: _dlgField(
                                  ctrl: nameCtrl,
                                  label: "Full Name *",
                                  hint: "e.g. Dr. Jane Smith",
                                  icon: Icons.person_outline_rounded,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Name is required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _dlgField(
                                  ctrl: emailCtrl,
                                  label: "Email *",
                                  hint: "e.g. jane@edlab.com",
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty)
                                      return 'Email is required';
                                    if (!v.contains('@'))
                                      return 'Enter a valid email';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _dlgField(
                                  ctrl: designationCtrl,
                                  label: "Designation *",
                                  hint: "e.g. Assistant Professor",
                                  icon: Icons.badge_outlined,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Designation is required'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _dlgField(
                                  ctrl: speciCtrl,
                                  label: "Specialisation *",
                                  hint: "e.g. Machine Learning",
                                  icon: Icons.science_outlined,
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Specialisation is required'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _dlgField(
                                  ctrl: phoneCtrl,
                                  label: "Phone",
                                  hint: "+91 98765 43210",
                                  icon: Icons.phone_rounded,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _dlgField(
                                  ctrl: expCtrl,
                                  label: "Experience",
                                  hint: "e.g. 5 yrs",
                                  icon: Icons.workspace_premium_outlined,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Status",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: ['Active', 'In Class', 'On Leave'].map((
                              s,
                            ) {
                              final sel = selectedStatus == s;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: InkWell(
                                  onTap: () =>
                                      setDlgState(() => selectedStatus = s),
                                  borderRadius: BorderRadius.circular(10),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? _statusColor(s).withOpacity(0.12)
                                          : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: sel
                                            ? _statusColor(s)
                                            : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    child: Text(
                                      s,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: sel
                                            ? _statusColor(s)
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Footer
                Container(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setDlgState(() => duplicateError = null);
                            if (!formKey.currentState!.validate()) return;

                            final newEmail = emailCtrl.text
                                .trim()
                                .toLowerCase();
                            final newName = nameCtrl.text.trim().toLowerCase();

                            // Duplicate checks
                            if (_allStaff.any(
                              (s) =>
                                  s['email'].toString().toLowerCase() ==
                                  newEmail,
                            )) {
                              setDlgState(
                                () => duplicateError =
                                    'A staff member with this email already exists.',
                              );
                              return;
                            }
                            if (_allStaff.any(
                              (s) =>
                                  s['name'].toString().toLowerCase() == newName,
                            )) {
                              setDlgState(
                                () => duplicateError =
                                    'A staff member with this name already exists.',
                              );
                              return;
                            }

                            // Build initials from name
                            final parts = nameCtrl.text.trim().split(' ');
                            final initials = parts.length >= 2
                                ? '${parts.first[0]}${parts.last[0]}'
                                      .toUpperCase()
                                : nameCtrl.text
                                      .trim()
                                      .substring(
                                        0,
                                        nameCtrl.text.trim().length >= 2
                                            ? 2
                                            : 1,
                                      )
                                      .toUpperCase();

                            setState(() {
                              _allStaff.add({
                                'name': nameCtrl.text.trim(),
                                'email': emailCtrl.text.trim(),
                                'phone': phoneCtrl.text.trim().isEmpty
                                    ? 'N/A'
                                    : phoneCtrl.text.trim(),
                                'designation': designationCtrl.text.trim(),
                                'specialization': speciCtrl.text.trim(),
                                'experience': expCtrl.text.trim().isEmpty
                                    ? 'N/A'
                                    : expCtrl.text.trim(),
                                'status': selectedStatus,
                                'initials': initials,
                                'colorHex': nextColor,
                                'batches': <String>[],
                                'subjects': 0,
                              });
                            });

                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${nameCtrl.text.trim()} added successfully!',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(20),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366F1),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Add Staff Member",
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
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
      ),
    );
  }

  Widget _dlgField({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFFCBD5E1),
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF6366F1),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
          ),
          style: GoogleFonts.inter(fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          "Total Faculty",
          _allStaff.length.toString(),
          const Color(0xFF6366F1),
          Icons.people_alt_rounded,
        ),
        const SizedBox(width: 20),
        _buildStatCard(
          "Active / In Class",
          _activeCount.toString(),
          const Color(0xFF10B981),
          Icons.bolt_rounded,
        ),
        const SizedBox(width: 20),
        _buildStatCard(
          "On Leave",
          _onLeaveCount.toString(),
          const Color(0xFFF43F5E),
          Icons.event_busy_rounded,
        ),
        const SizedBox(width: 20),
        _buildStatCard(
          "Avg Experience",
          "7 yrs",
          const Color(0xFFF59E0B),
          Icons.workspace_premium_rounded,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: "Search by name or email...",
                      hintStyle: GoogleFonts.inter(
                        color: const Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        ...["All", "Active", "In Class", "On Leave"].map((s) {
          final sel = _selectedStatus == s;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedStatus = s),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Text(
                  s,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStaffGrid() {
    final filtered = _filteredStaff;

    if (filtered.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(60),
          child: Column(
            children: [
              Icon(
                Icons.person_search_rounded,
                size: 56,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                "No staff members match your search",
                style: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        mainAxisExtent: 340,
      ),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildStaffCard(filtered[index], index),
    );
  }

  Widget _buildStaffCard(Map<String, dynamic> data, int index) {
    final status = data['status'] as String;
    final color = Color(data['colorHex'] as int);
    final statusColor = _statusColor(status);

    return AnimatedBuilder(
      animation: _fadeAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnim.value)),
          child: Opacity(
            opacity: min(1.0, _fadeAnim.value * (1 + index * 0.15)),
            child: child,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top colored banner + avatar
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              child: Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.9), color.withOpacity(0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      bottom: -28,
                      left: 20,
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            data['initials'] as String,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              status.toUpperCase(),
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
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

            // Card body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 34, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data['designation'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _infoRow(
                      Icons.science_outlined,
                      data['specialization'] as String,
                      color,
                    ),
                    const SizedBox(height: 6),
                    _infoRow(
                      Icons.alternate_email_rounded,
                      data['email'] as String,
                      color,
                    ),
                    const SizedBox(height: 6),
                    _infoRow(
                      Icons.phone_rounded,
                      data['phone'] as String,
                      color,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _chipTag(
                          "${data['subjects']} Subjects",
                          const Color(0xFF6366F1),
                        ),
                        const SizedBox(width: 8),
                        _chipTag(
                          data['experience'] as String,
                          const Color(0xFF10B981),
                        ),
                      ],
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

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _chipTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF10B981);
      case 'In Class':
        return const Color(0xFF6366F1);
      case 'On Leave':
        return const Color(0xFFF43F5E);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}
