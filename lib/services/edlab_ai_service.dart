import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

class EdLabAIService {
  // ✅ FREE ACCESS: Using your API Key
  final String apiKey = "AIzaSyA1xWbpOjsikqSlhIKD1J2TEYqFkGp8pEM";

  late final GenerativeModel _model;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  EdLabAIService() {
    // 🛠️ UPDATE: Using 'gemini-2.0-flash' because 1.5 is retired.
    // If this fails, try 'gemini-2.0-flash-exp'
    _model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
  }

  // --- 1. SMART CONTEXT RETRIEVAL ---
  Future<String> _getDynamicContext(String prompt) async {
    StringBuffer context = StringBuffer();
    prompt = prompt.toLowerCase();

    try {
      if (prompt.contains('staff') || prompt.contains('teacher')) {
        final snap = await _db.collection('staff').limit(20).get();
        context.writeln("STAFF: ${snap.docs.map((d) => d.data()).toList()}");
      }

      if (prompt.contains('student') ||
          prompt.contains('gpa') ||
          prompt.contains('marks')) {
        final snap = await _db.collection('students').limit(10).get();
        context.writeln("STUDENTS: ${snap.docs.map((d) => d.data()).toList()}");
      }

      if (prompt.contains('dept') || prompt.contains('department')) {
        final snap = await _db.collection('departments').get();
        context.writeln("DEPTS: ${snap.docs.map((d) => d.data()).toList()}");
      }

      if (prompt.contains('report') || prompt.contains('result')) {
        final snap = await _db.collection('reports').limit(10).get();
        context.writeln("REPORTS: ${snap.docs.map((d) => d.data()).toList()}");
      }

      if (context.isEmpty) {
        context.writeln(
          "Note: No specific DB records found. Answer generally.",
        );
      }
      return context.toString();
    } catch (e) {
      return "DB Error: $e";
    }
  }

  // --- 2. GENERATE MESSAGE ---
  Future<String> sendMessage(String userId, String userPrompt) async {
    try {
      String dbContext = await _getDynamicContext(userPrompt);

      final fullPrompt =
          '''
      Context: $dbContext
      User: $userPrompt
      Answer as EdLab Admin AI (keep it short):
      ''';

      final content = [Content.text(fullPrompt)];
      final response = await _model.generateContent(content);

      final textResponse = response.text ?? "No response.";

      // Save to History
      await _db.collection('ai_history').add({
        'userId': userId,
        'prompt': userPrompt,
        'response': textResponse,
        'timestamp': FieldValue.serverTimestamp(),
        'id': const Uuid().v4(),
      });

      return textResponse;
    } catch (e) {
      debugPrint("❌ AI ERROR: $e");
      // ⚠️ Fallback message if model name is still wrong
      if (e.toString().contains('404')) {
        return "Error: Model not found. Try changing 'gemini-2.0-flash' to 'gemini-2.0-flash-exp' in edlab_ai_service.dart";
      }
      return "System Error: ${e.toString()}";
    }
  }

  Stream<QuerySnapshot> getChatHistory(String userId) {
    return _db
        .collection('ai_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
