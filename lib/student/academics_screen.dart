import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'timetable_screen.dart';
import 'attendance_screen.dart';
import 'results_screen.dart';
import 'assignments_screen.dart';

class AcademicsScreen extends StatefulWidget {
  const AcademicsScreen({super.key});

  @override
  State<AcademicsScreen> createState() => _AcademicsScreenState();
}

class _AcademicsScreenState extends State<AcademicsScreen> {
  // Reference to the collection created in your firebase_init.js
  final CollectionReference _announcementsRef = 
      FirebaseFirestore.instance.collection('announcements');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      // No BottomNavigationBar here! It should be in your Main Dashboard file.
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              const SizedBox(height: 24),
              _buildAiInsightCard(),
              const SizedBox(height: 24),
              // Real-world Firestore Section
              _buildRealtimeUpcomingSection(), 
              const SizedBox(height: 24),
              _buildGridMenu(context),
            ],
          ),
        ),
      ),
    );
  }

  // --- 1. Top Bar ---
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Using a Drawer trigger if you have a drawer, else just an icon
        Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 28),
            onPressed: () => Scaffold.of(context).openDrawer(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
        const Text(
          "Academics",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Stack(
          children: [
            const Icon(Icons.notifications_outlined, size: 28),
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            )
          ],
        )
      ],
    );
  }

  // --- 2. AI Insight Card (Static for now, Logic can be added later) ---
  Widget _buildAiInsightCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF3D6AF2), Color(0xFF7E5BEF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D6AF2).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      "AI INSIGHT",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "New",
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                RichText(
                  text: const TextSpan(
                    style: TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                    children: [
                      TextSpan(text: "Your attendance in "),
                      TextSpan(
                        text: "Mathematics",
                        style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                      ),
                      TextSpan(text: " is trending lower. Check schedule for make-up classes."),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- 3. Real-time Firestore Section ---
  Widget _buildRealtimeUpcomingSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Upcoming",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                // Navigate to a full announcements page
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "See All",
                  style: TextStyle(
                    color: Color(0xFF3D6AF2),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // STREAM BUILDER: Fetches data live from Firebase
        StreamBuilder<QuerySnapshot>(
          stream: _announcementsRef
              .where('isActive', isEqualTo: true) // Only active items
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              // Show error with fallback to dummy data
              debugPrint("Firebase Error: ${snapshot.error}");
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Using offline data. Check Firebase connection.",
                            style: TextStyle(color: Colors.orange[800], fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildEmptyState(), // Show dummy events
                ],
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyState();
            }

            // Sort documents by postedDate in code (instead of Firestore query)
            var docs = snapshot.data!.docs;
            docs.sort((a, b) {
              var aData = a.data() as Map<String, dynamic>;
              var bData = b.data() as Map<String, dynamic>;
              
              if (aData['postedDate'] == null) return 1;
              if (bData['postedDate'] == null) return -1;
              
              DateTime aDate = (aData['postedDate'] as Timestamp).toDate();
              DateTime bDate = (bData['postedDate'] as Timestamp).toDate();
              
              return bDate.compareTo(aDate); // Descending order
            });
            
            // Take only top 3
            var topDocs = docs.take(3).toList();

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topDocs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                var doc = topDocs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                // Map Firebase priority to Colors
                Color iconColor = Colors.blue;
                Color bgColor = Colors.blue.withValues(alpha: 0.1);
                IconData icon = Icons.notifications_active;

                if (data['priority'] == 'high') {
                  iconColor = Colors.red;
                  bgColor = Colors.red.withValues(alpha: 0.1);
                  icon = Icons.priority_high;
                } else if (data['priority'] == 'medium') {
                  iconColor = Colors.blue;
                  bgColor = Colors.blue.withValues(alpha: 0.1);
                  icon = Icons.event;
                } else {
                  iconColor = Colors.green;
                  bgColor = Colors.green.withValues(alpha: 0.1);
                  icon = Icons.info_outline;
                }

                // Format Timestamp
                String timeString = "Recently";
                if (data['postedDate'] != null) {
                  try {
                    DateTime dt = (data['postedDate'] as Timestamp).toDate();
                    timeString = DateFormat('MMM d, h:mm a').format(dt);
                  } catch (e) {
                    debugPrint("Error formatting date: $e");
                    timeString = data['time'] ?? "Soon";
                  }
                }

                return _buildEventCard(
                  icon: icon,
                  iconColor: iconColor,
                  bgColor: bgColor,
                  title: data['title'] ?? 'No Title',
                  subtitle: "${data['content']} • $timeString",
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    // Show dummy upcoming events when Firebase is empty
    return Column(
      children: [
        _buildEventCard(
          icon: Icons.mic,
          iconColor: Colors.deepPurple,
          bgColor: Colors.deepPurple.withValues(alpha: 0.1),
          title: "Guest Lecture: Future of AI",
          subtitle: "Auditorium • Tomorrow, 2:00 PM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.edit_calendar,
          iconColor: Colors.red,
          bgColor: Colors.red.withValues(alpha: 0.1),
          title: "Data Structure Mid-Term Exam",
          subtitle: "Exam Hall B • Monday, 9:00 AM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.assignment_turned_in,
          iconColor: Colors.orange,
          bgColor: Colors.orange.withValues(alpha: 0.1),
          title: "Python Project Submission",
          subtitle: "Online Portal • Due: Feb 15, 11:59 PM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.computer,
          iconColor: Colors.teal,
          bgColor: Colors.teal.withValues(alpha: 0.1),
          title: "Android Development Workshop",
          subtitle: "Computer Lab 3 • Friday, 10:00 AM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.sports_soccer,
          iconColor: Colors.green,
          bgColor: Colors.green.withValues(alpha: 0.1),
          title: "Inter-Department Football Match",
          subtitle: "Sports Ground • Saturday, 4:00 PM",
        ),
        const SizedBox(height: 12),
        _buildEventCard(
          icon: Icons.groups,
          iconColor: Colors.indigo,
          bgColor: Colors.indigo.withValues(alpha: 0.1),
          title: "Career Guidance Seminar",
          subtitle: "Seminar Hall • Next Week, 3:00 PM",
        ),
      ],
    );
  }

  Widget _buildEventCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: bgColor,
          radius: 24,
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      ),
    );
  }

  // --- 4. Grid Menu with Navigation ---
  Widget _buildGridMenu(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.calendar_today, 'label': 'Attendance', 'color': Colors.blue},
      {'icon': Icons.school, 'label': 'Results', 'color': Colors.indigo},
      {'icon': Icons.folder, 'label': 'Materials', 'color': Colors.orange},
      {'icon': Icons.payments, 'label': 'Fees', 'color': Colors.teal},
      {'icon': Icons.money_off, 'label': 'Over Dues', 'color': Colors.redAccent},
      {'icon': Icons.sports_soccer, 'label': 'Activities', 'color': Colors.orangeAccent},
      {'icon': Icons.event, 'label': 'Calendar', 'color': Colors.blueAccent}, // Links to Timetable
      {'icon': Icons.assignment, 'label': 'Assignments', 'color': Colors.deepPurple},
      {'icon': Icons.quiz, 'label': 'Q-Bank', 'color': Colors.tealAccent.shade700},
      {'icon': Icons.book, 'label': 'Syllabus', 'color': Colors.cyan},
      {'icon': Icons.work, 'label': 'Placement', 'color': Colors.purple},
      {'icon': Icons.newspaper, 'label': 'News', 'color': Colors.red},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return GestureDetector(
          onTap: () {
            // Navigation Logic
            if (item['label'] == 'Calendar') {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const TimetableScreen())
              );
            } else if (item['label'] == 'Attendance') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AttendanceScreen())
              );
            } else if (item['label'] == 'Results') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResultsScreen()),
              );
            } else if (item['label'] == 'Assignments') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AssignmentsScreen()),
              );
            }
            // Add other navigation logic here (e.g., Fees, Materials)
          },
          child: Column(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: item['color'].withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(item['icon'], color: item['color'], size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                item['label'],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              )
            ],
          ),
        );
      },
    );
  }
}