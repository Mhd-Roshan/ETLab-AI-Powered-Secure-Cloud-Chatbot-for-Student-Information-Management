import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PlacementScreen extends StatefulWidget {
  final Color color;
  const PlacementScreen({super.key, required this.color});

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

class _PlacementScreenState extends State<PlacementScreen> {
  // --- STATE VARIABLES ---
  
  // Controllers for "Add Drive"
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _eligibilityController = TextEditingController();

  // --- DATA SOURCE ---
  // Initial empty list to match the "No upcoming drives" state in your image
  // You can add dummy data here to test the list view
  List<Map<String, dynamic>> _drives = [];

  @override
  void dispose() {
    _companyController.dispose();
    _dateController.dispose();
    _eligibilityController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _showAddDriveDialog() {
    _companyController.clear();
    _dateController.clear();
    _eligibilityController.clear();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text("Add Placement Drive", style: GoogleFonts.dmSans(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(_companyController, "Company Name"),
            const SizedBox(height: 12),
            _buildTextField(_dateController, "Drive Date (e.g., Oct 20)"),
            const SizedBox(height: 12),
            _buildTextField(_eligibilityController, "Eligibility (e.g., CGPA > 7.5)"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancel")
          ),
          ElevatedButton(
            onPressed: () {
              if (_companyController.text.isNotEmpty) {
                setState(() {
                  _drives.add({
                    "company": _companyController.text,
                    "date": _dateController.text,
                    "eligibility": _eligibilityController.text,
                    "status": "Scheduled", // Default
                  });
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Drive Added Successfully"), backgroundColor: Colors.green)
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F766E), // Teal/Green tone
              foregroundColor: Colors.white,
            ),
            child: const Text("Add Drive"),
          )
        ],
      ),
    );
  }

  void _deleteDrive(Map<String, dynamic> drive) {
    setState(() {
      _drives.remove(drive);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Drive Removed"), backgroundColor: Colors.redAccent)
    );
  }

  TextField _buildTextField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        centerTitle: false,
        title: Text(
          "Placement Management",
          style: GoogleFonts.dmSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Breadcrumbs
            Text(
              "Home / Placements / Dashboard",
              style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),

            // 2. Metrics Cards (Expanded to fill width)
            Row(
              children: [
                Expanded(child: _buildMetricCard("STUDENTS PLACED", "0", "/ 1,200 Total", Icons.person_add_alt_1_rounded, Colors.blue)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("COMPANIES VISITING", "${_drives.length}", "Confirmed", Icons.business_rounded, Colors.teal)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("ACTIVE JOB POSTS", "0", "Open Roles", Icons.campaign_rounded, Colors.purple)),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard("HIGHEST PACKAGE", "0", "LPA", Icons.payments_rounded, Colors.orange)),
              ],
            ),

            const SizedBox(height: 30),

            // 3. Main Content Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  // Header Row with Actions
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Upcoming Placement Drives",
                              style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Schedule and manage forthcoming recruitment events",
                              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: BorderSide(color: Colors.grey.shade300),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              child: const Text("Export PDF"),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton.icon(
                              onPressed: _showAddDriveDialog,
                              icon: const Icon(Icons.add, size: 18, color: Colors.white),
                              label: const Text("Add New Drive"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0E7490), // Cyan/Teal shade
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFEEEEEE)),

                  // Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    color: const Color(0xFFF8FAFC), // Slight off-white header bg
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: _headerText("COMPANY NAME")),
                        Expanded(flex: 2, child: _headerText("DRIVE DATE")),
                        Expanded(flex: 3, child: _headerText("ELIGIBILITY")),
                        Expanded(flex: 2, child: _headerText("STATUS")),
                        Expanded(flex: 1, child: _headerText("ACTIONS")),
                      ],
                    ),
                  ),

                  const Divider(height: 1, color: Color(0xFFEEEEEE)),

                  // List Body or Empty State
                  if (_drives.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(60),
                      width: double.infinity,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.calendar_today_rounded, size: 32, color: Colors.grey.shade400),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "No upcoming drives scheduled",
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Start by adding a new placement drive to your calendar.",
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _drives.length,
                      separatorBuilder: (ctx, i) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        return _buildDriveRow(_drives[index]);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER FUNCTIONS ---

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade500,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: GoogleFonts.dmSans(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade400,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Colors.grey.shade400,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDriveRow(Map<String, dynamic> drive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 3, 
            child: Text(
              drive['company'], 
              style: GoogleFonts.dmSans(fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 14)
            ),
          ),
          Expanded(
            flex: 2, 
            child: Text(
              drive['date'], 
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)
            ),
          ),
          Expanded(
            flex: 3, 
            child: Text(
              drive['eligibility'], 
              style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade700)
            ),
          ),
          Expanded(
            flex: 2, 
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Text(
                  drive['status'].toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1, 
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: Colors.grey.shade400),
              color: Colors.white,
              onSelected: (val) {
                if(val == 'delete') _deleteDrive(drive);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit Details")),
                const PopupMenuItem(value: 'delete', child: Text("Delete Drive", style: TextStyle(color: Colors.red))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}