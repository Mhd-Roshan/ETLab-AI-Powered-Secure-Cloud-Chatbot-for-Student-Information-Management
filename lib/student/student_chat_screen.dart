import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/edlab_ai_service.dart';
import '../services/voice_service.dart';

class StudentChatScreen extends StatefulWidget {
  final Map<String, dynamic> studentData;
  final VoidCallback? onBack;
  const StudentChatScreen({super.key, required this.studentData, this.onBack});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EdLabAIService _aiService = EdLabAIService();
  final VoiceService _voiceService = VoiceService();
  final FocusNode _focusNode = FocusNode();

  final List<Map<String, dynamic>> _messages = [];

  bool _isTyping = false;
  bool _isListening = false;
  bool _isVoiceInitialized = false;

  late AnimationController _bgAnimController;
  late AnimationController _pulseController;

  // Premium light color palette
  static const Color _primaryBlue = Color(0xFF001FF4);
  static const Color _accentViolet = Color(0xFF7C3AED);
  static const Color _accentCyan = Color(0xFF0891B2);
  static const Color _lightBg = Color(0xFFF8FAFF);
  static const Color _cardWhite = Color(0xFFFFFFFF);
  static const Color _surfaceLight = Color(0xFFF1F5F9);
  static const Color _textPrimary = Color(0xFF1E293B);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();

    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _messages.add({
      'role': 'bot',
      'text':
          "Hey ${widget.studentData['firstName']}! 👋\n\nI'm **EdLab**, your AI study companion. Ask me about your attendance, results, assignments, or anything academic!",
      'time': DateTime.now(),
    });

    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      final initialized = await _voiceService.initialize();
      if (mounted) setState(() => _isVoiceInitialized = initialized);
      if (!initialized) return;

      _voiceService.onSpeechResult = (result) {
        if (mounted) {
          _textController.text = result;
          if (result.trim().isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 1500), () {
              if (mounted &&
                  _textController.text.trim().isNotEmpty &&
                  !_isListening) {
                _handleSend(_textController.text);
              }
            });
          }
        }
      };

      _voiceService.onListeningStateChanged = (isListening) {
        if (mounted) {
          setState(() => _isListening = isListening);
          if (!isListening && _textController.text.trim().isNotEmpty) {
            _handleSend(_textController.text);
          }
        }
      };

      _voiceService.onSpeechError = (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice error: $error'),
              backgroundColor: Colors.red.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      };
    } catch (e) {
      if (mounted) setState(() => _isVoiceInitialized = false);
    }
  }

  @override
  void dispose() {
    _bgAnimController.dispose();
    _pulseController.dispose();
    try {
      _voiceService.dispose();
    } catch (_) {}
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _lightBg,
      body: Stack(
        children: [
          // Subtle animated gradient blobs
          _buildAnimatedBackground(),

          // Main content
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: _messages.length + (_isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _messages.length)
                      return _buildTypingIndicator();
                    return _buildMessageBubble(_messages[index], index);
                  },
                ),
              ),
              if (_messages.length < 4) _buildSuggestionChips(),
              _buildInputBar(),
            ],
          ),
        ],
      ),
    );
  }

  // ─── ANIMATED BACKGROUND ────────────────────────────
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _bgAnimController,
      builder: (context, child) {
        return CustomPaint(
          painter: _LightGradientPainter(animation: _bgAnimController.value),
          size: Size.infinite,
        );
      },
    );
  }

  // ─── APP BAR ────────────────────────────────────────
  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 8,
            bottom: 14,
            left: 8,
            right: 14,
          ),
          decoration: BoxDecoration(
            color: _cardWhite.withOpacity(0.85),
            border: Border(
              bottom: BorderSide(
                color: _primaryBlue.withOpacity(0.06),
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: _textPrimary,
                ),
                onPressed: widget.onBack ?? () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              // AI Avatar with gradient ring
              Container(
                padding: const EdgeInsets.all(2.5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [_primaryBlue, _accentViolet, _accentCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryBlue.withOpacity(0.25),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF001FF4), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "EdLab AI",
                      style: GoogleFonts.inter(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF22C55E),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF22C55E).withOpacity(
                                      0.3 + _pulseController.value * 0.3,
                                    ),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "Online • Your Study Companion",
                          style: GoogleFonts.inter(
                            color: _textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _showClearConfirm,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: _textSecondary,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CLEAR CONFIRM ──────────────────────────────────
  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Clear Chat?",
          style: GoogleFonts.inter(
            color: _textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          "This will delete all messages in this session.",
          style: GoogleFonts.inter(color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: _textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade600,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add({
                  'role': 'bot',
                  'text': "Chat cleared! ✨ What would you like to know?",
                  'time': DateTime.now(),
                });
              });
              Navigator.pop(context);
            },
            child: Text(
              "Clear All",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SUGGESTION CHIPS ───────────────────────────────
  Widget _buildSuggestionChips() {
    final suggestions = [
      {
        'label': 'My Attendance',
        'icon': Icons.pie_chart_rounded,
        'color': const Color(0xFF16A34A),
      },
      {
        'label': 'Exam Results',
        'icon': Icons.emoji_events_rounded,
        'color': const Color(0xFFD97706),
      },
      {
        'label': 'Assignments',
        'icon': Icons.task_alt_rounded,
        'color': const Color(0xFF2563EB),
      },
      {
        'label': 'Study Tips',
        'icon': Icons.lightbulb_rounded,
        'color': const Color(0xFF9333EA),
      },
    ];

    return Container(
      height: 46,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final s = suggestions[i];
          return GestureDetector(
            onTap: () => _handleSend(s['label'] as String),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: (s['color'] as Color).withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: (s['color'] as Color).withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    s['icon'] as IconData,
                    size: 15,
                    color: s['color'] as Color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    s['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: s['color'] as Color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── INPUT BAR ──────────────────────────────────────
  Widget _buildInputBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: EdgeInsets.fromLTRB(
            16,
            10,
            16,
            MediaQuery.of(context).padding.bottom + 14,
          ),
          decoration: BoxDecoration(
            color: _cardWhite.withOpacity(0.9),
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 0.5),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isListening
                          ? Colors.red.withOpacity(0.4)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _focusNode,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _textPrimary,
                          ),
                          cursorColor: _primaryBlue,
                          decoration: InputDecoration(
                            hintText: _isListening
                                ? "Listening..."
                                : "Ask me anything...",
                            border: InputBorder.none,
                            hintStyle: GoogleFonts.inter(
                              color: _isListening
                                  ? Colors.red.shade400
                                  : Colors.grey.shade400,
                              fontWeight: _isListening
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                          onSubmitted: _handleSend,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleVoiceListening,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _isListening
                                ? Colors.red.withOpacity(0.1)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isListening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: _isListening
                                ? Colors.red.shade500
                                : Colors.grey.shade400,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _handleSend(_textController.text),
                child: Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryBlue, _accentViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _primaryBlue.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── MESSAGE BUBBLE ─────────────────────────────────
  Widget _buildMessageBubble(Map<String, dynamic> msg, int index) {
    bool isUser = msg['role'] == 'user' || msg['isUser'] == true;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 400 + (index < 3 ? index * 100 : 0)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[_buildBotAvatar(), const SizedBox(width: 8)],
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isUser ? null : _cardWhite,
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [_primaryBlue, Color(0xFF4338CA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isUser ? 20 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 20),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: Colors.grey.shade100, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: isUser
                          ? _primaryBlue.withOpacity(0.2)
                          : Colors.black.withOpacity(0.04),
                      blurRadius: isUser ? 16 : 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isUser
                    ? Text(
                        msg['text'],
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      )
                    : MarkdownBody(
                        data: msg['text'],
                        styleSheet: MarkdownStyleSheet(
                          p: GoogleFonts.inter(
                            color: _textPrimary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                          strong: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                          em: GoogleFonts.inter(
                            fontStyle: FontStyle.italic,
                            color: _accentViolet,
                          ),
                          listBullet: GoogleFonts.inter(color: _primaryBlue),
                          h1: GoogleFonts.inter(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          h2: GoogleFonts.inter(
                            color: _textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          code: GoogleFonts.firaCode(
                            color: _primaryBlue,
                            backgroundColor: _primaryBlue.withOpacity(0.06),
                            fontSize: 13,
                          ),
                          blockquoteDecoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: _accentViolet.withOpacity(0.4),
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
            ),
            if (isUser) ...[const SizedBox(width: 8), _buildUserAvatar()],
          ],
        ),
      ),
    );
  }

  Widget _buildBotAvatar() {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [_primaryBlue, _accentViolet],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: _primaryBlue.withOpacity(0.25), blurRadius: 8),
        ],
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
    );
  }

  Widget _buildUserAvatar() {
    String firstName = (widget.studentData['firstName'] ?? 'S')
        .toString()
        .trim();
    String initials = firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S';

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(color: _accentCyan.withOpacity(0.25), blurRadius: 8),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  // ─── TYPING INDICATOR ───────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildBotAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: _cardWhite,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => _buildAnimatedDot(i)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        final double offset = sin((value * 2 * pi) + (index * pi / 3)) * 3;
        return Container(
          margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
          child: Transform.translate(
            offset: Offset(0, offset),
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _primaryBlue.withOpacity(0.5 + (value * 0.5)),
                    _accentViolet.withOpacity(0.5 + (value * 0.5)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── ACTIONS ────────────────────────────────────────
  Future<void> _toggleVoiceListening() async {
    if (!_isVoiceInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Voice not available on this device',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: Colors.grey.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }
    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening();
      if (mounted) setState(() => _isListening = true);
    }
  }

  void _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    if (mounted) {
      setState(() {
        _messages.add({'role': 'user', 'text': text, 'time': DateTime.now()});
        _isTyping = true;
      });
    }
    _textController.clear();
    _focusNode.unfocus();
    _scrollToBottom();

    try {
      String response = await _aiService.sendStudentMessage(
        widget.studentData['registrationNumber'] ?? 'unknown',
        text,
        widget.studentData,
      );
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'bot',
            'text': response,
            'time': DateTime.now(),
          });
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'bot',
            'text':
                "Oops! I'm having a connection issue. Please try again in a moment. 🔄",
            'time': DateTime.now(),
          });
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }
}

// ─── LIGHT BACKGROUND PAINTER ───────────────────────
class _LightGradientPainter extends CustomPainter {
  final double animation;
  _LightGradientPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF8FAFF),
    );

    _drawOrb(
      canvas,
      Offset(
        size.width * 0.15 + sin(animation * 2 * pi) * 25,
        size.height * 0.1 + cos(animation * 2 * pi) * 15,
      ),
      size.width * 0.5,
      const Color(0xFF001FF4).withOpacity(0.04),
    );

    _drawOrb(
      canvas,
      Offset(
        size.width * 0.85 + cos(animation * 2 * pi + 1) * 20,
        size.height * 0.55 + sin(animation * 2 * pi + 1) * 25,
      ),
      size.width * 0.45,
      const Color(0xFF7C3AED).withOpacity(0.03),
    );

    _drawOrb(
      canvas,
      Offset(
        size.width * 0.5 + sin(animation * 2 * pi + 2) * 15,
        size.height * 0.9 + cos(animation * 2 * pi + 2) * 10,
      ),
      size.width * 0.4,
      const Color(0xFF06B6D4).withOpacity(0.03),
    );
  }

  void _drawOrb(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color, color.withOpacity(0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _LightGradientPainter oldDelegate) =>
      oldDelegate.animation != animation;
}
