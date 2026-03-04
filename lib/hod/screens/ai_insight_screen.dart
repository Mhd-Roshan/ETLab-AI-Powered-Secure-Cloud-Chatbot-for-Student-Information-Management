import 'package:flutter/material.dart';
import 'package:edlab/hod/screens/generic_page.dart';

class AiInsightScreen extends StatelessWidget {
  final String userId;
  const AiInsightScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GenericPage(title: "AI Insights Screen");
  }
}
