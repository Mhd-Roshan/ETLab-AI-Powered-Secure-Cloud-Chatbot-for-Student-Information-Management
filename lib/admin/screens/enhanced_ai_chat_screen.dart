import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/services/enhanced_ai_service.dart';
import 'package:edlab/services/voice_service.dart';
import 'package:edlab/services/translation_service.dart';

class EnhancedAiChatScreen extends StatefulWidget {
  final String? initialPrompt;
  const EnhancedAiChatScreen({super.key, this.initialPrompt});

  @override
  State<EnhancedAiChatScreen> createState() => _EnhancedAiChatScreenState();
}

class _EnhancedAiChatScreenState extends State<EnhancedAiChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final EnhancedAIService _aiService = EnhancedAIService();
  final VoiceService _voiceService = VoiceService();
  final TranslationService _translationService = TranslationService();
  final String _currentUserId = 'admin';

  String _currentResponse = "";
  bool _isLoading = false;
  bool _isVoiceMode = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastPrompt = "";
  String _voiceInputText = "";

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setInitialWelcomeMessage();
    
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _promptController.text = widget.initialPrompt!;
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendMessage();
      });
    }
  }

  void _initializeServices() async {
    // Initialize voice service
    final voiceInitialized = await _voiceService.initialize();
    if (voiceInitialized) {
      _voiceService.onSpeechResult = (result) {
        setState(() {
          _voiceInputText = result;
          _promptController.text = result;
        });
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

  void _setInitialWelcomeMessage() {
    _currentResponse = """# Welcome to EdLab Intelligence! 🎓🌍

I'm your **multilingual AI assistant** with instant access to all university data. I can communicate in multiple languages and respond via voice!

## 🗣️ **Voice & Language Features**
- **Voice Input**: Speak your questions naturally
- **Text-to-Speech**: Hear responses in your language
- **Auto Language Detection**: I'll detect and respond in your preferred language
- **15+ Languages Supported**: Hindi, Malayalam, Tamil, Telugu, and more!

## 📊 **Available Data & Insights**
- **Students**: Attendance, grades, performance analytics
- **Staff**: Faculty information, department assignments  
- **Departments**: MCA, MBA statistics and details
- **Fees**: Payment records, collection summaries, structures
- **Exams**: University exam schedules and venues
- **Accounts**: Financial ledger and balance information

## 💡 **Try These Queries** (in any language!)
- *"Show me attendance summary by department"*
- *"छात्रों की उपस्थिति दिखाएं"* (Hindi)
- *"വിദ്യാർത്ഥികളുടെ ഹാജർ കാണിക്കുക"* (Malayalam)
- *"What's the total fee collection this month?"*
- *"List all MCA students with low attendance"*

## 🎤 **Voice Commands**
- Click the microphone to start voice input
- Say "Switch to [language]" to change languages
- Ask questions naturally in your preferred language

**Ready to explore your data? Ask me anything in text or voice!**
""";
  }

  void _sendMessage() async {
    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    _lastPrompt = prompt;

    setState(() {
      _isLoading = true;
      _currentResponse = "🔍 ${_translationService.getLocalizedText('processing')}...";
    });

    _promptController.clear();
    _voiceInputText = "";

    try {
      final response = await _aiService.sendMessage(_currentUserId, prompt);
      if (mounted) {
        setState(() {
          _currentResponse = response;
        });

        // Auto-speak response if in voice mode
        if (_isVoiceMode && !_isSpeaking) {
          _speakResponse(response);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentResponse = _getErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(String error) {
    return """**${_translationService.getLocalizedText('translation_error')}**

${_translationService.getLocalizedText('processing')}: $error

**${_translationService.getLocalizedText('voice_not_supported')}:**
- Check your internet connection
- Verify Firebase AI configuration
- Try again in a moment

**Available Data:**
- Students: Query student information, attendance, grades
- Staff: Faculty and staff details
- Departments: MCA, MBA department information  

Try asking: "${_translationService.getLocalizedText('listening')}"
""";
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
    });
    
    if (!_isVoiceMode) {
      _voiceService.stopListening();
      _voiceService.stopSpeaking();
    }
    
    _showSnackBar(
      _isVoiceMode 
        ? _translationService.getLocalizedText('switch_to_voice')
        : _translationService.getLocalizedText('switch_to_text')
    );
  }

  void _startListening() async {
    if (!_voiceService.speechEnabled) {
      _showSnackBar(_translationService.getLocalizedText('voice_not_supported'), isError: true);
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

  void _speakResponse(String response) async {
    if (!_voiceService.speechEnabled) return;

    // Clean and prepare text for TTS
    String cleanText = _translationService.cleanTextForTts(response);
    
    setState(() {
      _isSpeaking = true;
    });

    await _voiceService.setLanguage(_translationService.currentVoiceCode);
    await _voiceService.speak(cleanText);
    
    // Monitor speaking state
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isSpeaking = _voiceService.isSpeaking;
        });
      }
    });
  }

  void _stopSpeaking() async {
    await _voiceService.stopSpeaking();
    setState(() {
      _isSpeaking = false;
    });
  }

  void _showLanguageSelector() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_translationService.getLocalizedText('select_language')),
        content: SizedBox(
          width: 300,
          height: 400,
          child: ListView.builder(
            itemCount: _translationService.getSupportedLanguages().length,
            itemBuilder: (context, index) {
              final lang = _translationService.getSupportedLanguages()[index];
              final isSelected = lang['code'] == _translationService.currentLanguage;
              
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? const Color(0xFF6366F1) : Colors.grey,
                ),
                title: Text(lang['name']!),
                subtitle: Text(lang['code']!.toUpperCase()),
                onTap: () {
                  _translationService.setLanguage(lang['code']!);
                  Navigator.pop(context);
                  setState(() {});
                  _showSnackBar('Language changed to ${lang['name']}');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _loadHistoryItem(String prompt, String response) {
    _promptController.text = prompt;
    setState(() => _currentResponse = response);
  }

  void _copyResponse() async {
    await Clipboard.setData(ClipboardData(text: _currentResponse));
    _showSnackBar("Response copied to clipboard!");
  }

  void _regenerateResponse() async {
    if (_lastPrompt.isNotEmpty) {
      _promptController.text = _lastPrompt;
      _sendMessage();
    }
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isVoiceMode ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isVoiceMode ? const Color(0xFF6366F1) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Voice mode toggle
          IconButton(
            onPressed: _toggleVoiceMode,
            icon: Icon(
              _isVoiceMode ? Icons.keyboard : Icons.mic,
              color: _isVoiceMode ? const Color(0xFF6366F1) : Colors.grey,
            ),
            tooltip: _isVoiceMode 
              ? _translationService.getLocalizedText('switch_to_text')
              : _translationService.getLocalizedText('switch_to_voice'),
          ),
          
          if (_isVoiceMode) ...[
            const SizedBox(width: 8),
            // Listening indicator
            if (_isListening)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic, color: Colors.red, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _translationService.getLocalizedText('listening'),
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              // Voice input button
              ElevatedButton.icon(
                onPressed: _startListening,
                icon: const Icon(Icons.mic, size: 16),
                label: Text(_translationService.getLocalizedText('speak_now')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                ),
              ),
            
            const SizedBox(width: 8),
            
            // Stop listening button
            if (_isListening)
              IconButton(
                onPressed: _stopListening,
                icon: const Icon(Icons.stop, color: Colors.red),
                tooltip: "Stop listening",
              ),
          ],
          
          const Spacer(),
          
          // Language selector
          TextButton.icon(
            onPressed: _showLanguageSelector,
            icon: const Icon(Icons.language, size: 16),
            label: Text(_translationService.currentLanguageName.split(' ')[0]),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6366F1),
            ),
          ),
          
          // TTS controls
          if (_isSpeaking)
            IconButton(
              onPressed: _stopSpeaking,
              icon: const Icon(Icons.volume_off, color: Colors.red),
              tooltip: "Stop speaking",
            )
          else
            IconButton(
              onPressed: () => _speakResponse(_currentResponse),
              icon: const Icon(Icons.volume_up, color: Color(0xFF6366F1)),
              tooltip: "Read aloud",
            ),
        ],
      ),
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
          const SizedBox(width: 90, child: AdminSidebar(activeIndex: 3)),
          Expanded(
            child: Row(
              children: [
                // Chat History Sidebar
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
                          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.history, color: Color(0xFF6366F1)),
                            const SizedBox(width: 12),
                            const Text("Chat History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const Spacer(),
                            Icon(
                              Icons.language,
                              color: Colors.grey.shade600,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: FutureBuilder<QuerySnapshot>(
                          future: _aiService.getChatHistory(_currentUserId),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final docs = snapshot.data!.docs;
                            if (docs.isEmpty) {
                              return const Center(child: Text("No history yet", style: TextStyle(color: Colors.grey)));
                            }
                            return ListView.builder(
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final data = docs[index].data() as Map<String, dynamic>;
                                final language = data['language'] ?? 'en';
                                return ListTile(
                                  title: Text(data['prompt'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                                  subtitle: Text(
                                    TranslationService.supportedLanguages[language]?['name'] ?? 'English',
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                                  ),
                                  leading: const Icon(Icons.chat_bubble_outline, size: 18, color: Color(0xFF6366F1)),
                                  onTap: () => _loadHistoryItem(data['prompt'], data['response']),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Main Chat Area
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
                        // Header
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("EdLab Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text(
                                    "Multilingual AI • ${_translationService.currentLanguageName}",
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                        
                        // Voice Controls
                        Container(
                          padding: const EdgeInsets.all(16),
                          child: _buildVoiceControls(),
                        ),
                        
                        // Response Area
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                            child: _isLoading
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _translationService.getLocalizedText('processing'),
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
                                      p: const TextStyle(fontSize: 15, height: 1.6, color: Color(0xFF1E293B)),
                                      h1: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                      code: TextStyle(backgroundColor: Colors.grey.shade100, color: const Color(0xFF6366F1)),
                                    ),
                                  ),
                          ),
                        ),
                        
                        // Input Area
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Column(
                            children: [
                              // Voice input display
                              if (_isVoiceMode && _voiceInputText.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue.shade200),
                                  ),
                                  child: Text(
                                    _voiceInputText,
                                    style: const TextStyle(fontStyle: FontStyle.italic),
                                  ),
                                ),
                              
                              // Text input row
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _promptController,
                                      onSubmitted: (_) => _sendMessage(),
                                      decoration: InputDecoration(
                                        hintText: _isVoiceMode 
                                          ? _translationService.getLocalizedText('voice_input')
                                          : "Ask anything about university data...",
                                        filled: true,
                                        fillColor: const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: const BorderSide(color: Color(0xFF6366F1)),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Material(
                                    color: const Color(0xFF6366F1),
                                    borderRadius: BorderRadius.circular(16),
                                    child: InkWell(
                                      onTap: _sendMessage,
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 24),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // Quick action buttons
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _buildQuickActionButton("📊 Attendance Summary", "Show me attendance summary by department"),
                                  _buildQuickActionButton("💰 Fee Collection", "What's the total fee collection this month?"),
                                  _buildQuickActionButton("👥 Student Stats", "Give me student count by department"),
                                  _buildQuickActionButton("📅 Upcoming Exams", "Show me upcoming exams this week"),
                                  _buildQuickActionButton("🏫 Staff Overview", "List all staff by department"),
                                  _buildQuickActionButton("📈 Performance Analytics", "Show me student performance analytics"),
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