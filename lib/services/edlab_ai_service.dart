import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class EdLabAIService {
  // ✅ FREE ACCESS: Using your API Key
  final String apiKey = "AIzaSyA1xWbpOjsikqSlhIKD1J2TEYqFkGp8pE";

  late final GenerativeModel _model;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  EdLabAIService() {
    _initializeModel();
  }

  void _initializeModel() {
    // 🚀 Using Firebase AI - No API key needed!
    // Firebase AI manages authentication automatically
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
  }

  // --- FIREBASE REMOTE CONFIG SETUP (Future Enhancement) ---
  // Future<void> _setupRemoteConfig() async {
  //   final remoteConfig = FirebaseRemoteConfig.instance;
  //   await remoteConfig.setConfigSettings(RemoteConfigSettings(
  //     fetchTimeout: const Duration(minutes: 1),
  //     minimumFetchInterval: const Duration(hours: 1),
  //   ));
  //   await remoteConfig.fetchAndActivate();
  // }

  // --- COMPREHENSIVE CONTEXT RETRIEVAL ---
  Future<String> _getComprehensiveContext(String prompt) async {
    StringBuffer context = StringBuffer();
    String p = prompt.toLowerCase();

    try {
      // Always include basic stats for context
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

  // --- ENHANCED SEND MESSAGE WITH VISUALIZATION SUPPORT ---
  Future<String> sendMessage(String userId, String userPrompt) async {
    try {
      String dbContext = await _getComprehensiveContext(userPrompt);

      final prompt = [
        Content.text(
          """You are EdLab AI, an intelligent assistant for EdLab University Management System.

CONTEXT DATA:
$dbContext

USER QUESTION: $userPrompt

INSTRUCTIONS:
1. Provide accurate, helpful responses based on the real data above
2. Use markdown formatting for better readability
3. Include relevant statistics and insights
4. If asked about visualizations, describe what charts/graphs would be helpful
5. For data queries, provide specific numbers and percentages
6. Be conversational but professional
7. If data is missing, suggest what information would be needed
8. Always reference actual data from the context when available

RESPONSE:""",
        ),
      ];

      // Generate content using Firebase AI
      final response = await _model.generateContent(prompt);
      final text = response.text ?? "AI returned empty response.";

      // Save to chat history
      await _saveChatHistory(userId, userPrompt, text);

      return text;
    } catch (e) {
      debugPrint("❌ AI SERVICE ERROR: $e");
      return """**Error Connecting to AI Service**

There was an issue processing your request: ${e.toString()}

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
""";
    }
  }

  // --- CHAT HISTORY MANAGEMENT ---
  Future<void> _saveChatHistory(String userId, String prompt, String response) async {
    try {
      await _db.collection('chat_history').add({
        'userId': userId,
        'prompt': prompt,
        'response': response,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("Failed to save chat history: $e");
    }
  }

  Future<QuerySnapshot> getChatHistory(String userId) async {
    return await _db
        .collection('chat_history')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
  }

  // --- QUICK DATA INSIGHTS ---
  Future<Map<String, dynamic>> getQuickInsights() async {
    try {
      final studentsSnap = await _db.collection('students').get();
      final staffSnap = await _db.collection('staff').get();
      final feeSnap = await _db.collection('fee_collections').get();
      
      double totalFees = 0;
      double totalAttendance = 0;
      int studentCount = studentsSnap.docs.length;
      
      for (var doc in feeSnap.docs) {
        totalFees += (doc.data()['amount'] ?? 0).toDouble();
      }
      
      for (var doc in studentsSnap.docs) {
        totalAttendance += (doc.data()['attendancePercentage'] ?? 0).toDouble();
      }
      
      return {
        'totalStudents': studentCount,
        'totalStaff': staffSnap.docs.length,
        'totalFeesCollected': totalFees,
        'averageAttendance': studentCount > 0 ? totalAttendance / studentCount : 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
