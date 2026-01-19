import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ==========================================
// LEVEL 1: DEPARTMENT SELECTION
// ==========================================

class StaffScreen extends StatelessWidget {
  final Color color;
  const StaffScreen({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    // KMCT Departments Data
    final List<Map<String, dynamic>> departments = [
      {"code": "MCA", "name": "Computer App.", "color": const Color(0xFF7F5AF0), "icon": Icons.dataset_linked_rounded},
      {"code": "MBA", "name": "Management", "color": const Color(0xFFFF2E63), "icon": Icons.pie_chart_rounded},
      {"code": "CSE", "name": "Comp. Science", "color": const Color(0xFF00C9A7), "icon": Icons.terminal_rounded},
      {"code": "EEE", "name": "Electrical", "color": const Color(0xFFFFD166), "icon": Icons.electric_bolt_rounded},
      {"code": "ME", "name": "Mechanical", "color": const Color(0xFFFF9F1C), "icon": Icons.settings_suggest_rounded},
      {"code": "ECE", "name": "Electronics", "color": const Color(0xFF2CB67D), "icon": Icons.memory_rounded},
      {"code": "CE", "name": "Civil Eng.", "color": const Color(0xFF2D81FF), "icon": Icons.holiday_village_rounded},
      {"code": "AIML", "name": "AI & ML", "color": const Color(0xFFF72585), "icon": Icons.psychology_rounded},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
        title: Text(
          "STAFF DIRECTORY",
          style: GoogleFonts.silkscreen(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.black87,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Department",
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w600
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: GridView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: departments.length + 1,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 28,
                mainAxisSpacing: 5,
                childAspectRatio: 1.5,
                ),
                itemBuilder: (context, index) {
                  if (index == departments.length) {
                    return _buildAddDepartmentItem(context);
                  }
                  final dept = departments[index];
                  return _buildMinimalDeptItem(context, dept);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalDeptItem(BuildContext context, Map<String, dynamic> dept) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DepartmentStaffListScreen(
              deptCode: dept['code'],
              deptName: dept['name'],
              themeColor: dept['color'],
            ),
          ),
        );
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: (dept['color'] as Color).withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(dept['icon'], color: dept['color'], size: 28),
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
          const SizedBox(height: 2),
          Text(
            dept['name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddDepartmentItem(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300, width: 2),
            ),
            child: Icon(Icons.add_rounded, color: Colors.grey.shade400, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            "NEW",
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// LEVEL 2: MCA FACULTY LIST
// ==========================================

class DepartmentStaffListScreen extends StatelessWidget {
  final String deptCode;
  final String deptName;
  final Color themeColor;

  const DepartmentStaffListScreen({
    super.key, 
    required this.deptCode, 
    required this.deptName,
    required this.themeColor
  });

  @override
  Widget build(BuildContext context) {
    
    // Exact MCA Faculty Data
    final List<Map<String, dynamic>> mcaFaculty = [
      {
        "name": "Mr. Ajayakumar K. K.",
        "role": "HOD",
        "img": "https://randomuser.me/api/portraits/men/55.jpg", 
        "qual": "M.Sc Physics, PGDCA, MCA.",
        "exp": "Over 31 years of experience in academics.",
        "area": "Area of Interest – Data structure, Linux Algorithms."
      },
      {
        "name": "Ms. Remmya C. B.",
        "role": "Assistant Professor",
        "img": "https://randomuser.me/api/portraits/women/44.jpg",
        "qual": "MCA.",
        "exp": "Close to 14 years of experience in academics.",
        "area": "Area of Interest – Logic design, Networks, Computer Org."
      },
      {
        "name": "Ms. Resmi S. R.",
        "role": "Assistant Professor",
        "img": "https://randomuser.me/api/portraits/women/68.jpg",
        "qual": "MCA.",
        "exp": "Over 15 years of experience in academics.",
        "area": "Area of Interest – DBMS, Operating Systems."
      },
      {
        "name": "Ms. Sharafunnissa O.",
        "role": "Assistant Professor",
        "img": "https://randomuser.me/api/portraits/women/29.jpg",
        "qual": "MCA.",
        "exp": "Over 16 years of experience.",
        "area": "Area of Interest – Advanced Operating systems, Computer Networks, Design and analysis of algorithms, Web data mining."
      },
      {
        "name": "Athulya Prabhakaran",
        "role": "Assistant Professor",
        "img": "https://randomuser.me/api/portraits/women/90.jpg",
        "qual": "M.Tech.",
        "exp": "2 years of experience in academics..",
        "area": "Area of Specialisation – Artificial Intelligence, Machine learning."
      },
    ];

    // Filter to ensure only MCA is shown or generic list if not MCA
    final List<Map<String, dynamic>> faculty = (deptCode == "MCA") 
        ? mcaFaculty 
        : []; // Empty for others as per "Only MCA needed" request

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              deptName,
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            Text(
              "Faculty Members",
              style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search_rounded, size: 28)),
          const SizedBox(width: 8),
          InkWell(
            onTap: (){},
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                color: themeColor,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: themeColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: faculty.isEmpty 
      ? Center(child: Text("No Data for $deptCode", style: GoogleFonts.dmSans(color: Colors.grey)))
      : ListView.separated(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: faculty.length,
        separatorBuilder: (ctx, i) => Divider(height: 40, color: Colors.grey.shade100),
        itemBuilder: (context, index) {
          return _buildDetailedStaffCard(context, faculty[index]);
        },
      ),
    );
  }

  Widget _buildDetailedStaffCard(BuildContext context, Map<String, dynamic> staff) {
    return Container(
      color: Colors.white,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Image
            Container(
              width: 80,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage(staff['img']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // 2. Name & Role Column
            SizedBox(
              width: 90, 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staff['name'],
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staff['role'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),

            // 3. Vertical Divider Line
            Container(
              width: 1,
              color: Colors.grey.shade200,
              margin: const EdgeInsets.symmetric(horizontal: 10),
            ),

            // 4. Details Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoText(staff['qual']),
                  const SizedBox(height: 4),
                  _buildInfoText(staff['exp']),
                  const SizedBox(height: 6),
                  Text(
                    staff['area'],
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // 5. Action Menu (Edit/Delete)
            GestureDetector(
               onTap: () => _showActionSheet(context, staff['name'], themeColor),
               child: Container(
                 padding: const EdgeInsets.only(left: 8, bottom: 8),
                 color: Colors.transparent, // expand touch area
                 child: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey.shade300),
               ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        color: Colors.grey.shade600,
        height: 1.3,
      ),
    );
  }

  // Action Sheet for Edit/Delete
  void _showActionSheet(BuildContext context, String name, Color themeColor) {
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
                name,
                style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              _buildActionTile(icon: Icons.edit_rounded, color: themeColor, text: "Edit Profile"),
              const SizedBox(height: 10),
              _buildActionTile(icon: Icons.delete_rounded, color: Colors.red, text: "Remove Staff"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionTile({required IconData icon, required Color color, required String text}) {
    return ListTile(
      onTap: () {},
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
}