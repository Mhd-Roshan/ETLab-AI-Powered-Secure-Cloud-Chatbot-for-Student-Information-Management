import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class HostelScreen extends StatefulWidget {
  final Color color;
  const HostelScreen({super.key, this.color = Colors.teal});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> {
  // Default selected Block
  String _selectedBlock = 'Block A (Boys)';
  bool _isProcessing = false;

  // Available Blocks
  final List<String> _blocks = [
    'Block A (Boys)',
    'Block B (Girls)',
    'Block C (Staff)',
  ];

  // Room Types
  final List<String> _roomTypes = ['Non-AC', 'AC', 'Deluxe'];

  // --- ALLOCATE ROOM DIALOG ---
  void _showAllocateDialog({String? docId, Map<String, dynamic>? data, String? collection}) {
    final formKey = GlobalKey<FormState>();
    
    String? selectedPersonId = docId;
    String? selectedPersonName = data != null 
        ? "${data['firstName'] ?? data['name'] ?? ''} ${data['lastName'] ?? ''}" 
        : null;
    String? selectedCollection = collection ?? (_selectedBlock == 'Block C (Staff)' ? 'staff' : 'students');
    String hostelBlock = data?['hostelBlock'] ?? _selectedBlock;
    String roomNumber = data?['hostelRoom'] ?? '';
    String roomType = data?['roomType'] ?? 'Non-AC';
    bool feesPaid = data?['feesPaid'] ?? false;

    bool isEdit = docId != null && data?['hostelRoom'] != null;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isEdit ? Icons.edit_rounded : Icons.add_home_rounded,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  isEdit ? "Edit Room Allocation" : "Allocate Room",
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Person Type Selection (only for new allocation)
                      if (!isEdit)
                        Column(
                          children: [
                            DropdownButtonFormField<String>(
                              value: selectedCollection,
                              decoration: InputDecoration(
                                labelText: "Allocate To",
                                prefixIcon: const Icon(Icons.category_rounded, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'students', child: Text('Student')),
                                DropdownMenuItem(value: 'staff', child: Text('Staff')),
                              ],
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedCollection = val;
                                  selectedPersonId = null;
                                  selectedPersonName = null;
                                  // Auto-set block based on type
                                  if (val == 'staff') {
                                    hostelBlock = 'Block C (Staff)';
                                  } else {
                                    hostelBlock = _selectedBlock != 'Block C (Staff)' 
                                        ? _selectedBlock 
                                        : 'Block A (Boys)';
                                  }
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),

                      // Person Selection (only for new allocation)
                      if (!isEdit)
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection(selectedCollection!)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }

                            // Filter persons without hostel room
                            var availablePersons = snapshot.data!.docs
                                .where((doc) {
                                  var d = doc.data() as Map<String, dynamic>;
                                  // For students, check status
                                  if (selectedCollection == 'students') {
                                    return d['hostelRoom'] == null && d['status'] == 'active';
                                  }
                                  // For staff, just check hostel room
                                  return d['hostelRoom'] == null;
                                })
                                .toList();

                            return DropdownButtonFormField<String>(
                              key: ValueKey(selectedCollection), // Force rebuild when collection changes
                              value: selectedPersonId,
                              decoration: InputDecoration(
                                labelText: selectedCollection == 'students' ? "Select Student" : "Select Staff",
                                prefixIcon: const Icon(Icons.person_rounded, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (v) => v == null ? "Required" : null,
                              items: availablePersons.map((doc) {
                                var d = doc.data() as Map<String, dynamic>;
                                String name;
                                String identifier;
                                
                                if (selectedCollection == 'students') {
                                  name = "${d['firstName']} ${d['lastName'] ?? ''}";
                                  identifier = d['registrationNumber'] ?? '';
                                } else {
                                  name = "${d['firstName']} ${d['lastName'] ?? ''}";
                                  identifier = d['staffId'] ?? d['email'] ?? '';
                                }
                                
                                return DropdownMenuItem(
                                  value: doc.id,
                                  child: Text("$name ($identifier)"),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedPersonId = val;
                                  if (val != null) {
                                    var personDoc = availablePersons
                                        .firstWhere((doc) => doc.id == val);
                                    var d = personDoc.data() as Map<String, dynamic>;
                                    selectedPersonName = "${d['firstName']} ${d['lastName'] ?? ''}";
                                  }
                                });
                              },
                            );
                          },
                        ),
                      if (isEdit)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Editing allocation for: $selectedPersonName",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Hostel Block
                      DropdownButtonFormField<String>(
                        value: hostelBlock,
                        decoration: InputDecoration(
                          labelText: "Hostel Block",
                          prefixIcon: const Icon(Icons.apartment_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _blocks
                            .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => hostelBlock = val!),
                      ),
                      const SizedBox(height: 16),

                      // Room Number
                      TextFormField(
                        initialValue: roomNumber,
                        decoration: InputDecoration(
                          labelText: "Room Number",
                          hintText: "e.g., 101, 202",
                          prefixIcon: const Icon(Icons.meeting_room_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (v) => v!.isEmpty ? "Required" : null,
                        onChanged: (val) => roomNumber = val,
                      ),
                      const SizedBox(height: 16),

                      // Room Type
                      DropdownButtonFormField<String>(
                        value: roomType,
                        decoration: InputDecoration(
                          labelText: "Room Type",
                          prefixIcon: const Icon(Icons.bed_rounded, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _roomTypes
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (val) => setDialogState(() => roomType = val!),
                      ),
                      const SizedBox(height: 16),

                      // Fees Paid
                      CheckboxListTile(
                        value: feesPaid,
                        onChanged: (val) => setDialogState(() => feesPaid = val!),
                        title: const Text("Fees Paid"),
                        subtitle: const Text("Check if hostel fees are paid"),
                        controlAffinity: ListTileControlAffinity.leading,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton.icon(
                onPressed: _isProcessing || selectedPersonId == null
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          setDialogState(() => _isProcessing = true);

                          try {
                            await FirebaseFirestore.instance
                                .collection(selectedCollection!)
                                .doc(selectedPersonId)
                                .update({
                              'hostelBlock': hostelBlock,
                              'hostelRoom': roomNumber,
                              'roomType': roomType,
                              'feesPaid': feesPaid,
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              _showMsg(isEdit 
                                  ? "Room allocation updated successfully" 
                                  : "Room allocated successfully");
                            }
                          } catch (e) {
                            _showMsg("Error: $e", isError: true);
                          } finally {
                            setDialogState(() => _isProcessing = false);
                          }
                        }
                      },
                icon: _isProcessing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                label: Text(isEdit ? "Update" : "Allocate"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(120, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- REMOVE FROM HOSTEL ---
  // --- REMOVE FROM HOSTEL ---
  void _removeFromHostel(String docId, String personName, String collection) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout, color: Colors.red, size: 20),
            ),
            const SizedBox(width: 12),
            const Text("Remove from Hostel?"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Are you sure you want to remove $personName from hostel?"),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.red),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "This will clear their room allocation.",
                      style: TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(collection)
                  .doc(docId)
                  .update({
                'hostelBlock': FieldValue.delete(),
                'hostelRoom': FieldValue.delete(),
                'roomType': FieldValue.delete(),
                'feesPaid': FieldValue.delete(),
              });
              if (mounted) {
                Navigator.pop(context);
                _showMsg("Removed from hostel successfully");
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text("Remove"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMsg(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: -1)),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),

                  // --- Header & Actions ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hostel Management",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Manage room allocations and occupancy",
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showAllocateDialog(),
                        icon: const Icon(Icons.add_home_rounded, size: 18),
                        label: const Text("Allocate Room"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- DATA STREAM ---
                  StreamBuilder<List<QuerySnapshot>>(
                    // Fetch both students and staff who have hostel rooms assigned
                    stream: FirebaseFirestore.instance
                        .collection('students')
                        .snapshots()
                        .asyncMap((studentsSnapshot) async {
                      final staffSnapshot = await FirebaseFirestore.instance
                          .collection('staff')
                          .get();
                      return [studentsSnapshot, staffSnapshot];
                    }).asBroadcastStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      var allDocs = <Map<String, dynamic>>[];
                      
                      if (snapshot.hasData) {
                        // Add students with collection info
                        for (var doc in snapshot.data![0].docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          if (data['hostelRoom'] != null) {
                            allDocs.add({
                              ...data,
                              '_docId': doc.id,
                              '_collection': 'students',
                            });
                          }
                        }
                        
                        // Add staff with collection info
                        for (var doc in snapshot.data![1].docs) {
                          var data = doc.data() as Map<String, dynamic>;
                          if (data['hostelRoom'] != null) {
                            allDocs.add({
                              ...data,
                              '_docId': doc.id,
                              '_collection': 'staff',
                            });
                          }
                        }
                      }

                      // Filter by Selected Block
                      var residents = allDocs.where((data) {
                        String block = data['hostelBlock'] ?? 'Block A (Boys)';
                        return block == _selectedBlock;
                      }).toList();

                      // --- Calculate Stats ---
                      int totalCapacity = 200; // Example fixed capacity per block
                      int occupied = residents.length;
                      int vacant = totalCapacity - occupied;
                      int maintenance = 2; // Static for demo

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Stats Row
                          Row(
                            children: [
                              _buildStatCard(
                                "Total Capacity",
                                "$totalCapacity Beds",
                                Colors.indigo,
                                Icons.bed,
                              ),
                              const SizedBox(width: 20),
                              _buildStatCard(
                                "Occupied",
                                "$occupied Residents",
                                Colors.green,
                                Icons.person,
                              ),
                              const SizedBox(width: 20),
                              _buildStatCard(
                                "Vacant",
                                "$vacant Beds",
                                Colors.orange,
                                Icons.check_circle_outline,
                              ),
                              const SizedBox(width: 20),
                              _buildStatCard(
                                "Maintenance",
                                "$maintenance Rooms",
                                Colors.red,
                                Icons.build,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // 2. Block Tabs
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _blocks
                                  .map((block) => _buildBlockTab(block))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // 3. Residents Table
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFFF1F5F9),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: residents.isEmpty
                                ? _buildEmptyState()
                                : DataTable(
                                    columnSpacing: 20,
                                    horizontalMargin: 32,
                                    headingRowHeight: 60,
                                    dataRowMinHeight: 70,
                                    dataRowMaxHeight: 70,
                                    columns: const [
                                      DataColumn(
                                        label: Text(
                                          "Room No",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Student Name",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Department",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Type",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Payment",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      DataColumn(
                                        label: Text(
                                          "Actions",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    rows: residents.map((data) {
                                      String docId = data['_docId'];
                                      String collection = data['_collection'];
                                      return DataRow(
                                        cells: [
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 6,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFFE2E8F0,
                                                  ),
                                                ),
                                              ),
                                              child: Text(
                                                data['hostelRoom'] ?? "000",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundColor:
                                                      Colors.blue.shade50,
                                                  child: Text(
                                                    (data['firstName']?[0] ??
                                                        "U"),
                                                    style: TextStyle(
                                                      color:
                                                          Colors.blue.shade700,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      "${data['firstName']} ${data['lastName'] ?? ''}",
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Text(
                                                      data['phone'] ??
                                                          "No Phone",
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors
                                                            .grey
                                                            .shade500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          DataCell(
                                            Text(data['department'] ?? "--"),
                                          ),
                                          DataCell(
                                            Text(
                                              data['roomType'] ?? "Non-AC",
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (data['feesPaid'] == true)
                                                    ? Colors.green.shade50
                                                    : Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                (data['feesPaid'] == true)
                                                    ? "PAID"
                                                    : "PENDING",
                                                style: TextStyle(
                                                  color:
                                                      (data['feesPaid'] == true)
                                                      ? Colors.green.shade700
                                                      : Colors.orange.shade700,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          DataCell(
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.edit_outlined,
                                                    size: 18,
                                                    color: Colors.grey,
                                                  ),
                                                  onPressed: () => _showAllocateDialog(
                                                    docId: docId,
                                                    data: data,
                                                    collection: collection,
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.logout,
                                                    size: 18,
                                                    color: Colors.redAccent,
                                                  ),
                                                  onPressed: () => _removeFromHostel(
                                                    docId,
                                                    "${data['firstName']} ${data['lastName'] ?? ''}",
                                                    collection,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                Icon(Icons.more_vert, size: 16, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockTab(String title) {
    bool isSelected = _selectedBlock == title;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedBlock = title),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFE2E8F0),
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(60),
      child: Column(
        children: [
          Icon(Icons.hotel_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No residents in $_selectedBlock",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Allocate rooms to students to see them here.",
            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
