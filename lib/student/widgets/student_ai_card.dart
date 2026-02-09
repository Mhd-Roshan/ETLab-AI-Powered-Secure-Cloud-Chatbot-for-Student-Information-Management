import 'package:flutter/material.dart';
import '../../services/edlab_ai_service.dart'; // Using your existing service

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EdLabAIService _aiService = EdLabAIService();

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': "Hi Roshan! 🚀\nI'm your EdLab AI assistant. I can check your personal timetable, attendance trends, or upcoming assignments. How can I help?",
      'time': DateTime.now(),
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
          // 1. Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) return _buildTypingIndicator();
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // 2. Quick Action Chips (Student Specific)
          _buildQuickActions(),

          // 3. Input Area (Matching the Screenshot style)
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade50,
            child: const Icon(Icons.auto_awesome, color: Color(0xFF3D6AF2), size: 20),
          ),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("edbot", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Online • Student Assistant", style: TextStyle(color: Colors.green, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'label': 'My Schedule', 'icon': Icons.calendar_month},
      {'label': 'Check Attendance', 'icon': Icons.pie_chart},
      {'label': 'Exam Dates', 'icon': Icons.history_edu},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: actions.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          return ActionChip(
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            avatar: Icon(actions[i]['icon'] as IconData, size: 16, color: const Color(0xFF3D6AF2)),
            label: Text(actions[i]['label'] as String, style: const TextStyle(fontSize: 12)),
            onPressed: () => _handleMessageSend(actions[i]['label'] as String),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.grey),
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
                      decoration: const InputDecoration(hintText: "Ask about your schedule...", border: InputBorder.none),
                      onSubmitted: _handleMessageSend,
                    ),
                  ),
                  const Icon(Icons.mic, color: Colors.grey),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleMessageSend(_textController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Color(0xFF3D6AF2), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isUser = msg['isUser'];
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF3D6AF2) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: [if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
        ),
        child: Text(
          msg['text'],
          style: TextStyle(color: isUser ? Colors.white : Colors.black87, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Text("edbot is thinking...", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
      ),
    );
  }

  void _handleMessageSend(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text, 'time': DateTime.now()});
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // Calling your service with userId
    String response = await _aiService.sendMessage('student_user', text); 

    if (mounted) {
      setState(() {
        _isTyping = false;
        _messages.add({'isUser': false, 'text': response, 'time': DateTime.now()});
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }
}