import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';
import 'package:edlab/services/edlab_ai_service.dart';

class AiChatScreen extends StatefulWidget {
  final String? initialPrompt;
  const AiChatScreen({super.key, this.initialPrompt});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _promptController = TextEditingController();
  final EdLabAIService _aiService = EdLabAIService();
  final String _currentUserId = 'admin';

  String _currentResponse = """# Welcome to EdLab Intelligence! 🎓

I'm your AI assistant with **instant access** to all university data. Ask me anything about:

## 📊 **Available Data & Insights**
- **Students**: Attendance, grades, performance analytics
- **Staff**: Faculty information, department assignments  
- **Departments**: MCA, MBA statistics and details
- **Fees**: Payment records, collection summaries, structures
- **Exams**: University exam schedules and venues
- **Accounts**: Financial ledger and balance information

## 💡 **Try These Queries**
- *"Show me attendance summary by department"*
- *"What's the total fee collection this month?"*
- *"List all MCA students with low attendance"*
- *"Give me staff count by department"*
- *"Show upcoming exams this week"*

## 🚀 **Visualization Support**
I can suggest charts, graphs, and data visualizations based on your queries!

**Ready to explore your data? Ask me anything!**
""";
  bool _isLoading = false;
  String _lastPrompt = "";

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _promptController.text = widget.initialPrompt!;
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendMessage();
      });
    }
  }

  void _sendMessage() async {
    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    _lastPrompt = prompt;

    setState(() {
      _isLoading = true;
      _currentResponse = "🔍 Analyzing your request and gathering data...";
    });

    _promptController.clear();

    try {
      final response = await EdLabAIService().sendMessage(_currentUserId, prompt);
      if (mounted) {
        setState(() {
          _currentResponse = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentResponse = "**Error Processing Request**\\n\\nThere was an issue: $e\\n\\n**Try asking:**\\n- Show me student attendance summary\\n- What's the total fee collection this month?\\n- List all staff in MCA department";
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
                        child: const Row(
                          children: [
                            Icon(Icons.history, color: Color(0xFF6366F1)),
                            SizedBox(width: 12),
                            Text("Chat History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                                return ListTile(
                                  title: Text(data['prompt'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
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
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("EdLab Intelligence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  Text("Firebase AI • Real-time Data Access", style: TextStyle(fontSize: 12, color: Colors.grey)),
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
                                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        "Analyzing your request...",
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
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _promptController,
                                      onSubmitted: (_) => _sendMessage(),
                                      decoration: InputDecoration(
                                        hintText: "Ask anything about university data...",
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
}