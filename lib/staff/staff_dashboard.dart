import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:edlab/staff/screens/ai_chat_screen.dart';
import 'package:edlab/services/staff_service.dart';
import 'package:edlab/services/voice_service.dart';

// Ensure these widget files exist in your project
import 'widgets/staff_sidebar.dart';
import 'widgets/staff_header.dart';
import 'widgets/staff_grid.dart';
import 'widgets/staff_calendar.dart';

class StaffDashboard extends StatefulWidget {
  final dynamic user;
  const StaffDashboard({super.key, this.user});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  final StaffService service = StaffService();

  // ✅ Navigation Helper
  void _navigateToAi(String prompt) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AiChatScreen(
          initialPrompt: prompt,
          userId: widget.user?.toString() ?? 'staff_member',
        ),
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
          // 1. Sidebar (Ensure your StaffSidebar has a button that calls _navigateToAi('') )
          StaffSidebar(
            activeIndex: 0,
            userId: widget.user?.toString() ?? 'staff_member',
          ),

          // 2. Main Content Area
          Expanded(
            flex: 5,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 32, 32, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StaffHeader(
                    userId: widget.user?.toString() ?? 'staff_member',
                  ),
                  const SizedBox(height: 32),

                  // --- SECTION 2: AI INTELLIGENCE HUB ---
                  Row(
                    children: [
                      // ✅ INTERACTIVE AI CHAT (Main Assistant)
                      Expanded(
                        flex: 3,
                        child: AiChatAssistantCard(
                          onSubmitted: (text) => _navigateToAi(text),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // ✅ AI PREDICTIVE INSIGHT CARD
                      const Expanded(flex: 2, child: AiInsightCard()),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // --- SECTION 3: WORKSPACE ---
                  Text(
                    "WORKSPACE",
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- SECTION 4: INTERACTIVE SERVICE GRID ---
                  StaffWorkspaceGrid(
                    staffId: widget.user?.toString() ?? 'staff_member',
                  ),
                ],
              ),
            ),
          ),

          // 3. Right Sidebar
          Container(
            width: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 20,
                  offset: const Offset(-5, 0),
                ),
              ],
            ),
            child: const StaffRightPanel(),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------
// ✅ 3. UPDATED AI CHAT CARD (Now Interactive!)
// ------------------------------------------------------------------
class AiChatAssistantCard extends StatefulWidget {
  final Function(String) onSubmitted; // Callback for search

  const AiChatAssistantCard({super.key, required this.onSubmitted});

  @override
  State<AiChatAssistantCard> createState() => _AiChatAssistantCardState();
}

class _AiChatAssistantCardState extends State<AiChatAssistantCard> {
  final TextEditingController _controller = TextEditingController();
  final VoiceService _voiceService = VoiceService();
  bool _isVoiceInitialized = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    final initialized = await _voiceService.initialize();
    if (mounted) {
      setState(() {
        _isVoiceInitialized = initialized;
      });
    }

    // Set up voice callbacks
    _voiceService.onSpeechResult = (result) {
      if (mounted) {
        _controller.text = result;
        // Auto-submit voice input
        if (result.isNotEmpty) {
          widget.onSubmitted(result);
        }
      }
    };

    _voiceService.onListeningStateChanged = (isListening) {
      if (mounted) {
        setState(() {
          _isListening = isListening;
        });
      }
    };

    _voiceService.onSpeechError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice error: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    };
  }

  Future<void> _toggleVoiceListening() async {
    if (!_isVoiceInitialized) return;

    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening();
    }
  }

  @override
  void dispose() {
    _voiceService.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF001FF4).withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, 15),
            spreadRadius: -5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Aurora Mesh Gradient Background
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF001FF4), // Brand Color
                    Color(0xFF4F46E5), // Indigo 600 (Transition)
                    Color(0xFF7C3AED), // Violet 600
                  ],
                ),
              ),
            ),
            // Floating Glow Effects
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 50,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -40,
              right: 10,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFEC4899).withValues(alpha: 0.3),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.4),
                      blurRadius: 60,
                    ),
                  ],
                ),
              ),
            ),
            // Main Content Layer
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "EdLab AI Assistant",
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Powered by Gemini 2.0 Pro",
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Refined Glass Input
                    Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: _isListening
                                    ? "Listening..."
                                    : "Ask anything about your classes...",
                                hintStyle: GoogleFonts.plusJakartaSans(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
                              ),
                              onSubmitted: (val) {
                                if (val.isNotEmpty) widget.onSubmitted(val);
                                _controller.clear();
                              },
                            ),
                          ),
                          // Voice Pulsing Button
                          GestureDetector(
                            onTap: _isVoiceInitialized
                                ? _toggleVoiceListening
                                : null,
                            child: Container(
                              margin: const EdgeInsets.only(right: 6),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _isListening
                                    ? Colors.redAccent
                                    : Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _isListening
                                    ? Icons.stop_rounded
                                    : Icons.mic_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          // Submit Action
                          GestureDetector(
                            onTap: () {
                              if (_controller.text.isNotEmpty) {
                                widget.onSubmitted(_controller.text);
                                _controller.clear();
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Color(0xFF001FF4),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AiInsightCard extends StatelessWidget {
  const AiInsightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background Gradient Shade
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "AI PREDICTIVE INSIGHTS",
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF64748B),
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.more_horiz_rounded,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 90,
                            height: 90,
                            child: CircularProgressIndicator(
                              value: 0.85,
                              strokeWidth: 10,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF10B981),
                              ),
                              strokeCap: StrokeCap.round,
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "85%",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF0F172A),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                "Stability",
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.shield_outlined,
                                  color: Color(0xFF15803D),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Low Risk",
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF15803D),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildInsightMini(
                            Icons.trending_down_rounded,
                            "12 At Risk",
                            const Color(0xFFF43F5E),
                          ),
                          const SizedBox(height: 8),
                          _buildInsightMini(
                            Icons.trending_up_rounded,
                            "45 Improving",
                            const Color(0xFF3B82F6),
                          ),
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
    );
  }

  Widget _buildInsightMini(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF475569),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
