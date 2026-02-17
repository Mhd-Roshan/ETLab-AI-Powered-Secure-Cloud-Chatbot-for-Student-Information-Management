import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/services/admin_service.dart';
import 'package:intl/intl.dart';

class AdminRightPanel extends StatefulWidget {
  const AdminRightPanel({super.key});

  @override
  State<AdminRightPanel> createState() => _AdminRightPanelState();
}

class _AdminRightPanelState extends State<AdminRightPanel> {
  final AdminService _adminService = AdminService();
  Timer? _taskCheckTimer;
  final Set<String> _alertedTasks = {}; // Track which tasks have been alerted

  @override
  void initState() {
    super.initState();
    
    // Check tasks every 30 seconds (more frequent)
    _taskCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkTaskTimes();
    });
    
    // Also check immediately on load
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _checkTaskTimes();
    });
  }

  @override
  void dispose() {
    _taskCheckTimer?.cancel();
    super.dispose();
  }

  // Check if any task time has been reached
  void _checkTaskTimes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('admin_tasks')
          .where('isDone', isEqualTo: false)
          .get();

      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timeLabel = data['timeLabel'] as String?;
        
        if (timeLabel == null || _alertedTasks.contains(doc.id)) continue;

        // Parse time from label (e.g., "3:05 PM")
        final taskTime = _parseTimeLabel(timeLabel);
        if (taskTime == null) continue;

        // Check if task time matches current time
        if (taskTime.hour == currentTime.hour && 
            taskTime.minute == currentTime.minute) {
          
          // Mark as alerted to prevent duplicate processing
          _alertedTasks.add(doc.id);
          
          // Automatically mark task as done
          await _adminService.toggleTask(doc.id, false);
          
          // Show success notification
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Task Completed',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            data['title'] ?? 'Task',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking task times: $e');
    }
  }

  // Parse time label like "3:05 PM" to TimeOfDay
  TimeOfDay? _parseTimeLabel(String timeLabel) {
    try {
      final parts = timeLabel.trim().split(' ');
      if (parts.length != 2) return null;

      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;

      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts[1].toUpperCase() == 'PM';

      // Convert to 24-hour format
      if (isPM && hour != 12) {
        hour += 12;
      } else if (!isPM && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
  }

  // --- DIALOG: Add Task (With Time) ---
  void _promptAddTask() {
    TextEditingController taskCtrl = TextEditingController();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Add New Task"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskCtrl,
                  decoration: const InputDecoration(
                    labelText: "Task Name",
                    hintText: "e.g., Review Applications",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.access_time, size: 20),
                  label: Text(
                    selectedTime.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (taskCtrl.text.isNotEmpty) {
                    // Format time as "3:05 PM"
                    final timeString = selectedTime.format(context);
                    _adminService.addTask(taskCtrl.text, timeString);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOG: Edit Task (With Time) ---
  void _promptEditTask(String docId, String currentTitle, String currentTime) {
    TextEditingController taskCtrl = TextEditingController(text: currentTitle);
    TimeOfDay selectedTime = _parseTimeLabel(currentTime) ?? TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Edit Task"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: taskCtrl,
                  decoration: const InputDecoration(
                    labelText: "Task Name",
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () async {
                    final TimeOfDay? picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                    );
                    if (picked != null) {
                      setDialogState(() {
                        selectedTime = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.access_time, size: 20),
                  label: Text(
                    selectedTime.format(context),
                    style: const TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () {
                  if (taskCtrl.text.isNotEmpty) {
                    final timeString = selectedTime.format(context);
                    _adminService.updateTask(docId, taskCtrl.text, timeString);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- DIALOG: Delete Confirmation ---
  void _promptDeleteTask(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Task?"),
        content: const Text("Are you sure you want to remove this task?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _adminService.deleteTask(docId);
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Calendar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(DateTime.now()),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Color(0xFF6366F1),
                      ),
                      SizedBox(width: 6),
                      _LiveClock(),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildNavIcon(Icons.chevron_left_rounded),
                  const SizedBox(width: 8),
                  _buildNavIcon(Icons.chevron_right_rounded),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 2. Calendar Grid
          _buildModernCalendar(),

          const SizedBox(height: 20),
          // Legends
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegend('Today', const Color(0xFF6366F1), isBox: true),
              _buildLegend('Sunday', const Color(0xFFEF4444)),
              _buildLegend('Festival', const Color(0xFFF59E0B)),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),

          // 3. FIREBASE TASKS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "TASKS",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              InkWell(
                onTap: _promptAddTask,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Task Stream
          StreamBuilder<QuerySnapshot>(
            stream: _adminService.getTasks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  return _buildTaskItem(doc);
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 24),

          // 4. FIREBASE ACTIVITY
          Text(
            "RECENT ACTIVITY",
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot>(
            stream: _adminService.getRecentActivities(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Text(
                  "No recent activity",
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String timeAgo = "Just now";
                  if (data['postedDate'] != null) {
                    Timestamp ts = data['postedDate'];
                    timeAgo = DateFormat('MMM d, h:mm a').format(ts.toDate());
                  }

                  return _buildActivityItem(
                    data['title'] ?? 'New Announcement',
                    timeAgo,
                    Colors.blueAccent,
                    Icons.notifications_none_outlined,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_turned_in_outlined,
            color: Colors.grey.shade300,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            "No tasks pending",
            style: GoogleFonts.poppins(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isDone = data['isDone'] ?? false;
    String title = data['title'] ?? 'Untitled';
    String time = data['timeLabel'] ?? 'Today';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFF8FAFC) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone ? Colors.transparent : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Checkbox (Toggle Done)
          InkWell(
            onTap: () => _adminService.toggleTask(doc.id, isDone),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF10B981) : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDone ? Colors.transparent : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),

          // Task Details (Click to Edit)
          Expanded(
            child: InkWell(
              onTap: () => _promptEditTask(doc.id, title, time),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF334155),
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Actions: Edit & Delete
          Row(
            children: [
              InkWell(
                onTap: () => _promptEditTask(doc.id, title, time),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _promptDeleteTask(doc.id),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline,
                    size: 16,
                    color: Colors.redAccent.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    Color color,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: color),
              ),
              Container(width: 2, height: 20, color: const Color(0xFFF1F5F9)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildModernCalendar() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now(); // February 9, 2026
    final todayDay = now.day.toString();
    
    // Calculate calendar for current month
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    
    // Get the weekday of the first day (1 = Monday, 7 = Sunday)
    final firstWeekday = firstDayOfMonth.weekday;
    
    // Define festivals/holidays for February 2026
    final festivals = {
      '14': 'Valentine\'s Day',
      '16': 'Presidents\' Day',
    };
    
    // Build calendar rows dynamically
    List<TableRow> rows = [
      // Header row with day names
      TableRow(
        children: days
            .asMap()
            .entries
            .map(
              (entry) => Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    entry.value,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      // Highlight Sunday column
                      color: entry.key == 6 
                          ? const Color(0xFFEF4444) 
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    ];
    
    // Build date cells
    List<String> currentWeek = [];
    int currentDayOfWeek = firstWeekday;
    
    // Add empty cells for days before the first day of month
    for (int i = 1; i < firstWeekday; i++) {
      currentWeek.add('');
    }
    
    // Add all days of the month
    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(day.toString());
      
      // When we have 7 days, create a row
      if (currentWeek.length == 7) {
        rows.add(_buildCalRow(
          currentWeek,
          activeDay: todayDay,
          startWeekday: currentDayOfWeek,
          festivals: festivals,
        ));
        currentWeek = [];
        currentDayOfWeek = 1; // Reset to Monday for next week
      }
    }
    
    // Add remaining days if any
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) {
        currentWeek.add('');
      }
      rows.add(_buildCalRow(
        currentWeek,
        activeDay: todayDay,
        startWeekday: currentDayOfWeek,
        festivals: festivals,
      ));
    }
    
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: rows,
    );
  }

  TableRow _buildCalRow(
    List<String> dates, {
    String? activeDay,
    int startWeekday = 1,
    Map<String, String>? festivals,
  }) {
    return TableRow(
      children: dates.asMap().entries.map((entry) {
        int index = entry.key;
        String date = entry.value;
        
        if (date.isEmpty) return const SizedBox.shrink();
        
        // Calculate the actual weekday for this date
        // startWeekday tells us what day of week the first cell is
        int actualWeekday = (startWeekday + index - 1) % 7 + 1;
        
        bool isToday = date == activeDay;
        bool isSunday = actualWeekday == 7;
        bool isFestival = festivals?.containsKey(date) ?? false;
        
        // Determine dot color
        Color? dotColor;
        if (isFestival) {
          dotColor = const Color(0xFFF59E0B); // Orange for festivals
        } else if (isSunday) {
          dotColor = const Color(0xFFEF4444); // Red for Sundays
        }
        
        return Center(
          child: Tooltip(
            message: isFestival ? festivals![date]! : (isSunday ? 'Sunday' : ''),
            child: Container(
              margin: const EdgeInsets.all(3),
              width: 32,
              height: 32,
              decoration: isToday
                  ? BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF6366F1),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    )
                  : null,
              child: Stack(
                children: [
                  // Date number
                  Center(
                    child: Text(
                      date,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                        color: isToday
                            ? const Color(0xFF6366F1)
                            : const Color(0xFF334155),
                      ),
                    ),
                  ),
                  // Dot indicator
                  if (dotColor != null)
                    Positioned(
                      bottom: 4,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLegend(String label, Color color, {bool isBox = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: isBox
              ? BoxDecoration(
                  border: Border.all(color: color, width: 2),
                  borderRadius: BorderRadius.circular(4),
                  color: color.withValues(alpha: 0.1),
                )
              : BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
          child: isBox
              ? null
              : Center(
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Separate widget for live clock - updates independently without rebuilding parent
class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  String _currentTime = '';

  @override
  void initState() {
    super.initState();
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
  }

  void _updateTime() {
    if (mounted) {
      setState(() {
        _currentTime = DateFormat('h:mm:ss a').format(DateTime.now());
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentTime,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF6366F1),
      ),
    );
  }
}
