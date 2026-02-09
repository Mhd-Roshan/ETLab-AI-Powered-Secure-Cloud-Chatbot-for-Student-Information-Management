import 'package:flutter/material.dart';

class AdminChatScreen extends StatefulWidget {
  const AdminChatScreen({super.key});

  @override
  State<AdminChatScreen> createState() => _AdminChatScreenState();
}

class _AdminChatScreenState extends State<AdminChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  // Initial Admin-Specific Message
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': "Welcome, Administrator. 🛡️\nI have access to real-time college data. Ask me about Fee Collections, Staff Attendance, or Student Performance.",
      'time': DateTime.now().subtract(const Duration(minutes: 1)),
    },
  ];

  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. Chat List Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // 2. Admin Quick Action Chips
          _buildQuickActionChips(),

          // 3. Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  // --- Widgets ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        },
      ),
      title: Row(
        children: [
          Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.shade50, // Purple for Admin
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.security, color: Colors.deepPurple, size: 20),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              )
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "EdLab Insight",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Admin Mode",
                style: TextStyle(
                  color: Colors.deepPurple.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade100, height: 1),
      ),
    );
  }

  Widget _buildQuickActionChips() {
    if (MediaQuery.of(context).viewInsets.bottom > 0) return const SizedBox.shrink();

    // Admin Specific Actions
    final actions = [
      {'icon': Icons.payments, 'label': 'Fee Stats', 'color': Colors.green},
      {'icon': Icons.people_alt, 'label': 'Staff Log', 'color': Colors.blue},
      {'icon': Icons.warning_amber_rounded, 'label': 'At-Risk', 'color': Colors.red},
      {'icon': Icons.bar_chart, 'label': 'Enrollment', 'color': Colors.orange},
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 12),
        itemBuilder: (ctx, i) {
          final action = actions[i];
          return ActionChip(
            elevation: 0,
            pressElevation: 2,
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            avatar: Icon(
              action['icon'] as IconData,
              size: 18,
              color: action['color'] as Color,
            ),
            label: Text(
              action['label'] as String,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            onPressed: () => _handleSubmitted(action['label'] as String),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.attach_file, color: Colors.grey, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                        hintText: "Ask about fees, staff...",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                      ),
                      onSubmitted: _handleSubmitted,
                    ),
                  ),
                  const Icon(Icons.mic, color: Colors.grey, size: 22),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleSubmitted(_textController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Colors.deepPurple, // Admin Theme Color
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final bool isUser = message['isUser'];
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.80),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
          ),
          boxShadow: [
            if (!isUser)
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Text(
          message['text'],
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
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
              color: Colors.deepPurpleAccent,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  // --- Admin Bot Logic ---

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'isUser': true,
        'text': text,
        'time': DateTime.now(),
      });
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Simulate thinking delay
    await Future.delayed(const Duration(seconds: 1, milliseconds: 200));

    String response = _generateAdminResponse(text);

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({
          'isUser': false,
          'text': response,
          'time': DateTime.now(),
        });
      });
      _scrollToBottom();
    }
  }

  String _generateAdminResponse(String input) {
    input = input.toLowerCase();
    
    if (input.contains("fee") || input.contains("money") || input.contains("collected")) {
      return "📊 **Fee Status (Today):**\n\n• Collected: \$12,500\n• Outstanding Dues: \$45,000\n\n85% of Semester 4 students have cleared their dues. Would you like a detailed report sent to your email?";
    } 
    else if (input.contains("staff") || input.contains("attendance") || input.contains("faculty")) {
      return "👥 **Staff Logistics:**\n\n• Attendance: 92% (48/52 present)\n• On Leave: Prof. Kumar, Dr. Smitha\n• Current Active Classes: 14\n\nDr. Sharma is currently in Lab Complex B.";
    } 
    else if (input.contains("risk") || input.contains("alert") || input.contains("fail")) {
      return "⚠️ **At-Risk Alerts:**\n\nI've identified 5 students in the CS Department with attendance below 75%. \n\nAlso, 3 students failed the recent Series Exam 2. Should I notify their Staff Advisors?";
    } 
    else if (input.contains("enroll") || input.contains("admission")) {
      return "📈 **Enrollment Stats:**\n\nTotal Students: 1,240\n• CSE: 420\n• ME: 380\n• ECE: 300\n• CE: 140\n\nAdmissions for the new batch are currently OPEN.";
    } 
    else if (input.contains("hello") || input.contains("hi")) {
      return "Hello Admin! I'm ready to assist with college management tasks. Try asking about 'Fees' or 'Staff Attendance'.";
    } 
    else {
      return "I can help with administrative data. Try asking: 'How much fee was collected today?' or 'Who is on leave?'.";
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
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