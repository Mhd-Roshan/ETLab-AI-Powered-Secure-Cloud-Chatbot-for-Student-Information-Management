import 'package:flutter/material.dart';
import 'staff_advisor_dashboard.dart';
import '../login.dart';

void main() {
  runApp(const StaffAdvisorApp());
}

class StaffAdvisorApp extends StatelessWidget {
  const StaffAdvisorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Staff Advisor Dashboard - Edlab',
      theme: ThemeData(
        fontFamily: 'Roboto',
        primaryColor: const Color(0xFF1867DC),
        scaffoldBackgroundColor: const Color(0xFFF8F9FB),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1867DC),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
