import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  // State for selected date
  DateTime _selectedDate = DateTime.now();
  
  // Generate the next 14 days for the calendar strip
  final List<DateTime> _calendarDays = List.generate(
    14, 
    (index) => DateTime.now().add(Duration(days: index)),
  );

  @override
  Widget build(BuildContext context) {
    // Formatters for the header
    String formattedHeaderDate = DateFormat('EEEE, MMM d').format(_selectedDate).toUpperCase();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      body: SafeArea(
        child: Stack(
          children: [
            // Main Content
            SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(formattedHeaderDate),
                  const SizedBox(height: 24),
                  _buildDateSelector(),
                  const SizedBox(height: 24),
                  _buildTodaysScheduleSection(),
                  const SizedBox(height: 24),
                  _buildUpcomingClassesHeader(),
                  const SizedBox(height: 16),
                  _buildClassList(),
                  const SizedBox(height: 100), // Space for bottom nav
                ],
              ),
            ),
            
            // Custom Floating Bottom Nav (Matching Screenshot)
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: _buildBottomNavBar(),
            ),
          ],
        ),
      ),
    );
  }

  // 1. Header Section
  Widget _buildHeader(String dateString) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateString,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                const Text(
                  "Timetable",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // 2. Horizontal Date Selector
  Widget _buildDateSelector() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _calendarDays.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = _calendarDays[index];
          final isSelected = DateUtils.isSameDay(date, _selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 65,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF1A73E8) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  if (!isSelected)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date), // e.g., Wed
                    style: TextStyle(
                      color: isSelected ? Colors.white70 : Colors.grey,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date), // e.g., 24
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // 3. "Today's Schedule" Section
  Widget _buildTodaysScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Schedule",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.blue.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4F8),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.grid_view_rounded, size: 20, color: Colors.black87),
                SizedBox(width: 8),
                Text(
                  "View All",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // 4. Upcoming Classes Header
  Widget _buildUpcomingClassesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Upcoming Classes",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            "See All",
            style: TextStyle(color: Color(0xFF1A73E8), fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  // 5. Dynamic Class List
  Widget _buildClassList() {
    // Get classes based on selected date
    final classes = _getMockClassesForDate(_selectedDate);

    // Sub-header for tomorrow logic or specific date
    String subHeader = DateFormat('EEEE, MMM d').format(_selectedDate);
    if (DateUtils.isSameDay(_selectedDate, DateTime.now().add(const Duration(days: 1)))) {
      subHeader = "Tomorrow, ${DateFormat('MMM d').format(_selectedDate)}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          subHeader,
          style: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        if (classes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: Text("No classes scheduled for this day.")),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: classes.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = classes[index];
              return Container(
                height: 60, // Matching the sleek look in screenshot
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30), // Pill shape
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      // Time Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: item['color'].withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['time'],
                          style: TextStyle(
                            color: item['color'],
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Subject Name
                      Expanded(
                        child: Text(
                          item['subject'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Room/Icon
                      Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  // 6. Custom Floating Navbar
  Widget _buildBottomNavBar() {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(Icons.home_rounded, false),
          _navItem(Icons.school, true), // Active
          _navItem(Icons.chat_bubble_rounded, false),
          _navItem(Icons.person, false),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon, 
          color: isActive ? const Color(0xFF1A73E8) : Colors.grey[400],
          size: 28,
        ),
        if (isActive)
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: Color(0xFF1A73E8),
              shape: BoxShape.circle,
            ),
          )
      ],
    );
  }

  // Mock Data Logic
  List<Map<String, dynamic>> _getMockClassesForDate(DateTime date) {
    // Returns different classes based on the day of the week to demonstrate functionality
    final weekday = date.weekday;

    if (weekday == DateTime.sunday || weekday == DateTime.saturday) {
      return []; // Weekend
    }

    // Mix up data slightly based on odd/even days
    if (date.day % 2 == 0) {
      return [
        {'time': '09:00 AM', 'subject': 'Mathematics', 'color': Colors.orange},
        {'time': '11:00 AM', 'subject': 'Computer Lab', 'color': Colors.purple},
        {'time': '02:00 PM', 'subject': 'Data Structure', 'color': Colors.blue},
      ];
    } else {
      return [
        {'time': '08:30 AM', 'subject': 'Python', 'color': Colors.green},
        {'time': '10:30 AM', 'subject': 'English Literature', 'color': Colors.red},
        {'time': '01:00 PM', 'subject': 'Android ', 'color': Colors.teal},
        {'time': '03:00 PM', 'subject': 'Digital Fundalmental', 'color': Colors.orange},
      ];
    }
  }
}