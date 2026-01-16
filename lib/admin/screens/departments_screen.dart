import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DepartmentsScreen extends StatelessWidget {
  final Color color;
  const DepartmentsScreen({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    // KMCT Departments Data
    final List<Map<String, dynamic>> departments = [
      {"code": "MCA", "name": "Computer App.", "hod": "Mr. Ajayakumar K.K", "color": const Color(0xFF7F5AF0)},
      {"code": "MBA", "name": "Management", "hod": " Dr. N. K. Shamla", "color": const Color(0xFFFF2E63)},
      {"code": "CSE", "name": "Comp. Science", "hod": "Mr. Swaradh P", "color": const Color(0xFF00C9A7)},
      {"code": "EEE", "name": "Electrical", "hod": "Ms. Shamna P V", "color": const Color(0xFFFFD166)},
      {"code": "ME", "name": "Mechanical", "hod": " Dr. Sunu Surendran K.T", "color": const Color(0xFFFF9F1C)},
      {"code": "CE", "name": "Civil Eng.", "hod": "Ms. Sheeja T.V", "color": const Color(0xFF2D81FF)},
      {"code": "AIML", "name": "AI & ML", "hod": "Dr. Kalaiselvan", "color": const Color(0xFFF72585)},
      {"code": "ADS", "name": "Data Science", "hod": "Dr. Mahesh", "color": const Color(0xFF4361EE)},
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
          "DEPARTMENTS",
          style: GoogleFonts.silkscreen(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: () {},
            color: Colors.black54,
          )
        ],
      ),
      // FAB Removed from here
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          // Add 1 to count for the Add Button
          itemCount: departments.length + 1,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 28,
            mainAxisSpacing: 5,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, index) {
            // Check if this is the last item
            if (index == departments.length) {
              return _buildAddDepartmentItem(context);
            }

            final dept = departments[index];
            return _buildMinimalItem(dept);
          },
        ),
      ),
    );
  }

  // Standard Department Item
  Widget _buildMinimalItem(Map<String, dynamic> dept) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: (dept['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {},
              splashColor: (dept['color'] as Color).withOpacity(0.2),
              child: Center(
                child: Text(
                  dept['code'].substring(0, 1),
                  style: GoogleFonts.dmSans(
                    color: dept['color'],
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          dept['code'],
          style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
            fontSize: 10, // Slightly reduced to fit
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_rounded, size: 12, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                dept['hod'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11, // Slightly reduced to fit
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // The New "Add Button" Item
  Widget _buildAddDepartmentItem(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle Add Department Action
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 2,
                // Make it dashed if you use a custom painter, or solid like this for clean look
              ),
            ),
            child: Icon(
              Icons.add_rounded,
              color: Colors.grey.shade400,
              size: 30,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "NEW",
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.grey.shade400,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "Department",
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}