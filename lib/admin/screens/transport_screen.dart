import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';

class TransportScreen extends StatefulWidget {
  const TransportScreen({super.key});

  @override
  State<TransportScreen> createState() => _TransportScreenState();
}

class _TransportScreenState extends State<TransportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _isInitialized = true;
    _checkAndSeedData();
  }

  Future<void> _checkAndSeedData() async {
    try {
      final busesSnapshot = await FirebaseFirestore.instance.collection('transport_buses').limit(1).get();
      debugPrint('Buses count: ${busesSnapshot.docs.length}');
      if (busesSnapshot.docs.isEmpty) {
        debugPrint('Seeding transport data...');
        await _seedTransportData();
        debugPrint('Transport data seeded successfully');
      }
    } catch (e) {
      debugPrint('Error checking/seeding data: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: -1)),
          Expanded(
            child: Column(
              children: [
                const AdminHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 32),
                        _buildStatsRow(),
                        const SizedBox(height: 32),
                        _buildTabSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transport Management',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A1A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage buses, routes, drivers and student transport',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _addBus,
              icon: const Icon(Icons.add, size: 18),
              label: Text('Add Bus', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _addRoute,
              icon: const Icon(Icons.route, size: 18),
              label: Text('Add Route', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transport_buses').snapshots(),
      builder: (context, busSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('transport_routes').snapshots(),
          builder: (context, routeSnapshot) {
            final totalBuses = busSnapshot.data?.docs.length ?? 0;
            final totalRoutes = routeSnapshot.data?.docs.length ?? 0;
            
            int activeBuses = 0;
            if (busSnapshot.hasData) {
              activeBuses = busSnapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['status'] == 'active';
              }).length;
            }
            
            return Row(
              children: [
                Expanded(child: _buildStatCard('Total Buses', totalBuses.toString(), Icons.directions_bus, const Color(0xFF0EA5E9), '+${totalBuses > 0 ? totalBuses : 0}')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Active Buses', activeBuses.toString(), Icons.check_circle, const Color(0xFF10B981), '$activeBuses')),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Routes', totalRoutes.toString(), Icons.route, const Color(0xFF8B5CF6), '+${totalRoutes > 0 ? totalRoutes : 0}')),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, String change) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A1A),
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSection() {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: const Color(0xFFE5E7EB), width: 1)),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFF0EA5E9),
              unselectedLabelColor: const Color(0xFF6B7280),
              indicatorColor: const Color(0xFF0EA5E9),
              indicatorWeight: 3,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 14),
              tabs: const [
                Tab(text: 'Buses'),
                Tab(text: 'Routes'),
              ],
            ),
          ),
          SizedBox(
            height: 600,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBusesTab(),
                _buildRoutesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transport_buses').snapshots(),
      builder: (context, snapshot) {
        debugPrint('Buses snapshot state: ${snapshot.connectionState}');
        debugPrint('Buses has data: ${snapshot.hasData}');
        debugPrint('Buses count: ${snapshot.data?.docs.length ?? 0}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF0EA5E9)));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(Icons.directions_bus_outlined, 'No Buses', 'Click "Add Bus" to add your first bus');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var bus = doc.data() as Map<String, dynamic>;
            final busId = doc.id;
            final isActive = bus['status'] == 'active';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF0EA5E9).withValues(alpha: 0.1) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.directions_bus,
                      color: isActive ? const Color(0xFF0EA5E9) : Colors.grey.shade600,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              bus['busNumber'] ?? 'Unknown',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isActive ? const Color(0xFF10B981) : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Driver: ${bus['driverName'] ?? 'Not Assigned'}',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                            ),
                            const SizedBox(width: 20),
                            Icon(Icons.event_seat, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Capacity: ${bus['capacity'] ?? 0} seats',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                            ),
                            const SizedBox(width: 20),
                            Icon(Icons.route, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Route: ${bus['routeName'] ?? 'Not Assigned'}',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteBus(busId),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRoutesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transport_routes').snapshots(),
      builder: (context, snapshot) {
        debugPrint('Routes snapshot state: ${snapshot.connectionState}');
        debugPrint('Routes has data: ${snapshot.hasData}');
        debugPrint('Routes count: ${snapshot.data?.docs.length ?? 0}');
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}', style: GoogleFonts.inter(color: Colors.red)),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(Icons.route_outlined, 'No Routes', 'Click "Add Route" to add your first route');
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var route = doc.data() as Map<String, dynamic>;
            final routeId = doc.id;
            final stops = (route['stops'] as List?)?.cast<String>() ?? [];
            
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.route, color: Color(0xFF8B5CF6), size: 32),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route['routeName'] ?? 'Unknown Route',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              '${stops.length} stops',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                            ),
                            const SizedBox(width: 20),
                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              '${route['startTime'] ?? 'N/A'} - ${route['endTime'] ?? 'N/A'}',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                            ),
                            const SizedBox(width: 20),
                            Icon(Icons.payments, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              '₹${route['fare'] ?? 0}/month',
                              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF6B7280)),
                            ),
                          ],
                        ),
                        if (stops.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: stops.map((stop) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                stop,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8B5CF6),
                                ),
                              ),
                            )).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteRoute(routeId),
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: const Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _seedTransportData() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      
      // Seed Buses
      final buses = [
        {'busNumber': 'KL-01-AB-1234', 'driverName': 'Rajesh Kumar', 'capacity': 40, 'status': 'active', 'routeName': 'Route A - City Center'},
        {'busNumber': 'KL-01-CD-5678', 'driverName': 'Suresh Nair', 'capacity': 35, 'status': 'active', 'routeName': 'Route B - North Zone'},
        {'busNumber': 'KL-01-EF-9012', 'driverName': 'Anil Kumar', 'capacity': 45, 'status': 'active', 'routeName': 'Route C - South Zone'},
        {'busNumber': 'KL-01-GH-3456', 'driverName': 'Vinod Thomas', 'capacity': 40, 'status': 'inactive', 'routeName': 'Not Assigned'},
        {'busNumber': 'KL-01-IJ-7890', 'driverName': 'Manoj Kumar', 'capacity': 38, 'status': 'active', 'routeName': 'Route D - East Zone'},
      ];
      
      for (var bus in buses) {
        batch.set(
          FirebaseFirestore.instance.collection('transport_buses').doc(),
          {...bus, 'createdAt': FieldValue.serverTimestamp()},
        );
      }
      
      // Seed Routes
      final routes = [
        {'routeName': 'Route A - City Center', 'stops': ['College Gate', 'City Center', 'Railway Station', 'Bus Stand', 'Market'], 'startTime': '07:00 AM', 'endTime': '08:30 AM', 'fare': 1500},
        {'routeName': 'Route B - North Zone', 'stops': ['College Gate', 'North Park', 'Mall Road', 'Hospital', 'Stadium'], 'startTime': '07:15 AM', 'endTime': '08:45 AM', 'fare': 1200},
        {'routeName': 'Route C - South Zone', 'stops': ['College Gate', 'South Avenue', 'Temple Road', 'Beach Road', 'Airport'], 'startTime': '06:45 AM', 'endTime': '08:15 AM', 'fare': 1800},
        {'routeName': 'Route D - East Zone', 'stops': ['College Gate', 'East Street', 'IT Park', 'University', 'Tech Hub'], 'startTime': '07:30 AM', 'endTime': '09:00 AM', 'fare': 1400},
      ];
      
      for (var route in routes) {
        batch.set(
          FirebaseFirestore.instance.collection('transport_routes').doc(),
          {...route, 'createdAt': FieldValue.serverTimestamp()},
        );
      }
      
      await batch.commit();
    } catch (e) {
      debugPrint('Error seeding transport data: $e');
    }
  }

  void _addBus() {
    final formKey = GlobalKey<FormState>();
    final busNumberController = TextEditingController();
    final driverNameController = TextEditingController();
    final capacityController = TextEditingController();
    String selectedStatus = 'active';
    String? selectedRoute;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Bus', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: busNumberController,
                    decoration: InputDecoration(
                      labelText: 'Bus Number *',
                      hintText: 'e.g., KL-01-AB-1234',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: driverNameController,
                    decoration: InputDecoration(
                      labelText: 'Driver Name *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: capacityController,
                    decoration: InputDecoration(
                      labelText: 'Capacity *',
                      hintText: 'Number of seats',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Must be a number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('transport_routes').snapshots(),
                    builder: (context, snapshot) {
                      final routes = snapshot.data?.docs ?? [];
                      return DropdownButtonFormField<String>(
                        value: selectedRoute,
                        decoration: InputDecoration(
                          labelText: 'Route',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Not Assigned')),
                          ...routes.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: data['routeName'],
                              child: Text(data['routeName'] ?? 'Unknown'),
                            );
                          }),
                        ],
                        onChanged: (value) => setState(() => selectedRoute = value),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    decoration: InputDecoration(
                      labelText: 'Status *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
                    ],
                    onChanged: (value) => setState(() => selectedStatus = value!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _saveBus(
                    busNumberController.text,
                    driverNameController.text,
                    int.parse(capacityController.text),
                    selectedRoute ?? 'Not Assigned',
                    selectedStatus,
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0EA5E9),
                foregroundColor: Colors.white,
              ),
              child: Text('Add Bus', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveBus(String busNumber, String driverName, int capacity, String routeName, String status) async {
    try {
      await FirebaseFirestore.instance.collection('transport_buses').add({
        'busNumber': busNumber,
        'driverName': driverName,
        'capacity': capacity,
        'routeName': routeName,
        'status': status,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Bus added successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e', style: GoogleFonts.inter())),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _addRoute() {
    final formKey = GlobalKey<FormState>();
    final routeNameController = TextEditingController();
    final startTimeController = TextEditingController();
    final endTimeController = TextEditingController();
    final fareController = TextEditingController();
    final List<TextEditingController> stopControllers = [TextEditingController()];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Add New Route', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: routeNameController,
                    decoration: InputDecoration(
                      labelText: 'Route Name *',
                      hintText: 'e.g., Route A - City Center',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: startTimeController,
                          decoration: InputDecoration(
                            labelText: 'Start Time *',
                            hintText: '07:00 AM',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: endTimeController,
                          decoration: InputDecoration(
                            labelText: 'End Time *',
                            hintText: '08:30 AM',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: fareController,
                    decoration: InputDecoration(
                      labelText: 'Monthly Fare *',
                      hintText: '1500',
                      prefixText: '₹',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Required';
                      if (int.tryParse(value!) == null) return 'Must be a number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Text('Stops', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ...List.generate(stopControllers.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stopControllers[index],
                              decoration: InputDecoration(
                                labelText: 'Stop ${index + 1}',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                            ),
                          ),
                          if (stopControllers.length > 1)
                            IconButton(
                              onPressed: () => setState(() => stopControllers.removeAt(index)),
                              icon: const Icon(Icons.remove_circle, color: Colors.red),
                            ),
                        ],
                      ),
                    );
                  }),
                  TextButton.icon(
                    onPressed: () => setState(() => stopControllers.add(TextEditingController())),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Stop'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _saveRoute(
                    routeNameController.text,
                    startTimeController.text,
                    endTimeController.text,
                    int.parse(fareController.text),
                    stopControllers.map((c) => c.text).toList(),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: Text('Add Route', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveRoute(String routeName, String startTime, String endTime, int fare, List<String> stops) async {
    try {
      await FirebaseFirestore.instance.collection('transport_routes').add({
        'routeName': routeName,
        'startTime': startTime,
        'endTime': endTime,
        'fare': fare,
        'stops': stops,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Route added successfully!', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e', style: GoogleFonts.inter())),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  void _deleteBus(String busId) async {
    await FirebaseFirestore.instance.collection('transport_buses').doc(busId).delete();
  }

  void _deleteRoute(String routeId) async {
    await FirebaseFirestore.instance.collection('transport_routes').doc(routeId).delete();
  }
}
