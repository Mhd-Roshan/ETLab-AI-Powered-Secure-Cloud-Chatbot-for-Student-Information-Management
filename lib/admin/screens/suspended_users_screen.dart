import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SuspendedUsersScreen extends StatefulWidget {
  final Color color;
  const SuspendedUsersScreen({super.key, required this.color});

  @override
  State<SuspendedUsersScreen> createState() => _SuspendedUsersScreenState();
}

class _SuspendedUsersScreenState extends State<SuspendedUsersScreen> {
  // --- STATE VARIABLES ---
  String _searchQuery = "";
  String _selectedTab = "Batch"; // Options: "Batch", "Students Only", "Staff Only"

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();

  // --- DATA SOURCE ---
  List<Map<String, dynamic>> _suspendedUsers = [
    {
      "name": "Arjun Nair",
      "id": "KMCT20CS001",
      "role": "Student",
      "reason": "Disciplinary Action",
      "date": "Jan 12, 2026",
      "duration": "2 Weeks",
      "status": "Active",
      "img": "https://randomuser.me/api/portraits/men/11.jpg"
    },
    {
      "name": "Mr. Rahul P.",
      "id": "EMP045",
      "role": "Staff",
      "reason": "Administrative Review",
      "date": "Jan 10, 2026",
      "duration": "Indefinite",
      "status": "Active",
      "img": "https://randomuser.me/api/portraits/men/32.jpg"
    },
    {
      "name": "Ben Johnson",
      "id": "KMCT20CS005",
      "role": "Student",
      "reason": "Fee Default",
      "date": "Jan 15, 2026",
      "duration": "Until Payment",
      "status": "Active",
      "img": "https://randomuser.me/api/portraits/men/3.jpg"
    },
  ];

  // --- LOGIC ---

  List<Map<String, dynamic>> get _filteredUsers {
    return _suspendedUsers.where((user) {
      final matchesSearch = (user['name']?.toString().toLowerCase() ?? "").contains(_searchQuery.toLowerCase()) || 
                            (user['id']?.toString().toLowerCase() ?? "").contains(_searchQuery.toLowerCase());
      
      bool matchesTab = true;
      if (_selectedTab == "Students Only") matchesTab = user['role'] == "Student";
      if (_selectedTab == "Staff Only") matchesTab = user['role'] == "Staff";

      return matchesSearch && matchesTab;
    }).toList();
  }

  // Metrics
  int get _totalSuspended => _suspendedUsers.length;
  int get _studentSuspended => _suspendedUsers.where((u) => u['role'] == 'Student').length;
  int get _staffSuspended => _suspendedUsers.where((u) => u['role'] == 'Staff').length;

  // --- ACTIONS ---

  void _revokeSuspension(Map<String, dynamic> user) {
    setState(() {
      _suspendedUsers.remove(user);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Suspension revoked for ${user['name']}"), backgroundColor: Colors.green)
    );
  }

  void _manualSuspendDialog() {
    _nameController.clear();
    _idController.clear();
    _reasonController.clear();
    String selectedRole = "Student";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text("Manually Suspend User", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(_nameController, "User Name"),
                  const SizedBox(height: 12),
                  _buildTextField(_idController, "ID / Reg No"),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    dropdownColor: Colors.white,
                    decoration: InputDecoration(
                      labelText: "Role",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: ["Student", "Staff"].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (val) => setStateSB(() => selectedRole = val!),
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(_reasonController, "Reason for Suspension"),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty) {
                    setState(() {
                      _suspendedUsers.add({
                        "name": _nameController.text,
                        "id": _idController.text,
                        "role": selectedRole,
                        "reason": _reasonController.text,
                        "date": "Just Now",
                        "duration": "Indefinite",
                        "status": "Active",
                        "img": "https://i.pravatar.cc/150?u=${_idController.text}"
                      });
                    });
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User suspended successfully"), backgroundColor: Colors.redAccent)
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                child: const Text("Suspend"),
              )
            ],
          );
        }
      ),
    );
  }

  TextField _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
        title: Text(
          "Suspended Users",
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // 2. Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Suspended Accounts",
                            style: GoogleFonts.dmSans(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Manage temporarily or permanently suspended student and staff accounts.",
                            style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      // Desktop/Tablet view Buttons (Hidden on small mobile usually, but kept for layout match)
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text("Export CSV"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _manualSuspendDialog,
                            icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                            label: const Text("Manually Suspend"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB), // Royal Blue
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 3. Metrics Row
            Row(
              children: [
                Expanded(child: _buildMetricCard("TOTAL SUSPENDED", "$_totalSuspended", Icons.block_rounded, Colors.red)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("STUDENTS", "$_studentSuspended", Icons.school_rounded, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("STAFF", "$_staffSuspended", Icons.badge_rounded, Colors.purple)),
              ],
            ),

            const SizedBox(height: 24),

            // 4. Filters & Search Bar
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Custom Tab Switcher
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: ["Batch", "Students Only", "Staff Only"].map((tab) {
                        bool isSelected = _selectedTab == tab;
                        return InkWell(
                          onTap: () => setState(() => _selectedTab = tab),
                          borderRadius: BorderRadius.circular(8),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
                            ),
                            child: Text(
                              tab,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.black87 : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const Spacer(),

                  // Search Field
                  SizedBox(
                    width: 300,
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: "Search by name, ID, or email...",
                        hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400, size: 20),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Filter Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.filter_list_rounded, size: 20, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 5. Data Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  SizedBox(width: 30, child: Icon(Icons.check_box_outline_blank_rounded, size: 20, color: Colors.grey.shade400)),
                  Expanded(flex: 3, child: _tableHeader("USER PROFILE")),
                  Expanded(flex: 2, child: _tableHeader("ROLE")),
                  Expanded(flex: 3, child: _tableHeader("REASON")),
                  Expanded(flex: 2, child: _tableHeader("SUSPENSION DATE")),
                  Expanded(flex: 2, child: _tableHeader("DURATION")),
                  Expanded(flex: 2, child: _tableHeader("STATUS")),
                  Expanded(flex: 1, child: _tableHeader("ACTIONS")),
                ],
              ),
            ),

            // 6. Data List / Empty State
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(
                  left: BorderSide(color: Colors.grey.shade200),
                  right: BorderSide(color: Colors.grey.shade200),
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: _filteredUsers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(40.0),
                      child: Center(
                        child: Text("No suspended accounts found.", style: GoogleFonts.inter(color: Colors.grey.shade500)),
                      ),
                    )
                  : Column(
                      children: _filteredUsers.map((user) => _buildUserRow(user)).toList(),
                    ),
            ),

            const SizedBox(height: 40),
            
            // Footer
            Center(
              child: Text(
                "© 2026 EduManager Systems. All rights reserved.",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: 12),
              Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5)),
            ],
          ),
          const SizedBox(height: 16),
          Text(value, style: GoogleFonts.dmSans(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _tableHeader(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500),
    );
  }

  Widget _buildUserRow(Map<String, dynamic> user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Icon(Icons.check_box_outline_blank_rounded, size: 20, color: Colors.grey.shade300)),
          
          // User Profile
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(user['img']),
                  backgroundColor: Colors.grey.shade200,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user['name'], style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                    Text(user['id'], style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),

          // Role
          Expanded(
            flex: 2,
            child: Text(user['role'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          ),

          // Reason
          Expanded(
            flex: 3,
            child: Text(user['reason'], style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
          ),

          // Date
          Expanded(
            flex: 2,
            child: Text(user['date'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
          ),

          // Duration
          Expanded(
            flex: 2,
            child: Text(user['duration'], style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600)),
          ),

          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Text(
                user['status'].toUpperCase(),
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Actions
          Expanded(
            flex: 1,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz_rounded, color: Colors.grey.shade400),
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (val) {
                if (val == 'revoke') _revokeSuspension(user);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'revoke',
                  child: Row(children: [Icon(Icons.restore, size: 18, color: Colors.green), SizedBox(width: 8), Text("Revoke Suspension")]),
                ),
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [Icon(Icons.edit, size: 18, color: Colors.blue), SizedBox(width: 8), Text("Edit Details")]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}