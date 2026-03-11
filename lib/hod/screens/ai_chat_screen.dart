import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/hod/widgets/hod_sidebar.dart';
import 'package:edlab/services/staff_ai_service.dart';
import 'package:edlab/services/voice_service.dart';
import 'package:edlab/services/translation_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialPrompt;
  final String userId;
  const AiChatScreen({super.key, this.initialPrompt, required this.userId});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final StaffAIService _aiService = StaffAIService();
  final VoiceService _voiceService = VoiceService();
  final TranslationService _translationService = TranslationService();
  late final String _currentUserId;

  String _currentResponse = """# Welcome to HOD Intelligence! 🏢👔

I'm your dedicated Assistant for **Departmental Administration & Management**. I have real-time access to staff metrics, student performance data, and institutional schedules.

## 🎤 **Departmental Voice Tools**
- **Voice Commands**: Ask about department status or staff progress
- **Instant TTS**: Response playback for hands-free management

## 📊 **Admin-Centric Data**
- **Staff**: Performance tracking and class scheduling
- **Students**: Department-wide attendance and grade analytics
- **Batches**: Resource allocation and batch status monitoring
- **Circulars**: Fast access to KTU university updates

## 💡 **Try These HOD Queries**
- *"Show me staff members with pending syllabus coverage"*
- *"Identify students across all batches with attendance below 75%"*
- *"Summarize department performance trends for the last semester"*
- *"What are the latest KTU circulars regarding semester exams?"*

**Ready to assist with your administrative duties. What can I help you with today?**
""";
  bool _isLoading = false;
  bool _isVoiceMode = false;
  bool _isListening = false;
  String _lastPrompt = "";
  String _voiceInputText = "";

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.userId;
    _initializeVoiceService();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _promptController.text = widget.initialPrompt!;
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendMessage();
      });
    }
  }

  void _initializeVoiceService() async {
    final voiceInitialized = await _voiceService.initialize();
    if (voiceInitialized) {
      _voiceService.onSpeechResult = (result) {
        setState(() {
          _voiceInputText = result;
          _promptController.text = result;
        });
        if (result.isNotEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!_isListening && _promptController.text.isNotEmpty) {
              _sendMessage();
            }
          });
        }
      };

      _voiceService.onSpeechError = (error) {
        _showSnackBar("Voice error: $error", isError: true);
      };

      _voiceService.onListeningStateChanged = (isListening) {
        setState(() {
          _isListening = isListening;
        });
      };
    }
  }

  void _sendMessage() async {
    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    _lastPrompt = prompt;

    setState(() {
      _isLoading = true;
      _currentResponse =
          "🔍 Analyzing departmental data and gathering insights...";
    });

    _promptController.clear();

    try {
      final response = await _aiService.sendMessage(_currentUserId, prompt);
      if (mounted) {
        setState(() {
          _currentResponse = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentResponse =
              "**Error Processing Admin Request**\n\nThere was an issue: $e\n\n**Try asking:**\n- Show department-wide low attendance\n- List staff with pending assignments\n- Summarize batch performance trends";
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadHistoryItem(String prompt, String response) {
    _promptController.text = prompt;
    setState(() => _currentResponse = response);
  }

  void _copyResponse() async {
    await Clipboard.setData(ClipboardData(text: _currentResponse));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Response copied to clipboard!"),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _regenerateResponse() async {
    if (_lastPrompt.isNotEmpty) {
      _promptController.text = _lastPrompt;
      _sendMessage();
    }
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
    });

    if (!_isVoiceMode) {
      _voiceService.stopListening();
    }

    _showSnackBar(
      _isVoiceMode
          ? "Voice mode enabled - Click microphone to speak"
          : "Voice mode disabled - Using text input",
    );
  }

  void _startListening() async {
    if (!_voiceService.speechEnabled) {
      _showSnackBar("Voice recognition not available", isError: true);
      return;
    }

    setState(() {
      _voiceInputText = "";
    });

    await _voiceService.setLanguage(_translationService.currentVoiceCode);
    await _voiceService.startListening();
  }

  void _stopListening() async {
    await _voiceService.stopListening();
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildVoiceControls() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _toggleVoiceMode,
          icon: Icon(
            _isVoiceMode ? Icons.keyboard : Icons.mic,
            color: _isVoiceMode ? const Color(0xFF001FF4) : Colors.grey,
          ),
          tooltip: _isVoiceMode
              ? 'Switch to text input'
              : 'Switch to voice input',
        ),
        if (_isVoiceMode) ...[
          const SizedBox(width: 8),
          if (_isListening)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, color: Colors.red, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'Listening...',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _startListening,
              icon: const Icon(Icons.mic, size: 16),
              label: const Text('Speak'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF001FF4),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (_isListening)
            IconButton(
              onPressed: _stopListening,
              icon: const Icon(Icons.stop, color: Colors.red),
              tooltip: "Stop listening",
            ),
        ],
      ],
    );
  }

  Widget _buildQuickActionButton(String label, String prompt) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          _promptController.text = prompt;
          _sendMessage();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF475569),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          HodSidebar(activeIndex: 1, userId: _currentUserId),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 300,
                  margin: const EdgeInsets.only(left: 24, top: 24, bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Color(0xFFF1F5F9)),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.history, color: Color(0xFF001FF4)),
                            SizedBox(width: 12),
                            Text(
                              "History",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: _aiService.getChatHistory(_currentUserId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return const Center(
                                child: Text(
                                  "No history yet",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data =
                                    docs[index].data() as Map<String, dynamic>;
                                return ListTile(
                                  title: Text(
                                    data['prompt'] ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  leading: const Icon(
                                    Icons.chat_bubble_outline,
                                    size: 18,
                                    color: Color(0xFF001FF4),
                                  ),
                                  onTap: () => _loadHistoryItem(
                                    data['prompt'],
                                    data['response'],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFF1F5F9)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF001FF4),
                                      Color(0xFF4F46E5),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "HOD Intelligence",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Admin Mode • Department Analytics • Institutional Support",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: _copyResponse,
                                    icon: const Icon(Icons.copy, size: 20),
                                    tooltip: "Copy Response",
                                  ),
                                  IconButton(
                                    onPressed: _regenerateResponse,
                                    icon: const Icon(Icons.refresh, size: 20),
                                    tooltip: "Regenerate",
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(40),
                            child: _isLoading
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF001FF4),
                                            ),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Synthesizing department insights...",
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )
                                : MarkdownBody(
                                    data: _currentResponse,
                                    selectable: true,
                                    styleSheet: MarkdownStyleSheet(
                                      p: const TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: Color(0xFF1E293B),
                                      ),
                                      h1: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      h2: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      code: TextStyle(
                                        backgroundColor: Colors.grey.shade100,
                                        color: const Color(0xFF001FF4),
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFF1F5F9)),
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_isVoiceMode && _voiceInputText.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.mic,
                                        color: Colors.blue,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _voiceInputText,
                                          style: const TextStyle(
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _promptController,
                                      onSubmitted: (_) => _sendMessage(),
                                      decoration: InputDecoration(
                                        hintText: _isVoiceMode
                                            ? "Voice input active - Speak now..."
                                            : "Ask about staff, students, or department metrics...",
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF001FF4),
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                        prefixIcon: _isVoiceMode
                                            ? const Icon(
                                                Icons.mic,
                                                color: Color(0xFF001FF4),
                                              )
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildVoiceControls(),
                                  const SizedBox(width: 8),
                                  Material(
                                    color: const Color(0xFF001FF4),
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: _sendMessage,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: const Icon(
                                          Icons.send_rounded,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildQuickActionButton(
                                    "📉 Dept Low Attend",
                                    "Show departmental low attendance report",
                                  ),
                                  _buildQuickActionButton(
                                    "👨‍🏫 Staff Syllabus",
                                    "Check staff syllabus coverage status",
                                  ),
                                  _buildQuickActionButton(
                                    "📈 Batch Metrics",
                                    "Summarize performance for all current batches",
                                  ),
                                  _buildQuickActionButton(
                                    "📜 KTU Circulars",
                                    "List latest KTU university circulars",
                                  ),
                                  _buildQuickActionButton(
                                    "📅 Admin Calendar",
                                    "Show upcoming department-wide events",
                                  ),
                                ],
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
