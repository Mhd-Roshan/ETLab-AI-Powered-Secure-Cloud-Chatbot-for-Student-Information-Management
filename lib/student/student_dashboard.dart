import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_service.dart';
import 'widgets/student_sidebar.dart';
import 'student_profile_page.dart';
import 'timetable_screen.dart';
import 'academics_screen.dart';
import 'attendance_screen.dart';
import 'results_screen.dart';
import 'student_chat_screen.dart';

class StudentDashboard extends StatefulWidget {
  final String studentRegNo;
  const StudentDashboard({super.key, required this.studentRegNo});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final StudentService _studentService = StudentService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 0 = Home, 1 = Academics, 2 = Chat, 3 = Profile
  int _currentIndex = 0;
  
  // Cache the future to prevent rebuilds - initialized on first access
  Future<DocumentSnapshot?>? _userDataFuture;

  Future<DocumentSnapshot?> _getUserData() {
    _userDataFuture ??= _studentService.getUserByIdentifier(widget.studentRegNo);
    return _userDataFuture!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot?>(
      future: _getUserData(),
      builder: (context, futureSnapshot) {
        if (futureSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (futureSnapshot.hasError) {
          debugPrint("Error: ${futureSnapshot.error}");
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error loading student data'),
                  const SizedBox(height: 8),
                  Text('${futureSnapshot.error}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          );
        }

        if (!futureSnapshot.hasData || futureSnapshot.data == null || !futureSnapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Student not found'),
                  const SizedBox(height: 8),
                  Text('ID: ${widget.studentRegNo}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

        // Extract data from users collection
        final doc = futureSnapshot.data!;
        final Map<String, dynamic> userData = doc.data() as Map<String, dynamic>? ?? {};
        
        // Map users collection fields to student fields
        final Map<String, dynamic> studentData = {
          'registrationNumber': userData['username'] ?? widget.studentRegNo,
          'firstName': userData['firstname'] ?? userData['firstName'] ?? 'Student',
          'lastName': userData['lastname'] ?? userData['lastName'] ?? '',
          'email': userData['email'] ?? '',
          'phone': userData['phone'] ?? '',
          'department': userData['department'] ?? 'N/A',
          'semester': userData['semester'] ?? 1,
          'batch': userData['batch'] ?? 2024,
          'gpa': userData['gpa'] ?? 0.0,
          'collegeCode': userData['collegeCode'] ?? '',
          'collegeName': userData['collegeName'] ?? '',
          'isActive': userData['isActive'] ?? true,
          'role': userData['role'] ?? 'student',
        };
        
        debugPrint("=== STUDENT DATA LOADED ===");
        debugPrint("User Data: $userData");
        debugPrint("Mapped Student Data: $studentData");

        // Get attendance for profile
        return StreamBuilder<QuerySnapshot>(
          stream: _studentService.getAttendance(widget.studentRegNo),
          builder: (context, attendanceSnap) {
            String attendancePercentage = "81.8%";
            if (attendanceSnap.hasData && attendanceSnap.data!.docs.isNotEmpty) {
              double val = attendanceSnap.data!.docs.where((d) => d['status'] == 'present').length /
                  attendanceSnap.data!.docs.length;
              attendancePercentage = "${(val * 100).toInt()}%";
            }

            // Define Pages - Each screen is now separate
            final List<Widget> pages = [
              _buildHomeScreen(studentData),     // Index 0 - Home
              const AcademicsScreen(),            // Index 1 - Academics  
              const StudentChatScreen(),          // Index 2 - Chat
              StudentProfilePage(
                userData: studentData,
                attendancePercentage: attendancePercentage,
              ),      // Index 3 - Profile
            ];

            return Scaffold(
              key: _scaffoldKey,
              backgroundColor: const Color(0xFFF8F9FE),
              
              // Sidebar (only show on home screen)
              drawer: _currentIndex == 0 
                ? StudentSidebar(
                    name: "${studentData['firstName'] ?? 'Student'} ${studentData['lastName'] ?? ''}",
                    email: studentData['email'] ?? '',
                    profileUrl: 'https://i.pravatar.cc/150?u=${studentData['registrationNumber'] ?? 'default'}',
                  )
                : null,

              // AppBar: Show only on Home (Index 0)
              appBar: _currentIndex == 0
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  toolbarHeight: 60,
                  leading: IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  ),
                  title: const Text(
                    'Dashboard',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: Colors.black,
                        size: 28,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 10),
                  ],
                )
              : null, // Hide AppBar on other pages if they have their own

          // Body Content - Switch based on current index
          body: pages[_currentIndex],

          // Bottom Navigation Bar - THE ONE AND ONLY
          bottomNavigationBar: _buildBottomNavBar(),

          // Floating Action Button (Only on Home)
          floatingActionButton: _currentIndex == 0
              ? _buildFloatingActionButton()
              : null,
        );
          },
        );
      },
    );
  }

  // ================= HOME SCREEN BUILDER =================
  Widget _buildHomeScreen(Map<String, dynamic> studentData) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildHeader(studentData),
          const SizedBox(height: 20),
          _buildAIInsightCard(),
          const SizedBox(height: 25),

          _buildScheduleSection(
            studentData['department'] ?? 'CSE', 
            studentData['semester'] ?? 4
          ),
          const SizedBox(height: 25),

          const Text(
            "Quick Actions",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          _buildActionGrid(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _buildHeader(Map<String, dynamic> studentData) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFF5C51E1),
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Colors.grey.shade200,
                child: ClipOval(
                  child: Image.network(
                    'https://i.pravatar.cc/150?u=${studentData['registrationNumber'] ?? 'default'}',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback to initials if image fails - with safety checks
                      String firstName = (studentData['firstName'] ?? 'S').toString().trim();
                      String lastName = (studentData['lastName'] ?? '').toString().trim();
                      
                      String initials = 'S';
                      if (firstName.isNotEmpty) {
                        initials = firstName[0];
                        if (lastName.isNotEmpty) {
                          initials += lastName[0];
                        }
                      }
                      
                      return Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initials.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          strokeWidth: 2,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                // CLICKING THE PENCIL NAVIGATES TO PROFILE TAB (Index 3)
                onTap: () {
                  setState(() {
                    _currentIndex = 3; 
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF5C51E1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, color: Colors.white, size: 12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome back,",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Text(
                "${studentData['firstName'] ?? 'Student'} ${studentData['lastName'] ?? 'User'}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${studentData['department'] ?? 'Dept'} | Sem ${studentData['semester'] ?? 'N/A'}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildCircularAttendance(),
      ],
    );
  }

  Widget _buildScheduleSection(String dept, int sem) {
    // Get today's classes from timetable
    final todayClasses = _getTodayClasses();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Schedule",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () {
                // Navigate to full timetable screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TimetableScreen(),
                  ),
                );
              },
              child: const Text(
                "See All",
                style: TextStyle(
                  color: Color(0xFF5C51E1),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        if (todayClasses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                "No classes today! 🎉",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: todayClasses.length > 3 ? 3 : todayClasses.length, // Show max 3
            itemBuilder: (context, index) {
              var classData = todayClasses[index];
              final isNow = index == 0; // First class is "now"
              final isLast = index == (todayClasses.length > 3 ? 2 : todayClasses.length - 1);
              
              return _scheduleTimelineItem(
                classData['subject'],
                classData['time'],
                isNow ? "Now" : "Room ${classData['room'] ?? 'S4'}",
                index == 0,
                isLast,
                isNow,
                Icons.book_outlined,
                const Color(0xFFE8E7FF),
                classData['color'],
              );
            },
          ),
      ],
    );
  }
  
  // Get today's classes based on day of week
  List<Map<String, dynamic>> _getTodayClasses() {
    final now = DateTime.now();
    final weekday = now.weekday;
    
    // Weekend check
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return [];
    }
    
    // Return classes based on odd/even days (matching timetable logic)
    if (now.day % 2 == 0) {
      return [
        {
          'time': '09:00 AM',
          'subject': 'Mathematics',
          'color': Colors.orange,
          'room': 'A101'
        },
        {
          'time': '11:00 AM',
          'subject': 'Computer Lab',
          'color': Colors.purple,
          'room': 'Lab 2'
        },
        {
          'time': '02:00 PM',
          'subject': 'Data Structure',
          'color': const Color(0xFF5C51E1),
          'room': 'B203'
        },
      ];
    } else {
      return [
        {
          'time': '08:30 AM',
          'subject': 'Python',
          'color': Colors.green,
          'room': 'Lab 1'
        },
        {
          'time': '10:30 AM',
          'subject': 'English Literature',
          'color': Colors.red,
          'room': 'C105'
        },
        {
          'time': '01:00 PM',
          'subject': 'Android',
          'color': Colors.teal,
          'room': 'Lab 3'
        },
        {
          'time': '03:00 PM',
          'subject': 'Digital Fundamental',
          'color': Colors.orange,
          'room': 'A202'
        },
      ];
    }
  }

  Widget _scheduleTimelineItem(
    String title,
    String time,
    String loc,
    bool isFirst,
    bool isLast,
    bool isNow,
    IconData icon,
    Color bg,
    Color ic,
  ) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: isFirst ? Colors.transparent : Colors.grey[300],
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                child: Icon(icon, color: ic, size: 20),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast ? Colors.transparent : Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    "$time • $loc",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          if (isNow)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E7FF),
                borderRadius: BorderRadius.circular(5),
              ),
              child: const Text(
                "Now",
                style: TextStyle(
                  color: Color(0xFF5C51E1),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      children: [
        _actionCard(Icons.calendar_month_rounded, "Attendance", Colors.blue, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AttendanceScreen(studentRegNo: widget.studentRegNo),
            ),
          );
        }),
        _actionCard(Icons.bar_chart_rounded, "Results", Colors.purple, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ResultsScreen(),
            ),
          );
        }),
        _actionCard(Icons.assignment_turned_in_rounded, "Tasks", Colors.green, null),
        _actionCard(Icons.account_balance_wallet_rounded, "Fees", Colors.teal, null),
        _actionCard(Icons.poll_rounded, "Survey", Colors.pink, null),
        _actionCard(Icons.event_note_rounded, "Exams", Colors.red, null),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularAttendance() {
    return StreamBuilder<QuerySnapshot>(
      stream: _studentService.getAttendance(widget.studentRegNo),
      builder: (context, snap) {
        double val = 0.0;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          val =
              snap.data!.docs.where((d) => d['status'] == 'present').length /
              snap.data!.docs.length;
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 55,
              height: 55,
              child: CircularProgressIndicator(
                value: val,
                strokeWidth: 5,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF8DC63F)),
              ),
            ),
            Text(
              "${(val * 100).toInt()}%",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAIInsightCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C51E1), Color(0xFF8C82FF)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C51E1).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 16),
                    SizedBox(width: 5),
                    Text(
                      "AI INSIGHT",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "Attendance Alert",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Reach 75% in Data Structures soon.",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.auto_awesome, color: Colors.white, size: 30),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF5C51E1),
        unselectedItemColor: Colors.grey.shade400,
        iconSize: 26,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            label: 'Academics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5C51E1).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => setState(() => _currentIndex = 2),
        backgroundColor: const Color(0xFF5C51E1),
        elevation: 0,
        shape: const CircleBorder(),
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
      ),
    );
  }
}