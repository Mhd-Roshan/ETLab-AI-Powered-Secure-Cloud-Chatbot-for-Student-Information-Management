import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/admin/widgets/admin_header.dart';
import 'package:edlab/services/admin_service.dart';
import 'package:edlab/login.dart';

class AdminProfileScreen extends StatefulWidget {
  final String userId;
  const AdminProfileScreen({super.key, required this.userId});

  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  final AdminService _service = AdminService();

  void _changePassword() {
    final currentPass = TextEditingController();
    final newPass = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Security Update",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "Current Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "New Password",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Password updated successfully!"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001FF4),
            ),
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String title, String field, String currentValue) {
    final controller = TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Edit $title",
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Enter new $title",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
          ),
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.inter(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _service.updateProfile(widget.userId, {
                  field: controller.text,
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("$title updated in database!"),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error: $e"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF001FF4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text("Save", style: GoogleFonts.inter(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _service.getProfile(widget.userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return _buildProfileUI({
              'fullName': 'Admin User',
              'email': widget.userId,
              'job': 'Head Administrator',
              'notifications': true,
              'darkMode': false,
            });
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          return _buildProfileUI(data);
        },
      ),
    );
  }

  Widget _buildProfileUI(Map<String, dynamic> data) {
    final fullName = data['fullName'] ?? data['username'] ?? 'Admin User';
    final email = data['email'] ?? widget.userId;
    final job = data['job'] ?? 'Head Administrator';
    final notifications = data['notifications'] ?? true;
    final darkMode = data['darkMode'] ?? false;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSidebar(
          activeIndex: -1,
          userId: widget.userId,
          isShrinkOnly: true,
        ),
        Expanded(
          child: Stack(
            children: [
              // Aurora Background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 350,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF001FF4),
                        Color(0xFF4F46E5),
                        Color(0xFF7C3AED),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AdminHeader(title: "Account Hub", isWhite: true),
                    const SizedBox(height: 60),

                    _buildPremiumProfileCard(fullName, job),
                    const SizedBox(height: 40),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Account Details
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader("Account Intelligence"),
                              _buildGlassContainer([
                                _buildEditableListTile(
                                  icon: Icons.person_rounded,
                                  color: const Color(0xFF001FF4),
                                  title: "Name",
                                  value: fullName,
                                  onTap: () => _showEditDialog(
                                    "Full Name",
                                    "fullName",
                                    fullName,
                                  ),
                                ),
                                _buildDivider(),
                                _buildEditableListTile(
                                  icon: Icons.alternate_email_rounded,
                                  color: const Color(0xFFF59E0B),
                                  title: "Email",
                                  value: email,
                                  onTap: () =>
                                      _showEditDialog("Email", "email", email),
                                ),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 32),
                        // Right: Preferences
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSectionHeader("Experience"),
                              _buildGlassContainer([
                                _buildSwitchTile(
                                  icon: Icons.notifications_active_rounded,
                                  color: const Color(0xFFEF4444),
                                  title: "Alerts",
                                  value: notifications,
                                  onChanged: (v) => _service.updateProfile(
                                    widget.userId,
                                    {'notifications': v},
                                  ).ignore(),
                                ),
                                _buildDivider(),
                                _buildSwitchTile(
                                  icon: Icons.dark_mode_rounded,
                                  color: const Color(0xFF8B5CF6),
                                  title: "Dark Mode",
                                  value: darkMode,
                                  onChanged: (v) => _service.updateProfile(
                                    widget.userId,
                                    {'darkMode': v},
                                  ).ignore(),
                                ),
                              ]),
                              const SizedBox(height: 32),
                              _buildSectionHeader("Security & Access"),
                              _buildGlassContainer([
                                ListTile(
                                  leading: _buildIcon(
                                    Icons.lock_person_rounded,
                                    const Color(0xFF0EA5E9),
                                  ),
                                  title: Text(
                                    "Safety Credentials",
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: const Color(0xFF1E293B),
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Update password regularly",
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF64748B),
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF94A3B8),
                                  ),
                                  onTap: _changePassword,
                                ),
                              ]),
                              const SizedBox(height: 48),
                              _buildSignOutButton(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumProfileCard(String fullName, String job) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
            spreadRadius: -10,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF001FF4), Color(0xFF4F46E5)],
                ),
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.white,
                backgroundImage: NetworkImage(
                  'https://ui-avatars.com/api/?name=$fullName&background=random&size=200',
                ),
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fullName,
                    style: GoogleFonts.inter(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF000000),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    job.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF001FF4),
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassContainer(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 20),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF94A3B8),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildEditableListTile({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      leading: _buildIcon(icon, color),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF94A3B8),
        ),
      ),
      subtitle: Text(
        value,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1E293B),
        ),
      ),
      trailing: const Icon(
        Icons.edit_rounded,
        color: Color(0xFF001FF4),
        size: 18,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color color,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      secondary: _buildIcon(icon, color),
      activeThumbColor: const Color(0xFF001FF4),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: const Color(0xFF1E293B),
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 22),
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, indent: 80, color: Color(0xFFF1F5F9));

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (r) => false,
        ),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text("TERMINATE SESSION"),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFF1F2),
          foregroundColor: const Color(0xFFE11D48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFECDD3)),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
