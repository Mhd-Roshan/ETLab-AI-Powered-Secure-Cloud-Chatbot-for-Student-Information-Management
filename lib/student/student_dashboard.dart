import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/student_service.dart';
import 'widgets/student_sidebar.dart';

class StudentDashboard extends StatefulWidget {
  final String studentRegNo;
  const StudentDashboard({super.key, required this.studentRegNo});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final StudentService _studentService = StudentService();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _studentService.getStudentProfile(widget.studentRegNo),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        var student = snapshot.data!;

        List<Widget> pages = [
          _buildHomeContent(student),
          const Center(child: Text("Academics Content")),
          const Center(child: Text("AI Assistant Chat")),
          const Center(child: Text("Profile Settings")),
        ];

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF8F9FE),
          drawer: StudentSidebar(
            name: "${student['firstName']} ${student['lastName']}",
            email: student['email'],
            profileUrl:
                'https://i.pravatar.cc/150?u=${student['registrationNumber']}',
          ),
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
              : null,
          body: pages[_currentIndex],
          bottomNavigationBar: _buildBottomNavBar(),
          floatingActionButton: _currentIndex == 0
              ? _buildFloatingActionButton()
              : null,
        );
      },
    );
  }

  Widget _buildHomeContent(DocumentSnapshot student) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          _buildHeader(student),
          const SizedBox(height: 20),
          _buildAIInsightCard(),
          const SizedBox(height: 25),

          _buildScheduleSection(student['department'], student['semester']),
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

  Widget _buildHeader(DocumentSnapshot student) {
    return Row(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 38,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/150?u=rahul',
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF5C51E1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 12),
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
                "${student['firstName']} ${student['lastName']}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                "${student['department']} | Sem ${student['semester']}",
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
            const Text(
              "See All",
              style: TextStyle(
                color: Color(0xFF5C51E1),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: _studentService.getCourses(dept, sem),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const LinearProgressIndicator();
            var courses = snapshot.data!.docs;
            if (courses.isEmpty) return const Text("No classes today.");

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                var data = courses[index];
                return _scheduleTimelineItem(
                  data['courseName'],
                  "9:00 AM - 10:00 AM",
                  index == 0 ? "Now" : "Room S4",
                  index == 0,
                  index == courses.length - 1,
                  index == 0,
                  Icons.book_outlined,
                  const Color(0xFFE8E7FF),
                  const Color(0xFF5C51E1),
                );
              },
            );
          },
        ),
      ],
    );
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
        _actionCard(Icons.calendar_month_rounded, "Attendance", Colors.blue),
        _actionCard(Icons.bar_chart_rounded, "Results", Colors.purple),
        _actionCard(Icons.assignment_turned_in_rounded, "Tasks", Colors.green),
        _actionCard(Icons.account_balance_wallet_rounded, "Fees", Colors.teal),
        _actionCard(Icons.poll_rounded, "Survey", Colors.pink),
        _actionCard(Icons.event_note_rounded, "Exams", Colors.red),
      ],
    );
  }

  Widget _actionCard(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
              color: color.withOpacity(0.1),
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
            color: const Color(0xFF5C51E1).withOpacity(0.3),
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
                const Text(
                  "Attendance Alert",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
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
            color: const Color(0xFF5C51E1).withOpacity(0.3),
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
