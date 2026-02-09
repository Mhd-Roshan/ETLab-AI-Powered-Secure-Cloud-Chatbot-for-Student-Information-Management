import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'translation_service.dart';

class EnhancedAIService {
  late final GenerativeModel _model;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TranslationService _translationService = TranslationService();

  EnhancedAIService() {
    _initializeModel();
  }

  void _initializeModel() {
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
  }

  /// Enhanced send message with multilingual support
  Future<String> sendMessage(String userId, String userPrompt, {bool autoTranslate = true}) async {
    try {
      String originalPrompt = userPrompt;
      String processedPrompt = userPrompt;

      // Auto-detect language if enabled
      if (autoTranslate) {
        await _translationService.autoDetectAndSetLanguage(userPrompt);
        
        // Translate to English for AI processing if not already in English
        if (_translationService.currentLanguage != 'en') {
          processedPrompt = await _translationService.translateToEnglish(userPrompt);
          debugPrint('Translated prompt: $processedPrompt');
        }
      }

      // Get database context
      String dbContext = await _getComprehensiveContext(processedPrompt);

      // Create multilingual-aware prompt
      final prompt = [
        Content.text(_buildMultilingualPrompt(dbContext, processedPrompt, originalPrompt)),
      ];

      // Generate AI response
      final response = await _model.generateContent(prompt);
      String aiResponse = response.text ?? "AI returned empty response.";

      // Translate response back to user's language if needed
      if (autoTranslate && _translationService.currentLanguage != 'en') {
        aiResponse = await _translationService.translateFromEnglish(aiResponse);
        debugPrint('Translated response to ${_translationService.currentLanguage}');
      }

      // Save to chat history with language info
      await _saveChatHistory(userId, originalPrompt, aiResponse, _translationService.currentLanguage);

      return aiResponse;
    } catch (e) {
      debugPrint("❌ ENHANCED AI SERVICE ERROR: $e");
      return _getErrorMessage();
    }
  }

  /// Build multilingual-aware prompt
  String _buildMultilingualPrompt(String dbContext, String processedPrompt, String originalPrompt) {
    String currentLang = _translationService.currentLanguage;
    String langName = _translationService.currentLanguageName;
    
    return """You are EdLab AI, an intelligent multilingual assistant for EdLab University Management System.

CURRENT USER LANGUAGE: $langName ($currentLang)
${currentLang != 'en' ? 'ORIGINAL USER INPUT: $originalPrompt' : ''}

CONTEXT DATA:
$dbContext

USER QUESTION: $processedPrompt

MULTILINGUAL INSTRUCTIONS:
1. Provide accurate, helpful responses based on the real data above
2. Use markdown formatting for better readability
3. Include relevant statistics and insights
4. If asked about visualizations, describe what charts/graphs would be helpful
5. For data queries, provide specific numbers and percentages
6. Be conversational but professional and culturally appropriate
7. If data is missing, suggest what information would be needed
8. Always reference actual data from the context when available
9. Consider cultural context when providing responses
10. Use appropriate honorifics and formal language when suitable for the detected language culture

RESPONSE FORMATTING:
- Use clear, simple language that translates well
- Avoid idioms or culture-specific references that may not translate properly
- Structure responses with clear headings and bullet points
- Include relevant emojis that are universally understood

RESPONSE:""";
  }

  /// Get error message in current language
  String _getErrorMessage() {
    Map<String, String> errorMessages = {
      'en': """**Error Connecting to AI Service**

There was an issue processing your request.

**Possible Solutions:**
- Check your internet connection
- Verify Firebase AI configuration
- Try again in a moment

**Available Data:**
- Students: Query student information, attendance, grades
- Staff: Faculty and staff details
- Departments: MCA, MBA department information  
- Fees: Payment records and fee structures
- Exams: University exam schedules
- Accounts: Financial ledger data

Try asking: "Show me student attendance summary" or "What's the total fee collection?"
""",
      'hi': """**AI सेवा से कनेक्ट करने में त्रुटि**

आपके अनुरोध को संसाधित करने में समस्या थी।

**संभावित समाधान:**
- अपना इंटरनेट कनेक्शन जांचें
- Firebase AI कॉन्फ़िगरेशन सत्यापित करें
- एक क्षण में फिर से कोशिश करें

**उपलब्ध डेटा:**
- छात्र: छात्र जानकारी, उपस्थिति, ग्रेड
- स्टाफ: संकाय और स्टाफ विवरण
- विभाग: MCA, MBA विभाग की जानकारी
- फीस: भुगतान रिकॉर्ड और फीस संरचना
- परीक्षा: विश्वविद्यालय परीक्षा कार्यक्रम
- खाते: वित्तीय खाता डेटा

कोशिश करें: "छात्र उपस्थिति सारांश दिखाएं" या "इस महीने की कुल फीस संग्रह क्या है?"
""",
    };

    return errorMessages[_translationService.currentLanguage] ?? errorMessages['en']!;
  }

  /// Enhanced context retrieval (same as original but with better error handling)
  Future<String> _getComprehensiveContext(String prompt) async {
    StringBuffer context = StringBuffer();
    String p = prompt.toLowerCase();

    try {
      context.writeln("=== EDLAB UNIVERSITY DATA CONTEXT ===\n");

      // Students Data
      if (p.contains('student') || p.contains('attendance') || p.contains('marks') || p.contains('grade') || p.contains('performance')) {
        final studentsSnap = await _db.collection('students').limit(50).get();
        if (studentsSnap.docs.isNotEmpty) {
          context.writeln("STUDENTS DATA:");
          for (var doc in studentsSnap.docs) {
            var data = doc.data();
            context.writeln("- ${data['firstName']} ${data['lastName']} (${data['registrationNumber']}) - Dept: ${data['department']}, GPA: ${data['gpa']}, Attendance: ${data['attendancePercentage']}%");
          }
          context.writeln("");
        }
      }

      // Staff Data
      if (p.contains('staff') || p.contains('teacher') || p.contains('faculty') || p.contains('professor')) {
        final staffSnap = await _db.collection('staff').limit(30).get();
        if (staffSnap.docs.isNotEmpty) {
          context.writeln("STAFF DATA:");
          for (var doc in staffSnap.docs) {
            var data = doc.data();
            context.writeln("- ${data['firstName']} ${data['lastName']} - Dept: ${data['department']}, Position: ${data['position']}, Email: ${data['email']}");
          }
          context.writeln("");
        }
      }

      // Departments Data
      if (p.contains('department') || p.contains('dept') || p.contains('mca') || p.contains('mba')) {
        final deptSnap = await _db.collection('departments').get();
        if (deptSnap.docs.isNotEmpty) {
          context.writeln("DEPARTMENTS DATA:");
          for (var doc in deptSnap.docs) {
            var data = doc.data();
            context.writeln("- ${data['name']}: ${data['description']} (Head: ${data['head']})");
          }
          context.writeln("");
        }
      }

      // Fee Data
      if (p.contains('fee') || p.contains('payment') || p.contains('finance') || p.contains('money')) {
        final feeSnap = await _db.collection('fee_collections').limit(20).get();
        final structureSnap = await _db.collection('fee_structures').get();
        
        if (feeSnap.docs.isNotEmpty) {
          context.writeln("FEE COLLECTIONS:");
          double totalCollected = 0;
          for (var doc in feeSnap.docs) {
            var data = doc.data();
            double amount = (data['amount'] ?? 0).toDouble();
            totalCollected += amount;
            context.writeln("- ${data['studentName']} (${data['regNo']}): ₹$amount for ${data['type']}");
          }
          context.writeln("Total Collected: ₹$totalCollected\n");
        }

        if (structureSnap.docs.isNotEmpty) {
          context.writeln("FEE STRUCTURE:");
          for (var doc in structureSnap.docs) {
            var data = doc.data();
            context.writeln("- ${data['title']}: ₹${data['amount']}");
          }
          context.writeln("");
        }
      }

      // Exam Data
      if (p.contains('exam') || p.contains('test') || p.contains('university')) {
        final examSnap = await _db.collection('university_exams').limit(15).get();
        if (examSnap.docs.isNotEmpty) {
          context.writeln("UNIVERSITY EXAMS:");
          for (var doc in examSnap.docs) {
            var data = doc.data();
            var date = (data['date'] as Timestamp?)?.toDate();
            context.writeln("- ${data['subject']} (${data['code']}) - Dept: ${data['department']}, Date: ${date?.toString().split(' ')[0]}, Venue: ${data['venue']}");
          }
          context.writeln("");
        }
      }

      // Attendance Data
      if (p.contains('attendance') || p.contains('present') || p.contains('absent')) {
        final studentsSnap = await _db.collection('students').get();
        if (studentsSnap.docs.isNotEmpty) {
          context.writeln("ATTENDANCE SUMMARY:");
          double totalAttendance = 0;
          int count = 0;
          for (var doc in studentsSnap.docs) {
            var data = doc.data();
            double attendance = (data['attendancePercentage'] ?? 0).toDouble();
            totalAttendance += attendance;
            count++;
          }
          double avgAttendance = count > 0 ? totalAttendance / count : 0;
          context.writeln("Average Attendance: ${avgAttendance.toStringAsFixed(1)}%");
          context.writeln("Total Students: $count\n");
        }
      }

      // Accounts Data
      if (p.contains('account') || p.contains('ledger') || p.contains('balance')) {
        final accountsSnap = await _db.collection('accounts').get();
        if (accountsSnap.docs.isNotEmpty) {
          context.writeln("ACCOUNTS DATA:");
          for (var doc in accountsSnap.docs) {
            var data = doc.data();
            context.writeln("- ${data['name']}: ₹${data['balance']} (${data['type']})");
          }
          context.writeln("");
        }
      }

      return context.isEmpty ? "No relevant data found in database." : context.toString();
    } catch (e) {
      return "Context Error: $e";
    }
  }

  /// Enhanced chat history with language tracking
  Future<void> _saveChatHistory(String userId, String prompt, String response, String language) async {
    try {
      await _db.collection('chat_history').add({
        'userId': userId,
        'prompt': prompt,
        'response': response,
        'language': language,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Failed to save chat history: $e");
    }
  }

  /// Get chat history with language filter
  Future<QuerySnapshot> getChatHistory(String userId, {String? language}) async {
    Query query = _db
        .collection('chat_history')
        .where('userId', isEqualTo: userId);
    
    if (language != null) {
      query = query.where('language', isEqualTo: language);
    }
    
    return await query
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
  }

  /// Get language statistics for user
  Future<Map<String, int>> getLanguageStats(String userId) async {
    try {
      final snapshot = await _db
          .collection('chat_history')
          .where('userId', isEqualTo: userId)
          .get();
      
      Map<String, int> stats = {};
      for (var doc in snapshot.docs) {
        String lang = doc.data()['language'] ?? 'en';
        stats[lang] = (stats[lang] ?? 0) + 1;
      }
      
      return stats;
    } catch (e) {
      debugPrint("Error getting language stats: $e");
      return {};
    }
  }
}