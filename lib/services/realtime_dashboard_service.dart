import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class RealtimeDashboardService {
  static final RealtimeDashboardService _instance = RealtimeDashboardService._internal();
  factory RealtimeDashboardService() => _instance;
  RealtimeDashboardService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  
  // Stream controllers for real-time metrics
  final StreamController<Map<String, dynamic>> _metricsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _recentActivitiesController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  // Subscription management
  final List<StreamSubscription> _subscriptions = [];
  Timer? _metricsTimer;

  // Getters for streams
  Stream<Map<String, dynamic>> get metricsStream => _metricsController.stream;
  Stream<List<Map<String, dynamic>>> get recentActivitiesStream => _recentActivitiesController.stream;

  void initialize() {
    _startRealtimeMetrics();
    _startPeriodicUpdates();
  }

  /// Start monitoring collections for real-time metrics
  void _startRealtimeMetrics() {
    // Monitor all collections for count changes
    _subscriptions.add(
      _db.collection('students').snapshots().listen((snapshot) {
        _updateMetrics();
      })
    );

    _subscriptions.add(
      _db.collection('staff').snapshots().listen((snapshot) {
        _updateMetrics();
      })
    );

    _subscriptions.add(
      _db.collection('fee_collections').snapshots().listen((snapshot) {
        _updateMetrics();
        _updateRecentActivities();
      })
    );

    _subscriptions.add(
      _db.collection('attendance').snapshots().listen((snapshot) {
        _updateMetrics();
      })
    );
  }

  /// Start periodic updates every 10 seconds
  void _startPeriodicUpdates() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _updateMetrics();
      _updateRecentActivities();
    });
  }

  /// Update real-time metrics
  Future<void> _updateMetrics() async {
    try {
      // Get counts from all collections
      final studentsCount = await _getCollectionCount('students');
      final staffCount = await _getCollectionCount('staff');
      final coursesCount = await _getCollectionCount('courses');
      final departmentsCount = await _getCollectionCount('departments');

      // Get fee collection total
      final feeTotal = await _getTotalFeeCollection();

      // Get attendance rate
      final attendanceRate = await _getAttendanceRate();

      // Get recent enrollment trend
      final enrollmentTrend = await _getEnrollmentTrend();

      Map<String, dynamic> metrics = {
        'students': {
          'count': studentsCount,
          'trend': enrollmentTrend,
          'lastUpdated': DateTime.now(),
        },
        'staff': {
          'count': staffCount,
          'trend': 'stable',
          'lastUpdated': DateTime.now(),
        },
        'courses': {
          'count': coursesCount,
          'trend': 'stable',
          'lastUpdated': DateTime.now(),
        },
        'departments': {
          'count': departmentsCount,
          'trend': 'stable',
          'lastUpdated': DateTime.now(),
        },
        'fees': {
          'total': feeTotal,
          'trend': 'increasing',
          'lastUpdated': DateTime.now(),
        },
        'attendance': {
          'rate': attendanceRate,
          'trend': attendanceRate > 80 ? 'good' : 'needs_attention',
          'lastUpdated': DateTime.now(),
        },
        'timestamp': DateTime.now(),
      };

      _metricsController.add(metrics);
    } catch (e) {
      debugPrint('Error updating metrics: $e');
    }
  }

  /// Update recent activities
  Future<void> _updateRecentActivities() async {
    try {
      List<Map<String, dynamic>> activities = [];

      // Get recent fee payments
      final recentFees = await _db
          .collection('fee_collections')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      for (var doc in recentFees.docs) {
        final data = doc.data();
        activities.add({
          'type': 'fee_payment',
          'title': 'Fee Payment',
          'description': '${data['studentName']} paid ₹${data['amount']}',
          'timestamp': data['timestamp'],
          'icon': 'payment',
          'color': 'green',
        });
      }

      // Get recent student registrations (if timestamp field exists)
      try {
        final recentStudents = await _db
            .collection('students')
            .orderBy('createdAt', descending: true)
            .limit(3)
            .get();

        for (var doc in recentStudents.docs) {
          final data = doc.data();
          activities.add({
            'type': 'student_registration',
            'title': 'New Student',
            'description': '${data['firstName']} ${data['lastName']} enrolled',
            'timestamp': data['createdAt'] ?? Timestamp.now(),
            'icon': 'person_add',
            'color': 'blue',
          });
        }
      } catch (e) {
        // Handle case where createdAt field doesn't exist
        debugPrint('Students collection may not have createdAt field: $e');
      }

      // Sort activities by timestamp
      activities.sort((a, b) {
        final aTime = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final bTime = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      _recentActivitiesController.add(activities.take(8).toList());
    } catch (e) {
      debugPrint('Error updating recent activities: $e');
    }
  }

  /// Get collection count
  Future<int> _getCollectionCount(String collection) async {
    try {
      final snapshot = await _db.collection(collection).get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('Error getting count for $collection: $e');
      return 0;
    }
  }

  /// Get total fee collection
  Future<double> _getTotalFeeCollection() async {
    try {
      final snapshot = await _db.collection('fee_collections').get();
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0).toDouble();
      }
      return total;
    } catch (e) {
      debugPrint('Error getting fee total: $e');
      return 0;
    }
  }

  /// Get attendance rate
  Future<double> _getAttendanceRate() async {
    try {
      final studentsSnapshot = await _db.collection('students').get();
      if (studentsSnapshot.docs.isEmpty) return 0;

      double totalAttendance = 0;
      int count = 0;

      for (var doc in studentsSnapshot.docs) {
        final attendance = (doc.data()['attendancePercentage'] ?? 0).toDouble();
        totalAttendance += attendance;
        count++;
      }

      return count > 0 ? totalAttendance / count : 0;
    } catch (e) {
      debugPrint('Error getting attendance rate: $e');
      return 0;
    }
  }

  /// Get enrollment trend
  Future<String> _getEnrollmentTrend() async {
    try {
      // This is a simplified trend calculation
      // In a real app, you'd compare with historical data
      final count = await _getCollectionCount('students');
      
      if (count > 100) return 'increasing';
      if (count > 50) return 'stable';
      return 'low';
    } catch (e) {
      debugPrint('Error getting enrollment trend: $e');
      return 'stable';
    }
  }

  /// Get current metrics snapshot
  Future<Map<String, dynamic>> getCurrentMetrics() async {
    await _updateMetrics();
    return {
      'students': await _getCollectionCount('students'),
      'staff': await _getCollectionCount('staff'),
      'courses': await _getCollectionCount('courses'),
      'fees': await _getTotalFeeCollection(),
      'attendance': await _getAttendanceRate(),
      'timestamp': DateTime.now(),
    };
  }

  /// Get specific collection stream
  Stream<int> getCollectionCountStream(String collection) {
    return _db.collection(collection).snapshots().map((snapshot) => snapshot.docs.length);
  }

  /// Get fee collection stream
  Stream<double> getFeeCollectionStream() {
    return _db.collection('fee_collections').snapshots().map((snapshot) {
      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] ?? 0).toDouble();
      }
      return total;
    });
  }

  /// Dispose resources
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    
    _metricsTimer?.cancel();
    
    _metricsController.close();
    _recentActivitiesController.close();
  }
}