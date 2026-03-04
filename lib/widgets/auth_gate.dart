import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../login.dart';
import '../admin/admin_dashboard.dart';
import '../hod/hod_dashboard.dart';
import '../staff/staff_dashboard.dart';
import '../staff_advisor/staff_advisor_dashboard.dart';
import '../student/student_dashboard.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;
  String? _username;
  String? _role;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      _username = prefs.getString('username');
      _role = prefs.getString('role');
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isLoggedIn || _username == null || _role == null) {
      return const LoginPage();
    }

    // Direct to correct dashboard based on saved role
    switch (_role) {
      case 'admin':
        return const AdminDashboard();
      case 'hod':
        return const HodDashboard();
      case 'student':
        return StudentDashboard(studentRegNo: _username!);
      case 'staff':
        return StaffDashboard(user: _username);
      case 'staff_advisor':
        return const StaffAdvisorDashboard();
      default:
        return StaffDashboard(user: _username);
    }
  }
}
