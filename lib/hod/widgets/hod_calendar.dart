import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/services/staff_service.dart';
import 'package:intl/intl.dart';

class HodRightPanel extends StatefulWidget {
  const HodRightPanel({super.key});

  @override
  State<HodRightPanel> createState() => _HodRightPanelState();
}

class _HodRightPanelState extends State<HodRightPanel> {
  final StaffService service =
      StaffService(); // Reusing staff service for tasks
  Timer? _taskCheckTimer;
  final Set<String> _alertedTasks = {};

  @override
  void initState() {
    super.initState();
    _taskCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkTaskTimes();
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _checkTaskTimes();
    });
  }

  @override
  void dispose() {
    _taskCheckTimer?.cancel();
    super.dispose();
  }

  void _checkTaskTimes() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(
            'staff_tasks',
          ) // Shared with staff for now or use hod_tasks
          .where('isDone', isEqualTo: false)
          .get();

      final now = DateTime.now();
      final currentTime = TimeOfDay(hour: now.hour, minute: now.minute);

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final timeLabel = data['timeLabel'] as String?;

        if (timeLabel == null || _alertedTasks.contains(doc.id)) continue;

        final taskTime = _parseTimeLabel(timeLabel);
        if (taskTime == null) continue;

        if (taskTime.hour == currentTime.hour &&
            taskTime.minute == currentTime.minute) {
          _alertedTasks.add(doc.id);
          await service.toggleTask(doc.id, false);

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
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            data['title'] ?? 'Task',
                            style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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

  TimeOfDay? _parseTimeLabel(String timeLabel) {
    try {
      final parts = timeLabel.trim().split(' ');
      if (parts.length != 2) return null;
      final timeParts = parts[0].split(':');
      if (timeParts.length != 2) return null;
      int hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      final isPM = parts[1].toUpperCase() == 'PM';
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
                    final timeString = selectedTime.format(context);
                    service.addTask(taskCtrl.text, timeString);
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
                    service.updateTask(docId, taskCtrl.text, timeString);
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
              service.deleteTask(docId);
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(DateTime.now()),
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: Color(0xFF001FF4),
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
            _buildModernCalendar(),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegend('Today', const Color(0xFF001FF4), isBox: true),
                _buildLegend('Sunday', const Color(0xFFEF4444)),
                _buildLegend('Festival', const Color(0xFFF59E0B)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "TASKS",
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
                      size: 20,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: service.getTasks(),
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
                  children: snapshot.data!.docs
                      .map((doc) => _buildTaskItem(doc))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "RECENT ACTIVITY",
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "LIVE",
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: service.getHodActivities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return StreamBuilder<QuerySnapshot>(
                    stream: service.getRecentActivities(),
                    builder: (context, annSnap) {
                      if (!annSnap.hasData || annSnap.data!.docs.isEmpty) {
                        return _buildEmptyState();
                      }
                      return _buildActivityTimeline(annSnap.data!.docs);
                    },
                  );
                }

                return _buildActivityTimeline(snapshot.data!.docs);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTimeline(List<QueryDocumentSnapshot> docs) {
    final items = docs.take(5).toList();
    return Column(
      children: items.asMap().entries.map((entry) {
        final isLast = entry.key == items.length - 1;
        final data = entry.value.data() as Map<String, dynamic>;
        final title = data['title'] ?? 'Activity';
        final subtitle = data['subtitle'] ?? data['content'] ?? '';

        // Format timestamp
        String timeStr = 'Just now';
        final ts = data['timestamp'] ?? data['postedDate'];
        if (ts != null) {
          final dt = (ts as Timestamp).toDate();
          final diff = DateTime.now().difference(dt);
          if (diff.inMinutes < 1)
            timeStr = 'Just now';
          else if (diff.inMinutes < 60)
            timeStr = '${diff.inMinutes}m ago';
          else if (diff.inHours < 24)
            timeStr = '${diff.inHours}h ago';
          else
            timeStr = '${diff.inDays}d ago';
        }

        // Icon mapping
        final iconName = data['icon'] ?? 'circle';
        IconData actIcon;
        Color actColor;
        switch (iconName) {
          case 'assignment':
            actIcon = Icons.assignment_outlined;
            actColor = const Color(0xFF6366F1);
            break;
          case 'people':
            actIcon = Icons.people_outline_rounded;
            actColor = const Color(0xFF10B981);
            break;
          case 'school':
            actIcon = Icons.school_outlined;
            actColor = const Color(0xFFF59E0B);
            break;
          case 'announcement':
            actIcon = Icons.campaign_outlined;
            actColor = const Color(0xFFEC4899);
            break;
          default:
            actIcon = Icons.circle_notifications_outlined;
            actColor = const Color(0xFF64748B);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: actColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(actIcon, size: 15, color: actColor),
                ),
                if (!isLast)
                  Container(
                    width: 1.5,
                    height: 32,
                    color: const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF334155),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: const Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF94A3B8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

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
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            "No tasks pending",
            style: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 14),
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
          InkWell(
            onTap: () => service.toggleTask(doc.id, isDone),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 24,
              height: 24,
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
          Expanded(
            child: InkWell(
              onTap: () => _promptEditTask(doc.id, title, time),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF334155),
                    ),
                  ),
                  Text(
                    time,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: () => _promptEditTask(doc.id, title, time),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              InkWell(
                onTap: () => _promptDeleteTask(doc.id),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Icon(
                    Icons.delete_outline,
                    size: 20,
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

  Widget _buildNavIcon(IconData icon) {
    return InkWell(
      onTap: () {},
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
      ),
    );
  }

  Widget _buildModernCalendar() {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final now = DateTime.now();
    final todayDay = now.day.toString();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final firstWeekday = firstDayOfMonth.weekday;
    final festivals = {'14': 'Valentine\'s Day', '16': 'Presidents\' Day'};

    List<TableRow> rows = [
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
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
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

    List<String> currentWeek = [];
    for (int i = 1; i < firstWeekday; i++) currentWeek.add('');
    for (int day = 1; day <= daysInMonth; day++) {
      currentWeek.add(day.toString());
      if (currentWeek.length == 7) {
        rows.add(
          _buildCalRow(currentWeek, activeDay: todayDay, festivals: festivals),
        );
        currentWeek = [];
      }
    }
    if (currentWeek.isNotEmpty) {
      while (currentWeek.length < 7) currentWeek.add('');
      rows.add(
        _buildCalRow(currentWeek, activeDay: todayDay, festivals: festivals),
      );
    }

    return Table(children: rows);
  }

  TableRow _buildCalRow(
    List<String> days, {
    required String activeDay,
    Map<String, String>? festivals,
  }) {
    return TableRow(
      children: days.asMap().entries.map((entry) {
        final day = entry.value;
        final isToday = day == activeDay;
        final isSunday = entry.key == 6;
        final isFestival = festivals != null && festivals.containsKey(day);

        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isToday ? const Color(0xFF001FF4) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isFestival
                  ? Border.all(color: const Color(0xFFF59E0B), width: 1)
                  : null,
            ),
            child: Center(
              child: Text(
                day,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                  color: isToday
                      ? Colors.white
                      : (isSunday
                            ? const Color(0xFFEF4444)
                            : (isFestival
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF1E293B))),
                ),
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
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isBox ? 2 : 4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();
  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('hh:mm:ss a').format(DateTime.now()),
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF64748B),
      ),
    );
  }
}
