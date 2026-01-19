import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AttendanceScreen extends StatefulWidget {
  final Color color;
  const AttendanceScreen({super.key, required this.color});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // 1. STATE VARIABLES (Initialized immediately to prevent null errors)
  
  // Dummy Data initialized here instead of initState to survive Hot Reloads
  List<Map<String, dynamic>> _allRecords = [
    {
      "id": "KMCT20CS001",
      "name": "Adithya Kumar",
      "role": "Student",
      "dept": "CSE",
      "timeIn": "09:05 AM",
      "timeOut": "04:10 PM",
      "status": "Present",
      "img": "https://randomuser.me/api/portraits/men/11.jpg"
    },
    {
      "id": "EMP045",
      "name": "Ms. Remmya C. B.",
      "role": "Staff",
      "dept": "MCA",
      "timeIn": "08:55 AM",
      "timeOut": "04:30 PM",
      "status": "Present",
      "img": "https://randomuser.me/api/portraits/women/44.jpg"
    },
    {
      "id": "KMCT20CS005",
      "name": "Ben Johnson",
      "role": "Student",
      "dept": "CSE",
      "timeIn": "09:45 AM",
      "timeOut": "--:--",
      "status": "Late",
      "img": "https://randomuser.me/api/portraits/men/3.jpg"
    },
    {
      "id": "EMP001",
      "name": "Mr. Ajayakumar",
      "role": "HOD",
      "dept": "MCA",
      "timeIn": "--:--",
      "timeOut": "--:--",
      "status": "Absent",
      "img": "https://randomuser.me/api/portraits/men/55.jpg"
    },
    {
      "id": "KMCT20CS012",
      "name": "Catherine Joy",
      "role": "Student",
      "dept": "CE",
      "timeIn": "09:00 AM",
      "timeOut": "04:00 PM",
      "status": "Present",
      "img": "https://randomuser.me/api/portraits/women/5.jpg"
    },
    {
      "id": "KMCT20CS020",
      "name": "Fathima R.",
      "role": "Student",
      "dept": "CSE",
      "timeIn": "10:00 AM",
      "timeOut": "--:--",
      "status": "Late",
      "img": "https://randomuser.me/api/portraits/women/9.jpg"
    },
  ];

  List<Map<String, dynamic>> _filteredRecords = [];
  
  // Filter States
  String _searchQuery = "";
  String _selectedRole = "All Roles";
  String _selectedDept = "All Departments";
  String _selectedStatus = "All Statuses";

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // Controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _roleController = TextEditingController();
  final _deptController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    // Initialize filtered list with all records on start
    _filteredRecords = List.from(_allRecords);
  }

  // 2. LOGIC FUNCTIONS

  void _applyFilters() {
    setState(() {
      _filteredRecords = _allRecords.where((record) {
        final matchesSearch = record['name'].toLowerCase().contains(_searchQuery.toLowerCase()) || 
                              record['id'].toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesRole = _selectedRole == "All Roles" || record['role'] == _selectedRole;
        final matchesDept = _selectedDept == "All Departments" || record['dept'] == _selectedDept;
        final matchesStatus = _selectedStatus == "All Statuses" || record['status'] == _selectedStatus;

        return matchesSearch && matchesRole && matchesDept && matchesStatus;
      }).toList();
      
      _currentPage = 1; // Reset to page 1 on filter change
    });
  }

  void _deleteRecord(String id) {
    setState(() {
      _allRecords.removeWhere((item) => item['id'] == id);
      _applyFilters(); // Re-apply filters to update UI
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Record $id deleted"), 
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        width: 300,
      ),
    );
  }

  void _showAddEditDialog({Map<String, dynamic>? record}) {
    bool isEdit = record != null;
    
    if (isEdit) {
      _nameController.text = record['name'];
      _idController.text = record['id'];
      _roleController.text = record['role'];
      _deptController.text = record['dept'];
    } else {
      _nameController.clear();
      _idController.clear();
      _roleController.clear();
      _deptController.clear();
    }

    String selectedDialogStatus = isEdit ? record['status'] : "Present";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(isEdit ? "Edit Attendance" : "Add Attendance", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(_nameController, "Full Name"),
              const SizedBox(height: 10),
              _buildTextField(_idController, "ID / Reg No", enabled: !isEdit), 
              const SizedBox(height: 10),
              _buildTextField(_roleController, "Role (Student/Staff)"),
              const SizedBox(height: 10),
              _buildTextField(_deptController, "Department"),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedDialogStatus,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                items: ["Present", "Absent", "Late"].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => selectedDialogStatus = val!,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white),
            onPressed: () {
              if (_nameController.text.isEmpty || _idController.text.isEmpty) return;

              setState(() {
                if (isEdit) {
                  int index = _allRecords.indexWhere((r) => r['id'] == record['id']);
                  if (index != -1) {
                    _allRecords[index] = {
                      ..._allRecords[index],
                      "name": _nameController.text,
                      "role": _roleController.text,
                      "dept": _deptController.text,
                      "status": selectedDialogStatus,
                    };
                  }
                } else {
                  _allRecords.add({
                    "name": _nameController.text,
                    "id": _idController.text,
                    "role": _roleController.text,
                    "dept": _deptController.text,
                    "timeIn": "09:00 AM",
                    "timeOut": "--:--",
                    "status": selectedDialogStatus,
                    "img": "https://i.pravatar.cc/150?u=${_idController.text}"
                  });
                }
                _applyFilters();
              });
              Navigator.pop(context);
            },
            child: Text(isEdit ? "Update" : "Add"),
          ),
        ],
      ),
    );
  }

  TextField _buildTextField(TextEditingController controller, String label, {bool enabled = true}) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // Pagination Logic
  List<Map<String, dynamic>> get _paginatedRecords {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _filteredRecords.length) endIndex = _filteredRecords.length;
    if (startIndex >= _filteredRecords.length) return [];
    return _filteredRecords.sublist(startIndex, endIndex);
  }

  // Robust getters for metrics (Safe against null)
  int get _presentCount => _allRecords.where((r) => r['status'] == 'Present').length;
  int get _lateCount => _allRecords.where((r) => r['status'] == 'Late').length;
  int get _absentCount => _allRecords.where((r) => r['status'] == 'Absent').length;


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
          "Attendance Management",
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded)),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.black,
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP ACTIONS ROW
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Overview",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_rounded, size: 18),
                      label: const Text("Export Report"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      label: const Text("Add Attendance"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.color, 
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. METRICS CARDS
            Row(
              children: [
                Expanded(child: _buildMetricCard("Present Today", "$_presentCount", Icons.people_alt_rounded, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("Late Arrivals", "$_lateCount", Icons.access_time_filled_rounded, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("Absent", "$_absentCount", Icons.cancel_rounded, Colors.red)),
              ],
            ),

            const SizedBox(height: 24),

            // 3. FILTERS
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownButton("Role", _selectedRole, ["All Roles", "Student", "Staff", "HOD"], (val) {
                          setState(() => _selectedRole = val!);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownButton("Department", _selectedDept, ["All Departments", "CSE", "MCA", "ME", "CE"], (val) {
                          setState(() => _selectedDept = val!);
                        }),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownButton("Status", _selectedStatus, ["All Statuses", "Present", "Absent", "Late"], (val) {
                          setState(() => _selectedStatus = val!);
                        }),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _applyFilters,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        ),
                        child: const Text("Apply"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (val) {
                      _searchQuery = val;
                      _applyFilters();
                    },
                    decoration: InputDecoration(
                      hintText: "Search by name or ID number...",
                      hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. HEADER
            _buildTableHeader(),

            // 5. LIST
            if (_filteredRecords.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40.0),
                child: Center(child: Text("No records found", style: GoogleFonts.inter(color: Colors.grey))),
              )
            else
              ..._paginatedRecords.map((data) => _buildAttendanceRow(context, data)).toList(),
            
            // 6. PAGINATION
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "Page $_currentPage of ${(_filteredRecords.length / _itemsPerPage).ceil() == 0 ? 1 : (_filteredRecords.length / _itemsPerPage).ceil()}",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                const SizedBox(width: 5),
                IconButton(
                  onPressed: (_currentPage * _itemsPerPage) < _filteredRecords.length 
                      ? () => setState(() => _currentPage++) : null,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Updated just now",
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownButton(String label, String currentValue, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: currentValue,
              isExpanded: true,
              dropdownColor: Colors.white,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey),
              style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
              onChanged: onChanged,
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _headerText("USER")),
          Expanded(flex: 2, child: _headerText("ROLE / DEPT")),
          Expanded(flex: 2, child: _headerText("TIME IN")),
          Expanded(flex: 2, child: _headerText("STATUS")),
          Expanded(flex: 1, child: _headerText("ACTIONS")),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _buildAttendanceRow(BuildContext context, Map<String, dynamic> data) {
    Color statusColor;
    Color statusBg;

    if (data['status'] == 'Present') {
      statusColor = Colors.green.shade700;
      statusBg = Colors.green.shade50;
    } else if (data['status'] == 'Late') {
      statusColor = Colors.orange.shade700;
      statusBg = Colors.orange.shade50;
    } else {
      statusColor = Colors.red.shade700;
      statusBg = Colors.red.shade50;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: NetworkImage(data['img']),
                  onBackgroundImageError: (_,__) {},
                  child: const Icon(Icons.person, size: 12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['name'],
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        data['id'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['role'],
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
                ),
                Text(
                  data['dept'],
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              data['timeIn'],
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 6, color: statusColor),
                      const SizedBox(width: 6),
                      Text(
                        data['status'],
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _showAddEditDialog(record: data),
                  icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600),
                  tooltip: "Edit",
                ),
                IconButton(
                  onPressed: () => _deleteRecord(data['id']),
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400),
                  tooltip: "Delete",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}