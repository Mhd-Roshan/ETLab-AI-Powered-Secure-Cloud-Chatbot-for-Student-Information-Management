import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';
import 'student_service.dart';

class EdLabAIService {
  // ✅ FREE ACCESS: Using your API Key
  final String apiKey = "AIzaSyA1xWbpOjsikqSlhIKD1J2TEYqFkGp8pE";

  late final GenerativeModel _model;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final StudentService _studentService = StudentService();

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
      if (p.contains('student') ||
          p.contains('attendance') ||
          p.contains('marks') ||
          p.contains('grade') ||
          p.contains('performance')) {
        final studentsSnap = await _db.collection('students').limit(50).get();
        if (studentsSnap.docs.isNotEmpty) {
          context.writeln("STUDENTS DATA:");
          for (var doc in studentsSnap.docs) {
            var data = doc.data();
            context.writeln(
              "- ${data['firstName']} ${data['lastName']} (${data['registrationNumber']}) - Dept: ${data['department']}, GPA: ${data['gpa']}, Attendance: ${data['attendancePercentage']}%",
            );
          }
          context.writeln("");
        }
      }

      // Staff Data
      if (p.contains('staff') ||
          p.contains('teacher') ||
          p.contains('faculty') ||
          p.contains('professor')) {
        final staffSnap = await _db.collection('staff').limit(30).get();
        if (staffSnap.docs.isNotEmpty) {
          context.writeln("STAFF DATA:");
          for (var doc in staffSnap.docs) {
            var data = doc.data();
            context.writeln(
              "- ${data['firstName']} ${data['lastName']} - Dept: ${data['department']}, Position: ${data['position']}, Email: ${data['email']}",
            );
          }
          context.writeln("");
        }
      }

      // Departments Data
      if (p.contains('department') ||
          p.contains('dept') ||
          p.contains('mca') ||
          p.contains('mba')) {
        final deptSnap = await _db.collection('departments').get();
        if (deptSnap.docs.isNotEmpty) {
          context.writeln("DEPARTMENTS DATA:");
          for (var doc in deptSnap.docs) {
            var data = doc.data();
            context.writeln(
              "- ${data['name']}: ${data['description']} (Head: ${data['head']})",
            );
          }
          context.writeln("");
        }
      }

      // Fee Data
      if (p.contains('fee') ||
          p.contains('payment') ||
          p.contains('finance') ||
          p.contains('money')) {
        final feeSnap = await _db.collection('fee_collections').limit(20).get();
        final structureSnap = await _db.collection('fee_structures').get();

        if (feeSnap.docs.isNotEmpty) {
          context.writeln("FEE COLLECTIONS:");
          double totalCollected = 0;
          for (var doc in feeSnap.docs) {
            var data = doc.data();
            double amount = (data['amount'] ?? 0).toDouble();
            totalCollected += amount;
            context.writeln(
              "- ${data['studentName']} (${data['regNo']}): ₹$amount for ${data['type']}",
            );
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
      if (p.contains('exam') ||
          p.contains('test') ||
          p.contains('university')) {
        final examSnap = await _db
            .collection('university_exams')
            .limit(15)
            .get();
        if (examSnap.docs.isNotEmpty) {
          context.writeln("UNIVERSITY EXAMS:");
          for (var doc in examSnap.docs) {
            var data = doc.data();
            var date = (data['date'] as Timestamp?)?.toDate();
            context.writeln(
              "- ${data['subject']} (${data['code']}) - Dept: ${data['department']}, Date: ${date?.toString().split(' ')[0]}, Venue: ${data['venue']}",
            );
          }
          context.writeln("");
        }
      }

      // Attendance Data
      if (p.contains('attendance') ||
          p.contains('present') ||
          p.contains('absent')) {
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
          context.writeln(
            "Average Attendance: ${avgAttendance.toStringAsFixed(1)}%",
          );
          context.writeln("Total Students: $count\n");
        }
      }

      // Accounts Data
      if (p.contains('account') ||
          p.contains('ledger') ||
          p.contains('balance')) {
        final accountsSnap = await _db.collection('accounts').get();
        if (accountsSnap.docs.isNotEmpty) {
          context.writeln("ACCOUNTS DATA:");
          for (var doc in accountsSnap.docs) {
            var data = doc.data();
            context.writeln(
              "- ${data['name']}: ₹${data['balance']} (${data['type']})",
            );
          }
          context.writeln("");
        }
      }

      return context.isEmpty
          ? "No relevant data found in database."
          : context.toString();
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
          """You are EdLab AI, an intelligent assistant for KMCT School of Business's EdLab University Management System.

COLLEGE INFORMATION:
- College Name: KMCT School of Business (Part of KMCT College of Engineering)
- University: APJ Abdul Kalam Technological University (KTU)
- Affiliation: KTU Affiliated
- Location: Kerala, India
- Programs: MCA (Master of Computer Applications), MBA (Master of Business Administration)
- Duration: 2 Years (4 Semesters) for both programs
- Accreditation: AICTE approved

MCA PROGRAM (Master of Computer Applications):
Duration: 2 Years, 4 Semesters, 90+ Credits

SEMESTER 1 (25 Credits):
- Mathematical Foundations for Computing (4 credits)
- Advanced Data Structures (4 credits)
- Computer Organization and Architecture (3 credits)
- Object-Oriented Programming using Java (4 credits)
- Database Management Systems (4 credits)
- Labs: Data Structures Lab, Java Lab, DBMS Lab (2 credits each)

SEMESTER 2 (25 Credits):
- Design and Analysis of Algorithms (4 credits)
- Operating Systems (4 credits)
- Software Engineering (3 credits)
- Web Technologies (4 credits)
- Computer Networks (4 credits)
- Labs: Algorithm Lab, Web Tech Lab, Network Lab (2 credits each)

SEMESTER 3 (27 Credits):
- Machine Learning (4 credits)
- Cloud Computing (3 credits)
- Mobile Application Development (4 credits)
- Big Data Analytics (3 credits)
- Electives: Cyber Security, Blockchain, IoT, AI, NLP, Computer Vision (3 credits each)
- Labs: ML Lab, Mobile App Lab (2 credits each)
- Mini Project (3 credits)

SEMESTER 4 (23 Credits):
- Distributed Systems (3 credits)
- Information Security (3 credits)
- Elective (3 credits)
- Major Project (12 credits)
- Seminar (2 credits)

MBA PROGRAM (Master of Business Administration):
Duration: 2 Years, 4 Semesters, 90+ Credits
Specializations: Marketing, Finance, HR, Operations, IT Management

SEMESTER 1 (25 Credits):
- Principles of Management (4 credits)
- Managerial Economics (4 credits)
- Accounting for Managers (4 credits)
- Organizational Behavior (3 credits)
- Business Statistics (4 credits)
- Marketing Management (4 credits)
- Business Communication (2 credits)

SEMESTER 2 (24 Credits):
- Financial Management (4 credits)
- Human Resource Management (4 credits)
- Operations Management (4 credits)
- Research Methodology (3 credits)
- Management Information Systems (3 credits)
- Business Environment and Ethics (3 credits)
- Quantitative Techniques (3 credits)

SEMESTER 3 (26 Credits):
- Strategic Management (4 credits)
- Entrepreneurship Development (3 credits)
- Specialization Subjects (4 subjects x 3 credits = 12 credits)
  * Marketing: Consumer Behavior, Digital Marketing, Sales Management, Brand Management
  * Finance: Investment Analysis, Corporate Finance, Financial Markets, International Finance
  * HR: Talent Management, Training & Development, Compensation, Industrial Relations
  * Operations: Supply Chain, TQM, Project Management, Lean Operations
- Elective (3 credits)
- Summer Internship Report (4 credits)

SEMESTER 4 (24 Credits):
- Business Policy and Strategic Analysis (3 credits)
- Specialization Electives (3 subjects x 3 credits = 9 credits)
- Major Project/Dissertation (10 credits)
- Comprehensive Viva Voce (2 credits)

CO-CURRICULAR ACTIVITIES:
- Industry Visits, Guest Lectures, Workshops
- Hackathons (MCA), Business Competitions (MBA)
- Tech Club, Marketing Club, Finance Club, HR Club, Entrepreneurship Cell
- Certifications: AWS, Google Cloud, Java, Azure (MCA); Google Analytics, Six Sigma, PMP (MBA)
- Soft Skills: Communication, Leadership, Personality Development
- Placement Training: Resume building, Mock interviews, Aptitude training

KTU EVALUATION SYSTEM:
- Continuous Internal Evaluation (CIE): 50 marks (Assignments 10, Tests 30, Attendance 5, Seminar 5)
- Semester End Examination (SEE): 50 marks (3-hour exam)
- Grading: 10-point CGPA (S=10, A+=9, A=8.5, B+=8, B=7, C=6, P=5, F=0)
- Minimum Attendance: 75% required for appearing in exams
- Pass Marks: 50% overall (minimum 40% in SEE)

PLACEMENT OPPORTUNITIES:
MCA: Software Developer, Data Scientist, Cloud Engineer, ML Engineer, Full Stack Developer
Top Recruiters: TCS, Infosys, Wipro, Amazon, Microsoft, Google, Flipkart
Average Package: ₹4-6 LPA, Highest: ₹12-15 LPA

MBA: Marketing Manager, Financial Analyst, HR Manager, Operations Manager, Business Analyst
Top Recruiters: HDFC, ICICI, Deloitte, EY, Amazon, Flipkart, ITC, HUL
Average Package: ₹5-7 LPA, Highest: ₹15-18 LPA

CONTEXT DATA:
$dbContext

USER QUESTION: $userPrompt

INSTRUCTIONS:
1. When asked about MCA or MBA, provide detailed semester-wise subject information
2. When asked about syllabus, refer to the complete KTU curriculum listed above
3. When asked about activities, mention co-curricular activities, clubs, and certifications
4. When asked about placements, provide job roles, companies, and package details
5. When asked about college, mention KMCT School of Business affiliated to KTU
6. Provide accurate, helpful responses based on the real data above
7. Use markdown formatting for better readability
8. Include relevant statistics and insights
9. Be conversational but professional
10. Always reference actual data from the context when available
11. For academic queries, reference KTU regulations and KMCT policies

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

**About KMCT School of Business:**
- Affiliated to APJ Abdul Kalam Technological University (KTU)
- Offers MCA (Master of Computer Applications) and MBA (Master of Business Administration)
- 2-year programs with 4 semesters each
- Follows KTU syllabus and curriculum
- Minimum 75% attendance required for KTU exams

**MCA Program**: Advanced Data Structures, Java, DBMS, Machine Learning, Cloud Computing, Mobile Development, Big Data
**MBA Specializations**: Marketing, Finance, HR, Operations, IT Management

**Available Data:**
- Students: Query student information, attendance, grades
- Staff: Faculty and staff details
- Departments: MCA, MBA
- Fees: Payment records and fee structures
- Exams: KTU university exam schedules
- Accounts: Financial ledger data

Try asking: 
- "What subjects are in MCA Semester 1?"
- "Tell me about MBA specializations"
- "What is the KTU syllabus for MCA?"
- "What activities are available for MBA students?"
- "Show me student attendance summary"
- "What are the placement opportunities?"
""";
    }
  }

  // --- STUDENT SPECIFIC CHAT ---
  Future<String> sendStudentMessage(
    String userId,
    String userPrompt,
    Map<String, dynamic> studentProfile,
  ) async {
    try {
      // 1. Get General Context
      String dbContext = await _getComprehensiveContext(userPrompt);

      // 2. Fetch Detailed Student Data
      // 2. Fetch Detailed Student Data
      String regNo = (studentProfile['registrationNumber'] ?? '').toString();
      String dept = (studentProfile['department'] ?? 'MCA').toString();

      // Handle semester conversion (e.g. 1 -> "Semester 1")
      dynamic rawSem = studentProfile['semester'];
      String sem = rawSem?.toString() ?? 'Semester 1';
      if (!sem.toLowerCase().startsWith('semester') &&
          int.tryParse(sem) != null) {
        sem = 'Semester $sem';
      }

      // Get Results
      String resultsSummary = "No results available.";
      try {
        final results = await _studentService.getResults(regNo);
        if (results.isNotEmpty) {
          final buffer = StringBuffer();
          results.forEach((examName, subjects) {
            buffer.writeln("$examName:");
            for (var subj in subjects) {
              buffer.writeln(
                "  - ${subj['subject']} (${subj['code']}): Grade ${subj['grade']} (${subj['marks']}/${subj['maxMarks']})",
              );
            }
            buffer.writeln("");
          });
          resultsSummary = buffer.toString();
        }
      } catch (e) {
        resultsSummary = "Error loading results: $e";
      }

      // Get Assignments
      String assignmentsSummary = "No pending assignments.";
      try {
        final assignments = await _studentService.getAssignments(regNo);
        if (assignments.isNotEmpty) {
          final buffer = StringBuffer();
          final now = DateTime.now();
          for (var asm in assignments) {
            final status = asm['status'].toString().toUpperCase();
            dynamic rawDueDate = asm['dueDate'];
            DateTime dueDate;
            if (rawDueDate is Timestamp) {
              dueDate = rawDueDate.toDate();
            } else if (rawDueDate is DateTime) {
              dueDate = rawDueDate;
            } else {
              dueDate = DateTime.now();
            }
            final isOverdue = status == 'PENDING' && now.isAfter(dueDate);
            final dueStr = "${dueDate.day}/${dueDate.month}/${dueDate.year}";

            buffer.writeln("- ${asm['subject']}: ${asm['description']}");
            buffer.writeln(
              "  Status: $status ${isOverdue ? '(OVERDUE!)' : ''} | Due: $dueStr",
            );
          }
          assignmentsSummary = buffer.toString();
        }
      } catch (e) {
        assignmentsSummary = "Error loading assignments: $e";
      }

      // Get Attendance Details
      String attendanceSummary = "Attendance data unavailable.";
      try {
        final attList = await _studentService.getDetailedAttendance(regNo);
        if (attList.isNotEmpty) {
          StringBuffer sb = StringBuffer();
          double totalPresent = 0;
          double totalClasses = 0;
          for (var att in attList) {
            double p = (att['present'] ?? 0).toDouble();
            double t = (att['total'] ?? 0).toDouble();
            totalPresent += p;
            totalClasses += t;
            double perc = t > 0 ? (p / t) * 100 : 0;
            sb.writeln(
              "- ${att['subjectName']}: ${p.toInt()}/${t.toInt()} (${perc.toStringAsFixed(1)}%)",
            );
          }
          double overall = totalClasses > 0
              ? (totalPresent / totalClasses) * 100
              : 0;
          sb.writeln("\nOVERALL ATTENDANCE: ${overall.toStringAsFixed(1)}%");
          attendanceSummary = sb.toString();
        }
      } catch (e) {
        attendanceSummary = "Error fetching attendance: $e";
      }

      // Get Study Materials
      String materialsSummary = "No study materials found.";
      try {
        final matList = await _studentService.fetchMaterials(dept, sem);
        if (matList.isNotEmpty) {
          materialsSummary = matList
              .map((m) => "- ${m['subject']}: ${m['title']} (${m['type']})")
              .join('\n');
        }
      } catch (e) {
        materialsSummary = "Error fetching materials: $e";
      }

      // 3. Build Student Specific Context
      String studentContext =
          """
STUDENT PROFILE:
- Name: ${studentProfile['firstName']} ${studentProfile['lastName']}
- Reg No: ${studentProfile['registrationNumber']}
- Department: ${studentProfile['department']}
- Semester: ${studentProfile['semester']}
- Batch: ${studentProfile['batch']}
- Attendance: ${studentProfile['attendance'] ?? 'N/A'}%
- Email: ${studentProfile['email']}

ACADEMIC DETAILED DATA:
--- ATTENDANCE REPORT ---
$attendanceSummary

--- RECENT RESULTS ---
$resultsSummary

--- ASSIGNMENTS & TASKS ---
$assignmentsSummary

--- AVAILABLE STUDY MATERIALS ---
$materialsSummary
""";

      // 3. Create System Prompt
      final prompt = [
        Content.text(
          """You are EdLab, an intelligent and helpful student assistant for ${studentProfile['firstName']}.
You are distinct from the specific Admin AI; your focus is entirely on the student's success, well-being, and academic progress.

YOUR CONTEXT (Student Specific):
$studentContext

GENERAL COLLEGE CONTEXT:
$dbContext

COLLEGE INFORMATION:
- College Name: KMCT School of Business (Part of KMCT College of Engineering)
- University: APJ Abdul Kalam Technological University (KTU)
- Affiliation: KTU Affiliated
- Location: Kerala, India
- Programs: MCA, MBA
- Duration: 2 Years (4 Semesters)

MCA PROGRAM DETAILS (Master of Computer Applications):
- Sem 1: Maths, Data Structures, Architecture, Java, DBMS
- Sem 2: Algorithms, OS, Software Engg, Web Tech, Networks
- Sem 3: ML, Cloud, Mobile Dev, Big Data, Electives (Cyber Security, AI, etc.)
- Sem 4: Distributed Systems, Info Security, Major Project

MBA PROGRAM DETAILS (Master of Business Administration):
- Sem 1: Management, Economics, Accounting, Org Behavior, Stats, Marketing
- Sem 2: Financial Mgmt, HR, Operations, Research, MIS
- Sem 3: Strategy, Entrepreneurship, Specializations (Marketing, Finance, HR, Operations)
- Sem 4: Strategic Analysis, Major Project

INSTRUCTIONS:
1. ADDRESS the student by name (${studentProfile['firstName']}) occasionally to be personal.
2. ANSWER questions about their marks, assignments, materials, timetable, attendance, and staff based on the context provided.
3. If specific data (like exact marks for a recent exam) is not in the context, EXPLAIN that you are using the latest available data or ask them to check the specific section in the app, but assume the provided context is the truth.
4. BE ENCOURAGING and supportive.
5. REFER to yourself as "EdLab".
6. DO NOT act as an admin; you are a student companion.

USER QUESTION: $userPrompt

RESPONSE:""",
        ),
      ];

      // Generate content
      final response = await _model.generateContent(prompt);
      final text = response.text ?? "I'm having trouble thinking right now.";

      // Save to chat history
      await _saveChatHistory(userId, userPrompt, text);

      return text;
    } catch (e) {
      debugPrint("❌ STUDENT AI ERROR: $e");
      return "I'm having trouble connecting to my brain right now. Please try again later. (Error: $e)";
    }
  }

  // --- CHAT HISTORY MANAGEMENT ---
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
        'averageAttendance': studentCount > 0
            ? totalAttendance / studentCount
            : 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // --- PERSONALIZED STUDENT INSIGHTS (BATCH) ---
  Future<List<Map<String, String>>> getStudentInsights(
    Map<String, dynamic> studentData,
    Map<String, dynamic> academicData,
  ) async {
    try {
      final prompt = [
        Content.text("""You are an educational AI advisor.
Student: ${studentData['firstName']} (${studentData['department']})
Attendance: ${studentData['attendance']}%
Academic: $academicData

Task: Generate 5 distinct, short, actionable insights.
Mix of:
- Motivation
- Study tips
- Health tips
- Attendance warnings (if < 75%)
- Career advice

Format:
Title|Message
Title|Message
...

No markdown. One insight per line."""),
      ];

      final response = await _model.generateContent(prompt);
      final text = response.text?.trim() ?? "";

      List<Map<String, String>> insights = [];
      final lines = text.split('\n');

      for (var line in lines) {
        if (line.contains('|')) {
          final parts = line.split('|');
          if (parts.length >= 2) {
            insights.add({
              'title': parts[0].trim(),
              'message': parts[1].trim(),
            });
          }
        }
      }

      if (insights.isEmpty) {
        insights.add({
          'title': 'Welcome',
          'message': 'Have a great day of learning!',
        });
        insights.add({
          'title': 'Focus',
          'message': 'Stay consistent with your studies.',
        });
      }

      return insights;
    } catch (e) {
      debugPrint("Insight Generation Error: $e");
      return [
        {'title': 'Welcome Back', 'message': 'Check your schedule for today.'},
        {'title': 'Study Tip', 'message': 'Review your notes after class.'},
      ];
    }
  }
}
