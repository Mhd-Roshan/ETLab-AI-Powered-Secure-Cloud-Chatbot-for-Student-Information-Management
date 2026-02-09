# Seed Students to Firebase - Instructions

## Overview
This script will add 10 sample students (5 MCA + 5 MBA) to your Firebase Firestore database.

## Students to be Added

### MCA Students (5)
1. **Arjun Krishna** - MCA2024001 - GPA: 8.5 - Attendance: 85%
2. **Priya Menon** - MCA2024002 - GPA: 9.2 - Attendance: 92%
3. **Rahul Sharma** - MCA2024003 - GPA: 7.8 - Attendance: 78%
4. **Sneha Nair** - MCA2024004 - GPA: 8.9 - Attendance: 88%
5. **Karthik Pillai** - MCA2024005 - GPA: 8.2 - Attendance: 82%

### MBA Students (5)
1. **Anjali Varma** - MBA2024001 - GPA: 8.7 - Attendance: 87% - Specialization: Marketing
2. **Vikram Reddy** - MBA2024002 - GPA: 9.0 - Attendance: 90% - Specialization: Finance
3. **Divya Iyer** - MBA2024003 - GPA: 8.4 - Attendance: 84% - Specialization: HR
4. **Aditya Kumar** - MBA2024004 - GPA: 7.9 - Attendance: 79% - Specialization: Operations
5. **Meera Shetty** - MBA2024005 - GPA: 8.6 - Attendance: 86% - Specialization: Marketing

## How to Run

### Method 1: Using Flutter Run (Recommended)

1. Open your terminal in the project root directory

2. Run the seeder script:
```bash
flutter run seed_students.dart
```

3. Wait for the script to complete. You should see output like:
```
🌱 Starting Student Seeder...
📚 Adding 10 students to Firestore...
✅ MCA2024001 - Arjun Krishna (MCA)
✅ MCA2024002 - Priya Menon (MCA)
...
🎉 Seeding Complete!
```

### Method 2: Using Dart Run

1. Make sure you have Dart SDK installed

2. Run:
```bash
dart run seed_students.dart
```

### Method 3: Create a Temporary Button in Admin Dashboard

If the above methods don't work, you can add a temporary button in the admin dashboard:

1. Open `lib/admin/admin_dashboard.dart`

2. Add this import at the top:
```dart
import '../seed_students.dart' as seeder;
```

3. Add a button in the UI:
```dart
ElevatedButton(
  onPressed: () async {
    await seeder.main();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Students seeded successfully!')),
    );
  },
  child: const Text('Seed Students'),
)
```

4. Run your app and click the button

5. Remove the button after seeding

## What Gets Created

### In `students` Collection:
- 10 student documents with all details
- Fields: firstName, lastName, registrationNumber, email, phone, department, batch, semester, gpa, status, attendancePercentage, etc.

### In `users` Collection:
- 10 user documents for login functionality
- Document ID: email with special characters replaced
- Fields: username, email, firstname, lastname, phone, department, semester, batch, gpa, role, etc.

## Verification

After running the seeder:

1. **Check Firebase Console**:
   - Go to Firebase Console → Firestore Database
   - Look for `students` collection → Should have 10 documents
   - Look for `users` collection → Should have 10 new documents

2. **Check Admin Dashboard**:
   - Login to admin dashboard
   - Go to Students screen
   - Select MCA department → Should see 5 students
   - Select MBA department → Should see 5 students

3. **Test Student Login**:
   - Try logging in with any student email (e.g., arjun.krishna@kmct.edu.in)
   - Password: You'll need to set this up in Firebase Authentication

## Important Notes

⚠️ **Duplicate Prevention**: The script checks if a student with the same registration number already exists. If found, it skips that student.

⚠️ **Run Once**: Only run this script once. Running multiple times will attempt to add duplicates (which will be skipped).

⚠️ **Firebase Connection**: Make sure your Firebase configuration is correct in `firebase_options.dart`

⚠️ **Authentication**: This script only creates Firestore documents. For student login, you'll need to:
- Create Firebase Authentication accounts separately, OR
- Use the registration numbers as usernames with a default password

## Troubleshooting

### Error: "Firebase not initialized"
- Make sure `firebase_options.dart` exists
- Run `flutterfire configure` to regenerate Firebase config

### Error: "Permission denied"
- Check Firestore security rules
- Make sure you have write permissions for `students` and `users` collections

### Students not showing in dashboard
- Verify the data in Firebase Console
- Check if the department filter is set correctly
- Make sure batch is "2024-2026"

## Clean Up

To remove all seeded students:

1. Go to Firebase Console → Firestore Database
2. Delete documents from `students` collection
3. Delete corresponding documents from `users` collection

Or create a cleanup script if needed.

## Next Steps

After seeding:
1. ✅ Verify students appear in admin dashboard
2. ✅ Test filtering by department (MCA/MBA)
3. ✅ Test filtering by batch (2024-2026)
4. ✅ Set up Firebase Authentication for student login
5. ✅ Test student dashboard with seeded data

---

**File**: `seed_students.dart`
**Collections**: `students`, `users`
**Total Students**: 10 (5 MCA + 5 MBA)
**Batch**: 2024-2026
**Status**: Ready to run
