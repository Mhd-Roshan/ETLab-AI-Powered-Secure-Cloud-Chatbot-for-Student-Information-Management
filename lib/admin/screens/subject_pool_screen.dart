import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectPoolScreen extends StatefulWidget {
  final Color color;
  const SubjectPoolScreen({super.key, required this.color});

  @override
  State<SubjectPoolScreen> createState() => _SubjectPoolScreenState();
}

class _SubjectPoolScreenState extends State<SubjectPoolScreen> with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  String _searchQuery = "";
  String _selectedDept = "All Depts";
  String _selectedType = "All Types";
  String _selectedStatus = "Status: All";

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 6;

  // Controllers
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _creditsController = TextEditingController();
  final TextEditingController _prereqController = TextEditingController();

  // --- DATA SOURCE ---
  List<Map<String, dynamic>> _subjects = [
    {
      "code": "CS101",
      "title": "Intro to Programming",
      "dept": "CSE",
      "credits": "4",
      "type": "Core",
      "prerequisites": "None",
      "status": "Active"
    },
    {
      "code": "MA102",
      "title": "Calculus II",
      "dept": "Math",
      "credits": "3",
      "type": "Core",
      "prerequisites": "MA101",
      "status": "Active"
    },
    {
      "code": "CS205",
      "title": "Data Structures",
      "dept": "CSE",
      "credits": "4",
      "type": "Core",
      "prerequisites": "CS101",
      "status": "Review"
    },
    {
      "code": "HU301",
      "title": "Professional Ethics",
      "dept": "Humanities",
      "credits": "2",
      "type": "Elective",
      "prerequisites": "None",
      "status": "Active"
    },
    {
      "code": "ME101",
      "title": "Engg Mechanics",
      "dept": "ME",
      "credits": "3",
      "type": "Core",
      "prerequisites": "PH101",
      "status": "Inactive"
    },
    {
      "code": "CS306",
      "title": "Database Systems",
      "dept": "CSE",
      "credits": "4",
      "type": "Core",
      "prerequisites": "CS205",
      "status": "Active"
    },
    {
      "code": "EC201",
      "title": "Digital Logic",
      "dept": "ECE",
      "credits": "3",
      "type": "Core",
      "prerequisites": "PH102",
      "status": "Active"
    },
  ];

  // --- LOGIC ---

  List<Map<String, dynamic>> get _filteredSubjects {
    return _subjects.where((item) {
      final matchesSearch = item['title'].toLowerCase().contains(_searchQuery.toLowerCase()) || 
                            item['code'].toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesDept = _selectedDept == "All Depts" || item['dept'] == _selectedDept;
      
      final matchesType = _selectedType == "All Types" || item['type'] == _selectedType;
      
      // Status filter logic (parsing "Status: All" -> "All")
      String statusClean = _selectedStatus.replaceAll("Status: ", "");
      final matchesStatus = statusClean == "All" || item['status'] == statusClean;

      return matchesSearch && matchesDept && matchesType && matchesStatus;
    }).toList();
  }

  List<Map<String, dynamic>> get _paginatedSubjects {
    int startIndex = (_currentPage - 1) * _itemsPerPage;
    int endIndex = startIndex + _itemsPerPage;
    if (endIndex > _filteredSubjects.length) endIndex = _filteredSubjects.length;
    if (startIndex >= _filteredSubjects.length) return [];
    return _filteredSubjects.sublist(startIndex, endIndex);
  }

  // Dynamic Metrics
  int get _totalSubjects => _subjects.length;
  int get _activeSubjects => _subjects.where((s) => s['status'] == 'Active').length;
  int get _deptCount => _subjects.map((s) => s['dept']).toSet().length;
  int get _reviewNeeded => _subjects.where((s) => s['status'] == 'Review').length;

  // --- ACTIONS ---

  void _showAddEditDialog({Map<String, dynamic>? subject}) {
    bool isEdit = subject != null;
    if (isEdit) {
      _codeController.text = subject['code'];
      _titleController.text = subject['title'];
      _creditsController.text = subject['credits'];
      _prereqController.text = subject['prerequisites'];
    } else {
      _codeController.clear();
      _titleController.clear();
      _creditsController.clear();
      _prereqController.clear();
    }

    String dialogDept = isEdit ? subject['dept'] : "CSE";
    String dialogType = isEdit ? subject['type'] : "Core";
    String dialogStatus = isEdit ? subject['status'] : "Active";

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: Text(isEdit ? "Edit Subject" : "Create New Subject", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_codeController, "Code")),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTextField(_creditsController, "Credits")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildTextField(_titleController, "Subject Title"),
                  const SizedBox(height: 10),
                  _buildTextField(_prereqController, "Prerequisites (e.g. CS101)"),
                  const SizedBox(height: 10),
                  // Dropdowns for Dialog
                  DropdownButtonFormField<String>(
                    value: dialogDept,
                    decoration: InputDecoration(labelText: "Department", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                    items: ["CSE", "ECE", "ME", "CE", "Math", "Humanities"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (v) => setStateSB(() => dialogDept = v!),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: dialogType,
                          decoration: InputDecoration(labelText: "Type", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: ["Core", "Elective", "Lab"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setStateSB(() => dialogType = v!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: dialogStatus,
                          decoration: InputDecoration(labelText: "Status", border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: ["Active", "Inactive", "Review"].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (v) => setStateSB(() => dialogStatus = v!),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  if (_codeController.text.isNotEmpty && _titleController.text.isNotEmpty) {
                    setState(() {
                      if (isEdit) {
                        // Update
                        int index = _subjects.indexOf(subject);
                        _subjects[index] = {
                          "code": _codeController.text,
                          "title": _titleController.text,
                          "dept": dialogDept,
                          "credits": _creditsController.text,
                          "type": dialogType,
                          "prerequisites": _prereqController.text,
                          "status": dialogStatus
                        };
                      } else {
                        // Create
                        _subjects.add({
                          "code": _codeController.text,
                          "title": _titleController.text,
                          "dept": dialogDept,
                          "credits": _creditsController.text,
                          "type": dialogType,
                          "prerequisites": _prereqController.text,
                          "status": dialogStatus
                        });
                      }
                    });
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                child: Text(isEdit ? "Save Changes" : "Create Subject"),
              )
            ],
          );
        }
      ),
    );
  }

  void _deleteSubject(Map<String, dynamic> subject) {
    setState(() {
      _subjects.remove(subject);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${subject['code']} deleted"), backgroundColor: Colors.red));
  }

  TextField _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          "Subject Pool Management",
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER SECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Manage your academic subjects.",
                        style: GoogleFonts.silkscreen(fontSize: 18, color: const Color.fromARGB(255, 10, 10, 10)),
                      ),
                    ],
                  ),
                ),
                // Header Buttons
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.upload_file_rounded, size: 18),
                      label: const Text("Import CSV"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _showAddEditDialog(),
                      icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                      label: const Text("Create New Subject"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB), // Royal Blue
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                )
              ],
            ),

            const SizedBox(height: 24),

            // 2. METRICS CARDS
            Row(
              children: [
                Expanded(child: _buildMetricCard("Total Subjects", "$_totalSubjects", Icons.library_books_rounded, Colors.blue, "12%", true)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("Active Courses", "$_activeSubjects", Icons.check_circle_rounded, Colors.green, "85%", true)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("Departments", "$_deptCount", Icons.domain_rounded, Colors.purple, "3 New", true)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("Review Needed", "$_reviewNeeded", Icons.warning_rounded, Colors.orange, "Action Required", false)),
              ],
            ),

            const SizedBox(height: 24),

            // 3. FILTER BAR
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  // Search
                  Expanded(
                    flex: 2,
                    child: TextField(
                      onChanged: (val) => setState(() { _searchQuery = val; _currentPage = 1; }),
                      decoration: InputDecoration(
                        hintText: "Filter by name or code...",
                        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Dropdowns
                  Expanded(child: _buildFilterDropdown(_selectedDept, ["All Depts", "CSE", "ECE", "ME", "CE", "Math", "Humanities"], (v) => setState(() => _selectedDept = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFilterDropdown(_selectedType, ["All Types", "Core", "Elective", "Lab"], (v) => setState(() => _selectedType = v!))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFilterDropdown(_selectedStatus, ["Status: All", "Status: Active", "Status: Inactive", "Status: Review"], (v) => setState(() => _selectedStatus = v!))),
                  const SizedBox(width: 12),
                  // Icon Btn
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade200), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.filter_list_rounded, size: 20, color: Colors.grey.shade600),
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. DATA TABLE (Custom Header + List)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 30, child: Icon(Icons.check_box_outline_blank_rounded, size: 20, color: Colors.grey.shade400)),
                        Expanded(flex: 2, child: _headerText("CODE")),
                        Expanded(flex: 4, child: _headerText("SUBJECT TITLE")),
                        Expanded(flex: 2, child: _headerText("DEPARTMENT")),
                        Expanded(flex: 2, child: _headerText("CREDITS")),
                        Expanded(flex: 2, child: _headerText("TYPE")),
                        Expanded(flex: 2, child: _headerText("PREREQUISITES")),
                        Expanded(flex: 2, child: _headerText("STATUS")),
                        Expanded(flex: 2, child: _headerText("ACTIONS")),
                      ],
                    ),
                  ),
                  // List
                  if (_paginatedSubjects.isEmpty)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: Text("No subjects found")))
                  else
                    ..._paginatedSubjects.map((subject) => _buildSubjectRow(subject)).toList(),
                  
                  // Footer Pagination
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade100)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Showing ${(_currentPage - 1) * _itemsPerPage + 1} to ${(_currentPage * _itemsPerPage).clamp(0, _filteredSubjects.length)} of ${_filteredSubjects.length} entries",
                          style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text("Previous"),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton(
                              onPressed: (_currentPage * _itemsPerPage) < _filteredSubjects.length ? () => setState(() => _currentPage++) : null,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey.shade700,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                              ),
                              child: const Text("Next"),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

  Widget _headerText(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 0.5));
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, String badgeText, bool isPositive) {
    return Container(
      padding: const EdgeInsets.all(20),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 18, color: color),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.dmSans(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isPositive ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isPositive) Icon(Icons.trending_up, size: 12, color: Colors.green.shade700),
                Text(" $badgeText", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: isPositive ? Colors.green.shade700 : Colors.orange.shade800)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String value, List<String> items, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Colors.grey.shade600),
          style: GoogleFonts.inter(fontSize: 13, color: Colors.black87),
          onChanged: onChanged,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        ),
      ),
    );
  }

  Widget _buildSubjectRow(Map<String, dynamic> subject) {
    Color statusColor = Colors.grey;
    if (subject['status'] == 'Active') statusColor = Colors.green;
    if (subject['status'] == 'Review') statusColor = Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade50)),
      ),
      child: Row(
        children: [
          SizedBox(width: 30, child: Icon(Icons.check_box_outline_blank_rounded, size: 20, color: Colors.grey.shade300)),
          
          Expanded(flex: 2, child: Text(subject['code'], style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13))),
          
          Expanded(flex: 4, child: Text(subject['title'], style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87))),
          
          Expanded(flex: 2, child: Text(subject['dept'], style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700))),
          
          Expanded(flex: 2, child: Text(subject['credits'], style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700))),
          
          Expanded(flex: 2, child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
            child: Text(subject['type'], style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.grey.shade700), textAlign: TextAlign.center),
          )),
          
          Expanded(flex: 2, child: Text(subject['prerequisites'], style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500))),
          
          Expanded(flex: 2, child: Row(
            children: [
              Icon(Icons.circle, size: 8, color: statusColor),
              const SizedBox(width: 6),
              Text(subject['status'], style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
            ],
          )),
          
          Expanded(flex: 2, child: Row(
            children: [
              IconButton(onPressed: () => _showAddEditDialog(subject: subject), icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade600)),
              IconButton(onPressed: () => _deleteSubject(subject), icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade400)),
            ],
          )),
        ],
      ),
    );
  }
}