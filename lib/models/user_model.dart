class User {
  final String id;
  final String username;
  final String email;
  final String collegeCode;
  final String collegeName;
  final String role; // admin, hod, staff_advisor, staff, student
  final String firstName;
  final String lastName;
  final String? phone;
  final String? department;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.collegeCode,
    required this.collegeName,
    required this.role,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.department,
    required this.isActive,
    required this.createdAt,
    this.lastLogin,
  });

  // Get full name
  String get fullName => '$firstName $lastName';

  // Determine role from username prefix
  static String determineRoleFromUsername(String username) {
    if (username.isEmpty) return 'staff';
    String first = username.substring(0, 1).toUpperCase();
    if (first == 'A') return 'admin';
    if (first == 'H') return 'hod';
    
    if (username.length >= 2) {
      String firstTwo = username.substring(0, 2).toUpperCase();
      if (firstTwo == 'SA') return 'staff_advisor';
    }
    
    if (first == 'S') return 'staff';
    return 'staff'; // Default
  }

  // Convert User to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'collegeCode': collegeCode,
      'collegeName': collegeName,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'department': department,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
    };
  }

  // Create User from JSON (from Firestore)
  factory User.fromJson(Map<String, dynamic> json) {
    // Helper function to parse dates from Firestore (handles both Timestamp and String)
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.parse(value);
      // Handle Firestore Timestamp objects (they have toDate() method)
      if (value.runtimeType.toString().contains('Timestamp')) {
        try {
          return value.toDate() as DateTime;
        } catch (e) {
          return DateTime.now();
        }
      }
      return null;
    }

    return User(
      id: json['id'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      collegeCode: json['collegeCode'] as String? ?? '',
      collegeName: json['collegeName'] as String? ?? '',
      role: json['role'] as String? ?? 'staff',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      phone: json['phone'] as String?,
      department: json['department'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      lastLogin: parseDate(json['lastLogin']),
    );
  }

  // Copy with method for updates
  User copyWith({
    String? id,
    String? username,
    String? email,
    String? collegeCode,
    String? collegeName,
    String? role,
    String? firstName,
    String? lastName,
    String? phone,
    String? department,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastLogin,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      collegeCode: collegeCode ?? this.collegeCode,
      collegeName: collegeName ?? this.collegeName,
      role: role ?? this.role,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }

  @override
  String toString() => 'User(username: $username, role: $role, college: $collegeName)';
}
