# Add Upcoming Events to Firebase

## Quick Guide to Add Dummy Events

### Method 1: Firebase Console (Manual)

1. **Open Firebase Console**
   - Go to https://console.firebase.google.com
   - Select your EdLab project

2. **Navigate to Firestore**
   - Click "Firestore Database"
   - Find or create `announcements` collection

3. **Add Each Event Below**

---

### Event 1: Guest Lecture
**Document ID:** Auto-generate

```json
{
  "title": "Guest Lecture: Future of AI",
  "content": "Auditorium",
  "postedDate": "2024-02-09T14:00:00Z",
  "priority": "medium",
  "isActive": true,
  "type": "lecture",
  "location": "Main Auditorium",
  "department": "CSE"
}
```

---

### Event 2: Mid-Term Exam
**Document ID:** Auto-generate

```json
{
  "title": "Data Structure Mid-Term Exam",
  "content": "Exam Hall B",
  "postedDate": "2024-02-12T09:00:00Z",
  "priority": "high",
  "isActive": true,
  "type": "exam",
  "location": "Exam Hall B",
  "department": "CSE"
}
```

---

### Event 3: Project Submission
**Document ID:** Auto-generate

```json
{
  "title": "Python Project Submission",
  "content": "Online Portal",
  "postedDate": "2024-02-15T23:59:00Z",
  "priority": "high",
  "isActive": true,
  "type": "assignment",
  "location": "Online",
  "department": "CSE"
}
```

---

### Event 4: Workshop
**Document ID:** Auto-generate

```json
{
  "title": "Android Development Workshop",
  "content": "Computer Lab 3",
  "postedDate": "2024-02-16T10:00:00Z",
  "priority": "medium",
  "isActive": true,
  "type": "workshop",
  "location": "Computer Lab 3",
  "department": "CSE"
}
```

---

### Event 5: Sports Event
**Document ID:** Auto-generate

```json
{
  "title": "Inter-Department Football Match",
  "content": "Sports Ground",
  "postedDate": "2024-02-17T16:00:00Z",
  "priority": "low",
  "isActive": true,
  "type": "sports",
  "location": "Sports Ground",
  "department": "All"
}
```

---

### Event 6: Seminar
**Document ID:** Auto-generate

```json
{
  "title": "Career Guidance Seminar",
  "content": "Seminar Hall",
  "postedDate": "2024-02-19T15:00:00Z",
  "priority": "medium",
  "isActive": true,
  "type": "seminar",
  "location": "Seminar Hall",
  "department": "All"
}
```

---

## Field Descriptions

| Field | Type | Description |
|-------|------|-------------|
| title | string | Event name/title |
| content | string | Brief description or location |
| postedDate | timestamp | Event date and time |
| priority | string | "high", "medium", or "low" |
| isActive | boolean | true to show, false to hide |
| type | string | Event category |
| location | string | Where the event takes place |
| department | string | Which department (or "All") |

---

## Priority Colors

- **high** → Red icon (urgent events like exams)
- **medium** → Blue icon (normal events)
- **low** → Default icon (optional events)

---

## What Happens After Adding

Once you add these events to Firebase:

1. **Academics screen** will automatically load them
2. **Shows top 3** most recent events
3. **Real-time updates** - no app restart needed
4. **Sorted by date** - newest first
5. **Color-coded** by priority

---

## Current Fallback (If Firebase is Empty)

The app now shows 6 dummy events when Firebase has no data:

1. ✅ Guest Lecture: Future of AI
2. ✅ Data Structure Mid-Term Exam
3. ✅ Python Project Submission
4. ✅ Android Development Workshop
5. ✅ Inter-Department Football Match
6. ✅ Career Guidance Seminar

These appear automatically if the `announcements` collection is empty!

---

## Testing

### Without Firebase Data
1. Run app
2. Go to Academics tab
3. See 6 dummy events displayed

### With Firebase Data
1. Add events to Firebase (using guide above)
2. Run app (or hot reload)
3. See real events from Firebase
4. Only top 3 most recent shown
5. Click "See All" to view more (future feature)

---

## Quick Add via Firebase Console

1. **Firestore Database** → `announcements` collection
2. **Add document** → Auto-generate ID
3. **Add fields:**
   - title (string)
   - content (string)
   - postedDate (timestamp) - Click calendar icon
   - priority (string) - "high", "medium", or "low"
   - isActive (boolean) - true
   - type (string)
   - location (string)
   - department (string)
4. **Save**
5. **Repeat** for each event

---

## Success! 🎉

Your Academics screen now shows:
- ✅ 6 dummy events as fallback
- ✅ Real-time Firebase events when available
- ✅ Color-coded by priority
- ✅ Sorted by date
- ✅ Beautiful UI

Try it now! 🚀
