import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class UniversityExamScreen extends StatefulWidget {
  const UniversityExamScreen({super.key});

  @override
  State<UniversityExamScreen> createState() => _UniversityExamScreenState();
}

class _UniversityExamScreenState extends State<UniversityExamScreen> {
  String _selectedDept = 'All';
  final List<String> _departments = ['All', 'MCA', 'MBA'];
  bool _isProcessing = false; // Prevents duplicate clicks during DB check

  // --- HELPER: SHOW MESSAGES ---
  void _showMsg(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // --- FUNCTION: Schedule New Exam ---
  void _showScheduleDialog() {
    final subjectCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    final venueCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = const TimeOfDay(hour: 9, minute: 30);
    String selectedDept = 'MCA';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Schedule New Exam"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: subjectCtrl, decoration: const InputDecoration(labelText: "Subject Name", hintText: "e.g., Data Structures")),
                  const SizedBox(height: 12),
                  TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: "Course Code", hintText: "e.g., CS301")),
                  const SizedBox(height: 12),
                  TextField(controller: venueCtrl, decoration: const InputDecoration(labelText: "Venue/Hall", hintText: "e.g., Block A - Hall 1")),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    items: ['MCA', 'MBA', 'CSE', 'ECE', 'ME'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                    onChanged: (val) => setDialogState(() => selectedDept = val!),
                    decoration: const InputDecoration(labelText: "Department"),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: Text("Date: ${DateFormat('MMM d, yyyy').format(selectedDate)}"),
                    trailing: const Icon(Icons.calendar_today, size: 20),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (picked != null) setDialogState(() => selectedDate = picked);
                    },
                  ),
                  ListTile(
                    title: Text("Time: ${selectedTime.format(context)}"),
                    trailing: const Icon(Icons.access_time, size: 20),
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(context: context, initialTime: selectedTime);
                      if (picked != null) setDialogState(() => selectedTime = picked);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: _isProcessing ? null : () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  if (subjectCtrl.text.isEmpty || codeCtrl.text.isEmpty || venueCtrl.text.isEmpty) {
                    _showMsg("Please fill all fields", isError: true);
                    return;
                  }

                  setDialogState(() => _isProcessing = true);

                  // 1. Construct the DateTime
                  DateTime finalDateTime = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, selectedTime.hour, selectedTime.minute);
                  String courseCode = codeCtrl.text.trim().toUpperCase();
                  String venue = venueCtrl.text.trim().toUpperCase();

                  try {
                    final db = FirebaseFirestore.instance.collection('university_exams');

                    // --- DUPLICATION CHECK 1: Same Course on same day ---
                    // Note: We check if any exam with this code exists within the same 24 hour window
                    DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

                    final duplicateCourse = await db
                        .where('code', isEqualTo: courseCode)
                        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
                        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
                        .get();

                    if (duplicateCourse.docs.isNotEmpty) {
                      _showMsg("Exam for code '$courseCode' is already scheduled for this day!", isError: true);
                      setDialogState(() => _isProcessing = false);
                      return;
                    }

                    // --- DUPLICATION CHECK 2: Venue Conflict ---
                    // Check if the venue is already booked for the exact same date and time
                    final duplicateVenue = await db
                        .where('venue', isEqualTo: venue)
                        .where('date', isEqualTo: Timestamp.fromDate(finalDateTime))
                        .get();

                    if (duplicateVenue.docs.isNotEmpty) {
                      _showMsg("Venue '$venue' is already occupied at this time!", isError: true);
                      setDialogState(() => _isProcessing = false);
                      return;
                    }

                    // --- CREATE IF NO CONFLICTS ---
                    await db.add({
                      'subject': subjectCtrl.text.trim(),
                      'code': courseCode,
                      'venue': venue,
                      'department': selectedDept,
                      'date': Timestamp.fromDate(finalDateTime),
                      'status': 'Scheduled',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) Navigator.pop(context);
                    _showMsg("Exam scheduled successfully!");
                  } catch (e) {
                    _showMsg("Error: $e", isError: true);
                  } finally {
                    setDialogState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white),
                child: _isProcessing 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text("Schedule"),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- FUNCTION: Edit Existing Exam ---
  void _showEditDialog(String docId, Map<String, dynamic> currentData) {
    final subjectCtrl = TextEditingController(text: currentData['subject'] ?? '');
    final codeCtrl = TextEditingController(text: currentData['code'] ?? '');
    final venueCtrl = TextEditingController(text: currentData['venue'] ?? '');
    
    DateTime selectedDate = (currentData['date'] as Timestamp).toDate();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    String selectedDept = currentData['department'] ?? 'MCA';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Edit Exam"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: subjectCtrl,
                    decoration: const InputDecoration(
                      labelText: "Subject Name",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      labelText: "Subject Code",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedDept,
                    decoration: const InputDecoration(
                      labelText: "Department",
                      border: OutlineInputBorder(),
                    ),
                    items: ['MCA', 'MBA'].map((dept) {
                      return DropdownMenuItem(value: dept, child: Text(dept));
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedDept = val!),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: venueCtrl,
                    decoration: const InputDecoration(
                      labelText: "Venue",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) setDialogState(() => selectedDate = date);
                          },
                          icon: const Icon(Icons.calendar_today),
                          label: Text(DateFormat('MMM d, yyyy').format(selectedDate)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime,
                            );
                            if (time != null) setDialogState(() => selectedTime = time);
                          },
                          icon: const Icon(Icons.access_time),
                          label: Text(selectedTime.format(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: _isProcessing ? null : () async {
                  if (subjectCtrl.text.trim().isEmpty) {
                    _showMsg("Please enter subject name", isError: true);
                    return;
                  }

                  setDialogState(() => _isProcessing = true);

                  try {
                    DateTime finalDateTime = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    await FirebaseFirestore.instance
                        .collection('university_exams')
                        .doc(docId)
                        .update({
                      'subject': subjectCtrl.text.trim(),
                      'code': codeCtrl.text.trim(),
                      'department': selectedDept,
                      'venue': venueCtrl.text.trim(),
                      'date': Timestamp.fromDate(finalDateTime),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) Navigator.pop(context);
                    _showMsg("Exam updated successfully!");
                  } catch (e) {
                    _showMsg("Error: $e", isError: true);
                  } finally {
                    setDialogState(() => _isProcessing = false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(
                        color: Colors.white, 
                        strokeWidth: 2
                      )
                    ) 
                  : const Text("Update"),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _deleteExam(String docId) async {
    await FirebaseFirestore.instance.collection('university_exams').doc(docId).delete();
    _showMsg("Exam removed", isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 2)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("University Examinations", style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text("Manage schedules, halls, and invigilation", style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showScheduleDialog,
                        icon: const Icon(Icons.add_task_rounded, size: 18),
                        label: const Text("Schedule Exam"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrangeAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: _departments.map<Widget>((dept) => _buildFilterTab(dept)).toList())),
                  const SizedBox(height: 24),
                  _buildExamTable(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('university_exams').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        var docs = snapshot.data!.docs;
        int todayCount = 0;
        int upcoming = 0;
        DateTime now = DateTime.now();

        for (var doc in docs) {
          var data = doc.data() as Map<String, dynamic>;
          if (data['date'] != null) {
            DateTime d = (data['date'] as Timestamp).toDate();
            if (d.year == now.year && d.month == now.month && d.day == now.day) todayCount++;
            if (d.isAfter(now)) upcoming++;
          }
        }

        return Row(
          children: [
            _buildStatCard("Total Scheduled", "${docs.length}", Colors.blueAccent, Icons.assignment),
            const SizedBox(width: 20),
            _buildStatCard("Today's Exams", "$todayCount", Colors.orangeAccent, Icons.today),
            const SizedBox(width: 20),
            _buildStatCard("Upcoming", "$upcoming", Colors.green, Icons.event_available),
          ],
        );
      },
    );
  }

  Widget _buildExamTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 5))]),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('university_exams').orderBy('date').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()));
          var docs = snapshot.data?.docs ?? [];
          var filtered = docs.where((doc) => _selectedDept == 'All' || (doc.data() as Map)['department'] == _selectedDept).toList();
          if (filtered.isEmpty) return _buildEmptyState();

          return DataTable(
            columnSpacing: 20, horizontalMargin: 32, headingRowHeight: 60, dataRowMinHeight: 70, dataRowMaxHeight: 70,
            columns: const [
              DataColumn(label: Text("Subject", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Date & Time", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Department", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Venue", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Status", style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text("Action", style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: filtered.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              DateTime date = (data['date'] as Timestamp).toDate();
              return DataRow(cells: [
                DataCell(Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(data['subject'] ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(data['code'] ?? "--", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ])),
                DataCell(Text("${DateFormat('MMM d, yyyy').format(date)}\n${DateFormat('h:mm a').format(date)}", style: const TextStyle(fontSize: 12))),
                DataCell(Text(data['department'] ?? "--")),
                DataCell(Text(data['venue'] ?? "TBA")),
                DataCell(_buildStatusBadge(date)),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
                      onPressed: () => _showEditDialog(doc.id, data),
                      tooltip: "Edit Exam",
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      onPressed: () => _deleteExam(doc.id),
                      tooltip: "Delete Exam",
                    ),
                  ],
                )),
              ]);
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildFilterTab(String title) {
    bool isSelected = _selectedDept == title;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedDept = title),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(color: isSelected ? Colors.deepOrangeAccent : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? Colors.deepOrangeAccent : const Color(0xFFE2E8F0))),
          child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(0xFF64748B))),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Expanded(child: Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFF1F5F9)), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(children: [Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 20)), const SizedBox(width: 16), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)), const SizedBox(height: 4), Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)))])])));
  }

  Widget _buildStatusBadge(DateTime date) {
    DateTime now = DateTime.now();
    bool isPast = date.isBefore(now.subtract(const Duration(hours: 3)));
    bool isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    String text = isPast ? "Completed" : isToday ? "Today" : "Scheduled";
    Color color = isPast ? Colors.green : isToday ? Colors.blue : Colors.orange;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)));
  }

  Widget _buildEmptyState() {
    return Container(width: double.infinity, padding: const EdgeInsets.all(60), child: Column(children: [Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade300), const SizedBox(height: 16), Text("No exams scheduled", style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)))]));
  }
}