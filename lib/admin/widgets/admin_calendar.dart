import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Task Model
class CalendarTask {
  String title;
  String time;
  bool isCompleted;

  CalendarTask(this.title, {this.time = "All Day", this.isCompleted = false});
}

class AdminCalendar extends StatefulWidget {
  const AdminCalendar({super.key});

  @override
  State<AdminCalendar> createState() => _AdminCalendarState();
}

class _AdminCalendarState extends State<AdminCalendar> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // 1. HOLIDAYS
  final Map<DateTime, String> _holidays = {
    DateTime.utc(2026, 1, 26): "Republic Day",
    DateTime.utc(2026, 3, 29): "Holi",
    DateTime.utc(2026, 4, 14): "Vishu",
    DateTime.utc(2026, 5, 1): "May Day",
    DateTime.utc(2026, 8, 15): "Independence Day",
    DateTime.utc(2026, 8, 28): "Onam",
    DateTime.utc(2026, 10, 2): "Gandhi Jayanti",
    DateTime.utc(2026, 11, 8): "Diwali",
    DateTime.utc(2026, 12, 25): "Christmas",
  };

  // 2. TASKS DATA
  Map<DateTime, List<CalendarTask>> _tasks = {};

  // 3. EDITING STATE
  // If true, shows the creation form at the top
  bool _isCreating = false;
  // If not null, shows the edit form for this specific task
  CalendarTask? _editingTask;

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    _tasks = {
      today: [
        CalendarTask("Submit Department Report", time: "09:00 AM", isCompleted: true),
        CalendarTask("Staff Meeting", time: "02:00 PM", isCompleted: false),
        CalendarTask("Review Budget Proposal 2026", time: "05:00 PM", isCompleted: false),
      ],
      DateTime.utc(2026, 1, 26): [
        CalendarTask("Flag Hoisting Ceremony", time: "08:00 AM", isCompleted: false),
      ],
    };
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  List<CalendarTask> _getTasksForDay(DateTime day) {
    final normalizedDate = DateTime.utc(day.year, day.month, day.day);
    return _tasks[normalizedDate] ?? [];
  }

  // --- ACTIONS ---

  void _startCreating() {
    setState(() {
      _isCreating = true;
      _editingTask = null; // Cancel any active edits
      _titleController.clear();
      _selectedTime = TimeOfDay.now();
    });
  }

  void _startEditing(CalendarTask task) {
    setState(() {
      _isCreating = false; // Cancel creation
      _editingTask = task;
      _titleController.text = task.title;
      try {
        final dt = DateFormat.jm().parse(task.time);
        _selectedTime = TimeOfDay.fromDateTime(dt);
      } catch (_) {
        _selectedTime = TimeOfDay.now();
      }
    });
  }

  void _cancelAction() {
    setState(() {
      _isCreating = false;
      _editingTask = null;
      _titleController.clear();
      FocusScope.of(context).unfocus(); // Close keyboard
    });
  }

  void _saveTask() {
    if (_titleController.text.isEmpty) return;

    final normalizedDate = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    final timeStr = DateFormat.jm().format(DateTime(2024, 1, 1, _selectedTime.hour, _selectedTime.minute));

    setState(() {
      if (_isCreating) {
        // Create New
        if (_tasks[normalizedDate] == null) _tasks[normalizedDate] = [];
        _tasks[normalizedDate]!.add(CalendarTask(_titleController.text, time: timeStr));
      } else if (_editingTask != null) {
        // Update Existing
        _editingTask!.title = _titleController.text;
        _editingTask!.time = timeStr;
      }
      // Reset
      _isCreating = false;
      _editingTask = null;
      _titleController.clear();
    });
  }

  void _deleteTask(CalendarTask task) {
    final normalizedDate = DateTime.utc(_selectedDay.year, _selectedDay.month, _selectedDay.day);
    setState(() {
      _tasks[normalizedDate]?.remove(task);
      if (_tasks[normalizedDate]?.isEmpty ?? false) {
        _tasks.remove(normalizedDate);
      }
      // If we were editing this task, stop editing
      if (_editingTask == task) {
        _editingTask = null;
        _isCreating = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);

    return Column(
      children: [
        // --- CALENDAR ---
        ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.6),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(isDark ? 0.1 : 0.6), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              padding: const EdgeInsets.all(16),
              child: TableCalendar(
                firstDay: DateTime.utc(2024, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                eventLoader: _getTasksForDay,
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                  titleTextStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
                  leftChevronIcon: Icon(Icons.chevron_left, color: textColor),
                  rightChevronIcon: Icon(Icons.chevron_right, color: textColor),
                ),
                startingDayOfWeek: StartingDayOfWeek.monday,
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: GoogleFonts.inter(color: textColor),
                  weekendTextStyle: GoogleFonts.inter(color: Colors.grey),
                  markersMaxCount: 1,
                  markerDecoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                ),
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _cancelAction(); // Cancel any editing when changing days
                  });
                },
                calendarBuilders: CalendarBuilders(
                  prioritizedBuilder: (context, day, focusedDay) {
                    final normalizeDate = DateTime.utc(day.year, day.month, day.day);
                    final isHoliday = _holidays.keys.any((d) => 
                      d.year == normalizeDate.year && d.month == normalizeDate.month && d.day == normalizeDate.day
                    );
                    if (isHoliday) {
                      return Center(
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.red.withOpacity(0.5))
                          ),
                          child: Center(child: Text('${day.day}', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold))),
                        ),
                      );
                    }
                    return null;
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return Center(
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.4), blurRadius: 8)]
                        ),
                        child: Center(child: Text('${day.day}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600))),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // --- TASK SECTION ---
        _buildTaskSection(context, textColor),

        const SizedBox(height: 16),
        _buildUpcomingHolidays(context, textColor),
      ],
    );
  }

  Widget _buildTaskSection(BuildContext context, Color textColor) {
    final tasks = _getTasksForDay(_selectedDay);
    final dateStr = DateFormat('MMMM d').format(_selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "AGENDA - $dateStr", 
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)
            ),
            
            // Add Button (Hidden if Creating)
            if (!_isCreating)
              InkWell(
                onTap: _startCreating,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.add_rounded, size: 14, color: Colors.blue),
                      const SizedBox(width: 4),
                      Text("Add Task", style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // 1. INLINE CREATION FORM (Appears at top)
        if (_isCreating) ...[
          _buildInlineForm(context, textColor),
          const SizedBox(height: 12),
        ],

        // 2. TASK LIST
        if (tasks.isEmpty && !_isCreating)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
            ),
            child: Column(
              children: [
                Icon(Icons.assignment_add, color: Colors.grey.withOpacity(0.3), size: 32),
                const SizedBox(height: 8),
                Text("No tasks yet.", style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
              ],
            ),
          )
        else
          ...tasks.map((task) {
            // Check if this specific task is being edited
            if (_editingTask == task) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildInlineForm(context, textColor),
              );
            }
            return _buildModernTaskItem(context, task, textColor);
          }),
      ],
    );
  }

  // --- THE INLINE FORM WIDGET ---
  Widget _buildInlineForm(BuildContext context, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 1.5), // Highlight border
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Input Row
          Row(
            children: [
              // TextField
              Expanded(
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: GoogleFonts.inter(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText: "Enter task title...",
                    hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onSubmitted: (_) => _saveTask(),
                ),
              ),
              const SizedBox(width: 8),
              
              // Time Picker Chip
              InkWell(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(context: context, initialTime: _selectedTime);
                  if (picked != null) setState(() => _selectedTime = picked);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _selectedTime.format(context),
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: _cancelAction,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Cancel", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _saveTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text("Save", style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // --- DISPLAY WIDGET ---
  Widget _buildModernTaskItem(BuildContext context, CalendarTask task, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => task.isCompleted = !task.isCompleted),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Theme.of(context).cardColor.withOpacity(0.7), Theme.of(context).cardColor.withOpacity(0.4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: task.isCompleted ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.15),
                width: 1
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                // Checkbox
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: task.isCompleted ? const Color(0xFF10B981) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: task.isCompleted ? const Color(0xFF10B981) : Colors.grey.withOpacity(0.4),
                      width: 2
                    ),
                  ),
                  child: task.isCompleted ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
                ),
                const SizedBox(width: 16),
                
                // Text Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: task.isCompleted ? Colors.grey.shade400 : textColor,
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                          decorationColor: Colors.grey.shade400,
                          fontWeight: task.isCompleted ? FontWeight.w400 : FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        task.time,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: task.isCompleted ? Colors.grey.shade300 : Colors.blue.shade300,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Edit Button (Only if not completed)
                if (!task.isCompleted)
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                    onPressed: () => _startEditing(task),
                    tooltip: "Edit Inline",
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                
                const SizedBox(width: 12),
                
                // Delete Button
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, size: 18, color: Colors.red.shade300),
                  onPressed: () => _deleteTask(task),
                  tooltip: "Delete",
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUpcomingHolidays(BuildContext context, Color textColor) {
    final now = DateTime.now();
    final sortedHolidays = _holidays.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    final upcomingEntry = sortedHolidays.firstWhere(
      (e) => e.key.isAfter(now.subtract(const Duration(days: 1))),
      orElse: () => sortedHolidays.last,
    );

    if (upcomingEntry.key.year < now.year && upcomingEntry != sortedHolidays.last) {
       return const SizedBox.shrink();
    }

    final formattedDate = DateFormat('MMM d, yyyy').format(upcomingEntry.key);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), shape: BoxShape.circle),
            child: const Icon(Icons.celebration_rounded, color: Colors.red, size: 16),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "UPCOMING EVENT",
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: Colors.red.withOpacity(0.7)),
              ),
              Text(
                "${upcomingEntry.value} - $formattedDate",
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          )
        ],
      ),
    );
  }
}