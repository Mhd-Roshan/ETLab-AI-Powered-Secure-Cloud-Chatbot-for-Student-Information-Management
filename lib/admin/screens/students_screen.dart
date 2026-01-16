import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// LEVEL 1: DEPARTMENT SELECTION
// ==========================================
// (This remains the same as previous step, skipping to Level 2 & 3 as requested)

class StudentsScreen extends StatelessWidget {
  final Color color;
  const StudentsScreen({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    // KMCT Departments Data
    final List<Map<String, dynamic>> departments = [
      {"code": "CSE", "name": "Computer Science", "color": const Color(0xFF00C9A7), "icon": Icons.terminal_rounded},
      {"code": "MCA", "name": "Computer App.", "color": const Color(0xFF7F5AF0), "icon": Icons.dataset_linked_rounded},
      {"code": "ME", "name": "Mechanical", "color": const Color(0xFFFF9F1C), "icon": Icons.settings_suggest_rounded},
      {"code": "CE", "name": "Civil Eng.", "color": const Color(0xFF2D81FF), "icon": Icons.holiday_village_rounded},
      {"code": "ECE", "name": "Electronics", "color": const Color(0xFF2CB67D), "icon": Icons.memory_rounded},
      {"code": "EEE", "name": "Electrical", "color": const Color(0xFFFFD166), "icon": Icons.electric_bolt_rounded},
      {"code": "AIML", "name": "AI & ML", "color": const Color(0xFFF72585), "icon": Icons.psychology_rounded},
      {"code": "ADS", "name": "Data Science", "color": const Color(0xFF4361EE), "icon": Icons.hub_rounded},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "STUDENTS",
          style: GoogleFonts.silkscreen(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Colors.black,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Text(
              "Select Department",
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              itemCount: departments.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, 
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8, 
              ),
              itemBuilder: (context, index) {
                if (index == departments.length) {
                  return _buildAddDeptCard(context);
                }
                final dept = departments[index];
                return _buildCompactDeptItem(context, dept);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDeptItem(BuildContext context, Map<String, dynamic> dept) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepartmentBatchesScreen(
              deptCode: dept['code'],
              deptName: dept['name'],
              themeColor: dept['color'],
            ),
          ),
        );
      },
      onLongPress: () {
        _showActionSheet(context, "Department: ${dept['code']}", dept['color']);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: (dept['color'] as Color).withOpacity(0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(dept['icon'], color: dept['color'], size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            dept['code'],
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.5,
            ),
          ),
          Text(
            dept['name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDeptCard(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300, width: 2), 
            ),
            child: Icon(Icons.add_rounded, color: Colors.grey.shade400, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            "Add New",
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 9), 
        ],
      ),
    );
  }
}

// ==========================================
// LEVEL 2: ACADEMIC BATCHES (Modern Clean List)
// ==========================================

class DepartmentBatchesScreen extends StatelessWidget {
  final String deptCode;
  final String deptName;
  final Color themeColor;

  const DepartmentBatchesScreen({
    super.key, 
    required this.deptCode, 
    required this.deptName,
    required this.themeColor
  });

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> batches;

    // Logic: MCA gets 2 years, others get 4 years
    if (deptCode == "MCA") {
      batches = [
        {"range": "2024 - 2026", "sem": "S2 - First Year", "status": "Active"},
        {"range": "2023 - 2025", "sem": "S4 - Final Year", "status": "Active"},
        {"range": "2022 - 2024", "sem": "Graduated", "status": "Alumni"},
      ];
    } else {
      batches = [
        {"range": "2024 - 2028", "sem": "S2 - First Year", "status": "Active"},
        {"range": "2023 - 2027", "sem": "S4 - Second Year", "status": "Active"},
        {"range": "2022 - 2026", "sem": "S6 - Third Year", "status": "Active"},
        {"range": "2021 - 2025", "sem": "S8 - Final Year", "status": "Active"},
        {"range": "2020 - 2024", "sem": "Graduated", "status": "Alumni"},
      ];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        centerTitle: true,
        title: Text(
          deptCode,
          style: GoogleFonts.dmSans(fontWeight: FontWeight.w900, fontSize: 22),
        ),
        actions: [
          // MODERN TOP ADD BUTTON
          _buildTopAddButton(context, themeColor, () {
             // Logic to Add Batch
          }),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 20),
            child: Text(
              "Academic Batches",
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              itemCount: batches.length,
              separatorBuilder: (ctx, i) => Divider(height: 30, color: Colors.grey.shade100),
              itemBuilder: (context, index) {
                final batch = batches[index];
                return _buildCleanBatchItem(context, batch);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCleanBatchItem(BuildContext context, Map<String, String> batch) {
    bool isAlumni = batch['status'] == "Alumni";

    return InkWell(
      onTap: () {
         Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BatchStudentListScreen(
                batchRange: batch['range']!,
                deptName: deptName,
                sem: batch['sem']!,
                themeColor: themeColor,
              ),
            ),
          );
      },
      splashColor: themeColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 1. Status Indicator Bar
            Container(
              width: 4,
              height: 45,
              decoration: BoxDecoration(
                color: isAlumni ? Colors.grey.shade300 : themeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 20),
            
            // 2. Main Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    batch['range']!,
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isAlumni ? Colors.grey.shade400 : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (!isAlumni) 
                        Icon(Icons.circle, size: 6, color: themeColor),
                      if (!isAlumni) 
                        const SizedBox(width: 6),
                      Text(
                        batch['sem']!,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isAlumni ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Edit/Delete Action
            IconButton(
              icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade300),
              onPressed: () {
                _showActionSheet(context, "Batch ${batch['range']}", themeColor);
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// LEVEL 3: STUDENTS LIST (Modern Clean List)
// ==========================================

class BatchStudentListScreen extends StatelessWidget {
  final String batchRange;
  final String deptName;
  final String sem;
  final Color themeColor;

  const BatchStudentListScreen({
    super.key,
    required this.batchRange,
    required this.deptName,
    required this.sem,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> students = [
      {"name": "Adithya Kumar", "reg": "KMCT20CS001", "img": "https://randomuser.me/api/portraits/men/11.jpg"},
      {"name": "Ben Johnson", "reg": "KMCT20CS005", "img": "https://randomuser.me/api/portraits/men/3.jpg"},
      {"name": "Catherine Joy", "reg": "KMCT20CS012", "img": "https://randomuser.me/api/portraits/women/5.jpg"},
      {"name": "David Miller", "reg": "KMCT20CS015", "img": "https://randomuser.me/api/portraits/men/8.jpg"},
      {"name": "Fathima R.", "reg": "KMCT20CS020", "img": "https://randomuser.me/api/portraits/women/9.jpg"},
      {"name": "Gokul S.", "reg": "KMCT20CS022", "img": "https://randomuser.me/api/portraits/men/12.jpg"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              batchRange,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(
              "Students",
              style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.search_rounded, size: 28)
          ),
          const SizedBox(width: 8),
          // MODERN TOP ADD BUTTON
          _buildTopAddButton(context, Colors.black, () {
             // Logic to Add Student
          }),
          const SizedBox(width: 16),
        ],
      ),
      body: ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: students.length,
        separatorBuilder: (ctx, i) => const SizedBox(height: 20),
        itemBuilder: (context, index) {
          final student = students[index];
          return _buildCleanStudentTile(context, student);
        },
      ),
    );
  }

  Widget _buildCleanStudentTile(BuildContext context, Map<String, dynamic> student) {
    return InkWell(
      onTap: () {
        // Navigate to Profile
      },
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(18),
              image: DecorationImage(
                image: NetworkImage(student['img']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 15),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student['name'],
                  style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.black87
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    student['reg'],
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
          
          // Edit/Delete Action
          IconButton(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade300),
            onPressed: () {
              _showActionSheet(context, student['name'], themeColor);
            },
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SHARED WIDGETS
// ==========================================

// 1. Top Bar Add Button (Modern Squircle)
Widget _buildTopAddButton(BuildContext context, Color color, VoidCallback onTap) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      height: 38,
      width: 38,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: 22,
      ),
    ),
  );
}

// 2. Edit/Delete Bottom Sheet
void _showActionSheet(BuildContext context, String title, Color themeColor) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              title,
              style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            _buildActionTile(
              icon: Icons.edit_rounded, 
              color: themeColor, 
              text: "Edit Details",
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            _buildActionTile(
              icon: Icons.delete_rounded, 
              color: Colors.red, 
              text: "Delete",
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildActionTile({required IconData icon, required Color color, required String text, required VoidCallback onTap}) {
  return ListTile(
    onTap: onTap,
    contentPadding: EdgeInsets.zero,
    leading: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color),
    ),
    title: Text(
      text, 
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600, 
        fontSize: 16,
        color: color == Colors.red ? Colors.red : Colors.black87
      )
    ),
    trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
  );
}