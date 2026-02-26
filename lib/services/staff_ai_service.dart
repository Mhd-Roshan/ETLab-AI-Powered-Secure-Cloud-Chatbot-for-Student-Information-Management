import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';

class StaffAIService {
  late final GenerativeModel _model;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  StaffAIService() {
    _initializeModel();
  }

  void _initializeModel() {
    _model = FirebaseAI.googleAI().generativeModel(model: 'gemini-2.5-flash');
  }

  Future<String> _getStaffContext(String prompt) async {
    StringBuffer context = StringBuffer();
    try {
      context.writeln("=== STAFF-SPECIFIC DATA CONTEXT ===\n");

      // Focus on students, attendance, schedules, and academic tasks
      final studentsSnap = await _db.collection('students').limit(30).get();
      if (studentsSnap.docs.isNotEmpty) {
        context.writeln("YOUR STUDENTS PERFORMANCE:");
        for (var doc in studentsSnap.docs) {
          var data = doc.data();
          context.writeln(
            "- ${data['firstName']} ${data['lastName']} (${data['registrationNumber']}) - Attendance: ${data['attendancePercentage']}%, GPA: ${data['gpa']}",
          );
        }
        context.writeln("");
      }

      // University Exams for Staff
      final examSnap = await _db.collection('university_exams').limit(10).get();
      if (examSnap.docs.isNotEmpty) {
        context.writeln("UPCOMING UNIVERSITY EXAMS & VENUES:");
        for (var doc in examSnap.docs) {
          var data = doc.data();
          context.writeln(
            "- ${data['subject']} (${data['code']}) on ${data['date']} at ${data['venue']}",
          );
        }
        context.writeln("");
      }

      return context.toString();
    } catch (e) {
      return "Context Error: $e";
    }
  }

  Future<String> sendMessage(String userId, String userPrompt) async {
    try {
      String dbContext = await _getStaffContext(userPrompt);

      final prompt = [
        Content.text(
          """You are Staff Intel AI, a dedicated assistant specifically for the FACULTY and STAFF of KMCT School of Business.
          
          YOUR ROLE:
          - You assist professors, assistant professors, and lecturers in managing their academic duties.
          - Your focus is on student progress, attendance tracking, exam invigilation details, and class schedules.
          - You are NOT an admin assistant (leave financial/revenue/policy stuff to the Admin AI).
          - You are NOT a student companion.
          
          KMCT CONTEXT:
          - Programs: MCA & MBA (KTU Affiliated).
          - Focus on KTU regulations (75% mandatory attendance).
          
          DATA CONTEXT:
          $dbContext
          
          INSTRUCTIONS:
          1. Be professional, efficient, and respect the faculty's time.
          2. Help with syllabus queries, student performance analysis, and scheduling.
          3. If asked about salary or revenue, politely state that you are an Academic Faculty Assistant and they should contact the Administration for financial queries.
          4. Use markdown formatting.
          
          USER (Staff member) QUESTION: $userPrompt
          
          RESPONSE:""",
        ),
      ];

      final response = await _model.generateContent(prompt);
      final text = response.text ?? "Staff AI returned empty response.";

      // Save to chat history
      await _saveChatHistory(userId, userPrompt, text);

      return text;
    } catch (e) {
      return "Staff AI Error: $e";
    }
  }

  Future<void> _saveChatHistory(
    String userId,
    String prompt,
    String response,
  ) async {
    try {
      await _db.collection('chat_history').add({
        'userId': userId,
        'prompt': prompt,
        'response': response,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Failed to save staff chat history: $e");
    }
  }

  Future<QuerySnapshot> getChatHistory(String userId) async {
    return await _db
        .collection('chat_history')
        .where('userId', isEqualTo: 'staff_$userId')
        .orderBy('timestamp', descending: true)
        .limit(20)
        .get();
  }
}
