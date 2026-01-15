# Firebase Firestore Auto-Initialization Guide

This script automatically creates all required Firebase collections with dummy data.

## Collections Created

1. **users** - User accounts (admin, hod, staff, staff_advisor)
2. **colleges** - College information
3. **departments** - Department details
4. **students** - Student records
5. **staff** - Staff/faculty information
6. **courses** - Course details
7. **classes** - Class sections
8. **announcements** - System announcements
9. **attendance** - Attendance records
10. **reports** - Student grades/reports

---

## Setup Instructions

### Step 1: Install Node.js & Firebase Admin SDK

```bash
# Install Node.js from https://nodejs.org/ (if not already installed)

# Navigate to the scripts folder
cd scripts

# Initialize npm (if not done)
npm init -y

# Install Firebase Admin SDK
npm install firebase-admin
```

### Step 2: Download Service Account Key

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Click ⚙️ **Project Settings** (top left)
4. Go to **Service Accounts** tab
5. Click **Generate New Private Key**
6. Save the JSON file as `serviceAccountKey.json` in the `scripts/` folder

### Step 3: Run the Initialization Script

```bash
# From the scripts folder
node firebase_init.js
```

You should see output like:
```
🚀 Starting Firebase Firestore initialization...

📝 Creating users collection...
  ✓ Created 4 test users
📝 Creating colleges collection...
  ✓ Created 4 colleges
📝 Creating departments collection...
  ✓ Created 4 departments
📝 Creating students collection...
  ✓ Created 3 students
📝 Creating staff collection...
  ✓ Created 3 staff members
📝 Creating courses collection...
  ✓ Created 4 courses
📝 Creating classes collection...
  ✓ Created 3 classes
📝 Creating announcements collection...
  ✓ Created 3 announcements
📝 Creating attendance collection...
  ✓ Created 2 attendance records
📝 Creating reports collection...
  ✓ Created 2 reports

✅ Firebase initialization completed successfully!
```

### Step 4: Verify in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Go to **Firestore Database**
4. You should see all 10 collections with dummy data

---

## Test Data Included

### User Accounts

| Role | Username | Password | College |
|------|----------|----------|---------|
| Admin | admin123 | admin@123 | TVE |
| HOD | hod456 | hod@456 | KMCT |
| Staff | staff789 | staff@789 | TCR |
| Staff Advisor | advisor101 | advisor@101 | RIT |

### Sample Data

- **4 Colleges** (TVE, KMCT, TCR, RIT)
- **4 Departments** (CSE, ECE, ME, CE)
- **3 Students** with enrollment details
- **3 Staff Members** with credentials
- **4 Courses** with course information
- **3 Classes** with section details
- **3 Announcements** with dates
- **2 Attendance Records** with marking details
- **2 Student Reports** with grades

---

## Important Notes

⚠️ **Security:**
- This script is for **development/testing only**
- Never commit `serviceAccountKey.json` to Git
- Add to `.gitignore`:
  ```
  scripts/serviceAccountKey.json
  scripts/node_modules/
  scripts/package-lock.json
  ```

📝 **To Replace Data:**
1. Delete collections from Firebase Console
2. Run the script again

🔧 **To Modify Data:**
- Edit the arrays in `firebase_init.js` (e.g., `users`, `students`, `courses`)
- Run the script again

📱 **To Add More Data:**
- Add new users/students/staff to the respective arrays
- The script will create new documents for each entry

---

## Directory Structure

```
edlab/
├── scripts/
│   ├── firebase_init.js          ← Main initialization script
│   ├── serviceAccountKey.json    ← Your Firebase credentials (keep private!)
│   ├── package.json              ← Node.js dependencies
│   └── node_modules/             ← Installed packages
├── lib/
├── assets/
└── pubspec.yaml
```

---

## Troubleshooting

### Error: "Cannot find module 'firebase-admin'"
```bash
npm install firebase-admin
```

### Error: "serviceAccountKey.json not found"
Make sure you downloaded the file and placed it in the `scripts/` folder

### Error: "Permission denied"
Make sure your Firebase Firestore security rules allow writes:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;  // For testing only!
    }
  }
}
```

### Script runs but no data appears
1. Check Firebase Console for errors
2. Verify service account has correct permissions
3. Check Firestore security rules

---

## After Running the Script

✅ Your Firestore database is ready with:
- Complete collection structure
- Test users for all roles
- Sample academic data
- Ready for real data insertion

You can now:
1. Run your Flutter app
2. Login with test credentials
3. Replace dummy data with real information as needed

Happy coding! 🚀
