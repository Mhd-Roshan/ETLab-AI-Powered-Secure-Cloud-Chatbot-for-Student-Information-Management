# How to Login to EdLab Student App

## ✅ Fixed! Login screen now shows first

The student app now starts with the login screen instead of going directly to the dashboard.

---

## Step-by-Step Login Process

### 1. Run the App
```bash
flutter run -d chrome
```

Or use the run script:
```bash
.\run_app.ps1 5
```

### 2. You'll See the Login Screen
Beautiful retro-style login page with:
- College dropdown
- Username field
- Password field
- LOGIN button

### 3. Fill in Your Credentials

**Based on your Firebase data:**

| Field | Value |
|-------|-------|
| College | KMCT College of Engineering Kozhikode |
| Username | `Rosh@gmail.com` or `roshan@gmail.com` |
| Password | `Rosh@101` |

### 4. Click LOGIN

The system will:
1. Show loading indicator
2. Search Firebase for your user
3. Verify password
4. Check if account is active
5. Redirect to Student Dashboard

---

## What to Check in Console

After clicking LOGIN, check the browser console (F12) for debug output:

```
=== LOGIN DEBUG ===
Attempting login with username: rosh@gmail.com
Search by username: 0 results
Search by email: 0 results
Trying manual search...
Total users in collection: 5
User doc ID: student
Username: Rosh@gmail.com
Email: roshan@gmail.com
Found match in doc: student
Found user with role: student
Login successful!
```

This will tell you:
- If the user was found
- Which document matched
- What role was assigned
- If login succeeded

---

## Possible Usernames to Try

Based on your Firebase structure, try these:

1. `Rosh@gmail.com` (exact match from Firebase)
2. `rosh@gmail.com` (lowercase)
3. `roshan@gmail.com` (if that's the email)
4. Whatever is in the `username` field in Firebase

---

## If Login Still Fails

### Check Firebase Console

1. Go to Firebase Console
2. Open Firestore Database
3. Go to `users` collection
4. Find the `student` document
5. Check these fields:
   - `username`: Should match what you're typing
   - `email`: Alternative login option
   - `password`: Must match exactly (case-sensitive)
   - `role`: Should be "student"
   - `isActive`: Should be `true` (boolean)

### Common Issues

**"USER NOT FOUND"**
- Username doesn't match Firebase
- Check exact spelling and case
- Try using email instead

**"INCORRECT PASSWORD"**
- Password is case-sensitive
- Check for extra spaces
- Verify in Firebase: `Rosh@101`

**"ACCOUNT SUSPENDED"**
- `isActive` field is `false`
- Change it to `true` in Firebase

---

## Expected Behavior After Login

Once logged in successfully, you'll see:

✅ **Student Dashboard** with:
- Welcome message with your name "Roshan"
- Department: "Master Of Computer Application"
- College: "KMCT College of Engineering Kozhikode"
- Attendance percentage
- Today's schedule
- Quick action buttons
- Bottom navigation (Home, Academics, Chat, Profile)

✅ **Profile Page** (tap Profile icon):
- Your photo
- Name and email
- GPA, Attendance, Semester stats
- Academic details
- Contact information
- Edit Profile and Logout buttons

---

## Quick Test

1. **Run:** `flutter run -d chrome`
2. **Login with:**
   - College: KMCT College of Engineering Kozhikode
   - Username: `Rosh@gmail.com`
   - Password: `Rosh@101`
3. **Check console** for debug messages
4. **Should redirect** to beautiful student dashboard!

---

## Still Having Issues?

Share the console output (F12 → Console tab) and I'll help debug further!

The debug messages will show exactly what's happening:
- What username you entered
- What was found in Firebase
- Why login failed (if it did)

🚀 Try it now!
