import 'package:flutter/material.dart';

class ModuleScreen extends StatelessWidget {
  final String title;
  final Color color;

  const ModuleScreen({super.key, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: color,
        title: Text(title, style: const TextStyle(color: Colors.white)),
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: color.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              "$title Module",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 10),
            const Text("Functionality coming soon..."),
          ],
        ),
      ),
    );
  }
}