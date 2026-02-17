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

class _StudentChatScreenState extends State<StudentChatScreen> {
  // ... existing state variables ...
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EdLabAIService _aiService = EdLabAIService();
  final VoiceService _voiceService = VoiceService();

  final List<Map<String, dynamic>> _messages = [];

  bool _isTyping = false;
  bool _isListening = false;
  bool _isVoiceInitialized = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'text':
          "Hi ${widget.studentData['firstName']}! I'm EdLab. 👋 \nI can help with your marks, assignments, attendance, or anything else about your studies. What's on your mind?",
      'time': DateTime.now(),
    });
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      final initialized = await _voiceService.initialize();
      if (mounted) {
        setState(() {
          _isVoiceInitialized = initialized;
        });
      }

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
          setState(() {
            _isListening = isListening;
          });
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
              backgroundColor: Colors.red,
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
    try {
      _voiceService.dispose();
    } catch (e) {
      // Ignore
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5), // Softer background
      extendBodyBehindAppBar: true,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const NetworkImage(
              'https://www.transparenttextures.com/patterns/cubes.png',
            ),
            opacity: 0.05,
            colorFilter: ColorFilter.mode(
              Colors.blue.withOpacity(0.05),
              BlendMode.srcATop,
            ),
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(
                  16,
                  MediaQuery.of(context).padding.top + 70,
                  16,
                  20,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) return _buildTypingIndicator();
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),

            // Chips
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_messages.length < 5) _buildSuggestionChips(),
                  _buildInputBar(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(65),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 18,
                    color: Colors.black87,
                  ),
                  onPressed: widget.onBack ?? () => Navigator.pop(context),
                ),
                const SizedBox(width: 4),
                _buildAvatar('bot', size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "EdLab AI",
                        style: GoogleFonts.poppins(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Always Active",
                            style: GoogleFonts.inter(
                              color: Colors.green.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.history_rounded,
                    color: Colors.grey.shade700,
                    size: 22,
                  ),
                  tooltip: "Clear History",
                  onPressed: _showClearConfirm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showClearConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          "Clear Chat?",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "This will delete all current messages in this session.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red,
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
                  'text': "Chat reset! How can I assist you now?",
                  'time': DateTime.now(),
                });
              });
              Navigator.pop(context);
            },
            child: const Text("Clear All"),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String role, {double size = 32}) {
    bool isBot = role == 'bot';

    if (isBot) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFF3D6AF2), Color(0xFF6B92F2)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.auto_awesome, color: Colors.white, size: size * 0.6),
      );
    }

    // Student Avatar logic
    String? profileUrl = widget.studentData['profileImage'];
    String regNo = (widget.studentData['registrationNumber'] ?? 'default')
        .toString();

    // If no explicit profile image, use the same pravatar service as dashboard
    final String imageUrl = (profileUrl != null && profileUrl.isNotEmpty)
        ? profileUrl
        : 'https://i.pravatar.cc/150?u=$regNo';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback to initial like Dashboard
            String firstName = (widget.studentData['firstName'] ?? 'S')
                .toString()
                .trim();
            String initials = firstName.isNotEmpty
                ? firstName[0].toUpperCase()
                : 'S';

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    final List<Map<String, dynamic>> suggestions = [
      {'label': 'My Attendance', 'icon': Icons.calendar_month},
      {'label': 'Exam Results', 'icon': Icons.grade},
      {'label': 'Pending Assignments', 'icon': Icons.assignment},
      {'label': 'Class Schedule', 'icon': Icons.schedule},
    ];

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          return InkWell(
            onTap: () => _handleSend(suggestions[i]['label']),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.blue.shade100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade50,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    suggestions[i]['icon'],
                    size: 14,
                    color: const Color(0xFF3D6AF2),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    suggestions[i]['label'],
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
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

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F9),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: _isListening
                            ? "Listening..."
                            : "Ask me anything...",
                        border: InputBorder.none,
                        hintStyle: TextStyle(
                          color: _isListening
                              ? const Color(0xFF3D6AF2)
                              : Colors.grey.shade500,
                          fontWeight: _isListening
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      onSubmitted: _handleSend,
                    ),
                  ),
                  GestureDetector(
                    onTap: _toggleVoiceListening,
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: _isListening ? Colors.red : Colors.grey.shade600,
                      size: 20,
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
              height: 48,
              width: 48,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3D6AF2), Color(0xFF5C81F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isUser = msg['role'] == 'user' || msg['isUser'] == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[_buildAvatar('bot'), const SizedBox(width: 8)],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF3D6AF2) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 5),
                  bottomRight: Radius.circular(isUser ? 5 : 20),
                ),
                gradient: isUser
                    ? const LinearGradient(
                        colors: [Color(0xFF3D6AF2), Color(0xFF5C81F2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: isUser
                  ? Text(
                      msg['text'],
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    )
                  : MarkdownBody(
                      data: msg['text'],
                      styleSheet: MarkdownStyleSheet(
                        p: GoogleFonts.inter(
                          color: Colors.black87,
                          fontSize: 14,
                          height: 1.5,
                        ),
                        strong: GoogleFonts.inter(fontWeight: FontWeight.bold),
                        listBullet: GoogleFonts.inter(color: Colors.black87),
                      ),
                    ),
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), _buildAvatar('user')],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildAvatar('bot'),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 5,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(0),
                const SizedBox(width: 4),
                _dot(1),
                const SizedBox(width: 4),
                _dot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: (value + (index * 0.3)) % 1.0,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF3D6AF2),
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // --- Actions ---

  Future<void> _toggleVoiceListening() async {
    if (!_isVoiceInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Voice not available on this device')),
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
            'text': "I'm having trouble connecting. Please check your network.",
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}
