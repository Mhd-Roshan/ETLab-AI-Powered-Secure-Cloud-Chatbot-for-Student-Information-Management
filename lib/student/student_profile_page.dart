import 'package:flutter/material.dart';

class StudentProfilePage extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String? attendancePercentage;

  const StudentProfilePage({
    super.key, 
    required this.userData,
    this.attendancePercentage,
  });

  @override
  Widget build(BuildContext context) {
    // Primary Theme Color
    const Color primaryColor = Color(0xFF5C51E1);

    // Handle empty data case
    if (userData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No profile data available"),
            SizedBox(height: 8),
            Text("Please add student data to Firestore", 
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. TOP HEADER SECTION (Gradient + Avatar)
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _buildHeaderGradient(primaryColor),
              Positioned(
                top: 100,
                child: _buildProfileImage(userData['registrationNumber']),
              ),
            ],
          ),

          const SizedBox(height: 70),

          // 2. NAME & EMAIL
          Text(
            "${userData['firstName'] ?? 'Student'} ${userData['lastName'] ?? ''}",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            userData['email'] ?? "student@edlab.edu",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14, letterSpacing: 0.5),
          ),

          const SizedBox(height: 25),

          // 3. STATS ROW (GPA & Semester only)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("GPA", userData['gpa']?.toString() ?? "0.0", Colors.orange),
                _buildStatCard("Semester", userData['semester']?.toString() ?? "N/A", Colors.blue),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 4. ATTENDANCE SECTION (Like Attendance Screen)
          _buildAttendanceSection(attendancePercentage ?? "81.8%"),

          const SizedBox(height: 25),

          // 4. DETAILED INFORMATION SECTIONS
          _buildInfoSection("Academic Details", [
            _buildInfoTile(Icons.school_rounded, "Registration No", userData['registrationNumber']),
            _buildInfoTile(Icons.account_balance_rounded, "Department", userData['department']),
            _buildInfoTile(Icons.calendar_today_rounded, "Batch", "${userData['batch'] ?? 'N/A'}"),
          ]),

          _buildInfoSection("Contact Information", [
            _buildInfoTile(Icons.phone_android_rounded, "Phone", userData['phone'] ?? "+91 98765 43210"),
            _buildInfoTile(Icons.email_rounded, "Email", userData['email']),
            _buildInfoTile(Icons.location_on_rounded, "College", userData['collegeName']),
          ]),

          // 5. ACTION BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildActionButton(
                  label: "Edit Profile",
                  icon: Icons.edit_note_rounded,
                  color: primaryColor,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: "Logout",
                  icon: Icons.logout_rounded,
                  color: Colors.redAccent,
                  onPressed: () {
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  isOutlined: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper: Header Gradient
  Widget _buildHeaderGradient(Color color) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withBlue(255).withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
      ),
    );
  }

  // Helper: Profile Image with Edit Badge
  Widget _buildProfileImage(String? regNo) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))
            ],
          ),
          child: CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$regNo'),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 5,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  // Helper: Individual Stat Card
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // Helper: Section Container
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
          const Divider(height: 25, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  // Helper: Info List Tile
  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: const Color(0xFFF0EFFF), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: const Color(0xFF5C51E1), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
                Text(value ?? "Not Set", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Action Button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: color),
              label: Text(label, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white),
              label: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
    );
  }

  // Helper: Attendance Section (Like Attendance Screen)
  Widget _buildAttendanceSection(String attendancePercentage) {
    // Subject data calculated to give 81.8% overall attendance (90/110 = 81.82%)
    final List<Map<String, dynamic>> subjectAttendance = [
      {'subject': 'Data Structures', 'code': 'CS401', 'present': 23, 'total': 28, 'color': const Color(0xFF5C51E1), 'icon': Icons.code},
      {'subject': 'Mathematics', 'code': 'MA402', 'present': 25, 'total': 30, 'color': Colors.orange, 'icon': Icons.calculate},
      {'subject': 'Python Programming', 'code': 'CS403', 'present': 22, 'total': 27, 'color': Colors.green, 'icon': Icons.computer},
      {'subject': 'Digital Fundamentals', 'code': 'EC404', 'present': 20, 'total': 25, 'color': Colors.red, 'icon': Icons.memory},
    ];

    int totalPresent = subjectAttendance.fold(0, (sum, item) => sum + (item['present'] as int));
    int totalClasses = subjectAttendance.fold(0, (sum, item) => sum + (item['total'] as int));
    double overallPercentage = (totalPresent / totalClasses) * 100;

    Color cardColor;
    String status;
    IconData statusIcon;

    if (overallPercentage >= 75) {
      cardColor = const Color(0xFF4CAF50);
      status = "Good Standing";
      statusIcon = Icons.check_circle;
    } else if (overallPercentage >= 65) {
      cardColor = const Color(0xFFFFA726);
      status = "Need Improvement";
      statusIcon = Icons.warning;
    } else {
      cardColor = const Color(0xFFEF5350);
      status = "Critical";
      statusIcon = Icons.error;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Attendance Overview", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 15),
          
          // Overall Attendance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [cardColor, cardColor.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: cardColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Circular Progress
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: overallPercentage / 100,
                        strokeWidth: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          "${overallPercentage.toStringAsFixed(1)}%",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "$totalPresent/$totalClasses",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Overall Attendance",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        overallPercentage >= 75 
                            ? "Keep up the good work!" 
                            : "Attend more classes to reach 75%",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          const Text("Subject-wise Breakdown", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          
          // Subject Cards
          ...subjectAttendance.map((subject) => _buildSubjectAttendanceCard(subject)).toList(),
        ],
      ),
    );
  }

  // Helper: Subject Attendance Card
  Widget _buildSubjectAttendanceCard(Map<String, dynamic> subject) {
    int present = subject['present'];
    int total = subject['total'];
    double percentage = (present / total) * 100;
    Color subjectColor = subject['color'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Subject Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: subjectColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  subject['icon'],
                  color: subjectColor,
                  size: 18,
                ),
              ),
              
              const SizedBox(width: 10),
              
              // Subject Name & Code
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject['subject'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      subject['code'],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Percentage Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: percentage >= 75 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${percentage.toStringAsFixed(1)}%",
                  style: TextStyle(
                    color: percentage >= 75 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 6,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(subjectColor),
            ),
          ),
          
          const SizedBox(height: 6),
          
          // Present/Total Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$present Present / $total Total",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                "${total - present} Absent",
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
