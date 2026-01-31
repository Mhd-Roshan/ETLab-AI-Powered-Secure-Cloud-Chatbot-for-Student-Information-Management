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

  // --- DIALOG: Add Task (With Time) ---
  void _promptAddTask() {
    TextEditingController taskCtrl = TextEditingController();
    // Pre-fill with current time (e.g., "3:05 PM")
    TextEditingController timeCtrl = TextEditingController(
      text: DateFormat('h:mm a').format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(
                labelText: "Time",
                hintText: "e.g., 10:00 AM",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, size: 20),
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
                // Pass both title and time to service
                _adminService.addTask(taskCtrl.text, timeCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // --- DIALOG: Edit Task (With Time) ---
  void _promptEditTask(String docId, String currentTitle, String currentTime) {
    TextEditingController taskCtrl = TextEditingController(text: currentTitle);
    TextEditingController timeCtrl = TextEditingController(text: currentTime);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            TextField(
              controller: timeCtrl,
              decoration: const InputDecoration(
                labelText: "Time",
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.access_time, size: 20),
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
                _adminService.updateTask(docId, taskCtrl.text, timeCtrl.text);
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
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
            color: Colors.black.withOpacity(0.03),
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
              Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: const Color(0xFF1E293B),
                ),
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
          // Holiday Legend
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "Holiday",
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
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
                    color: Colors.redAccent.withOpacity(0.6),
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
                  color: color.withOpacity(0.1),
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
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: days
              .map(
                (d) => Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      d,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        _buildCalRow(['', '', '', '1', '2', '3', '4'], holiday: '1'),
        _buildCalRow(['5', '6', '7', '8', '9', '10', '11']),
        _buildCalRow(['12', '13', '14', '15', '16', '17', '18']),
        _buildCalRow(['19', '20', '21', '22', '23', '24', '25']),
        _buildCalRow(
          ['26', '27', '28', '29', '30', '31', ''],
          activeDay: '29',
          holiday: '26',
        ),
      ],
    );
  }

  TableRow _buildCalRow(
    List<String> dates, {
    String? activeDay,
    String? holiday,
  }) {
    return TableRow(
      children: dates.map((date) {
        if (date.isEmpty) return const SizedBox.shrink();
        bool isActive = date == activeDay;
        bool isHoliday = date == holiday;
        return Center(
          child: Container(
            margin: const EdgeInsets.all(3),
            width: 32,
            height: 32,
            decoration: isActive
                ? BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  )
                : isHoliday
                ? BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Center(
              child: Text(
                date,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: (isActive || isHoliday)
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : isHoliday
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF334155),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
