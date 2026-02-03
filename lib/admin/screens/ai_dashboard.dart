import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edlab/services/edlab_ai_service.dart';

class EdLabSmartDashboard extends StatefulWidget {
  final String currentUserId;
  // ✅ ADD THIS: Allow receiving a prompt from the previous screen
  final String? initialPrompt;

  const EdLabSmartDashboard({
    super.key,
    required this.currentUserId,
    this.initialPrompt, // <--- Add this
  });

  @override
  State<EdLabSmartDashboard> createState() => _EdLabSmartDashboardState();
}

class _EdLabSmartDashboardState extends State<EdLabSmartDashboard> {
  final TextEditingController _promptController = TextEditingController();
  final EdLabAIService _aiService = EdLabAIService();

  String _currentResponse =
      "Hello! Ask me about Staff, Students, or Departments.";
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // ✅ AUTO-START: If a prompt was passed, run it immediately
    if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
      _promptController.text = widget.initialPrompt!;
      // Wait a brief moment for the UI to build, then send
      Future.delayed(const Duration(milliseconds: 500), () {
        _sendMessage();
      });
    }
  }

  void _sendMessage() async {
    String prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _currentResponse = "Scanning database for '$prompt'...";
    });

    // Keep text in controller for reference, or clear it if you prefer
    // _promptController.clear();

    try {
      final response = await _aiService.sendMessage(
        widget.currentUserId,
        prompt,
      );
      if (mounted) {
        setState(() {
          _currentResponse = response;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentResponse = "Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _loadHistoryItem(String prompt, String response) {
    _promptController.text = prompt;
    setState(() => _currentResponse = response);
  }

  @override
  Widget build(BuildContext context) {
    // ... (KEEP THE REST OF YOUR BUILD METHOD EXACTLY THE SAME AS BEFORE)
    // Just ensure the _promptController is attached to your TextField
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("EdLab AI"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          // Sidebar (History)
          Container(
            width: 300,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.blueGrey[50],
                  width: double.infinity,
                  child: const Text(
                    "History",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<QuerySnapshot>(
                    future: _aiService.getChatHistory(widget.currentUserId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData)
                        return const Center(child: CircularProgressIndicator());
                      final docs = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;
                          return ListTile(
                            title: Text(
                              data['prompt'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: const Icon(Icons.history, size: 16),
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
          // Main Chat Area
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(40),
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : MarkdownBody(
                            data: _currentResponse,
                            selectable: true,
                          ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promptController,
                          onSubmitted: (_) => _sendMessage(),
                          decoration: const InputDecoration(
                            hintText: "Follow up question...",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendMessage,
                      ),
                    ],
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
