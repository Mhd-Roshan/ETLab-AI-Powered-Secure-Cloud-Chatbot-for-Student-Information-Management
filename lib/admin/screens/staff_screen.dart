import 'package:flutter/material.dart';

class StaffScreen extends StatelessWidget {
  final Color color;
  const StaffScreen({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    // Dummy data based on your firebase_init.js
    final List<Map<String, dynamic>> staffList = [
      {
        "name": "Dr. Sharma",
        "designation": "Associate Professor",
        "dept": "CSE",
        "id": "TVE_001"
      },
      {
        "name": "Prof. Kumar",
        "designation": "Assistant Professor",
        "dept": "ME",
        "id": "TCR_001"
      },
      {
        "name": "Dr. Patel",
        "designation": "Professor",
        "dept": "ECE",
        "id": "KMCT_001"
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff Management"),
        backgroundColor: color,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list), onPressed: () {}),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        backgroundColor: color,
        icon: const Icon(Icons.person_add),
        label: const Text("Add Staff"),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search staff...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // Staff List
          Expanded(
            child: ListView.builder(
              itemCount: staffList.length,
              itemBuilder: (context, index) {
                final staff = staffList[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      staff['name'].substring(0, 1),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    staff['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("${staff['designation']} • ${staff['dept']}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone, color: Colors.green),
                    onPressed: () {},
                  ),
                  onTap: () {},
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}