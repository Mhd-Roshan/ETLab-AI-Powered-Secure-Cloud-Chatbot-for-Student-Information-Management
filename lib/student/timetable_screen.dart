import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();

  // Generate 15 days before and 15 days after today for a wider calendar range
  final List<DateTime> _calendarDays = List.generate(
    31,
    (index) => DateTime.now()
        .subtract(const Duration(days: 15))
        .add(Duration(days: index)),
  );

  @override
  void initState() {
    super.initState();

    // Find today's index
    int todayIndex = _calendarDays.indexWhere(
      (date) => DateUtils.isSameDay(date, DateTime.now()),
    );

    // Scroll to today after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (todayIndex != -1 && _scrollController.hasClients) {
        // Item width (65) + separator (12)
        double itemExtent = 65.0 + 12.0;
        double scrollPosition = todayIndex * itemExtent;

        // Center today in the view
        double screenWidth = MediaQuery.of(context).size.width;
        double targetScroll =
            scrollPosition -
            (screenWidth / 2) +
            (65.0 / 2) +
            16.0; // 16.0 is horizontal padding

        _scrollController.animateTo(
          targetScroll.clamp(0.0, _scrollController.position.maxScrollExtent),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Helper to get mock attendance for 4 periods
  List<bool?> _getAttendanceForDate(DateTime date) {
    // If it's a weekend, no periods
    if (date.weekday == DateTime.sunday || date.weekday == DateTime.saturday) {
      return [null, null, null, null];
    }

    // If it's in the future, periods aren't marked yet
    if (date.isAfter(DateTime.now().subtract(const Duration(hours: 24)))) {
      // Only show dots for today if it's already past some periods,
      // but for simplicity, let's say future days have no dots yet.
      if (DateUtils.isSameDay(date, DateTime.now())) {
        return [
          true,
          true,
          false,
          null,
        ]; // Today: 2 present, 1 absent, 1 pending
      }
      return [null, null, null, null];
    }

    // Mock logic for past days: mostly present, some absent
    final day = date.day;
    return [
      day % 5 != 0, // Period 1
      day % 7 != 0, // Period 2
      day % 4 != 0, // Period 3
      day % 6 != 0, // Period 4
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Formatters for the header
    bool isTodaySelected = DateUtils.isSameDay(_selectedDate, DateTime.now());
    String headerLabel = isTodaySelected
        ? "TODAY"
        : DateFormat('EEEE').format(_selectedDate).toUpperCase();
    String formattedHeaderDate = DateFormat(
      'MMMM d, yyyy',
    ).format(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background
      appBar: AppBar(
        title: const Text(
          "Timetable",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (!isTodaySelected)
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedDate = DateTime.now();
                });
              },
              child: const Text(
                "Today",
                style: TextStyle(
                  color: Color(0xFF5C51E1),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headerLabel,
                      style: const TextStyle(
                        color: Color(0xFF5C51E1),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedHeaderDate,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDateSelector(),
              const SizedBox(height: 24),
              _buildTodayScheduleHeader(),
              const SizedBox(height: 16),
              _buildClassList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector() {
    return SizedBox(
      height: 100, // Increased height to accommodate dots
      child: ListView.separated(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: _calendarDays.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = _calendarDays[index];
          final isSelected = DateUtils.isSameDay(date, _selectedDate);
          final attendance = _getAttendanceForDate(date);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
              });
            },
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 65,
                  height: 75,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF5C51E1) : Colors.white,
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
                        DateFormat('E').format(date).toUpperCase(), // e.g., WED
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                const SizedBox(height: 8),
                // Attendance Dots Row
                Row(
                  children: List.generate(4, (periodIndex) {
                    final isPresent = attendance[periodIndex];
                    Color dotColor = Colors.grey.shade300;
                    if (isPresent == true) {
                      dotColor = Colors.green;
                    } else if (isPresent == false) {
                      dotColor = Colors.red;
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: dotColor,
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 4. Today Schedule Header
  Widget _buildTodayScheduleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Today Schedule",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {
            _showWeeklyTimetableDialog();
          },
          child: const Text(
            "See All",
            style: TextStyle(
              color: Color(0xFF1A73E8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _showWeeklyTimetableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Weekly Timetable",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWeeklyRow("Mon", [
                  "ADVANCED DATA STRUCTURES",
                  "MATHEMATICAL FOUNDATIONS",
                  "PROGRAMMING LAB",
                ]),
                _buildWeeklyRow("Tue", [
                  "ADVANCED SOFTWARE ENGINEERING",
                  "COMPUTER ARCHITECTURE",
                  "WEB PROGRAMMING LAB",
                ]),
                _buildWeeklyRow("Wed", [
                  "ADVANCED DATA STRUCTURES",
                  "MATHEMATICAL FOUNDATIONS",
                  "DATA STRUCTURES LAB",
                ]),
                _buildWeeklyRow("Thu", [
                  "ADVANCED SOFTWARE ENGINEERING",
                  "COMPUTER ARCHITECTURE",
                  "PROGRAMMING LAB",
                ]),
                _buildWeeklyRow("Fri", [
                  "ADVANCED DATA STRUCTURES",
                  "ADVANCED SOFTWARE ENGINEERING",
                  "WEB PROGRAMMING LAB",
                ]),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyRow(String day, List<String> subjects) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF5C51E1),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: subjects
                .map(
                  (s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 10)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                )
                .toList(),
          ),
          const Divider(),
        ],
      ),
    );
  }

  // 5. Dynamic Class List
  Widget _buildClassList() {
    // Get classes based on selected date
    final classes = _getMockClassesForDate(_selectedDate);

    // Sub-header for tomorrow logic or specific date
    String subHeader = DateFormat('EEEE, MMM d').format(_selectedDate);
    if (DateUtils.isSameDay(
      _selectedDate,
      DateTime.now().add(const Duration(days: 1)),
    )) {
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
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
                      // Subject & Room
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['subject'],
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "Room ${item['room']}",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
}
