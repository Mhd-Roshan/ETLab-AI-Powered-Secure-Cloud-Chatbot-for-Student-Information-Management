import 'package:flutter/material.dart';
import '../services/edlab_ai_service.dart';
import '../services/voice_service.dart';

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final EdLabAIService _aiService = EdLabAIService();
  final VoiceService _voiceService = VoiceService();

  // Local message list (Empty initial state)
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': "Hi! I'm edbot. 👋 How can I help with your schedule or academics today?",
      'time': DateTime.now(),
    }
  ];

  bool _isTyping = false;
  bool _isListening = false;
  bool _isVoiceInitialized = false;

  @override
  void initState() {
    super.initState();
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

      if (!initialized) {
        // Voice not available on this platform
        return;
      }

      // Set up voice callbacks
      _voiceService.onSpeechResult = (result) {
        if (mounted) {
          _textController.text = result;
          // Auto-send when voice input is complete
          if (result.trim().isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted && _textController.text.trim().isNotEmpty) {
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
          
          // When listening stops, auto-send if there's text
          if (!isListening && _textController.text.trim().isNotEmpty) {
            Future.delayed(const Duration(milliseconds: 800), () {
              if (mounted && _textController.text.trim().isNotEmpty && !_isListening) {
                _handleSend(_textController.text);
              }
            });
          }
        }
      };

      _voiceService.onSpeechError = (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Voice error: $error'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      };
    } catch (e) {
      // Voice service not available on this platform (e.g., web)
      if (mounted) {
        setState(() {
          _isVoiceInitialized = false;
        });
      }
    }
  }

  @override
  void dispose() {
    try {
      _voiceService.dispose();
    } catch (e) {
      // Voice service dispose failed - safe to ignore on web
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // 1. Chat Messages Area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // 2. Suggestion Chips (From your screenshot)
          _buildSuggestionChips(),

          // 3. Floating Input Bar
          _buildInputBar(),
        ],
      ),
    );
  }

  // --- UI Components ---

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black54),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: false,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                radius: 18,
                child: const Icon(Icons.auto_awesome, color: Color(0xFF3D6AF2), size: 18),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.lightGreenAccent.shade400,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("edbot", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Online", style: TextStyle(color: Colors.blue.shade400, fontSize: 12)),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(icon: const Icon(Icons.more_horiz, color: Colors.black54), onPressed: () {}),
      ],
    );
  }

  Widget _buildSuggestionChips() {
    final List<Map<String, dynamic>> suggestions = [
      {'label': 'My Schedule', 'icon': Icons.calendar_today},
      {'label': 'Exam Dates', 'icon': Icons.star_border},
      {'label': 'Library', 'icon': Icons.book_outlined},
    ];

    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (ctx, i) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          return ActionChip(
            backgroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade200),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            avatar: Icon(suggestions[i]['icon'] as IconData, size: 16, color: const Color(0xFF3D6AF2)),
            label: Text(suggestions[i]['label'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            onPressed: () => _handleSend(suggestions[i]['label'] as String),
          );
        },
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  hintText: _isListening ? "Listening..." : "Ask about your schedule...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: _isListening ? const Color(0xFF3D6AF2) : Colors.grey,
                    fontWeight: _isListening ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
                onSubmitted: _handleSend,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _toggleVoiceListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _isListening ? Colors.red.shade50 : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: _isListening ? Colors.red : Colors.grey,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _handleSend(_textController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF3D6AF2),
                shape: BoxShape.circle,
              ),
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
          color: isUser ? const Color(0xFF3D6AF2) : const Color(0xFFF3F7FF),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
        ),
        child: Text(
          msg['text'],
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            height: 1.4,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
        child: const Text("edbot is thinking...", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
      ),
    );
  }

  // --- Logic ---

  Future<void> _toggleVoiceListening() async {
    if (!_isVoiceInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice service not available'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_isListening) {
      await _voiceService.stopListening();
    } else {
      await _voiceService.startListening();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.mic, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Listening... Message will send automatically')),
              ],
            ),
            backgroundColor: Color(0xFF3D6AF2),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({'isUser': true, 'text': text, 'time': DateTime.now()});
      _isTyping = true;
    });
    _textController.clear();
    _scrollToBottom();

    // CALL YOUR SERVICE
    try {
      String response = await _aiService.sendMessage('student_user', text); // Using sendMessage

      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({'isUser': false, 'text': response, 'time': DateTime.now()});
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isTyping = false);
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