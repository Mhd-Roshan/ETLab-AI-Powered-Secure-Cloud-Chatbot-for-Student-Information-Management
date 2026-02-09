import 'package:flutter/material.dart';
import 'package:edlab/services/chatbot_testing_service.dart';
import 'package:edlab/admin/widgets/admin_sidebar.dart';

class ChatbotTestScreen extends StatefulWidget {
  const ChatbotTestScreen({super.key});

  @override
  State<ChatbotTestScreen> createState() => _ChatbotTestScreenState();
}

class _ChatbotTestScreenState extends State<ChatbotTestScreen> {
  final ChatbotTestingService _testingService = ChatbotTestingService();
  
  bool _isRunningTests = false;
  Map<String, dynamic>? _testResults;
  String? _testReport;

  void _runComprehensiveTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = null;
      _testReport = null;
    });

    try {
      final results = await _testingService.runComprehensiveTests();
      final report = _testingService.generateTestReport(results);
      
      setState(() {
        _testResults = results;
        _testReport = report;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test execution failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  void _testSpecificLanguage(String languageCode) async {
    setState(() {
      _isRunningTests = true;
    });

    try {
      final results = await _testingService.testLanguageAccuracy(languageCode);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Language Test Results: ${results['languageName']}'),
          content: SizedBox(
            width: 400,
            height: 300,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Success Rate: ${results['successRate']}%'),
                  Text('Passed: ${results['passedTests']}'),
                  Text('Failed: ${results['failedTests']}'),
                  const SizedBox(height: 16),
                  const Text('Test Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...((results['results'] as List<Map<String, dynamic>>?) ?? []).map(
                    (result) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Icon(
                            result['passed'] ? Icons.check_circle : Icons.error,
                            color: result['passed'] ? Colors.green : Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              result['testCase']['input'],
                              style: const TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language test failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Widget _buildTestResultsCard() {
    if (_testResults == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assessment, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  'Test Results Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text('${_testResults!['successRate']}% Success'),
                  backgroundColor: double.parse(_testResults!['successRate']) >= 80
                      ? Colors.green.shade100
                      : Colors.orange.shade100,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatCard('Total Tests', '${_testResults!['totalTests']}', Icons.quiz),
                const SizedBox(width: 16),
                _buildStatCard('Passed', '${_testResults!['passedTests']}', Icons.check_circle, Colors.green),
                const SizedBox(width: 16),
                _buildStatCard('Failed', '${_testResults!['failedTests']}', Icons.error, Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Language Performance:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._buildLanguageStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, [Color? color]) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: (color ?? const Color(0xFF6366F1)).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? const Color(0xFF6366F1)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color ?? const Color(0xFF6366F1),
              ),
            ),
            Text(title, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLanguageStats() {
    final langStats = _testResults!['languageStats'] as Map<String, Map<String, int>>;
    return langStats.entries.map((entry) {
      final lang = entry.key;
      final stats = entry.value;
      final total = (stats['passed'] ?? 0) + (stats['failed'] ?? 0);
      final rate = total > 0 ? ((stats['passed'] ?? 0) / total * 100).toStringAsFixed(1) : '0.0';
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Text(lang.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Expanded(
              child: LinearProgressIndicator(
                value: double.parse(rate) / 100,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  double.parse(rate) >= 80 ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('$rate%', style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildTestReport() {
    if (_testReport == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Color(0xFF6366F1)),
                const SizedBox(width: 8),
                const Text(
                  'Detailed Test Report',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    // In a real app, this would save or share the report
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Report copied to clipboard')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Report'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _testReport!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                ),
              ),
            ),
          ],
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFEC4899)]),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.bug_report, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chatbot Testing Suite',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Voice & Multilingual Functionality Testing',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Test Controls
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Test Controls',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          
                          // Comprehensive Test Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _isRunningTests ? null : _runComprehensiveTests,
                              icon: _isRunningTests
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.play_arrow),
                              label: Text(_isRunningTests ? 'Running Tests...' : 'Run Comprehensive Tests'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Language-specific tests
                          const Text('Test Specific Languages:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildLanguageTestButton('English', 'en'),
                              _buildLanguageTestButton('Hindi', 'hi'),
                              _buildLanguageTestButton('Malayalam', 'ml'),
                              _buildLanguageTestButton('Tamil', 'ta'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Test Results
                  if (_testResults != null) _buildTestResultsCard(),
                  
                  // Test Report
                  if (_testReport != null) _buildTestReport(),
                  
                  // Test Information
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Testing Information',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          const Text('The comprehensive test suite validates:'),
                          const SizedBox(height: 8),
                          const Text('• Voice recognition accuracy across languages'),
                          const Text('• Translation quality and consistency'),
                          const Text('• AI response relevance and accuracy'),
                          const Text('• Service initialization and error handling'),
                          const Text('• Performance benchmarks and response times'),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tests run against live services and may take several minutes to complete.',
                                    style: TextStyle(color: Colors.blue),
                                  ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageTestButton(String name, String code) {
    return ElevatedButton(
      onPressed: _isRunningTests ? null : () => _testSpecificLanguage(code),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF6366F1),
        side: const BorderSide(color: Color(0xFF6366F1)),
      ),
      child: Text(name),
    );
  }
}