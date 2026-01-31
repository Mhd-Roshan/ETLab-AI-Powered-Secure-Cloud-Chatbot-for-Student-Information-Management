import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/admin/admin_dashboard.dart';
import 'package:edlab/hod/hod_dashboard.dart';
import 'package:edlab/staff/staff_dashboard.dart';
import 'package:edlab/staff_advisor/staff_advisor_dashboard.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _collegeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // Animation for floating elements
  late AnimationController _controller;

  // --- COLOR PALETTE (Pixel / Retro Tech) ---
  final Color _accentOrange = const Color(0xFFFF6803); // Retro Orange
  final Color _deepOrange = const Color(0xFFAE3A02);
  final Color _bgGray = const Color(0xFFEBEBEB); // Light tech gray
  final Color _textBlack = const Color(0xFF1A1A1A);
  final Color _glassWhite = Colors.white.withOpacity(0.65); // Frosted feel
  final Color _glassBorder = Colors.white.withOpacity(0.9);

  // --- LIST OF KTU COLLEGES ---
  static const List<String> _ktuColleges = [
    "College of Engineering Trivandrum (TVE)",
    "KMCT College of Engineering Kozhikode (KMCT)",
    "Govt. Engineering College, Thrissur (TCR)",
    "Rajiv Gandhi Institute of Technology, Kottayam (RIT)",
    "Govt. Engineering College, Barton Hill (TRV)",
    "Govt. Engineering College, Kozhikode (KKE)",
    "Model Engineering College, Thrikkakara (MEC)",
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _collegeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleLogin(BuildContext context) async {
    if (_collegeController.text.isEmpty ||
        _usernameController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PLEASE FILL ALL FIELDS',
            style: GoogleFonts.courierPrime(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: _deepOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    String role = _determineUserRole(_usernameController.text);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      _navigateToDashboard(context, role);
    }
  }

  String _determineUserRole(String username) {
    final upperUser = username.toUpperCase().trim();
    if (upperUser.contains('ADVISOR') || upperUser.contains('STAFFAD'))
      return 'staff_advisor';
    if (upperUser.contains('HOD')) return 'hod';
    if (upperUser.contains('ADMIN')) return 'admin';
    if (upperUser.startsWith('SA')) return 'staff_advisor';
    if (upperUser.startsWith('H')) return 'hod';
    if (upperUser.startsWith('A')) return 'admin';
    if (upperUser.startsWith('S')) return 'staff';
    return 'staff';
  }

  void _navigateToDashboard(BuildContext context, String role) {
    Widget dashboard;

    // Explicitly assigning the widget based on role
    switch (role) {
      case 'admin':
        dashboard = const AdminDashboard();
        break;
      case 'hod':
        dashboard = const HodDashboard();
        break;
      case 'staff_advisor':
        dashboard = const StaffAdvisorDashboard();
        break;
      case 'staff':
      default:
        dashboard = const StaffDashboard();
        break;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => dashboard),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 1000;

    return Scaffold(
      backgroundColor: _bgGray,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Dot Grid Background
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(color: _textBlack.withOpacity(0.1)),
            ),
          ),

          // 2. Background Typography
          Positioned(
            top: size.height * 0.1,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.03,
              child: Text(
                "EDLAB",
                textAlign: TextAlign.center,
                style: GoogleFonts.silkscreen(
                  fontSize: isDesktop ? 200 : 100,
                  fontWeight: FontWeight.w900,
                  color: _textBlack,
                  height: 0.9,
                ),
              ),
            ),
          ),

          // 3. Floating Objects
          _buildFloatingObject(
            left: size.width * 0.1,
            top: size.height * 0.15,
            icon: Icons.menu_book_rounded,
            color: Colors.blueAccent,
            size: 60,
            delay: 0,
          ),
          _buildFloatingObject(
            right: size.width * 0.1,
            bottom: size.height * 0.2,
            icon: Icons.school_rounded,
            color: _textBlack,
            size: 80,
            delay: 1.5,
          ),
          _buildFloatingObject(
            right: size.width * 0.15,
            top: size.height * 0.1,
            icon: Icons.science_rounded,
            color: Colors.purpleAccent,
            size: 50,
            delay: 2.5,
          ),
          _buildFloatingObject(
            left: size.width * 0.12,
            bottom: size.height * 0.15,
            icon: Icons.memory_rounded,
            color: _accentOrange,
            size: 70,
            delay: 3.5,
          ),

          // 4. Main Glass Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    alignment: Alignment.center,
                    child: Image.asset(
                      "assets/edlab.png",
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.hub, color: _accentOrange, size: 60);
                      },
                    ),
                  ),
                  const SizedBox(height: 11),
                  Text(
                    "INITIALIZE SESSION...",
                    style: GoogleFonts.courierPrime(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 40,
                        ),
                        decoration: BoxDecoration(
                          color: _glassWhite,
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: _glassBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildPixelInput(
                              label: "College Institute",
                              child: _buildAutocompleteField(),
                            ),
                            const SizedBox(height: 24),
                            _buildPixelInput(
                              label: "User Identity",
                              child: TextFormField(
                                controller: _usernameController,
                                style: GoogleFonts.spaceMono(
                                  color: _textBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                                cursorColor: _accentOrange,
                                decoration: _buildInputDecoration(
                                  "ID NO",
                                  Icons.badge,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            _buildPixelInput(
                              label: "Security Key",
                              child: TextFormField(
                                controller: _passwordController,
                                obscureText: !_isPasswordVisible,
                                style: GoogleFonts.spaceMono(
                                  color: _textBlack,
                                  fontWeight: FontWeight.bold,
                                ),
                                cursorColor: _accentOrange,
                                decoration:
                                    _buildInputDecoration(
                                      "Password",
                                      Icons.lock_outline,
                                    ).copyWith(
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _isPasswordVisible
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                          color: Colors.grey[600],
                                          size: 18,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _isPasswordVisible =
                                                !_isPasswordVisible;
                                          });
                                        },
                                      ),
                                    ),
                              ),
                            ),

                            const SizedBox(height: 36),

                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : () => _handleLogin(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentOrange,
                                  foregroundColor: _textBlack,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 10,
                                  shadowColor: _accentOrange.withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: _textBlack,
                                          strokeWidth: 3,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "LOGIN",
                                            style: GoogleFonts.courierPrime(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.login, size: 20),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    "RESET KEY?",
                                    style: GoogleFonts.spaceMono(
                                      color: _textBlack.withOpacity(0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {},
                                  child: Text(
                                    "GET HELP",
                                    style: GoogleFonts.spaceMono(
                                      color: _textBlack.withOpacity(0.6),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "SYSTEM STATUS: ",
                        style: GoogleFonts.spaceMono(
                          color: Colors.grey[600],
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        "ONLINE",
                        style: GoogleFonts.spaceMono(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
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
  Widget _buildFloatingObject({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required IconData icon,
    required Color color,
    required double size,
    required double delay,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double offsetY = sin((_controller.value * 2 * pi) + delay) * 15;
        final double rotateZ = sin((_controller.value * 2 * pi) + delay) * 0.1;

        return Positioned(
          top: top != null ? top + offsetY : null,
          bottom: bottom != null ? bottom + offsetY : null,
          left: left,
          right: right,
          child: Transform.rotate(
            angle: rotateZ,
            child: Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(size / 3),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, color: color, size: size * 0.6),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPixelInput({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.spaceMono(
              color: _textBlack.withOpacity(0.6),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: child,
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.spaceMono(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, color: _textBlack.withOpacity(0.7), size: 20),
      border: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      isDense: true,
    );
  }

  Widget _buildAutocompleteField() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Autocomplete<String>(
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            return _ktuColleges.where((String option) {
              return option.toLowerCase().contains(
                textEditingValue.text.toLowerCase(),
              );
            });
          },
          onSelected: (String selection) {
            _collegeController.text = selection;
          },
          fieldViewBuilder:
              (context, textController, focusNode, onFieldSubmitted) {
                textController.addListener(() {
                  _collegeController.text = textController.text;
                });
                return TextFormField(
                  controller: textController,
                  focusNode: focusNode,
                  style: GoogleFonts.spaceMono(
                    color: _textBlack,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  cursorColor: _accentOrange,
                  decoration: _buildInputDecoration(
                    "Search College...",
                    Icons.school_outlined,
                  ),
                );
              },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                color: Colors.transparent,
                elevation: 15,
                shadowColor: Colors.black12,
                child: Container(
                  width: constraints.maxWidth,
                  margin: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[200]),
                    itemBuilder: (BuildContext context, int index) {
                      final String option = options.elementAt(index);
                      return ListTile(
                        dense: true,
                        title: Text(
                          option,
                          style: GoogleFonts.spaceMono(
                            color: _textBlack,
                            fontSize: 12,
                          ),
                        ),
                        onTap: () => onSelected(option),
                        hoverColor: _accentOrange.withOpacity(0.1),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class DotGridPainter extends CustomPainter {
  final Color color;
  DotGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2;

    const double spacing = 40;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
