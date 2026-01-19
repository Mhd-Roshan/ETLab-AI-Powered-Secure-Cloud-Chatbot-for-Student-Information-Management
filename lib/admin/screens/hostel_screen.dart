import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HostelScreen extends StatefulWidget {
  final Color color;
  const HostelScreen({super.key, required this.color});

  @override
  State<HostelScreen> createState() => _HostelScreenState();
}

class _HostelScreenState extends State<HostelScreen> with SingleTickerProviderStateMixin {
  // --- STATE VARIABLES ---
  String _searchQuery = "";
  String _selectedBuilding = "All"; 
  
  // Configuration
  final int _capacityPerHostel = 50;
  final List<String> _hostelList = ["All", "A", "B", "C", "D"]; // Shortened labels for better fit

  // Controllers
  late TabController _tabController;
  final TextEditingController _roomController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _idController = TextEditingController();

  // --- DATA SOURCES ---
  List<Map<String, dynamic>> _allocations = [
    {
      "name": "Arjun Nair",
      "id": "KMCT20CS001",
      "room": "101",
      "hostel": "Hostel A",
      "status": "Occupied",
      "img": "https://randomuser.me/api/portraits/men/11.jpg"
    },
    {
      "name": "Ben Johnson",
      "id": "KMCT20CS005",
      "room": "102",
      "hostel": "Hostel A",
      "status": "Occupied",
      "img": "https://randomuser.me/api/portraits/men/3.jpg"
    },
    {
      "name": "Rahul P.",
      "id": "KMCT20CS045",
      "room": "205",
      "hostel": "Hostel B",
      "status": "Occupied",
      "img": "https://randomuser.me/api/portraits/men/32.jpg"
    },
    {
      "name": "Sarah J.",
      "id": "KMCT20CS055",
      "room": "301",
      "hostel": "Hostel C",
      "status": "Occupied",
      "img": "https://randomuser.me/api/portraits/women/44.jpg"
    },
    {
      "name": "Vishnu V.",
      "id": "KMCT20CS060",
      "room": "405",
      "hostel": "Hostel D",
      "status": "Cleaning",
      "img": "https://randomuser.me/api/portraits/men/65.jpg"
    },
  ];

  List<Map<String, dynamic>> _unassignedQueue = [
    {
      "name": "Adithya Kumar",
      "id": "KMCT21CS012",
      "img": "https://randomuser.me/api/portraits/men/8.jpg"
    },
    {
      "name": "Fathima R.",
      "id": "KMCT21CS022",
      "img": "https://randomuser.me/api/portraits/women/9.jpg"
    },
    {
      "name": "David Miller",
      "id": "KMCT21CS033",
      "img": "https://randomuser.me/api/portraits/men/15.jpg"
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _roomController.dispose();
    _nameController.dispose();
    _idController.dispose();
    super.dispose();
  }

  // --- LOGIC FUNCTIONS ---

  List<Map<String, dynamic>> get _filteredAllocations {
    return _allocations.where((item) {
      final name = (item['name'] ?? "").toString().toLowerCase();
      final room = (item['room'] ?? "").toString().toLowerCase();
      final search = _searchQuery.toLowerCase();
      
      final matchesSearch = name.contains(search) || room.contains(search);
      // Logic: If "All" selected, show all. If "A", match "Hostel A", etc.
      final matchesHostel = _selectedBuilding == "All" || (item['hostel']?.toString() ?? "") == "Hostel $_selectedBuilding";
      return matchesSearch && matchesHostel;
    }).toList();
  }

  List<Map<String, dynamic>> get _filteredQueue {
    return _unassignedQueue.where((item) {
      final name = (item['name'] ?? "").toString().toLowerCase();
      final id = (item['id'] ?? "").toString().toLowerCase();
      final search = _searchQuery.toLowerCase();
      return name.contains(search) || id.contains(search);
    }).toList();
  }

  int get _currentCapacity {
    return _selectedBuilding == "All" ? _capacityPerHostel * 4 : _capacityPerHostel;
  }

  int get _currentOccupied {
    if (_selectedBuilding == "All") return _allocations.length;
    return _allocations.where((i) => i['hostel'] == "Hostel $_selectedBuilding").length;
  }

  void _assignRoomFromQueue(Map<String, dynamic> student) {
    _roomController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("Assign Room", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Assigning room for ${student['name']}", style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 15),
            TextField(
              controller: _roomController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Room Number",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.meeting_room_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (_roomController.text.isNotEmpty) {
                setState(() {
                  _unassignedQueue.remove(student);
                  _allocations.add({
                    ...student,
                    "room": _roomController.text,
                    "hostel": _selectedBuilding == "All" ? "Hostel A" : "Hostel $_selectedBuilding",
                    "status": "Occupied"
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Room assigned"), backgroundColor: Colors.green)
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white),
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }

  void _allocateNewStudent() {
    _nameController.clear();
    _idController.clear();
    _roomController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("New Allocation", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameController, decoration: InputDecoration(labelText: "Name", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _idController, decoration: InputDecoration(labelText: "ID", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 12),
              TextField(controller: _roomController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Room No", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (_nameController.text.isNotEmpty) {
                setState(() {
                  _allocations.add({
                    "name": _nameController.text,
                    "id": _idController.text,
                    "room": _roomController.text,
                    "hostel": _selectedBuilding == "All" ? "Hostel A" : "Hostel $_selectedBuilding",
                    "status": "Occupied",
                    "img": "https://i.pravatar.cc/150?u=${_idController.text}"
                  });
                });
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.color, foregroundColor: Colors.white),
            child: const Text("Allocate"),
          )
        ],
      ),
    );
  }

  void _handleAction(String action, Map<String, dynamic> item) {
    if (action == "Vacate") {
      setState(() => _allocations.remove(item));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Room vacated"), backgroundColor: Colors.orange));
    } else if (action == "Delete") {
      setState(() {
        if (_allocations.contains(item)) _allocations.remove(item);
        if (_unassignedQueue.contains(item)) _unassignedQueue.remove(item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
        title: Text(
          "Hostel Management",
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _allocateNewStudent,
              icon: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
              label: const Text("Allocate New", style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Metrics - Expanded Row
                Row(
                  children: [
                    Expanded(child: _buildModernMetricCard("Capacity", "$_currentCapacity", Icons.domain_rounded, Colors.blue)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildModernMetricCard("Occupied", "$_currentOccupied", Icons.bedroom_parent_rounded, Colors.green)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildModernMetricCard("Vacant", "${_currentCapacity - _currentOccupied}", Icons.meeting_room_outlined, Colors.orange)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildModernMetricCard("Queue", "${_unassignedQueue.length}", Icons.hourglass_top_rounded, Colors.purple)),
                  ],
                ),

                const SizedBox(height: 24),

                // Hostel Selection & Search
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Column(
                    children: [
                      // Expanded Hostel Filter Chips (Fill width)
                      Row(
                        children: _hostelList.map((hostel) {
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                              child: _buildFilterChip(
                                hostel, 
                                _selectedBuilding == hostel, 
                                () => setState(() => _selectedBuilding = hostel)
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      // Search Bar
                      TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: "Search student, room number...",
                          hintStyle: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade400),
                          prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Tab Bar
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: widget.color.withOpacity(0.1),
                    ),
                    indicatorPadding: const EdgeInsets.all(4),
                    labelColor: widget.color,
                    unselectedLabelColor: Colors.grey.shade600,
                    labelStyle: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 14),
                    dividerColor: Colors.transparent,
                    tabs: [
                      const Tab(text: "Allocated Rooms"),
                      Tab(text: "Unassigned Queue"),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Expanded List View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _filteredAllocations.isEmpty 
                    ? _buildEmptyState("No allocations found for $_selectedBuilding")
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _filteredAllocations.length,
                        separatorBuilder: (_,__) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildAllocationCard(_filteredAllocations[index]),
                      ),

                _filteredQueue.isEmpty 
                    ? _buildEmptyState("Queue is empty")
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        itemCount: _filteredQueue.length,
                        separatorBuilder: (_,__) => const SizedBox(height: 12),
                        itemBuilder: (context, index) => _buildQueueCard(_filteredQueue[index]),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildModernMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: color.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.black87),
            ),
          ),
          Text(
            title,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12), // Taller touch area
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label, // "All", "A", "B", etc.
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildAllocationCard(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? "Unknown";
    Color statusColor = status == "Occupied" ? Colors.green : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: widget.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                data['room']?.toString() ?? "-",
                style: GoogleFonts.dmSans(fontWeight: FontWeight.w800, fontSize: 18, color: widget.color),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name']?.toString() ?? "Unknown",
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                ),
                Text(
                  "${data['id'] ?? ''} • ${data['hostel'] ?? ''}",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400),
            color: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) => _handleAction(value, data),
            itemBuilder: (context) => [
              const PopupMenuItem(value: "Vacate", child: Row(children: [Icon(Icons.logout, size: 18, color: Colors.orange), SizedBox(width: 10), Text("Vacate Room")])),
              const PopupMenuItem(value: "Delete", child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 10), Text("Delete Record")])),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildQueueCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundImage: NetworkImage(data['img'] ?? ""),
            onBackgroundImageError: (_,__) {},
            backgroundColor: Colors.grey.shade200,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name']?.toString() ?? "Unknown",
                  style: GoogleFonts.dmSans(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  data['id']?.toString() ?? "",
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _assignRoomFromQueue(data),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("Assign", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Icons.bed_rounded, size: 40, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 16),
          Text(text, style: GoogleFonts.inter(color: Colors.grey.shade400, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}