import 'package:flutter/material.dart';
import 'package:edlab/hod/screens/generic_page.dart';

class AlertsScreen extends StatelessWidget {
  final String userId;
  const AlertsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return GenericPage(title: "Alerts Screen");
  }
}
