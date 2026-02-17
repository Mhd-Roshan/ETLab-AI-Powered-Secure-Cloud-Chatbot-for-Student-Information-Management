import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../login.dart';

class StudentProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? attendancePercentage;
  final String studentId;

  const StudentProfilePage({
    super.key,
    required this.userData,
    this.attendancePercentage,
    required this.studentId,
  });

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final ImagePicker _picker = ImagePicker();
  String? _localImagePath;
  bool _isUploading = false;
  String? _currentPhone;
  String? _currentBatch;

  @override
  void initState() {
    super.initState();
    _currentPhone = widget.userData['phone']?.toString();
    _currentBatch = widget.userData['batch']?.toString();
  }

  // Pick image from gallery or camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      debugPrint('=== PICKING IMAGE ===');
      debugPrint(
        'Source: ${source == ImageSource.camera ? "Camera" : "Gallery"}',
      );

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );

      if (image == null) {
        debugPrint('No image selected');
        return;
      }

      debugPrint('Image selected: ${image.path}');

      // Show loading immediately
      setState(() {
        _isUploading = true;
      });

      try {
        // Update Firestore with new image path
        debugPrint('Updating Firestore for user: ${widget.studentId}');

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.studentId)
            .update({
              'profileImage': image.path,
              'updatedAt': FieldValue.serverTimestamp(),
            });

        debugPrint('Firestore updated successfully');

        // Update local state
        if (mounted) {
          setState(() {
            _localImagePath = image.path;
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text(
                    'Profile image updated!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error updating Firestore: $e');

        if (mounted) {
          setState(() {
            _isUploading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Failed to update: ${e.toString()}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');

      if (mounted) {
        setState(() {
          _isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // Show image source selection dialog
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              'Change Profile Picture',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),

            // Camera Option
            _buildImageOption(
              icon: Icons.camera_alt_rounded,
              title: 'Take Photo',
              subtitle: 'Use camera to take a new photo',
              color: const Color(0xFF3B82F6),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),

            const SizedBox(height: 12),

            // Gallery Option
            _buildImageOption(
              icon: Icons.photo_library_rounded,
              title: 'Choose from Gallery',
              subtitle: 'Select an existing photo',
              color: const Color(0xFF8B5CF6),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),

            const SizedBox(height: 12),

            // Remove Option
            _buildImageOption(
              icon: Icons.delete_outline_rounded,
              title: 'Remove Photo',
              subtitle: 'Use default avatar',
              color: const Color(0xFFEF4444),
              onTap: () {
                Navigator.pop(context);
                _removeProfileImage();
              },
            ),

            const SizedBox(height: 12),

            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper: Build image option tile
  Widget _buildImageOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // Show Edit Profile Dialog
  void _showEditProfileDialog() {
    final TextEditingController phoneController = TextEditingController(
      text: _currentPhone ?? "9087654321",
    );
    final TextEditingController batchController = TextEditingController(
      text: _currentBatch ?? "",
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Profile"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: "Phone Number"),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: batchController,
                decoration: const InputDecoration(labelText: "Batch"),
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
                try {
                  // Show loading
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        const Center(child: CircularProgressIndicator()),
                  );

                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.studentId)
                      .update({
                        'phone': phoneController.text.trim(),
                        'batch': batchController.text.trim(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                  // Update local state
                  setState(() {
                    _currentPhone = phoneController.text.trim();
                    _currentBatch = batchController.text.trim();
                  });

                  // Close loading
                  if (context.mounted) Navigator.pop(context);
                  // Close dialog
                  if (context.mounted) Navigator.pop(context);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Profile updated successfully!"),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) Navigator.pop(context); // Close loading
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                }
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  // Remove profile image
  Future<void> _removeProfileImage() async {
    try {
      debugPrint('=== REMOVING PROFILE IMAGE ===');
      debugPrint('User ID: ${widget.studentId}');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.studentId)
          .update({
            'profileImage': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      debugPrint('Profile image removed from Firestore');

      setState(() {
        _localImagePath = null;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                const Text(
                  'Profile image removed',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFF59E0B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error removing image: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Error: ${e.toString()}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Primary Theme Color
    const Color primaryColor = Color(0xFF5C51E1);

    // Handle empty data case
    if (widget.userData.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("No profile data available"),
            SizedBox(height: 8),
            Text(
              "Please add student data to Firestore",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. TOP HEADER SECTION (Gradient + Avatar)
          Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              _buildHeaderGradient(primaryColor),
              Positioned(
                top: 100,
                child: _buildProfileImage(
                  widget.userData['registrationNumber'],
                ),
              ),
            ],
          ),

          const SizedBox(height: 70),

          // 2. NAME & EMAIL
          Text(
            "${widget.userData['firstName'] ?? 'Student'} ${widget.userData['lastName'] ?? ''}",
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            widget.userData['email'] ?? "student@edlab.edu",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: 25),

          // 3. STATS ROW (GPA & Semester only)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Overall", "84.6%", Colors.orange),
                _buildStatCard(
                  "Semester",
                  widget.userData['semester']?.toString() ?? "N/A",
                  Colors.blue,
                ),
                _buildStatCard(
                  "Attendance",
                  widget.attendancePercentage ?? "0%",
                  Colors.green,
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // 4. DETAILED INFORMATION SECTIONS
          _buildInfoSection("Academic Details", [
            _buildInfoTile(
              Icons.school_rounded,
              "Registration No",
              widget.userData['registrationNumber'],
            ),
            _buildInfoTile(
              Icons.account_balance_rounded,
              "Department",
              widget.userData['department'],
            ),
            _buildInfoTile(
              Icons.calendar_today_rounded,
              "Batch",
              "${_currentBatch ?? 'N/A'}",
            ),
          ]),

          _buildInfoSection("Contact Information", [
            _buildInfoTile(
              Icons.phone_android_rounded,
              "Phone",
              (_currentPhone != null && _currentPhone!.isNotEmpty)
                  ? _currentPhone
                  : "9087654321",
            ),
            _buildInfoTile(
              Icons.email_rounded,
              "Email",
              widget.userData['email'],
            ),
            _buildInfoTile(
              Icons.location_on_rounded,
              "College",
              widget.userData['collegeName'],
            ),
          ]),

          // 5. ACTION BUTTONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                _buildActionButton(
                  label: "Edit Profile",
                  icon: Icons.edit_note_rounded,
                  color: primaryColor,
                  onPressed: () => _showEditProfileDialog(),
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: "Logout",
                  icon: Icons.logout_rounded,
                  color: Colors.redAccent,
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(),
                      ),
                      (route) => false,
                    );
                  },
                  isOutlined: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // Helper: Header Gradient
  Widget _buildHeaderGradient(Color color) {
    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withBlue(255).withValues(alpha: 0.8)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(50)),
      ),
    );
  }

  // Helper: Profile Image with Edit Badge
  Widget _buildProfileImage(String? regNo) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: _isUploading
              ? const CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: _localImagePath != null
                      ? FileImage(File(_localImagePath!))
                      : (widget.userData['profileImage'] != null
                                ? NetworkImage(widget.userData['profileImage'])
                                : NetworkImage(
                                    'https://i.pravatar.cc/150?u=$regNo',
                                  ))
                            as ImageProvider,
                ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _showImageSourceDialog,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper: Individual Stat Card
  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Section Container
  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const Divider(height: 25, thickness: 0.5),
          ...children,
        ],
      ),
    );
  }

  // Helper: Info List Tile
  Widget _buildInfoTile(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EFFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF5C51E1), size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value ?? "Not Set",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Action Button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool isOutlined = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: isOutlined
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: color),
              label: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, color: Colors.white),
              label: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
    );
  }
}
