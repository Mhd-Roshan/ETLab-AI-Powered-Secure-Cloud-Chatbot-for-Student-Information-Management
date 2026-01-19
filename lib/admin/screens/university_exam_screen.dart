import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UniversityExamScreen extends StatefulWidget {
  final Color color;
  const UniversityExamScreen({super.key, required this.color});

  @override
  State<UniversityExamScreen> createState() => _UniversityExamScreenState();
}

class _UniversityExamScreenState extends State<UniversityExamScreen> {
  // --- STATE VARIABLES ---
  String _searchQuery = "";
  String _selectedStatus = "Status: All";
  
  // Pagination State
  int _currentPage = 1;
  final int _itemsPerPage = 5;

  // Controllers for "Create Exam"
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _invigilatorController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();

  // --- DATA SOURCE (Initialized inline to handle hot reload) ---
  List<Map<String, dynamic>> _exams = [
    {
      "subject": "Data Structures & Algorithms",
      "code": "CS201",
      "date": "Oct 24, 2026",
      "time": "10:00 AM",
      "invigilator": "Dr. Sarah Smith",
      "status": "Scheduled"
    },
    {
      "subject": "Digital Electronics",
      "code": "EC204",
      "date": "Oct 26, 2026",
      "time": "01:30 PM",
      "invigilator": "Prof. Rahul P.",
      "status": "Draft"
    },
    {
      "subject": "Engineering Mathematics IV",
      "code": "MA202",
      "date": "Oct 28, 2026",
      "time": "10:00 AM",
      "invigilator": "Dr. V. Kumar",
      "status": "Published"
    },
    {
      "subject": "Operating Systems",
      "code": "CS305",
      "date": "Oct 30, 2026",
      "time": "10:00 AM",
      "invigilator": "Ms. Remmya C.",
      "status": "Scheduled"
    },
    {
      "subject": "Computer Networks",
      "code": "CS307",
      "date": "Nov 02, 2026",
      "time": "09:30 AM",
      "invigilator": "Mr. Ajayakumar",
      "status": "Draft"
    },
    {
      "subject": "Database Management",
      "code": "CS302",
      "date": "Nov 05, 2026",
      "time": "01:30 PM",
      "invigilator": "Ms. Sharafunnissa",
      "status": "Scheduled"
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _codeController.dispose();
    _invigilatorController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  // --- LOGIC ---

  // Filter Logic
  List<Map<String, dynamic>> get _filteredExams {
    return _exams.where((exam) {
      final subject = (exam['subject'] ?? "").toString().toLowerCase();
      final code = (exam['code'] ?? "").toString().toLowerCase();
      final search = _searchQuery.toLowerCase();
      
      final matchesSearch = subject.contains(search) || code.contains(search);
      
      String statusClean = _selectedStatus.replaceAll("Status: ", "");
      final matchesStatus = _selectedStatus == "Status: All" || exam['status'] == statusClean;

      return matchesSearch && matchesStatus;
    }).toList();
  }

  // Pagination Logic
  List<Map<String, dynamic>> get _paginatedExams {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    
    // Safety check for bounds
    if (startIndex >= _filteredExams.length) {
      return []; 
    }
    if (endIndex > _filteredExams.length) {
      endIndex = _filteredExams.length;
    }
    
    return _filteredExams.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredExams.length / _itemsPerPage).ceil();

  // --- ACTIONS ---

  void _showCreateExamDialog() {
    // Clear controllers
    _subjectController.clear();
    _codeController.clear();
    _invigilatorController.clear();
    _dateController.clear();
    _timeController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Create New Exam", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 500, // Fixed width for desktop/web look
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_subjectController, "Exam Subject"),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_codeController, "Course Code")),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_invigilatorController, "Invigilator")),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_dateController, "Date (e.g. Oct 24)")),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTextField(_timeController, "Time (e.g. 10:00 AM)")),
                  ],
                ),
              ],
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade600))
          ),
          ElevatedButton(
            onPressed: () {
              if (_subjectController.text.isNotEmpty && _codeController.text.isNotEmpty) {
                setState(() {
                  _exams.insert(0, { // Add to top
                    "subject": _subjectController.text,
                    "code": _codeController.text,
                    "date": _dateController.text,
                    "time": _timeController.text,
                    "invigilator": _invigilatorController.text,
                    "status": "Draft" // Default status
                  });
                  _currentPage = 1; // Reset to page 1 to see new item
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Exam Created Successfully"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating)
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB), 
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
            ),
            child: const Text("Create Exam"),
          )
        ],
      ),
    );
  }

  void _deleteExam(Map<String, dynamic> exam) {
    setState(() {
      _exams.remove(exam);
      // Adjust pagination if page becomes empty
      if (_paginatedExams.isEmpty && _currentPage > 1) {
        _currentPage--;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Exam Deleted"), backgroundColor: Colors.redAccent, behavior: SnackBarBehavior.floating)
    );
  }

  TextField _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          "University Exam Management",
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "University Exam Management",
                        style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Streamline exam schedules, manage question banks, assign invigilators, and publish results effectively.",
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                // Create New Button
                ElevatedButton.icon(
                  onPressed: _showCreateExamDialog,
                  icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                  label: const Text("Create New Exam"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB), // Primary Blue
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // 2. Quick Action Cards
            Row(
              children: [
                Expanded(child: _buildActionCard("Schedule Exam", "Set dates & venues", Icons.calendar_month_rounded, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildActionCard("Question Banks", "Manage papers & topics", Icons.library_books_rounded, Colors.purple)),
                const SizedBox(width: 16),
                Expanded(child: _buildActionCard("Invigilator Duty", "Assign faculty staff", Icons.badge_rounded, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildActionCard("Publish Results", "Grade & release scores", Icons.analytics_rounded, Colors.green)),
              ],
            ),

            const SizedBox(height: 30),

            // 3. Filter Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Search
                  Expanded(
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _currentPage = 1; // Reset pagination on search
                        });
                      },
                      decoration: InputDecoration(
                        hintText: "Search by subject, course code, or exam ID...",
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Status Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedStatus,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black87),
                        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
                        items: ["Status: All", "Status: Scheduled", "Status: Draft", "Status: Published"]
                            .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedStatus = val!;
                            _currentPage = 1;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Filter Button
                  _buildOutlineButton(Icons.filter_list_rounded, "Filter"),
                  const SizedBox(width: 12),
                  
                  // Export Button
                  _buildOutlineButton(Icons.download_rounded, "Export"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Data Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(flex: 4, child: _headerText("EXAM NAME / SUBJECT")),
                  Expanded(flex: 3, child: _headerText("DATE & TIME")),
                  Expanded(flex: 2, child: _headerText("CODE")),
                  Expanded(flex: 3, child: _headerText("INVIGILATOR")),
                  Expanded(flex: 2, child: _headerText("STATUS")),
                  Expanded(flex: 1, child: _headerText("ACTIONS")),
                ],
              ),
            ),

            // 5. Data List / Empty State
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
              child: _filteredExams.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(60.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, size: 40, color: Colors.grey.shade300),
                            const SizedBox(height: 10),
                            Text("No exam records found.", style: GoogleFonts.inter(color: Colors.grey.shade400)),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _paginatedExams.length,
                      separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade100),
                      itemBuilder: (context, index) {
                        return _buildExamRow(_paginatedExams[index]);
                      },
                    ),
            ),

            // 6. Pagination Footer
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage).clamp(0, _filteredExams.length)} of ${_filteredExams.length} results",
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                ),
                Row(
                  children: [
                    _buildPaginationButton(Icons.chevron_left, () {
                      if (_currentPage > 1) setState(() => _currentPage--);
                    }, _currentPage > 1),
                    const SizedBox(width: 8),
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(color: const Color(0xFF2563EB), borderRadius: BorderRadius.circular(6)),
                      child: Center(child: Text("$_currentPage", style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold))),
                    ),
                    const SizedBox(width: 8),
                    _buildPaginationButton(Icons.chevron_right, () {
                      if (_currentPage < _totalPages) setState(() => _currentPage++);
                    }, _currentPage < _totalPages),
                  ],
                )
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 22),
              ),
              Icon(Icons.arrow_forward_rounded, color: Colors.grey.shade300, size: 20),
            ],
          ),
          const SizedBox(height: 20),
          Text(title, style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildOutlineButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.black87,
        side: BorderSide(color: Colors.grey.shade200),
        backgroundColor: Colors.grey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  Widget _buildPaginationButton(IconData icon, VoidCallback onTap, bool enabled) {
    return Container(
      decoration: BoxDecoration(
        color: enabled ? Colors.white : Colors.grey.shade100, 
        border: Border.all(color: Colors.grey.shade300), 
        borderRadius: BorderRadius.circular(6)
      ),
      child: IconButton(
        onPressed: enabled ? onTap : null, 
        icon: Icon(icon, size: 18, color: enabled ? Colors.black87 : Colors.grey), 
        padding: EdgeInsets.zero, 
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32)
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: Colors.grey.shade500,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildExamRow(Map<String, dynamic> exam) {
    Color statusColor = Colors.grey;
    Color statusBg = Colors.grey.shade50;

    if (exam['status'] == "Scheduled") {
      statusColor = Colors.blue;
      statusBg = Colors.blue.shade50;
    } else if (exam['status'] == "Published") {
      statusColor = Colors.green;
      statusBg = Colors.green.shade50;
    } else if (exam['status'] == "Draft") {
      statusColor = Colors.orange;
      statusBg = Colors.orange.shade50;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Expanded(
            flex: 4, 
            child: Text(exam['subject'], style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.blue.shade900, fontSize: 14)),
          ),
          Expanded(
            flex: 3, 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exam['date'], style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87)),
                Text(exam['time'], style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Expanded(
            flex: 2, 
            child: Text(exam['code'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey.shade700)),
          ),
          Expanded(
            flex: 3, 
            child: Row(
              children: [
                CircleAvatar(radius: 12, backgroundColor: Colors.grey.shade200, child: const Icon(Icons.person, size: 14, color: Colors.grey)),
                const SizedBox(width: 8),
                Expanded(child: Text(exam['invigilator'], style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700), overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
          Expanded(
            flex: 2, 
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  exam['status'].toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1, 
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
              color: Colors.white,
              onSelected: (val) {
                if(val == 'delete') _deleteExam(exam);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 16, color: Colors.blue), SizedBox(width: 8), Text("Edit")])),
                const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16, color: Colors.red), SizedBox(width: 8), Text("Delete", style: TextStyle(color: Colors.red))])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}