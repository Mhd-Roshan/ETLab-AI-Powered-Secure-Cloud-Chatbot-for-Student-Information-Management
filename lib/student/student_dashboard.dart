import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/student_service.dart';
import '../services/edlab_ai_service.dart';
import 'widgets/student_sidebar.dart';
import 'student_profile_page.dart';
import 'timetable_screen.dart';
import 'academics_screen.dart';
import 'attendance_screen.dart';
import 'results_screen.dart';
import 'package:edlab/student/student_chat_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fees_screen.dart';
import 'survey_screen.dart';
import 'notifications_screen.dart';
import 'exams_screen.dart';
import 'assignments_screen.dart';
import '../login.dart';

class StudentDashboard extends StatefulWidget {
  final String studentRegNo;
  const StudentDashboard({super.key, required this.studentRegNo});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final StudentService _studentService = StudentService();

  // Use lazy initialization for AI service to handle hot reload state updates safer
  EdLabAIService? _aiServiceInstance;
  EdLabAIService get _aiService => _aiServiceInstance ??= EdLabAIService();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Cache the insight future - now a list of insights
  Future<List<Map<String, String>>>? _insightListFuture;

  // Timer for cycling insights
  Timer? _insightTimer;
  int _currentInsightIndex = 0;
  List<Map<String, String>> _insights = [];

  // 0 = Home, 1 = Academics, 2 = Chat, 3 = Profile
  int _currentIndex = 0;

  // FAB Position
  Offset? _fabOffset;

  // Cache the future to prevent rebuilds - initialized on first access
  Future<DocumentSnapshot?>? _userDataFuture;

  Future<DocumentSnapshot?> _getUserData() {
    _userDataFuture ??= _studentService.getUserByIdentifier(
      widget.studentRegNo,
    );
    return _userDataFuture!;
  }

  @override
  void dispose() {
    _insightTimer?.cancel();
    super.dispose();
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
                  Text(
                    '${futureSnapshot.error}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        if (!futureSnapshot.hasData ||
            futureSnapshot.data == null ||
            !futureSnapshot.data!.exists) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.person_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Student not found'),
                  const SizedBox(height: 8),
                  Text(
                    'ID: ${widget.studentRegNo}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                        (route) => false,
                      );
                    },
                    child: const Text('Go Back to Login'),
                  ),
                ],
              ),
            ),
          );
        }

        // Extract data from users collection
        final doc = futureSnapshot.data!;
        final Map<String, dynamic> userData =
            doc.data() as Map<String, dynamic>? ?? {};

        // Map users collection fields to student fields
        final Map<String, dynamic> studentData = {
          'registrationNumber': userData['username'] ?? widget.studentRegNo,
          'firstName':
              userData['firstname'] ?? userData['firstName'] ?? 'Student',
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
            // Use the attendance from user data directly, or fallback to calculation if available
            String attendancePercentage =
                (userData['attendancePercentage']?.toString() ?? "75") + "%";

            if (attendanceSnap.hasData &&
                attendanceSnap.data!.docs.isNotEmpty) {
              double val =
                  attendanceSnap.data!.docs
                      .where((d) => d['status'] == 'present')
                      .length /
                  attendanceSnap.data!.docs.length;
              attendancePercentage = "${(val * 100).toInt()}%";
            }

            // Define Pages - Each screen is now separate with stable keys
            final List<Widget> pages = [
              _buildHomeScreen(
                studentData,
                attendancePercentage,
                key: const ValueKey('home_screen'),
              ), // Index 0 - Home
              AcademicsScreen(
                key: const ValueKey('academics_screen'),
                attendancePercentage: attendancePercentage,
                studentId: widget.studentRegNo,
              ), // Index 1 - Academics
              StudentChatScreen(
                key: const ValueKey('chat_screen'),
                studentData: studentData,
                onBack: () => setState(() => _currentIndex = 0),
              ), // Index 2 - Chat
              StudentProfilePage(
                key: const ValueKey('profile_screen'),
                userData: studentData,
                attendancePercentage: attendancePercentage,
                studentId: doc.id,
              ), // Index 3 - Profile
            ];

            // Initialize FAB position only once
            if (_fabOffset == null) {
              final size = MediaQuery.of(context).size;
              _fabOffset = Offset(size.width - 70, size.height - 160);
            }

            return Stack(
              children: [
                Scaffold(
                  key: _scaffoldKey,
                  backgroundColor: const Color(0xFFF8F9FE),

                  // Sidebar (only show on home screen)
                  drawer: _currentIndex == 0
                      ? StudentSidebar(
                          name:
                              "${studentData['firstName'] ?? 'Student'} ${studentData['lastName'] ?? ''}",
                          email: studentData['email'] ?? '',
                          regNo: widget.studentRegNo,
                          profileUrl:
                              'https://i.pravatar.cc/150?u=${studentData['registrationNumber'] ?? 'default'}',
                        )
                      : null,

                  // AppBar: Show only on Home (Index 0)
                  appBar: _currentIndex == 0
                      ? AppBar(
                          backgroundColor: Colors.white,
                          elevation: 0,
                          scrolledUnderElevation: 0,
                          toolbarHeight: 60,
                          leadingWidth: 80,
                          leading: Container(
                            margin: const EdgeInsets.only(left: 16),
                            child: Row(
                              children: [
                                Container(
                                  height: 8,
                                  width: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "LIVE",
                                  style: GoogleFonts.pressStart2p(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize:
                                        10, // Pixel fonts are often large, so reducing size
                                  ),
                                ),
                              ],
                            ),
                          ),
                          title: Image.asset('assets/edlab.png', height: 40),
                          centerTitle: true,
                          actions: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const NotificationsScreen(),
                                  ),
                                );
                              },
                              child: Stack(
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    size: 28,
                                  ),
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                          ],
                        )
                      : null, // Hide AppBar on other pages if they have their own
                  // Body Content - Switch based on current index using IndexedStack
                  body: IndexedStack(index: _currentIndex, children: pages),

                  // Bottom Navigation Bar - THE ONE AND ONLY
                  bottomNavigationBar: _buildBottomNavBar(),
                ),

                // DRAGGABLE FLOATING ACTION BUTTON
                if (_currentIndex == 0 && _fabOffset != null)
                  Positioned(
                    left: _fabOffset!.dx,
                    top: _fabOffset!.dy,
                    child: GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          _fabOffset = Offset(
                            _fabOffset!.dx + details.delta.dx,
                            _fabOffset!.dy + details.delta.dy,
                          );
                        });
                      },
                      child: _buildFloatingActionButton(),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ================= HOME SCREEN BUILDER =================
  Widget _buildHomeScreen(
    Map<String, dynamic> studentData,
    String attendance, {
    Key? key,
  }) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildHeader(studentData, attendance),
          const SizedBox(height: 20),
          _buildAIInsightCard(studentData, attendance),
          const SizedBox(height: 25),

          _buildScheduleSection(
            studentData['department'] ?? 'CSE',
            studentData['semester'] ?? 4,
          ),
          const SizedBox(height: 25),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quick Actions",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
                icon: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: Color(0xFF001FF4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildActionGrid(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  // ================= WIDGETS =================

  Widget _buildHeader(Map<String, dynamic> studentData, String attendance) {
    return Row(
      children: [
        Stack(
          children: [
            CircleAvatar(
              radius: 38,
              backgroundColor: const Color(0xFF001FF4),
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
                      String firstName = (studentData['firstName'] ?? 'S')
                          .toString()
                          .trim();
                      String lastName = (studentData['lastName'] ?? '')
                          .toString()
                          .trim();

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
                    color: Color(0xFF001FF4),
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
              Text(
                studentData['department']?.toString().toUpperCase() == 'MCA'
                    ? "Master Of Computer Application"
                    : (studentData['department'] ??
                          "Master Of Computer Application"),
                style: GoogleFonts.poppins(
                  color: Colors.grey,
                  fontSize: 12, // Slightly smaller to help it fit
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                "${studentData['firstName'] ?? 'ROSHAN'}".toUpperCase(),
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "Semester ${studentData['semester'] ?? '1'}",
                style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildCircularAttendance(attendance),
      ],
    );
  }

  Widget _buildScheduleSection(String dept, int sem) {
    // 1. Get ALL classes for today
    final allClasses = _getAllClassesForDay();
    final now = DateTime.now();
    final dateFormat = DateFormat("hh:mm a");

    // 2. Filter relevant classes (Ongoing or Future)
    List<Map<String, dynamic>> relevantClasses = [];

    for (var cls in allClasses) {
      try {
        // Parse class time
        final timeStr = cls['time'] as String;
        final parsedTime = dateFormat.parse(timeStr);
        final startTime = DateTime(
          now.year,
          now.month,
          now.day,
          parsedTime.hour,
          parsedTime.minute,
        );
        // Assume 1 hour duration if not specified
        final endTime = startTime.add(const Duration(hours: 1));

        // Logic:
        // - ongoing: start <= now < end
        // - future: now < start
        // - past: end <= now

        if (now.isBefore(endTime)) {
          // It's either ongoing or future -> keep it
          // Check if it is "Now"
          bool isNow =
              now.isAfter(startTime) || now.isAtSameMomentAs(startTime);

          relevantClasses.add({
            ...cls,
            'startTime': startTime,
            'endTime': endTime,
            'isNow': isNow,
          });
        }
      } catch (e) {
        debugPrint("Error parsing time for ${cls['subject']}: $e");
      }
    }

    // Sort by time just in case
    relevantClasses.sort(
      (a, b) =>
          (a['startTime'] as DateTime).compareTo(b['startTime'] as DateTime),
    );

    // Take top 3
    final displayClasses = relevantClasses.take(3).toList();

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
                  color: Color(0xFF001FF4),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (displayClasses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
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
                Icon(
                  Icons.check_circle_outline,
                  size: 40,
                  color: Colors.green.withOpacity(0.5),
                ),
                const SizedBox(height: 10),
                const Text(
                  "All classes completed! 🎉",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayClasses.length,
            itemBuilder: (context, index) {
              final classData = displayClasses[index];
              final isLast = index == displayClasses.length - 1;
              final isNow = classData['isNow'] as bool;

              return _scheduleTimelineItem(
                classData['subject'],
                classData['time'],
                isNow ? "Ongoing Class" : "Room ${classData['room'] ?? 'S4'}",
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

  // Get raw list of all classes for the day
  List<Map<String, dynamic>> _getAllClassesForDay() {
    final now = DateTime.now();
    final weekday = now.weekday;

    // Weekend check
    if (weekday == DateTime.saturday || weekday == DateTime.sunday) {
      return [];
    }

    // Mock data based on odd/even days
    if (now.day % 2 == 0) {
      return [
        {
          'time': '09:00 AM',
          'subject': 'ADVANCED DATA STRUCTURES',
          'color': Colors.orange,
          'room': 'A101',
        },
        {
          'time': '11:00 AM',
          'subject': 'PROGRAMMING LAB',
          'color': Colors.purple,
          'room': 'Lab 2',
        },
        {
          'time': '02:00 PM',
          'subject': 'MATHEMATICAL FOUNDATIONS FOR COMPUTING',
          'color': Colors.blue,
          'room': 'B203',
        },
      ];
    } else {
      return [
        {
          'time': '08:30 AM',
          'subject': 'ADVANCED SOFTWARE ENGINEERING',
          'color': Colors.green,
          'room': 'Room 302',
        },
        {
          'time': '10:30 AM',
          'subject': 'DIGITAL FUNDAMENTALS AND COMPUTER ARCHITECTURE',
          'color': Colors.red,
          'room': 'C105',
        },
        {
          'time': '01:00 PM',
          'subject': 'WEB PROGRAMMING LAB',
          'color': Colors.teal,
          'room': 'Web Lab',
        },
        {
          'time': '03:00 PM',
          'subject': 'DATA STRUCTURES LAB',
          'color': Colors.orange,
          'room': 'Lab 1',
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
                  color: Color(0xFF001FF4),
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
        _actionCard(
          Icons.calendar_month_rounded,
          "Attendance",
          Colors.blue,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    AttendanceScreen(studentRegNo: widget.studentRegNo),
              ),
            );
          },
        ),
        _actionCard(Icons.bar_chart_rounded, "Results", Colors.purple, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ResultsScreen()),
          );
        }),
        _actionCard(Icons.school_rounded, "Assignments", Colors.green, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssignmentsScreen()),
          );
        }),
        _actionCard(
          Icons.account_balance_wallet_rounded,
          "Fees",
          Colors.teal,
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    FeesScreen(studentId: widget.studentRegNo),
              ),
            );
          },
        ),
        _actionCard(Icons.poll_rounded, "Survey", Colors.pink, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  SurveyScreen(studentId: widget.studentRegNo),
            ),
          );
        }),
        _actionCard(Icons.event_note_rounded, "Exams", Colors.red, () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExamsScreen(studentId: widget.studentRegNo),
            ),
          );
        }),
      ],
    );
  }

  Widget _actionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
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

  Widget _buildCircularAttendance(String attendanceStr) {
    // Parse percentage string "75%" -> 0.75
    double val = 0.75; // Default fallback
    try {
      final clean = attendanceStr.replaceAll('%', '').trim();
      val = double.parse(clean) / 100.0;
    } catch (e) {
      val = 0.75;
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
  }

  Widget _buildAIInsightCard(
    Map<String, dynamic> studentData,
    String attendance,
  ) {
    // Safety check for insights list
    // ignore: unnecessary_null_comparison
    if (_insights == null) {
      _insights = [];
    }

    // Fetch insights if not already loaded
    if (_insights.isEmpty && _insightListFuture == null) {
      final academicData = {
        'gpa': studentData['gpa'] ?? 0.0,
        'semester': studentData['semester'] ?? 1,
      };
      final aiContext = <String, dynamic>{
        'firstName': studentData['firstName'],
        'department': studentData['department'],
        'attendance': attendance.replaceAll('%', ''),
      };

      _insightListFuture = _aiService.getStudentInsights(
        aiContext,
        academicData,
      );

      _insightListFuture!
          .then((data) {
            if (mounted) {
              setState(() {
                _insights = data;
                _currentInsightIndex = 0;
              });

              _insightTimer?.cancel();
              if (_insights.isNotEmpty) {
                _insightTimer = Timer.periodic(const Duration(seconds: 10), (
                  timer,
                ) {
                  if (mounted && _insights.isNotEmpty) {
                    setState(() {
                      _currentInsightIndex =
                          (_currentInsightIndex + 1) % _insights.length;
                    });
                  }
                });
              }
            }
          })
          .catchError((e) {
            debugPrint("Insight error: $e");
            if (mounted) {
              setState(() {
                _insights = [
                  {
                    'title': 'Welcome Back',
                    'message': 'Check your schedule for today.',
                  },
                ];
              });
            }
          });
    }

    // Determine what to display
    String title = "AI INSIGHT";
    String message = "Analyzing your performance...";
    bool isLoading = _insights.isEmpty;

    if (_insights.isNotEmpty) {
      int index = _currentInsightIndex;
      if (index < 0 || index >= _insights.length) {
        index = 0;
        _currentInsightIndex = 0;
      }
      final item = _insights[index];
      title = item['title'] ?? "Insight";
      message = item['message'] ?? "Keep pushing forward.";
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF001FF4), Color(0xFF8C82FF)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001FF4).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isLoading)
                      const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                    else
                      const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 16,
                      ),
                    const SizedBox(width: 5),
                    const Text(
                      "AI INSIGHT",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                  child: Column(
                    key: ValueKey<int>(_currentInsightIndex),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.auto_awesome, color: Colors.white, size: 30),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.home_outlined, "Home"),
            _buildNavItem(1, Icons.business_center_outlined, "Acads"),
            _buildNavItem(2, Icons.chat_bubble_outline_rounded, "Chat"),
            _buildNavItem(3, Icons.person_outline_rounded, "Profile"),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    bool isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 18 : 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF001FF4) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade400,
              size: 22,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF001FF4),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001FF4).withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => setState(() => _currentIndex = 2),
        backgroundColor: const Color(0xFF001FF4),
        elevation: 0,
        shape: const CircleBorder(),
        mini: true,
        child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
      ),
    );
  }
}
