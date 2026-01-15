import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/dashboard_home.dart';
import 'screens/generic_page.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_header.dart';
import '../login.dart'; 

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      const DashboardHome(),
      const GenericPage(title: "Staff Advisor Portal"),
      const GenericPage(title: "My Classes"),
      const GenericPage(title: "FA Calculator"),
      const GenericPage(title: "My Timetable"),
      const GenericPage(title: "Substitutions"),
    ];
  }

  void _onSidebarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _handleLogout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width >= 1024;

    // IOS 26 Style Colors
    final bgColor = _isDarkMode ? const Color(0xFF0D0D0D) : const Color(0xFFF2F2F7);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        scaffoldBackgroundColor: bgColor,
        fontFamily: GoogleFonts.inter().fontFamily, // Clean modern font
        useMaterial3: true,
      ),
      home: Scaffold(
        drawer: !isDesktop
            ? Drawer(
                backgroundColor: _isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                child: AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: (index) {
                    _onSidebarItemTapped(index);
                    Navigator.pop(context);
                  },
                  onLogout: _handleLogout,
                  isDarkMode: _isDarkMode,
                ),
              )
            : null,
        body: Row(
          children: [
            if (isDesktop)
              SizedBox(
                width: 280, // Slightly wider for better spacing
                child: AdminSidebar(
                  selectedIndex: _selectedIndex,
                  onItemSelected: _onSidebarItemTapped,
                  onLogout: _handleLogout,
                  isDarkMode: _isDarkMode,
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  DashboardHeader(
                    toggleTheme: _toggleTheme,
                    isDarkMode: _isDarkMode,
                    showMenu: !isDesktop,
                  ),
                  Expanded(child: _pages[_selectedIndex]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}