import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';
import 'package:edlab/login.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Reference to global settings
  final DocumentReference _settingsRef = FirebaseFirestore.instance
      .collection('settings')
      .doc('global');

  // --- 1. EDIT INSTITUTION PROFILE ---
  void _editInstitutionProfile(Map<String, dynamic> data) {
    final nameCtrl = TextEditingController(
      text: data['institutionName'] ?? "EdLab University",
    );
    final addressCtrl = TextEditingController(
      text: data['address'] ?? "New York, USA",
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Institution Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: "Institution Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: "Address",
                border: OutlineInputBorder(),
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
            onPressed: () async {
              await _settingsRef.set({
                'institutionName': nameCtrl.text,
                'address': addressCtrl.text,
              }, SetOptions(merge: true));
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- 2. CHANGE PASSWORD DIALOG ---
  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(),
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
              // Add Firebase Auth logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Password updated successfully!")),
              );
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  // --- 3. TRIGGER BACKUP ---
  void _triggerBackup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            SizedBox(width: 16),
            Text("Backing up database..."),
          ],
        ),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blueAccent,
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
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 5)),

          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AdminHeader(),
                  const SizedBox(height: 32),

                  Text(
                    "Settings",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- DATA STREAM FOR SETTINGS ---
                  StreamBuilder<DocumentSnapshot>(
                    stream: _settingsRef.snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const LinearProgressIndicator();
                      }

                      // Default Data if document doesn't exist
                      Map<String, dynamic> data =
                          (snapshot.data?.data() as Map<String, dynamic>?) ??
                          {
                            'institutionName': 'EdLab University',
                            'address': 'New York, USA',
                            'notifications': true,
                            'darkMode': false,
                            'academicYear': '2025-2026',
                          };

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. GENERAL SECTION
                          _buildSectionHeader("General"),
                          _buildSettingContainer([
                            ListTile(
                              leading: _buildIcon(
                                Icons.school_rounded,
                                Colors.blue,
                              ),
                              title: const Text(
                                "Institution Profile",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "${data['institutionName']} • ${data['address']}",
                              ),
                              trailing: const Icon(
                                Icons.edit_outlined,
                                size: 18,
                              ),
                              onTap: () => _editInstitutionProfile(data),
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: _buildIcon(
                                Icons.calendar_today_rounded,
                                Colors.orange,
                              ),
                              title: const Text(
                                "Academic Year",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text("Current active session"),
                              trailing: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: data['academicYear'],
                                  items: ['2024-2025', '2025-2026', '2026-2027']
                                      .map(
                                        (y) => DropdownMenuItem(
                                          value: y,
                                          child: Text(y),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) => _settingsRef.set({
                                    'academicYear': val,
                                  }, SetOptions(merge: true)),
                                  style: GoogleFonts.inter(
                                    color: Colors.blueAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 32),

                          // 2. SYSTEM & PREFERENCES
                          _buildSectionHeader("Preferences"),
                          _buildSettingContainer([
                            SwitchListTile(
                              secondary: _buildIcon(
                                Icons.notifications_active_rounded,
                                Colors.redAccent,
                              ),
                              title: const Text(
                                "System Notifications",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text(
                                "Receive alerts for new registrations",
                              ),
                              value: data['notifications'] ?? true,
                              activeThumbColor: Colors.blueAccent,
                              onChanged: (val) => _settingsRef.set({
                                'notifications': val,
                              }, SetOptions(merge: true)),
                            ),
                            const Divider(height: 1),
                            SwitchListTile(
                              secondary: _buildIcon(
                                Icons.dark_mode_rounded,
                                Colors.purple,
                              ),
                              title: const Text(
                                "Dark Mode",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text("Switch interface theme"),
                              value: data['darkMode'] ?? false,
                              activeThumbColor: Colors.purpleAccent,
                              onChanged: (val) => _settingsRef.set({
                                'darkMode': val,
                              }, SetOptions(merge: true)),
                            ),
                          ]),

                          const SizedBox(height: 32),

                          // 3. SECURITY & DATA
                          _buildSectionHeader("Security & Data"),
                          _buildSettingContainer([
                            ListTile(
                              leading: _buildIcon(
                                Icons.lock_rounded,
                                Colors.teal,
                              ),
                              title: const Text(
                                "Change Password",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: _changePassword,
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: _buildIcon(
                                Icons.cloud_upload_rounded,
                                Colors.indigo,
                              ),
                              title: const Text(
                                "Backup Data",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: const Text("Last backup: 2 hours ago"),
                              trailing: OutlinedButton(
                                onPressed: _triggerBackup,
                                child: const Text("Backup Now"),
                              ),
                            ),
                          ]),

                          const SizedBox(height: 40),

                          // Logout Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LoginPage(),
                                  ),
                                  (r) => false,
                                );
                              },
                              icon: const Icon(Icons.logout_rounded),
                              label: const Text("Sign Out"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade500,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
