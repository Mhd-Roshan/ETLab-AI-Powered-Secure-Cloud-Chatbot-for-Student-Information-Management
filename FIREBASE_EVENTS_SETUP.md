# Firebase Events Setup Guide

## 3 Ways to Add Events to Firebase

Choose the method that works best for you:

---

## Method 1: Run Dart Script (Easiest & Fastest) ⚡

### Step 1: Run the Script
```bash
dart run add_events_to_firebase.dart
```

### Step 2: Wait for Completion
You'll see output like:
```
🚀 Starting Firebase Events Seeder...

📝 Adding 8 events to Firebase...

✅ [1/8] Added: Guest Lecture: Future of AI
✅ [2/8] Added: Data Structure Mid-Term Exam
✅ [3/8] Added: Python Project Submission
...

📊 Summary:
   ✅ Successfully added: 8 events
🎉 Done!
```

### Step 3: Verify
- Open Firebase Console
- Go to Firestore Database
- Check `announcements` collection
- You should see 8 new documents!

---

## Method 2: Firebase Console (Manual) 🖱️

### Step 1: Open Firebase Console
1. Go to https://console.firebase.google.com
2. Select your EdLab project
3. Click "Firestore Database"

### Step 2: Create Collection
1. Click "Start collection" (if `announcements` doesn't exist)
2. Collection ID: `announcements`
3. Click "Next"

### Step 3: Add Each Event

#### Event 1: Guest Lecture
Click "Add document" → Auto-generate ID

**Fields:**
- `title` (string): `Guest Lecture: Future of AI`
- `content` (string): `Join us for an insightful session on Artificial Intelligence`
- `postedDate` (timestamp): Click calendar → Select tomorrow's date, 2:00 PM
- `priority` (string): `medium`
- `isActive` (boolean): `true`
- `type` (string): `lecture`
- `location` (string): `Main Auditorium`
- `department` (string): `CSE`
- `time` (string): `2:00 PM`
- `speaker` (string): `Dr. John Smith`

Click "Save"

#### Event 2: Mid-Term Exam
Click "Add document" → Auto-generate ID

**Fields:**
- `title` (string): `Data Structure Mid-Term Exam`
- `content` (string): `Mid-term examination for Data Structures course`
- `postedDate` (timestamp): 4 days from now, 9:00 AM
- `priority` (string): `high`
- `isActive` (boolean): `true`
- `type` (string): `exam`
- `location` (string): `Exam Hall B`
- `department` (string): `CSE`
- `time` (string): `9:00 AM`
- `duration` (string): `2 hours`

Click "Save"

#### Event 3: Project Submission
**Fields:**
- `title`: `Python Project Submission`
- `content`: `Final project submission deadline for Python Programming`
- `postedDate`: 7 days from now, 11:59 PM
- `priority`: `high`
- `isActive`: `true`
- `type`: `assignment`
- `location`: `Online Portal`
- `department`: `CSE`
- `time`: `11:59 PM`

#### Event 4: Workshop
**Fields:**
- `title`: `Android Development Workshop`
- `content`: `Hands-on workshop on building Android apps with Flutter`
- `postedDate`: 8 days from now, 10:00 AM
- `priority`: `medium`
- `isActive`: `true`
- `type`: `workshop`
- `location`: `Computer Lab 3`
- `department`: `CSE`
- `time`: `10:00 AM`
- `duration`: `3 hours`

#### Event 5: Sports Event
**Fields:**
- `title`: `Inter-Department Football Match`
- `content`: `CSE vs ECE - Annual sports tournament`
- `postedDate`: 9 days from now, 4:00 PM
- `priority`: `low`
- `isActive`: `true`
- `type`: `sports`
- `location`: `Sports Ground`
- `department`: `All`
- `time`: `4:00 PM`

#### Event 6: Seminar
**Fields:**
- `title`: `Career Guidance Seminar`
- `content`: `Industry experts share insights on career opportunities`
- `postedDate`: 11 days from now, 3:00 PM
- `priority`: `medium`
- `isActive`: `true`
- `type`: `seminar`
- `location`: `Seminar Hall`
- `department`: `All`
- `time`: `3:00 PM`

#### Event 7: Quiz Competition
**Fields:**
- `title`: `Mathematics Quiz Competition`
- `content`: `Test your mathematical skills and win prizes`
- `postedDate`: 5 days from now, 2:30 PM
- `priority`: `low`
- `isActive`: `true`
- `type`: `competition`
- `location`: `Room A-201`
- `department`: `All`
- `time`: `2:30 PM`

#### Event 8: Tech Fest
**Fields:**
- `title`: `Technical Fest Registration`
- `content`: `Register for the annual technical festival TechFest 2024`
- `postedDate`: 3 days from now
- `priority`: `high`
- `isActive`: `true`
- `type`: `event`
- `location`: `Online Registration`
- `department`: `All`
- `time`: `Open Now`

---

## Method 3: Import JSON (Advanced) 📄

### Step 1: Use Firebase CLI
```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firestore
firebase init firestore
```

### Step 2: Import Data
```bash
# Use the firebase_events.json file
firebase firestore:import firebase_events.json
```

---

## Event Structure Reference

### Required Fields
| Field | Type | Description | Example |
|-------|------|-------------|---------|
| title | string | Event name | "Guest Lecture: Future of AI" |
| content | string | Description | "Join us for..." |
| postedDate | timestamp | Event date/time | Feb 10, 2024 2:00 PM |
| priority | string | "high", "medium", "low" | "high" |
| isActive | boolean | Show/hide event | true |
| type | string | Event category | "lecture", "exam", etc. |
| location | string | Where it happens | "Main Auditorium" |
| department | string | Which dept or "All" | "CSE" or "All" |

### Optional Fields
- `time` (string): Display time
- `duration` (string): How long
- `speaker` (string): Who's speaking
- `deadline` (string): Submission deadline
- `registrationRequired` (boolean): Need to register?

---

## Priority Colors

The app displays different colors based on priority:

- **high** → 🔴 Red icon (Exams, urgent deadlines)
- **medium** → 🔵 Blue icon (Lectures, workshops)
- **low** → ⚪ Default icon (Sports, optional events)

---

## Testing After Adding Events

### Step 1: Run Your App
```bash
flutter run -d chrome
```

### Step 2: Login
- Username: `rosh@gmail.com`
- Password: `Rosh@101`

### Step 3: Go to Academics Tab
- Tap "Academics" in bottom navigation

### Step 4: Check Upcoming Section
- Scroll to "Upcoming" section
- You should see your events!
- Top 3 most recent events displayed
- Click "See All" to view more (future feature)

---

## Troubleshooting

### Events Not Showing?
1. **Check Firestore Rules:**
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /announcements/{document} {
         allow read: if true;
         allow write: if true; // For testing only!
       }
     }
   }
   ```

2. **Verify Collection Name:**
   - Must be exactly `announcements` (lowercase, plural)

3. **Check Field Names:**
   - All field names are case-sensitive
   - `isActive` must be boolean `true`
   - `postedDate` must be timestamp type

4. **Hot Reload:**
   - Press `r` in terminal to hot reload
   - Or restart the app

### Script Errors?
```bash
# Make sure you're in the project directory
cd path/to/edlab

# Run with full path
dart run add_events_to_firebase.dart

# If Firebase not initialized, check firebase_options.dart exists
```

---

## Quick Verification Checklist

- [ ] Firebase Console → Firestore Database opened
- [ ] `announcements` collection exists
- [ ] At least 3-8 documents added
- [ ] Each document has required fields
- [ ] `isActive` is `true` (boolean)
- [ ] `postedDate` is timestamp type
- [ ] App running and logged in
- [ ] Academics tab opened
- [ ] Events visible in "Upcoming" section

---

## Success! 🎉

Once events are added, your app will:
- ✅ Show real-time events from Firebase
- ✅ Display top 3 most recent events
- ✅ Color-code by priority
- ✅ Sort by date automatically
- ✅ Update without app restart

**Choose your preferred method and add the events now!** 🚀

---

## Recommended: Use Method 1 (Dart Script)

It's the fastest and most reliable:
```bash
dart run add_events_to_firebase.dart
```

Takes only 5 seconds! ⚡
