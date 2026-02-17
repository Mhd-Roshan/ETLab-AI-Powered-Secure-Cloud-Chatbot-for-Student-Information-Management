import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/student_service.dart';
import 'package:url_launcher/url_launcher.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({super.key});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final StudentService _studentService = StudentService();
  String _selectedDepartment = "MCA";
  String _selectedSemester = "Semester 1";

  final List<String> _departments = ["MCA"];
  final List<String> _semesters = ["Semester 1"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text(
          "Study Materials",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new,
            size: 20,
            color: Colors.black,
          ),
        ),
        actions: [],
      ),
      body: Column(
        children: [
          if (_departments.length > 1 || _semesters.length > 1) _buildFilters(),
          Expanded(child: _buildMaterialsList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  value: _selectedDepartment,
                  items: _departments,
                  onChanged: (val) =>
                      setState(() => _selectedDepartment = val!),
                  icon: Icons.business,
                  label: "Department",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  value: _selectedSemester,
                  items: _semesters,
                  onChanged: (val) => setState(() => _selectedSemester = val!),
                  icon: Icons.school,
                  label: "Semester",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          onChanged: onChanged,
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Row(
                children: [
                  Icon(icon, size: 18, color: Colors.blueAccent),
                  const SizedBox(width: 8),
                  Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMaterialsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _studentService.getMaterials(
        _selectedDepartment,
        _selectedSemester,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 80, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  "No materials found for $_selectedDepartment - $_selectedSemester",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
              ],
            ),
          );
        }

        // Group by subject
        final materials = snapshot.data!.docs;
        final Map<String, List<DocumentSnapshot>> groupedMaterials = {};

        for (var doc in materials) {
          final data = doc.data() as Map<String, dynamic>;
          final subject = data['subject'] ?? 'Unknown Subject';
          if (!groupedMaterials.containsKey(subject)) {
            groupedMaterials[subject] = [];
          }
          groupedMaterials[subject]!.add(doc);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: groupedMaterials.keys.length,
          itemBuilder: (context, index) {
            final subject = groupedMaterials.keys.elementAt(index);
            final subjectMaterials = groupedMaterials[subject]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        subject,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                ...subjectMaterials.map((doc) => _buildMaterialCard(doc)),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMaterialCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['type'] ?? 'DOC';
    final title = data['title'] ?? 'Untitled';
    final url = data['url'] ?? '#';

    Color iconColor;
    IconData icon;

    switch (type.toString().toUpperCase()) {
      case 'PDF':
        iconColor = Colors.red;
        icon = Icons.picture_as_pdf;
        break;
      case 'PPT':
        iconColor = Colors.orange;
        icon = Icons.slideshow;
        break;
      case 'VIDEO':
        iconColor = Colors.blue;
        icon = Icons.play_circle_fill;
        break;
      default:
        iconColor = Colors.blueGrey;
        icon = Icons.description;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          "Type: $type",
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.blueAccent),
          onPressed: () => _launchURL(url),
        ),
        onTap: () => _launchURL(url),
      ),
    );
  }

  Future<void> _launchURL(String urlString) async {
    if (urlString == '#' || urlString.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Download link not available yet.')),
      );
      return;
    }

    try {
      final Uri url = Uri.parse(urlString);

      // Immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attempting to download material...'),
          duration: const Duration(seconds: 2),
        ),
      );

      // Launch in an external application for better download handling
      final success = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open the link: $urlString')),
          );
        }
      }
    } catch (e) {
      debugPrint("Error launching URL: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Invalid URL format.')),
        );
      }
    }
  }
}
