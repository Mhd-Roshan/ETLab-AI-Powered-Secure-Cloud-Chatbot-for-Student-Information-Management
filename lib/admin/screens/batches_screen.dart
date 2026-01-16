import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BatchesScreen extends StatelessWidget {
  final Color color;
  const BatchesScreen({super.key, required this.color});

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text("NEW BATCH", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: GridView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: departments.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4, 
            crossAxisSpacing: 12,
            // 1. Reduced spacing between rows significantly
            mainAxisSpacing: 12,
            childAspectRatio: 1.8, 
          ),
          itemBuilder: (context, index) {
            final dept = departments[index];
            return _buildMinimalItem(dept);
          },
        ),
      ),
    );
  }

  Widget _buildMinimalItem(Map<String, dynamic> dept) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Icon / Graphic
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

        // Code
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

        // Name
        Text(
          dept['name'],
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 4),

        // HOD Name
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_rounded, size: 15, color: Colors.grey.shade400),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                dept['hod'],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 13,
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
}