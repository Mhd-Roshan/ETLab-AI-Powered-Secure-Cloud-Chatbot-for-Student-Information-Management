import 'package:cloud_firestore/cloud_firestore.dart';

class ManualService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _manualCollection => _db.collection('system_manual');

  // Stream current manual content
  Stream<DocumentSnapshot> streamManualContent() {
    return _manualCollection.doc('content').snapshots();
  }

  // Seed initial data if it doesn't exist
  Future<void> seedInitialManualData() async {
    final doc = await _manualCollection.doc('content').get();
    if (doc.exists) return;

    await _manualCollection.doc('content').set({
      'overview': {
        'intro':
            "Welcome to EdLab. Our platform is a comprehensive ecosystem designed to streamline academic management through AI-powered tools and secure cloud infrastructure. This guide will help you navigate the system efficiently.",
        'modules': [
          {
            'code': "MOD 01",
            'title': "AI Assistant",
            'subtitle': "Smart administrative aid",
            'icon': "auto_awesome_rounded",
            'color': "0xFF7C3AED",
          },
          {
            'code': "MOD 02",
            'title': "Attendance",
            'subtitle': "Digital register tracking",
            'icon': "how_to_reg_rounded",
            'color': "0xFF001FF4",
          },
          {
            'code': "MOD 03",
            'title': "Evaluations",
            'subtitle': "Student grade management",
            'icon': "assignment_outlined",
            'color': "0xFF10B981",
          },
          {
            'code': "MOD 04",
            'title': "Surveys",
            'subtitle': "Real-time student feedback",
            'icon': "poll_outlined",
            'color': "0xFFF59E0B",
          },
        ],
      },
      'features': [
        {
          'title': "EdLab AI Assistant",
          'subtitle': "How to use the AI chatbot",
          'accentColor': "0xFF7C3AED",
          'cards': [
            {
              'title': "Drafting Plans",
              'subtitle': "Use natural language to generate lesson plans.",
              'desc':
                  "Simply ask: 'Create a lesson plan for MCA Calculus' to get a structured outline including objectives, topics, and references.",
            },
            {
              'title': "Performance Insights",
              'subtitle': "Analyze student metrics instantly.",
              'desc':
                  "The AI analyzes attendance and evaluation data to provide summaries and early warning alerts for students needing support.",
            },
          ],
        },
        {
          'title': "Attendance & Registers",
          'subtitle': "Tracking and reporting",
          'accentColor': "0xFF001FF4",
          'cards': [
            {
              'title': "Smart Marking",
              'subtitle': "Daily digital attendance logs.",
              'desc':
                  "Mark attendance by batch. The system tracks partial presence and automatically computes the cumulative percentage.",
            },
            {
              'title': "Threshold Guard",
              'subtitle': "Automatic 75% monitoring.",
              'desc':
                  "System triggers alerts when a student's attendance falls below the minimum requirement, enabling immediate intervention.",
            },
          ],
        },
      ],
      'faq': [
        {
          'question': "How do I update my profile?",
          'answer':
              "Navigate to the header and click the profile icon. You can modify your designation, contact details, and account security settings from there.",
        },
        {
          'question': "Are student surveys anonymous?",
          'answer':
              "Yes. While we verify student registration, staff only receive the aggregated distribution of 'Excellent', 'Good', and 'Bad' ratings.",
        },
        {
          'question': "Where can I export PDF reports?",
          'answer':
              "Navigate to the relevant module (e.g., Course Plan or Attendance) and look for the 'Show PDF' or 'Download' icon in the top right actions layer.",
        },
        {
          'question': "Can I recover deleted data?",
          'answer':
              "Standard deletions are permanent. Please contact the System Administrator for recovery from database backups if absolutely necessary.",
        },
      ],
      'support': {
        'options': [
          {
            'icon': "alternate_email_rounded",
            'title': "Email Support",
            'content': "support@edlab.edu",
            'buttonLabel': "Send Email",
            'color': "0xFF001FF4",
          },
          {
            'icon': "chat_bubble_outline_rounded",
            'title': "Admin Direct Chat",
            'content': "Available 9 AM - 5 PM",
            'buttonLabel': "Start Chat",
            'color': "0xFF7C3AED",
          },
        ],
        'version': "EdLab v2.4.0 (Secure Cloud Build)",
      },
    });
  }
}
